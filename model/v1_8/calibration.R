# ==============================================================================
# BLSMM v1.8 Residual Calibration
# ==============================================================================
# A calibration is a two-pass operation:
#   1. solve with selected endogenous paths forced;
#   2. back out the effective residuals at that solution and rerun unforced.
# The unforced pass must reproduce the forced pass if the residual accounting is
# internally consistent.
# ==============================================================================

source("model/v1_8/simulation.R", local = TRUE)
source("model/v1_8/forcing.R", local = TRUE)
source("model/v1_8/user_deltas.R", local = TRUE)

#' Calibrate residuals to a forced path and verify an unforced round trip
#'
#' @param baseline_exog Baseline exogenous data frame
#' @param baseline_resid Baseline residual data frame
#' @param hist_data Historical data frame
#' @param forcing_spec Active forcing specification
#' @param user_deltas User deltas (NULL means all zero)
#' @param n_periods Number of periods to calibrate
#' @param params Model parameters (NULL means v1.8 defaults)
#' @param expectations_speed Fast expectations adjustment flag
#' @param verbose Print simulation progress
#' @return List with forced run, calibrated baseline residuals, unforced run,
#'   and round-trip error diagnostics
calibrate_residuals_v1_8 <- function(baseline_exog,
                                     baseline_resid,
                                     hist_data,
                                     forcing_spec,
                                     user_deltas = NULL,
                                     n_periods = nrow(baseline_exog),
                                     params = NULL,
                                     expectations_speed = FALSE,
                                     verbose = TRUE) {
  if (missing(forcing_spec) || is.null(forcing_spec) ||
      !is_forcing_active(forcing_spec)) {
    stop("forcing_spec must force at least one variable")
  }
  if (is.null(user_deltas)) user_deltas <- create_user_deltas(n_periods)

  forced <- simulate_blsmm_v1_8(
    n_periods = n_periods,
    baseline_exog = baseline_exog,
    baseline_resid = baseline_resid,
    hist_data = hist_data,
    user_deltas = user_deltas,
    forcing_spec = forcing_spec,
    params = params,
    expectations_speed = expectations_speed,
    verbose = verbose,
    diagnostics = TRUE
  )

  calibrated_resid <- baseline_resid[seq_len(n_periods), , drop = FALSE]
  calibrated_resid$epsxgap <- forced$epsxgap_final - user_deltas$user_delta_ADshock
  calibrated_resid$epsu <- forced$epsu_final
  calibrated_resid$epspi <- forced$epspi_final - user_deltas$user_delta_inflshock
  calibrated_resid$epspie <- forced$epspie_final
  calibrated_resid$epsrf <- forced$epsrf_final - user_deltas$user_delta_MPshock
  calibrated_resid$epsmpe <- forced$epsmpe_final
  calibrated_resid$epstp <- forced$epstp_final
  calibrated_resid$epsrg <- forced$epsrg_final

  unforced <- simulate_blsmm_v1_8(
    n_periods = n_periods,
    baseline_exog = baseline_exog,
    baseline_resid = calibrated_resid,
    hist_data = hist_data,
    user_deltas = user_deltas,
    forcing_spec = create_forcing_spec(n_periods),
    params = params,
    expectations_speed = expectations_speed,
    verbose = verbose,
    diagnostics = TRUE
  )

  compared <- c("xgap", "U", "PI", "PIE", "RF", "MPE10", "TP", "R10", "RG")
  roundtrip_errors <- data.frame(
    variable = compared,
    max_abs_error = vapply(
      compared,
      function(variable) max(abs(forced[[variable]] - unforced[[variable]])),
      numeric(1)
    ),
    stringsAsFactors = FALSE
  )

  list(
    forced = forced,
    calibrated_resid = calibrated_resid,
    unforced = unforced,
    roundtrip_errors = roundtrip_errors,
    max_abs_roundtrip_error = max(roundtrip_errors$max_abs_error)
  )
}
