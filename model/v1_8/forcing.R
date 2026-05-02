# =============================================================
# FORCING MODULE — EXPERIMENTAL / DORMANT
# =============================================================
# This module implements a "forcing" API that allows callers
# to override specific endogenous variables (xgap, u, pi, pie,
# rf, mpe10, tp, rg) with user-specified paths.
#
# CURRENT STATUS: partially operational but not production-ready.
#
# Known incomplete behavior:
#   recompute_all_residuals() is defined here but is NOT called
#   by the solver after convergence. This means forced runs do
#   not store the implied residuals that would produce the forced
#   path — the returned simulation's residual columns still
#   reflect the original baseline residuals, not the back-computed
#   implied residuals.
#
# Usage in shipped code:
#   No shipped code passes a non-NULL forcing_spec. The app,
#   all scenario input files, all tests, and cache_baseline.R
#   all pass forcing_spec = NULL.
#
# To complete this feature would require:
#   1. solver.R to call recompute_all_residuals() after
#      nleqslv() converges, using the converged solution values
#   2. A decision on the output schema (overwrite original
#      eps* columns or add eps*_final columns)
#   3. Tests verifying the implied-residual accounting
#
# Do not rely on this module for production runs until the
# above is resolved.
# =============================================================
# ==============================================================================
# BLSMM Forcing (Override) System
# ==============================================================================
# Source: BLSMM_v1_8_exact_equation_sheet.pdf
# Section 3.6: Forcing operator (all forceable endogenous variables) (page 6)
# Section 3.8: Residual recomputation under forcing (page 7)
# ==============================================================================

#' Create Forcing Specification
#'
#' Initialize forcing specification with all flags set to 0 (no forcing)
#' Users can set force flags to 1 and provide forced values for "what-if" scenarios
#'
#' The 8 forceable variables are: XGAP, U, PI, PIE, RF, MPE10, TP, RG
#'
#' @param n_periods Number of forecast periods (default 10)
#' @return List with forcing specification
create_forcing_spec <- function(n_periods = 10) {
  list(
    # Force flags (0 = use structural + residual, 1 = use forced value)
    force_xgap = rep(0, n_periods),
    force_u = rep(0, n_periods),
    force_pi = rep(0, n_periods),
    force_pie = rep(0, n_periods),
    force_rf = rep(0, n_periods),
    force_mpe = rep(0, n_periods),
    force_tp = rep(0, n_periods),
    force_rg = rep(0, n_periods),

    # Forced values (only used if corresponding flag = 1)
    forced_xgap = rep(NA, n_periods),
    forced_u = rep(NA, n_periods),
    forced_pi = rep(NA, n_periods),
    forced_pie = rep(NA, n_periods),
    forced_rf = rep(NA, n_periods),
    forced_mpe = rep(NA, n_periods),
    forced_tp = rep(NA, n_periods),
    forced_rg = rep(NA, n_periods)
  )
}

#' Apply Forcing Operator
#'
#' Implements PDF Section 3.6, e.g., row 167:
#'   xgap = force_xgap * forced_xgap + (1 - force_xgap) * (xgap_struct + epsxgap)
#'
#' If force_flag = 1, use forced_value
#' If force_flag = 0, use structural_value + residual
#'
#' @param structural_value Structural value from equation
#' @param residual Residual (shock)
#' @param force_flag Force flag (0 or 1)
#' @param forced_value Forced value (if forcing active)
#' @return Actual value (forced or structural + residual)
apply_forcing <- function(structural_value, residual, force_flag, forced_value) {

  # Handle NA forced_value when not forcing
  if (force_flag == 0) {
    forced_value <- 0  # Won't be used, but avoid NA arithmetic
  }

  # Forcing formula
  actual_value <- force_flag * forced_value +
                  (1 - force_flag) * (structural_value + residual)

  return(actual_value)
}

