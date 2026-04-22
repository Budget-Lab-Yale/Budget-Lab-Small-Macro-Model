N_PERIODS <- 10
TABLE_ROW_BASELINE <- 1
TABLE_ROW_DELTA <- 2
TABLE_ROW_LEVEL <- 3
TABLE_FIRST_DATA_COL <- 2

# Create fiscal year labels
create_fy_labels <- function(start_year = 2026, n_years = N_PERIODS) {
  paste0("FY", start_year:(start_year + n_years - 1))
}

# Create baseline data for input tables (3 rows: baseline, delta, level)
create_input_table <- function(baseline_values, variable_name) {
  n_periods <- length(baseline_values)
  fy_labels <- create_fy_labels(n_years = n_periods)

  # Create 3-row table
  table_data <- data.frame(
    Row = c("Baseline", "User Delta", "User Level"),
    stringsAsFactors = FALSE
  )

  # Add columns for each fiscal year
  for (i in 1:n_periods) {
    table_data[[fy_labels[i]]] <- c(
      round(baseline_values[i], 2),  # Baseline
      0.00,                          # Delta (user input)
      round(baseline_values[i], 2)   # Level (calculated)
    )
  }

  return(table_data)
}

# Extract deltas from handsontable
parse_table_deltas <- function(hot_data, n_periods = N_PERIODS) {
  if (is.null(hot_data)) {
    return(list(values = rep(0, n_periods), invalid_idx = integer(0)))
  }

  fy_cols <- seq(TABLE_FIRST_DATA_COL, TABLE_FIRST_DATA_COL + n_periods - 1)
  raw_vals <- as.character(unlist(hot_data[TABLE_ROW_DELTA, fy_cols], use.names = FALSE))
  raw_vals[is.na(raw_vals)] <- ""
  trimmed <- trimws(raw_vals)

  parsed <- suppressWarnings(as.numeric(trimmed))
  blank_mask <- trimmed == ""
  invalid_idx <- which(!blank_mask & is.na(parsed))
  parsed[blank_mask] <- 0

  list(values = parsed, invalid_idx = invalid_idx)
}

extract_deltas <- function(hot_data, n_periods = N_PERIODS) {
  parse_table_deltas(hot_data, n_periods)$values
}

# Map app tables to user_deltas structure (all 9 input types)
map_tables_to_user_deltas <- function(table_deltas, n_periods = N_PERIODS) {
  # Create empty user_deltas data frame
  user_deltas <- create_user_deltas(n_periods = n_periods)

  # Map all 9 tables to corresponding user_delta columns
  user_deltas$user_delta_lf <- table_deltas$table_lf_growth %||% rep(0, n_periods)
  user_deltas$user_delta_prod <- table_deltas$table_productivity %||% rep(0, n_periods)
  user_deltas$user_delta_rgfr <- table_deltas$table_receipts %||% rep(0, n_periods)
  user_deltas$user_delta_rgfop <- table_deltas$table_outlays %||% rep(0, n_periods)
  user_deltas$user_delta_rfstar_direct <- table_deltas$table_rfstar %||% rep(0, n_periods)
  user_deltas$user_delta_ADshock <- table_deltas$table_output_gap %||% rep(0, n_periods)
  user_deltas$user_delta_inflshock <- table_deltas$table_inflation_shock %||% rep(0, n_periods)
  user_deltas$user_delta_MPshock <- table_deltas$table_monetary_rule %||% rep(0, n_periods)
  user_deltas$user_delta_pistar <- table_deltas$table_inflation_target %||% rep(0, n_periods)

  return(user_deltas)
}

# ==============================================================================
# LFPR CONVERSION UTILITIES
# ==============================================================================

