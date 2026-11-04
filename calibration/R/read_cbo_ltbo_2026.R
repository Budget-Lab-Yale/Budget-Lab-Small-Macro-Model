# ==============================================================================
# Read CBO February 2026 Long-Term Outlook Workbooks
# ==============================================================================

suppressPackageStartupMessages({
  library(digest)
  library(openxlsx)
})

find_calibration_root <- function(start = getwd()) {
  path <- normalizePath(start, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(path, "calibration", "source_manifest.csv"))) return(path)
    parent <- dirname(path)
    if (identical(parent, path)) stop("Could not locate BLSMM project root")
    path <- parent
  }
}

resolve_manifest_source <- function(source_id, root = find_calibration_root(),
                                    verify_hash = TRUE) {
  manifest <- read.csv(file.path(root, "calibration", "source_manifest.csv"),
                       stringsAsFactors = FALSE)
  entry <- manifest[manifest$source_id == source_id, , drop = FALSE]
  if (nrow(entry) != 1L) stop("Manifest must contain exactly one entry for ", source_id)
  path <- normalizePath(file.path(root, entry$path), mustWork = TRUE)
  if (verify_hash) {
    actual <- digest(path, algo = "sha256", file = TRUE)
    if (!identical(actual, entry$sha256)) {
      stop("SHA-256 mismatch for ", source_id, ": expected ", entry$sha256,
           ", got ", actual)
    }
  }
  path
}

read_cached_sheet <- function(path, sheet) {
  read.xlsx(path, sheet = sheet, colNames = FALSE,
            skipEmptyRows = FALSE, skipEmptyCols = FALSE)
}

numeric_row_by_year <- function(sheet, row, year_row, years) {
  source_years <- suppressWarnings(as.integer(unlist(sheet[year_row, ], use.names = FALSE)))
  columns <- match(years, source_years)
  if (anyNA(columns)) stop("Missing requested source years: ", paste(years[is.na(columns)], collapse = ", "))
  as.numeric(unlist(sheet[row, columns], use.names = FALSE))
}

