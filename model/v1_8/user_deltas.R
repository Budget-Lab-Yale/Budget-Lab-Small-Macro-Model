# ==============================================================================
# BLSMM User Delta Framework
# ==============================================================================
# Source: BLSMM_v1_8_exact_equation_sheet.pdf
# Section 3.1: Exogenous and user-inclusive block (pages 3-4)
# Section 3.4: No-forcing residual block (page 5)
# ==============================================================================

#' Create User Delta Inputs
#'
#' Initialize all user delta inputs to zero (baseline)
#' Users can modify these to run alternative scenarios
#'
#' @param n_periods Number of forecast periods (default 10 for 2026-2035)
#' @return Data frame with user delta columns
create_user_deltas <- function(n_periods = 10) {
  data.frame(
    # Growth component deltas (PDF row 23-24)
    user_delta_prod = rep(0, n_periods),      # Adjust glqstar (productivity growth)
    user_delta_lf = rep(0, n_periods),        # Adjust glfstar (labor force growth)

    # Fiscal policy deltas (PDF row 25-26)
    user_delta_rgfr = rep(0, n_periods),      # Adjust rgfr* (revenue ratio)
    user_delta_rgfop = rep(0, n_periods),     # Adjust rgfop* (outlay ratio)

    # Neutral rate direct delta (PDF row 45)
    user_delta_rfstar_direct = rep(0, n_periods), # Direct rfstar adjustment

    # Inflation target delta (PDF row 32)
    user_delta_pistar = rep(0, n_periods),    # Adjust PISTAR

    # Residual shocks (PDF rows 92-99 additions)
    user_delta_ADshock = rep(0, n_periods),   # Additional epsxgap
    user_delta_inflshock = rep(0, n_periods), # Additional epspi
    user_delta_MPshock = rep(0, n_periods)    # Additional epsrf
  )
}

#' Compute User-Inclusive Exogenous Variables
#'
#' Implements PDF Section 3.1 "Exogenous and user-inclusive block"
#' Combines baseline exogenous paths with user deltas
#' Computes fiscal feedback accumulation
#'
#' @param baseline_exog Baseline exogenous data frame
#' @param user_deltas User delta data frame from create_user_deltas()
#' @param params Parameter list from create_parameters_v1_8()
#' @param hist_data Historical data for initialization (optional)
#' @return Data frame with user-inclusive exogenous variables
compute_user_inclusive_exog <- function(baseline_exog, user_deltas, params, hist_data = NULL) {
  n <- nrow(baseline_exog)

  # Initialize output with baseline
  exog <- baseline_exog

  # ============================================================================
  # GROWTH COMPONENTS (PDF rows 23-24)
  # ============================================================================
  exog$glqstar <- baseline_exog$glqstar + user_deltas$user_delta_prod
  exog$glfstar <- baseline_exog$glfstar + user_deltas$user_delta_lf

  # ============================================================================
  # REVENUE RATIO (PDF row 25)
  # ============================================================================
  exog$rgfr_star <- baseline_exog$rgfr_star + user_deltas$user_delta_rgfr

  # ============================================================================
  # FISCAL FEEDBACK ACCUMULATION (PDF rows 27-28)
  # ============================================================================
  # LF_fb and PROD_fb accumulate deviations from baseline
  # psi_1 and psi_2 are negative (higher growth → lower outlay ratio)
  LF_fb <- numeric(n)
  PROD_fb <- numeric(n)

  for (t in 1:n) {
    if (t > 1) {
      # Accumulate from previous period
      LF_fb[t] <- LF_fb[t-1] + params$psi_1 * (exog$glfstar[t] - baseline_exog$glfstar[t])
      PROD_fb[t] <- PROD_fb[t-1] + params$psi_2 * (exog$glqstar[t] - baseline_exog$glqstar[t])
    } else {
      # First period: initialize at 0 (no history available)
      LF_fb[t] <- 0
      PROD_fb[t] <- 0
    }
  }

  exog$LF_fb <- LF_fb
  exog$PROD_fb <- PROD_fb

  # ============================================================================
  # OUTLAY RATIO (PDF row 26)
  # ============================================================================
  # rgfop* = baseline + fiscal feedback + direct user delta
  exog$rgfop_star <- baseline_exog$rgfop_star + LF_fb + PROD_fb + user_deltas$user_delta_rgfop

  # ============================================================================
  # PRIMARY BUDGET RATIO (PDF row 29)
  # ============================================================================
  # rbudp* = revenue - outlays
  exog$rbudp_star <- exog$rgfr_star - exog$rgfop_star

  # Budget gap from baseline (PDF row 30, used later in rbar10 calc)
  exog$rbudp_gap <- exog$rbudp_star - baseline_exog$rbudp_star

  # ============================================================================
  # UN PATH (PDF row 31)
  # ============================================================================
  # Just use baseline UN_path (no user delta in PDF spec)
  exog$UN_path <- baseline_exog$UN

  # ============================================================================
  # INFLATION TARGET (PDF row 32)
  # ============================================================================
  exog$PISTAR <- baseline_exog$pistar + user_deltas$user_delta_pistar

  # ============================================================================
  # TERM PREMIUM BASELINE (PDF row 47)
  # ============================================================================
  # Baseline tp_0 (user can shock via residuals)
  exog$tp_0 <- baseline_exog$tp_0

  # Store baseline versions for gap calculations
  exog$glqstar_base <- baseline_exog$glqstar
  exog$glfstar_base <- baseline_exog$glfstar
  exog$rgfr_star_base <- baseline_exog$rgfr_star
  exog$rgfop_star_base <- baseline_exog$rgfop_star
  exog$rbudp_star_base <- baseline_exog$rbudp_star
  exog$PISTAR_base <- baseline_exog$pistar
  exog$tp_0_base <- baseline_exog$tp_0

  return(exog)
}