#' Convert LFPR target path to glfstar delta for BLSMM v1.8
#'
#' Given a target LFPR path and CBO population forecast, computes the glfstar
#' delta (in percentage points) that must be assigned to user_delta_glfstar
#' to achieve that LFPR path in the model. The model internally uses potential
#' labor force growth rates (glfstar), not LFPR directly.
#'
#' @param lfpr_target Numeric vector of length 10 (FY2026-FY2035). LFPR values
#'   in decimal form (e.g., 0.593 for 59.3%), not percent.
#' @param cnp Numeric vector of length 11 (FY2025, then FY2026-FY2035). Civilian
#'   noninstitutional population aged 16+, in millions. The FY2025 value is used
#'   only for computing lfpr_check; the recursion uses lf_anchor.
#' @param lf_anchor Scalar. FY2025 potential labor force level (millions) used
#'   as the starting point for the recursion. Default: 171.557 (BLSMM v1.8).
#' @param glfstar_base Numeric vector of length 10. Baseline potential labor
#'   force growth rates (% per year) for FY2026-FY2035. Default: CBO baseline
#'   values embedded in BLSMM v1.8.
#'
#' @return A list with four elements:
#'   \describe{
#'     \item{delta}{Length-10 numeric. The glfstar delta (pp) to assign to
#'       user_delta_glfstar[FY2026:FY2035] to achieve the target LFPR path.}
#'     \item{glfstar}{Length-10 numeric. Absolute glfstar values (audit only).}
#'     \item{lf_target}{Length-10 numeric. Implied LFstar levels in millions
#'       (audit only).}
#'     \item{lfpr_check}{Length-10 numeric. Should equal lfpr_target to machine
#'       precision; if not, cnp series is inconsistent.}
#'   }
#'
#' @examples
#' cnp_ex <- seq(270, 280, length.out = 11)  # illustrative, not real CBO
#' result  <- convert_lfpr_to_growth(rep(0.62, 10), cnp_ex)
#' stopifnot(length(result$delta) == 10)
#' stopifnot(max(abs(result$lfpr_check - 0.62)) < 1e-12)
convert_lfpr_to_growth <- function(
  lfpr_target,
  cnp,
  lf_anchor    = 171.557,
  glfstar_base = c(
    0.64002051796197,
    0.43149633662507014,
    0.4198385236447333,
    0.4238261508775265,
    0.4477714364141683,
    0.4839196351815289,
    0.45665981110374343,
    0.4269479146104205,
    0.41165436757981677,
    0.3965435275035567
  )
) {
  # Input validation
  if (length(lfpr_target) != 10)
    stop("lfpr_target must have length 10 (one value per FY2026-FY2035)")
  if (length(cnp) != 11)
    stop("cnp must have length 11: FY2025 value first, then FY2026-FY2035")
  if (length(glfstar_base) != 10)
    stop("glfstar_base must have length 10")
  if (any(lfpr_target <= 0) || any(lfpr_target >= 1))
    stop("lfpr_target values must be in (0,1) as decimals, e.g. 0.593 not 59.3")
  if (any(cnp <= 0))
    stop("cnp values must be positive (millions of people)")
  if (lf_anchor <= 0)
    stop("lf_anchor must be positive")

  # Step 1: Target LFstar levels (millions) for FY2026-FY2035
  lf_target <- lfpr_target * cnp[-1]

  # Step 2: Full LFstar path including FY2025 anchor
  lf_full <- c(lf_anchor, lf_target)

  # Step 3: Annual growth rates implied by the target LFstar path
  glfstar <- 100 * (lf_full[-1] / lf_full[-length(lf_full)] - 1)

  # Step 4: Delta vs baseline
  delta <- glfstar - glfstar_base

  # Step 5: Roundtrip check
  lfpr_check <- lf_target / cnp[-1]

  list(
    delta      = delta,
    glfstar    = glfstar,
    lf_target  = lf_target,
    lfpr_check = lfpr_check
  )
}