#' Read and transform the February 2026 CBO LTBO sources
#'
#' The fiscal ratio conversion uses the same-year calendar output gap as an
#' explicit approximation: ratio_to_potential = ratio_to_actual * actual/potential.
#' The returned provenance table flags this convention for review.
#'
#' @param years Years to extract (default 2026-2056)
#' @param root Project root
#' @param verify_hash Verify source workbooks against the manifest
#' @return List with economic, budget, model_inputs, targets, provenance, and
#'   unresolved_assumptions components
read_cbo_ltbo_2026 <- function(years = 2026:2056,
                               root = find_calibration_root(),
                               verify_hash = TRUE) {
  economic_path <- resolve_manifest_source("ltbo_economic", root, verify_hash)
  budget_path <- resolve_manifest_source("ltbo_budget", root, verify_hash)

  rates <- read_cached_sheet(economic_path, "1. Econ Vars_Annual Rates")
  levels <- read_cached_sheet(economic_path, "3. Econ Vars_Annual Levels")
  budget_sheet <- read_cached_sheet(budget_path, "Supplemental Table 1")

  econ_rate <- function(row) numeric_row_by_year(rates, row, 8, years)
  econ_level <- function(row) numeric_row_by_year(levels, row, 7, years)

  economic <- data.frame(
    year = years,
    gstar = econ_rate(10),
    glfstar = econ_rate(11),
    glqstar = econ_rate(12),
    real_gdp_growth = econ_rate(13),
    nominal_gdp_growth = econ_rate(15),
    unemployment = econ_rate(25),
    noncyclical_unemployment = econ_rate(26),
    pce_inflation = econ_rate(39),
    cpi_inflation = econ_rate(40),
    gdp_price_inflation = econ_rate(41),
    real_r10 = econ_rate(45),
    nominal_r10 = econ_rate(46),
    published_debt_rate = econ_rate(47),
    real_gdp = econ_level(8),
    nominal_gdp_calendar = econ_level(9),
    real_potential_gdp = econ_level(10),
    gdp_price_index = econ_level(11),
    potential_labor_force = econ_level(22),
    stringsAsFactors = FALSE
  )
  economic$xgap <- 100 * (economic$real_gdp / economic$real_potential_gdp - 1)
  economic$nominal_potential_gdp <- economic$real_potential_gdp * economic$gdp_price_index

  budget_years <- suppressWarnings(as.integer(unlist(budget_sheet[, 1], use.names = FALSE)))
  budget_rows <- match(years, budget_years)
  if (anyNA(budget_rows)) stop("Budget workbook is missing requested years")
  b <- function(column) as.numeric(unlist(budget_sheet[budget_rows, column], use.names = FALSE))

  budget <- data.frame(
    year = years,
    revenues_pct_gdp = b(2),
    noninterest_outlays_pct_gdp = b(8),
    net_interest_pct_gdp = b(9),
    total_outlays_pct_gdp = b(10),
    primary_balance_pct_gdp = b(11),
    total_balance_pct_gdp = b(12),
    debt_pct_gdp = b(13),
    nominal_gdp_fiscal = b(16) / 1000,
    stringsAsFactors = FALSE
  )

  # Convert fiscal-year ratios published relative to actual GDP into BLSMM's
  # potential-GDP denominator using the same-year calendar output gap.
  actual_to_potential <- 1 + economic$xgap / 100
  budget$actual_to_potential_factor <- actual_to_potential
  budget$revenues_pct_potential_gdp <- budget$revenues_pct_gdp * actual_to_potential
  budget$noninterest_outlays_pct_potential_gdp <-
    budget$noninterest_outlays_pct_gdp * actual_to_potential
  budget$primary_balance_pct_potential_gdp <-
    budget$primary_balance_pct_gdp * actual_to_potential
  budget$primary_balance_rounding_gap <- budget$primary_balance_pct_potential_gdp -
    (budget$revenues_pct_potential_gdp - budget$noninterest_outlays_pct_potential_gdp)

  budget$net_interest_dollars <- budget$net_interest_pct_gdp / 100 * budget$nominal_gdp_fiscal
  budget$debt_dollars <- budget$debt_pct_gdp / 100 * budget$nominal_gdp_fiscal
  # CBO's published debt rate equals current net interest divided by prior-year
  # debt. It provides a source-consistent 2025 debt anchor for the first average.
  prior_debt <- c(
    budget$net_interest_dollars[1] / (economic$published_debt_rate[1] / 100),
    head(budget$debt_dollars, -1)
  )
  budget$effective_rate_average_debt <-
    100 * budget$net_interest_dollars / ((prior_debt + budget$debt_dollars) / 2)

  model_inputs <- data.frame(
    year = years,
    glqstar = economic$glqstar,
    glfstar = economic$glfstar,
    rgfr_star = budget$revenues_pct_potential_gdp,
    rgfop_star = budget$noninterest_outlays_pct_potential_gdp,
    # Enforce the BLSMM identity. The separately published primary balance is
    # retained above as a rounding cross-check (CBO ratios have three decimals).
    rbudp_star = budget$revenues_pct_potential_gdp -
      budget$noninterest_outlays_pct_potential_gdp,
    UN = economic$noncyclical_unemployment,
    gstar = economic$gstar,
    RG_base = budget$effective_rate_average_debt,
    stringsAsFactors = FALSE
  )

  targets <- data.frame(
    year = years,
    xgap = economic$xgap,
    U = economic$unemployment,
    PI = economic$gdp_price_inflation,
    R10 = economic$nominal_r10,
    RG = budget$effective_rate_average_debt,
    stringsAsFactors = FALSE
  )

  provenance <- data.frame(
    model_series = c(
      "glqstar", "glfstar", "UN", "xgap", "U", "PI", "R10",
      "rgfr_star", "rgfop_star", "rbudp_star", "RG"
    ),
    source_id = c(rep("ltbo_economic", 7), rep("ltbo_budget", 4)),
    sheet = c(
      rep("1. Econ Vars_Annual Rates", 3), "3. Econ Vars_Annual Levels",
      "1. Econ Vars_Annual Rates", "1. Econ Vars_Annual Rates",
      "1. Econ Vars_Annual Rates", rep("Supplemental Table 1", 4)
    ),
    source_row_or_columns = c(
      "row 12", "row 11", "row 26", "levels rows 8 and 10", "row 25",
      "row 41", "row 46", "column 2", "column 8", "column 11",
      "columns 9, 13, and 16 (GDP converted from billions to trillions)"
    ),
    transformation = c(
      rep("direct", 3), "100 * (real GDP / real potential GDP - 1)",
      rep("direct", 3),
      rep("published ratio * (1 + calendar-year xgap / 100)", 3),
      "100 * net interest / average(current and prior debt)"
    ),
    stringsAsFactors = FALSE
  )

  list(
    years = years,
    economic = economic,
    budget = budget,
    model_inputs = model_inputs,
    targets = targets,
    provenance = provenance,
    unresolved_assumptions = c(
      "pistar path",
      "rfstar path",
      "tp_0 path",
      "rbar10 path",
      "R10 split between MPE10 and TP",
      "PIE target/forcing convention",
      "calendar-year versus fiscal-year alignment approval",
      "post-detailed-window residual convergence"
    ),
    source_paths = c(economic = economic_path, budget = budget_path)
  )
}
