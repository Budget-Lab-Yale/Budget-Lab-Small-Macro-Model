# ==============================================================================
# Build the spliced LTBO-centered calibration inputs.
#
# Overlap years (2026-2035): reuse the original v1.8 baseline FY paths.
# Extension years (2036+):  LTBO-derived, CY->FY converted, with the recorded
#                           Gate C conventions (calibration/config/cbo_ltbo_2026.yaml).
#
# Returns the pieces consumed by calibrate_residuals_v1_8(): an extended
# baseline_exog, a zero-extended baseline_resid, the unchanged historical
# anchor, and the forced target paths (xgap, U, PI, RF, MPE10, TP) over the
# whole horizon. PIE and RG are left structural.
#
# Convention (matching model/v1_8/calibration.R): sourced with getwd() at the
# project root.
# ==============================================================================

source("calibration/R/read_cbo_ltbo_2026.R")   # defines find_calibration_root
source("calibration/R/frequency.R")

#' Load the recorded Gate C conventions (config/cbo_ltbo_2026.yaml).
load_ltbo_config <- function(root = find_calibration_root()) {
  yaml::read_yaml(file.path(root, "calibration", "config", "cbo_ltbo_2026.yaml"))
}

#' Rebuild the calendar-year federal funds rate from hash-verified public CBO files.
build_cbo_ffr_cy <- function(years = 2026:2056,
                             root = find_calibration_root(),
                             config = load_ltbo_config(root),
                             verify_hash = TRUE) {
  rule <- config$rates$ffr
  if (is.null(rule) || !identical(rule$extension_rule, "lag_ffr_plus_change_ltbo_r10")) {
    stop("Config must specify rates.ffr.extension_rule = lag_ffr_plus_change_ltbo_r10")
  }
  if (!length(years) || anyNA(years) || any(years != as.integer(years)) ||
      any(diff(years) != 1L)) stop("FFR years must be consecutive ascending integers")
  detailed <- rule$detailed_forecast
  if (is.null(detailed$through_year) || is.null(detailed$year_row) ||
      is.null(detailed$label) || is.null(detailed$sheet) ||
      is.null(detailed$source_id)) stop("Incomplete FFR detailed_forecast config")
  path <- resolve_manifest_source(detailed$source_id, root, verify_hash)
  sheet <- read_cached_sheet(path, detailed$sheet)
  row <- which(trimws(as.character(sheet[[1]])) == detailed$label)
  if (length(row) != 1L) stop("Expected exactly one row labelled ", detailed$label, " in ", path)
  through_year <- detailed$through_year
  detailed_years <- seq.int(min(years[1], through_year), min(max(years), through_year))
  values <- numeric_row_by_year(sheet, row, detailed$year_row, detailed_years)
  if (any(!is.finite(values))) stop("Missing/nonfinite detailed CBO FFR in ", path)
  ffr <- data.frame(year = detailed_years, ffr = values)
  if (max(years) > through_year) {
    ltbo <- read_cbo_ltbo_2026(years = through_year:max(years), root = root,
                              verify_hash = verify_hash)
    yields <- ltbo$economic$nominal_r10
    if (any(!is.finite(yields))) stop("Missing/nonfinite LTBO nominal 10-year yield")
    tail_ffr <- tail(ffr$ffr, 1) + cumsum(diff(yields))
    ffr <- rbind(ffr, data.frame(year = (through_year + 1):max(years), ffr = tail_ffr))
  }
  ffr[match(years, ffr$year), , drop = FALSE]
}