#' Build LFPR path with linear ramp and flat hold
#'
#' Constructs a 10-element LFPR vector (FY2026-FY2035) that ramps linearly
#' from a starting value (FY2025) to a target value by a specified year, then
#' stays flat. This matches the structure of Scenario 2 in Karger et al.
#' Table 25.
#'
#' @param lfpr_start Scalar numeric in (0, 1). LFPR level at FY2025 (the ramp
#'   starting point). Not included in the returned vector. Typically computed
#'   as 171.557 / cnp[1] where cnp[1] is the FY2025 CNP.
#' @param lfpr_target Scalar numeric in (0, 1). LFPR level to reach at
#'   ramp_end_year and hold flat thereafter.
#' @param ramp_end_year Integer. Fiscal year at which lfpr_target is first
#'   reached. Must be within horizon_years. Default: 2030.
#' @param horizon_years Integer vector. Forecast years. Default: 2026:2035.
#'
#' @return Named numeric vector of length 10 (FY2026-FY2035). LFPR values in
#'   decimal form. The value at ramp_end_year equals lfpr_target exactly; all
#'   subsequent years hold that value.
#'
#' @examples
#' # Scenario 2: 0.630 -> 0.593 by FY2030, flat thereafter
#' # (0.630 is illustrative; use 171.557 / cnp[1] with real CBO data)
#' path <- build_lfpr_path(lfpr_start = 0.630, lfpr_target = 0.593)
#' stopifnot(length(path) == 10)
#' stopifnot(unname(path["2030"]) == 0.593)
#' stopifnot(all(path[as.character(2031:2035)] == 0.593))
build_lfpr_path <- function(
  lfpr_start,
  lfpr_target,
  ramp_end_year  = 2030,
  horizon_years  = 2026:2035
) {
  # Input validation
  if (!is.numeric(lfpr_start) || lfpr_start <= 0 || lfpr_start >= 1)
    stop("lfpr_start must be a numeric scalar in (0, 1)")
  if (!is.numeric(lfpr_target) || lfpr_target <= 0 || lfpr_target >= 1)
    stop("lfpr_target must be a numeric scalar in (0, 1)")
  if (!ramp_end_year %in% horizon_years)
    stop("ramp_end_year must be within horizon_years")

  # Number of annual steps from first forecast year to ramp_end_year
  n_ramp <- ramp_end_year - min(horizon_years) + 1

  # Linear sequence from lfpr_start to lfpr_target
  ramp_values <- seq(lfpr_start, lfpr_target, length.out = n_ramp + 1)[-1]

  # Flat values for all years after ramp_end_year
  n_flat      <- length(horizon_years) - n_ramp
  flat_values <- rep(lfpr_target, n_flat)

  # Combine and name
  path        <- c(ramp_values, flat_values)
  names(path) <- as.character(horizon_years)
  path
}

#' Summarise LFPR scenario conversion for audit
#'
#' Thin wrapper around convert_lfpr_to_growth() that returns a data.frame
#' showing the full chain: LFPR target -> LFstar level -> glfstar -> delta.
#' Use this to inspect and verify the conversion before running the model.
#'
#' @param lfpr_target_vec Numeric vector of length 10 (FY2026-FY2035). LFPR
#'   values in decimal form. Typically the output of build_lfpr_path().
#' @param cnp Numeric vector of length 11 (FY2025-FY2035). CNP in millions.
#' @param lf_anchor Scalar. FY2025 LFstar level. Default: 171.557.
#' @param glfstar_base Numeric vector of length 10. Baseline glfstar values.
#'   Default: CBO baseline embedded in BLSMM v1.8.
#'
#' @return A data.frame with 10 rows (FY2026-FY2035) and 5 columns:
#'   \describe{
#'     \item{fy}{Fiscal year (2026-2035).}
#'     \item{lfpr_target}{Target LFPR (decimal).}
#'     \item{lf_implied_M}{Implied LFstar level (millions).}
#'     \item{glfstar_abs}{Absolute glfstar growth rate (%).}
#'     \item{delta_glfstar}{Delta vs baseline (pp). This column should be
#'       assigned to user_delta_glfstar.}
#'   }
summarise_lfpr_scenario <- function(
  lfpr_target_vec,
  cnp,
  lf_anchor    = 171.557,
  glfstar_base = c(
    0.64002051796197, 0.43149633662507014, 0.4198385236447333,
    0.4238261508775265, 0.4477714364141683, 0.4839196351815289,
    0.45665981110374343, 0.4269479146104205,
    0.41165436757981677, 0.3965435275035567
  )
) {
  res <- convert_lfpr_to_growth(
    lfpr_target  = lfpr_target_vec,
    cnp          = cnp,
    lf_anchor    = lf_anchor,
    glfstar_base = glfstar_base
  )

  data.frame(
    fy              = 2026:2035,
    lfpr_target     = lfpr_target_vec,
    lf_implied_M    = res$lf_target,
    glfstar_abs     = res$glfstar,
    delta_glfstar   = res$delta,
    stringsAsFactors = FALSE
  )
}

# ==============================================================================
# SIMPLE-MODE INPUT HELPERS
# ==============================================================================