#' Recompute Residual Under Forcing
#'
#' Implements PDF Section 3.8, e.g., row 207:
#'   epsxgap_final = force_xgap * (solve_xgap - xgap_struct) + (1 - force_xgap) * epsxgap
#'
#' When forcing is active (force_flag = 1):
#'   residual_final = solved_value - structural_value
#'
#' When forcing is inactive (force_flag = 0):
#'   residual_final = original_residual
#'
#' This backs out the implied residual when a variable is forced
#'
#' @param solved_value Solved value (from solver or forcing)
#' @param structural_value Structural value from equation
#' @param force_flag Force flag (0 or 1)
#' @param original_residual Original residual (if not forcing)
#' @return Final (recomputed) residual
recompute_residual <- function(solved_value, structural_value, force_flag, original_residual) {

  residual_final <- force_flag * (solved_value - structural_value) +
                    (1 - force_flag) * original_residual

  return(residual_final)
}

#' Apply Forcing to All 8 Variables
#'
#' Convenience wrapper to apply forcing to all forceable variables at once
#'
#' @param structural_values List with structural values (xgap_struct, U_struct, etc.)
#' @param residuals List with original residuals (epsxgap, epsu, etc.)
#' @param forcing_spec Forcing specification from create_forcing_spec()
#' @param period_index Period index (1-based) to extract forcing values for this period
#' @return List with actual values after forcing
apply_forcing_all_variables <- function(structural_values, residuals,
                                        forcing_spec, period_index) {

  list(
    xgap = apply_forcing(
      structural_values$xgap_struct, residuals$epsxgap,
      forcing_spec$force_xgap[period_index], forcing_spec$forced_xgap[period_index]
    ),
    u = apply_forcing(
      structural_values$U_struct, residuals$epsu,
      forcing_spec$force_u[period_index], forcing_spec$forced_u[period_index]
    ),
    pi = apply_forcing(
      structural_values$PI_struct, residuals$epspi,
      forcing_spec$force_pi[period_index], forcing_spec$forced_pi[period_index]
    ),
    pie = apply_forcing(
      structural_values$PIE_struct, residuals$epspie,
      forcing_spec$force_pie[period_index], forcing_spec$forced_pie[period_index]
    ),
    rf = apply_forcing(
      structural_values$RF_struct, residuals$epsrf,
      forcing_spec$force_rf[period_index], forcing_spec$forced_rf[period_index]
    ),
    mpe10 = apply_forcing(
      structural_values$MPE10_struct, residuals$epsmpe,
      forcing_spec$force_mpe[period_index], forcing_spec$forced_mpe[period_index]
    ),
    tp = apply_forcing(
      structural_values$TP_struct, residuals$epstp,
      forcing_spec$force_tp[period_index], forcing_spec$forced_tp[period_index]
    ),
    rg = apply_forcing(
      structural_values$RG_struct, residuals$epsrg,
      forcing_spec$force_rg[period_index], forcing_spec$forced_rg[period_index]
    )
  )
}

#' Recompute All Residuals Under Forcing
#'
#' Convenience wrapper to recompute residuals for all 8 forceable variables
#'
#' @param solved_values List with solved values (xgap, u, pi, etc.)
#' @param structural_values List with structural values
#' @param residuals List with original residuals
#' @param forcing_spec Forcing specification
#' @param period_index Period index
#' @return List with recomputed residuals
recompute_all_residuals <- function(solved_values, structural_values,
                                    residuals, forcing_spec, period_index) {

  list(
    epsxgap_final = recompute_residual(
      solved_values$xgap, structural_values$xgap_struct,
      forcing_spec$force_xgap[period_index], residuals$epsxgap
    ),
    epsu_final = recompute_residual(
      solved_values$u, structural_values$U_struct,
      forcing_spec$force_u[period_index], residuals$epsu
    ),
    epspi_final = recompute_residual(
      solved_values$pi, structural_values$PI_struct,
      forcing_spec$force_pi[period_index], residuals$epspi
    ),
    epspie_final = recompute_residual(
      solved_values$pie, structural_values$PIE_struct,
      forcing_spec$force_pie[period_index], residuals$epspie
    ),
    epsrf_final = recompute_residual(
      solved_values$rf, structural_values$RF_struct,
      forcing_spec$force_rf[period_index], residuals$epsrf
    ),
    epsmpe_final = recompute_residual(
      solved_values$mpe10, structural_values$MPE10_struct,
      forcing_spec$force_mpe[period_index], residuals$epsmpe
    ),
    epstp_final = recompute_residual(
      solved_values$tp, structural_values$TP_struct,
      forcing_spec$force_tp[period_index], residuals$epstp
    ),
    epsrg_final = recompute_residual(
      solved_values$rg, structural_values$RG_struct,
      forcing_spec$force_rg[period_index], residuals$epsrg
    )
  )
}