# Parameter defaults are read from the YAML config so that editing the
# documented conventions actually changes the build. Pass an explicit value to
# override (e.g. for sensitivity runs). rbar10_terminal = NULL means "hold the
# baseline's end-of-overlap value", per the config's rbar10: baseline setting.
build_ltbo_calibration_inputs <- function(end_year = 2056,
                                          root = find_calibration_root(),
                                          config = load_ltbo_config(root),
                                          tp_0_terminal = config$rates$tp_0$terminal,
                                          pistar = config$rates$pistar,
                                          rfstar_terminal = config$rates$rfstar_terminal,
                                          rbar10_terminal = NULL,
                                          xgap_decay_years = config$output_gap$decay_years,
                                          xgap_decay_residual = config$output_gap$decay_residual,
                                          verify_hash = TRUE) {
  rd <- function(p) read.csv(file.path(root, p), check.names = FALSE)
  base_exog  <- rd("data/blsmm_v1_8_forecast_exog.csv")    # 2026-2035
  base_resid <- rd("data/blsmm_v1_8_forecast_resid.csv")   # 2026-2035
  base_soln  <- rd("data/blsmm_v1_8_baseline_solution.csv")

  overlap_years <- base_exog$year
  split_year <- max(overlap_years)                          # 2035
  ext_years <- (split_year + 1):end_year                    # 2036..end
  if (is.null(rbar10_terminal))
    rbar10_terminal <- base_exog$rbar10[base_exog$year == split_year]

  # ---- targets over the overlap: the baseline's own solution -----------------
  overlap_targets <- data.frame(
    year  = overlap_years,
    xgap  = base_soln$xgap,  U = base_soln$U, PI = base_soln$PI,
    RF    = base_soln$RF,    MPE10 = base_soln$MPE10, TP = base_soln$TP,
    stringsAsFactors = FALSE
  )

  # ---- LTBO tail: read split_year..end so CY->FY has its lag -----------------
  ltbo <- read_cbo_ltbo_2026(years = split_year:end_year, root = root,
                             verify_hash = verify_hash)
  e <- ltbo$economic
  cy <- data.frame(year = e$year, U = e$unemployment, R10 = e$nominal_r10,
                   PI = e$gdp_price_inflation, real_gdp = e$real_gdp,
                   real_potential_gdp = e$real_potential_gdp)
  ext_targets <- build_gate_c_targets(cy, tp_0 = tp_0_terminal, pistar = pistar)
  # Apply the public-CBO FFR extension rule in calendar years, then convert to FY.
  ffr_cy <- build_cbo_ffr_cy(split_year:end_year, root, config, verify_hash)$ffr
  if (anyNA(ffr_cy)) stop("Public CBO FFR missing years ", split_year, "..", end_year)
  ext_targets$RF <- cy_to_fy(ffr_cy)
  ext_targets <- ext_targets[, c("year", "xgap", "U", "PI", "RF", "MPE10", "TP")]

  forced_targets <- rbind(overlap_targets, ext_targets)

  # Close the output gap after the detailed CBO window. CBO's extended baseline
  # carries a small persistent gap that is economically implausible in the long
  # run; decay it exponentially toward 0, reaching xgap_decay_residual of the
  # end-of-window (split_year) gap after xgap_decay_years years.
  if (is.null(xgap_decay_years) || is.null(xgap_decay_residual)) {
    stop("output_gap.decay_years and output_gap.decay_residual are required in ",
         "calibration/config/cbo_ltbo_2026.yaml (set decay_years: 0 to switch the decay off)")
  }
  if (xgap_decay_years > 0) {
    anchor <- forced_targets$xgap[forced_targets$year == split_year]
    k <- forced_targets$year - split_year
    past <- k > 0
    forced_targets$xgap[past] <-
      anchor * xgap_decay_residual^(k[past] / xgap_decay_years)
  }

  # ---- extension exogenous: LTBO model inputs + Gate C constants -------------
  mi <- ltbo$model_inputs            # split_year..end
  fy <- function(v) cy_to_fy(v)      # CY->FY for the growth/rate inputs
  keep <- match(ext_years, mi$year)  # 2036..end rows of the model-input frame
  ext_exog <- data.frame(
    year       = ext_years,
    glqstar    = fy(mi$glqstar),                 # CY growth -> FY
    glfstar    = fy(mi$glfstar),
    rgfr_star  = mi$rgfr_star[keep],             # FY budget ratios (already FY)
    rgfop_star = mi$rgfop_star[keep],
    rbudp_star = mi$rbudp_star[keep],
    UN         = fy(mi$UN),                      # CY rate -> FY
    pistar     = pistar,
    rfstar     = rfstar_terminal,
    tp_0       = tp_0_terminal,
    rbar10     = rbar10_terminal,
    gstar      = fy(mi$gstar),                   # CY growth -> FY
    RG_base    = mi$RG_base[keep],               # FY effective debt rate
    stringsAsFactors = FALSE
  )

  stopifnot(identical(names(ext_exog), names(base_exog)))
  exog <- rbind(base_exog, ext_exog)

  # zero residuals for the extension; backed out by the calibration
  ext_resid <- base_resid[rep(1, length(ext_years)), , drop = FALSE]
  ext_resid[, ] <- 0
  ext_resid$year <- ext_years
  resid <- rbind(base_resid, ext_resid)

  list(
    baseline_exog  = exog,
    baseline_resid = resid,
    forced_targets = forced_targets,
    n_periods      = nrow(exog),
    years          = exog$year,
    split_year     = split_year
  )
}

#' Assemble the SPF-style forcing spec (force xgap,U,PI,RF,MPE10,TP) from targets.
build_ltbo_forcing_spec <- function(forced_targets, create_forcing_spec) {
  n <- nrow(forced_targets)
  fs <- create_forcing_spec(n)
  map <- c(xgap = "xgap", U = "u", PI = "pi", RF = "rf", MPE10 = "mpe", TP = "tp")
  for (v in names(map)) {
    s <- map[[v]]
    fs[[paste0("force_", s)]]  <- rep(1L, n)
    fs[[paste0("forced_", s)]] <- forced_targets[[v]]
  }
  fs   # PIE and RG left structural
}