#' Compute User-Inclusive Residuals
#'
#' Implements PDF Section 3.4 "No-forcing residual block"
#' Combines baseline residuals with user shock deltas
#'
#' @param baseline_resid Baseline residuals data frame
#' @param user_deltas User delta data frame
#' @return Data frame with user-inclusive residuals
compute_user_inclusive_resid <- function(baseline_resid, user_deltas) {
  n <- nrow(baseline_resid)

  resid <- baseline_resid

  # Add user shock deltas to baseline residuals (PDF rows 92-96)
  resid$epsxgap <- baseline_resid$epsxgap + user_deltas$user_delta_ADshock
  resid$epspi <- baseline_resid$epspi + user_deltas$user_delta_inflshock
  resid$epsrf <- baseline_resid$epsrf + user_deltas$user_delta_MPshock

  # Other residuals: no user delta adjustment in PDF
  # epsu, epspie, epsmpe, epstp, epsrg stay at baseline

  return(resid)
}

#' Print User Delta Summary
#'
#' Display user deltas for inspection
#'
#' @param user_deltas User delta data frame
#' @param years Optional year labels
print_user_delta_summary <- function(user_deltas, years = NULL) {
  n <- nrow(user_deltas)
  if (is.null(years)) years <- 2026:(2026 + n - 1)

  cat("\n")
  cat("================================================================================\n")
  cat("  User Delta Summary\n")
  cat("================================================================================\n\n")

  # Check if any deltas are non-zero
  has_deltas <- FALSE

  cat("GROWTH COMPONENTS:\n")
  if (any(user_deltas$user_delta_prod != 0)) {
    cat("  Productivity growth (glqstar) deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_prod[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_prod[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  Productivity growth: No deltas\n")
  }

  if (any(user_deltas$user_delta_lf != 0)) {
    cat("  Labor force growth (glfstar) deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_lf[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_lf[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  Labor force growth: No deltas\n")
  }

  cat("\nFISCAL POLICY:\n")
  if (any(user_deltas$user_delta_rgfr != 0)) {
    cat("  Revenue ratio (rgfr*) deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_rgfr[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_rgfr[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  Revenue ratio: No deltas\n")
  }

  if (any(user_deltas$user_delta_rgfop != 0)) {
    cat("  Outlay ratio (rgfop*) deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_rgfop[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_rgfop[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  Outlay ratio: No deltas\n")
  }

  cat("\nNEUTRAL RATE:\n")
  if (any(user_deltas$user_delta_rfstar_direct != 0)) {
    cat("  Direct rfstar deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_rfstar_direct[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_rfstar_direct[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  Direct rfstar: No deltas\n")
  }

  cat("\nINFLATION TARGET:\n")
  if (any(user_deltas$user_delta_pistar != 0)) {
    cat("  Inflation target (PISTAR) deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_pistar[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_pistar[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  Inflation target: No deltas\n")
  }

  cat("\nRESIDUAL SHOCKS:\n")
  if (any(user_deltas$user_delta_ADshock != 0)) {
    cat("  AD shocks (epsxgap) deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_ADshock[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_ADshock[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  AD shocks: No deltas\n")
  }

  if (any(user_deltas$user_delta_inflshock != 0)) {
    cat("  Inflation shocks (epspi) deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_inflshock[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_inflshock[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  Inflation shocks: No deltas\n")
  }

  if (any(user_deltas$user_delta_MPshock != 0)) {
    cat("  MP rule shocks (epsrf) deltas:\n")
    for (i in 1:n) {
      if (user_deltas$user_delta_MPshock[i] != 0) {
        cat(sprintf("    %d: %+.2f pp\n", years[i], user_deltas$user_delta_MPshock[i]))
        has_deltas <- TRUE
      }
    }
  } else {
    cat("  MP rule shocks: No deltas\n")
  }

  if (!has_deltas) {
    cat("\n>>> All user deltas are zero (baseline scenario) <<<\n")
  }

  cat("\n================================================================================\n\n")
}