#' Build a 10-year delta vector from a shape + magnitude
#'
#' Simple-mode inputs in the Assumptions drawer let the user pick a shape
#' ("permanent", "onetime", "ramp", "temporary3") and a magnitude rather
#' than typing 10 individual values. This function translates that pair
#' into the year-by-year vector the solver expects.
#'
#' @param shape One of "permanent", "onetime", "ramp", "temporary3".
#' @param magnitude Numeric scalar. If NA or NULL, returns all zeros.
#' @param n Integer. Horizon length (default N_PERIODS = 10).
#' @return Numeric vector of length n.
build_shape_delta <- function(shape, magnitude, n = N_PERIODS) {
  if (is.null(magnitude) || is.na(magnitude) || !is.finite(magnitude)) {
    return(rep(0, n))
  }
  shape <- shape %||% "permanent"
  switch(
    shape,
    "permanent"   = rep(magnitude, n),
    "onetime"     = c(magnitude, rep(0, n - 1)),
    "ramp"        = seq(0, magnitude, length.out = n),
    "temporary3"  = c(rep(magnitude, min(3, n)), rep(0, max(0, n - 3))),
    rep(0, n)
  )
}

#' Short preview string for a shape+magnitude delta vector.
#' Example: "0.20, 0.20, 0.20, ... 0.20" for a permanent +0.20.
format_shape_preview <- function(delta_vec, digits = 2) {
  if (length(delta_vec) <= 4) {
    return(paste(sprintf(paste0("%.", digits, "f"), delta_vec), collapse = ", "))
  }
  first3 <- sprintf(paste0("%.", digits, "f"), head(delta_vec, 3))
  last   <- sprintf(paste0("%.", digits, "f"), tail(delta_vec, 1))
  paste0(paste(first3, collapse = ", "), ", ..., ", last)
}

# Shape options presented in every simple-mode select input.
BLSMM_SHAPE_CHOICES <- c(
  "Permanent shift"     = "permanent",
  "One-time (year 1)"   = "onetime",
  "Linear ramp (0 → magnitude)" = "ramp",
  "Temporary (3 years)" = "temporary3"
)

#' Render a simple-mode input card for the Assumptions drawer
#'
#' Generates the per-input UI block: heading + example text, a shape
#' selector and magnitude input (side-by-side under wide drawer, stacked
#' under narrow), a small computed preview, and an expandable
#' "Edit year-by-year" details block that hosts the existing
#' rHandsontableOutput so advanced users can tweak individual cells.
#'
#' Server inputs created (example for `table_key = "productivity"`):
#'   input$shape_productivity, input$magnitude_productivity
#' Server outputs expected:
#'   output$preview_productivity (text rendering of the computed delta)
#'   output$table_productivity (handsontable, unchanged)
#'
#' @param table_key Short key used to derive input/output ids and the
#'   rHandsontableOutput id (prefixed "table_").
#' @param label Heading above the controls.
#' @param units Short units label placed after "Magnitude".
#' @param example Short example line shown in muted text.
simple_input_card <- function(table_key, label, units = "pp", example = NULL) {
  shape_id <- paste0("shape_",     table_key)
  mag_id   <- paste0("magnitude_", table_key)
  prev_id  <- paste0("preview_",   table_key)
  table_id <- paste0("table_",     table_key)

  shiny::div(
    class = "blsmm-input-card",

    shiny::h5(label),
    if (!is.null(example)) {
      shiny::p(class = "text-muted-custom", style = "font-size: 0.85em; margin-bottom: 10px;",
               shiny::HTML(example))
    },

    # Shape + magnitude side-by-side (stack under narrow drawer)
    bslib::layout_column_wrap(
      width = "200px",
      gap = "12px",
      shiny::selectInput(
        inputId = shape_id,
        label   = "Shape",
        choices = BLSMM_SHAPE_CHOICES,
        selected = "permanent",
        width = "100%"
      ),
      shiny::numericInput(
        inputId = mag_id,
        label   = paste0("Magnitude (", units, ")"),
        value   = 0,
        step    = 0.1,
        width   = "100%"
      )
    ),

    shiny::div(
      class = "blsmm-input-preview",
      shiny::textOutput(prev_id, inline = TRUE)
    ),

    # Advanced: expandable handsontable for year-by-year edits.
    shiny::tags$details(
      class = "blsmm-input-advanced",
      shiny::tags$summary(
        class = "text-link",
        style = "cursor: pointer; margin-top: 8px;",
        "Edit year-by-year"
      ),
      shiny::br(),
      rhandsontable::rHandsontableOutput(table_id, height = "180px")
    )
  )
}

# ==============================================================================
# USER INTERFACE
# ==============================================================================

