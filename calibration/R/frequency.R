# ==============================================================================
# Calendar-year to fiscal-year conversion and Gate C convention application
# for the CBO February-2026 LTBO-centered baseline.
#
# Decisions recorded in calibration/config/cbo_ltbo_2026.yaml.
# ==============================================================================

#' Calendar-year to fiscal-year conversion (3/4-1/4 rule).
#'
#' A U.S. fiscal year t spans October (t-1) through September (t): one quarter
#' falls in calendar year t-1 and three quarters in calendar year t. Hence
#'   FY(t) = 0.75 * CY(t) + 0.25 * CY(t-1).
#' This is an annual-rate approximation appropriate for the LTBO economic series
#' (unemployment, the 10-year rate, real and potential GDP), which CBO publishes
#' only on a calendar-year basis past the 10-year window.
#'
#' @param cy Numeric vector of calendar-year values in ascending year order. The
#'   first element is used only as the lag for the second; the result has length
#'   length(cy) - 1 and is aligned to calendar years cy[-1].
#' @return Fiscal-year values for the second through last input years.
cy_to_fy <- function(cy) {
  if (!is.numeric(cy)) stop("cy_to_fy: 'cy' must be numeric")
  if (length(cy) < 2L) stop("cy_to_fy: need a prior and a current year (length >= 2)")
  if (anyNA(cy)) stop("cy_to_fy: NA values are not permitted")
  0.75 * cy[-1L] + 0.25 * cy[-length(cy)]
}

#' Apply the recorded Gate C conventions to LTBO calendar-year series.
#'
#' Converts the calendar-year economic series to fiscal year and assembles the
#' fiscal-year model targets for the extension window. The input must include one
#' leading prior calendar year (e.g. pass 2035:2056 to produce FY 2036:2056).
#'
#' Conventions (config/cbo_ltbo_2026.yaml):
#'   - U, R10, and the GDP levels behind xgap are CY->FY converted (3/4-1/4);
#'   - xgap is formed from FY-converted real and potential GDP;
#'   - PI (GDP-price inflation, a flow) is converted the same way;
#'   - pistar is set to the CBO long-run value (default 2.0);
#'   - TP = tp_0 (carried baseline judgment); MPE10 = R10 - tp_0.
#' PIE and RG are intentionally left out; PIE is structural and RG is a
#' structural path cross-checked against avg_rate_debt.
#'
#' @param cy A data.frame in ascending year order with at least one leading prior
#'   year and columns: year, U, R10, PI, real_gdp, real_potential_gdp.
#' @param tp_0 Numeric term-premium path aligned to the OUTPUT years (length
#'   nrow(cy) - 1), or a scalar to be recycled.
#' @param pistar Long-run inflation target (default 2.0).
#' @return data.frame of fiscal-year targets for years cy$year[-1].
build_gate_c_targets <- function(cy, tp_0 = 1.0, pistar = 2.0) {
  required <- c("year", "U", "R10", "PI", "real_gdp", "real_potential_gdp")
  missing <- setdiff(required, names(cy))
  if (length(missing)) stop("build_gate_c_targets: missing columns: ",
                            paste(missing, collapse = ", "))
  if (is.unsorted(cy$year)) stop("build_gate_c_targets: 'cy' must be in ascending year order")

  out_years <- cy$year[-1L]
  n <- length(out_years)
  tp_0 <- if (length(tp_0) == 1L) rep(tp_0, n) else tp_0
  if (length(tp_0) != n) stop("build_gate_c_targets: tp_0 length must be ", n)

  rgdp_fy <- cy_to_fy(cy$real_gdp)
  pot_fy  <- cy_to_fy(cy$real_potential_gdp)
  R10_fy  <- cy_to_fy(cy$R10)

  data.frame(
    year   = out_years,
    xgap   = 100 * (rgdp_fy / pot_fy - 1),
    U      = cy_to_fy(cy$U),
    PI     = cy_to_fy(cy$PI),
    R10    = R10_fy,
    TP     = tp_0,                 # carried baseline term-premium judgment
    MPE10  = R10_fy - tp_0,        # reuse baseline split: MPE10 = R10 - tp_0
    pistar = pistar,
    stringsAsFactors = FALSE
  )
}