#' Check if Any Forcing is Active
#'
#' Returns TRUE if any variable is being forced in any period
#'
#' @param forcing_spec Forcing specification
#' @return Logical indicating if forcing is active
is_forcing_active <- function(forcing_spec) {
  any(forcing_spec$force_xgap == 1) ||
  any(forcing_spec$force_u == 1) ||
  any(forcing_spec$force_pi == 1) ||
  any(forcing_spec$force_pie == 1) ||
  any(forcing_spec$force_rf == 1) ||
  any(forcing_spec$force_mpe == 1) ||
  any(forcing_spec$force_tp == 1) ||
  any(forcing_spec$force_rg == 1)
}

#' Print Forcing Summary
#'
#' Display which variables are being forced and to what values
#'
#' @param forcing_spec Forcing specification
#' @param years Optional year labels
print_forcing_summary <- function(forcing_spec, years = NULL) {
  n <- length(forcing_spec$force_xgap)
  if (is.null(years)) years <- 2026:(2026 + n - 1)

  cat("\n")
  cat("================================================================================\n")
  cat("  Forcing (Override) Summary\n")
  cat("================================================================================\n\n")

  forcing_active <- is_forcing_active(forcing_spec)

  if (!forcing_active) {
    cat(">>> No forcing active (all variables use structural equations) <<<\n")
  } else {
    cat("Variables being forced:\n\n")

    # Check each variable
    var_names <- c("XGAP", "U", "PI", "PIE", "RF", "MPE10", "TP", "RG")
    force_names <- c("force_xgap", "force_u", "force_pi", "force_pie",
                     "force_rf", "force_mpe", "force_tp", "force_rg")
    forced_names <- c("forced_xgap", "forced_u", "forced_pi", "forced_pie",
                      "forced_rf", "forced_mpe", "forced_tp", "forced_rg")

    for (i in 1:8) {
      force_vec <- forcing_spec[[force_names[i]]]
      forced_vec <- forcing_spec[[forced_names[i]]]

      if (any(force_vec == 1)) {
        cat(sprintf("%s:\n", var_names[i]))
        for (t in 1:n) {
          if (force_vec[t] == 1) {
            cat(sprintf("  %d: Forced to %.4f\n", years[t], forced_vec[t]))
          }
        }
        cat("\n")
      }
    }
  }

  cat("================================================================================\n\n")
}

#' Validate Forcing Specification
#'
#' Check that forcing specification is properly formatted
#'
#' @param forcing_spec Forcing specification
#' @return List with validation results (is_valid, errors)
validate_forcing_spec <- function(forcing_spec) {
  errors <- character(0)

  # Check that all force flags are 0 or 1
  force_names <- c("force_xgap", "force_u", "force_pi", "force_pie",
                   "force_rf", "force_mpe", "force_tp", "force_rg")

  for (fname in force_names) {
    flags <- forcing_spec[[fname]]
    if (!all(flags %in% c(0, 1))) {
      errors <- c(errors, sprintf("%s contains values other than 0 or 1", fname))
    }
  }

  # Check that forced values are provided when forcing is active
  forced_names <- c("forced_xgap", "forced_u", "forced_pi", "forced_pie",
                    "forced_rf", "forced_mpe", "forced_tp", "forced_rg")

  for (i in 1:8) {
    flags <- forcing_spec[[force_names[i]]]
    values <- forcing_spec[[forced_names[i]]]

    if (any(flags == 1 & is.na(values))) {
      errors <- c(errors, sprintf("%s has force=1 but forced value is NA", forced_names[i]))
    }
  }

  # Return validation results
  is_valid <- length(errors) == 0

  return(list(
    is_valid = is_valid,
    errors = errors
  ))
}
