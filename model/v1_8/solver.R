# ==============================================================================
# BLSMM Solver with 8-Period Lag Management and Forcing
# ==============================================================================
# Source: BLSMM_v1_8_exact_equation_sheet.pdf
# Sections 3.5-3.7: Structural simultaneous block and identities
# ==============================================================================

library(nleqslv)

# Load equation and forcing functions into the same environment as this solver.
# Keeping structural evaluation outside the nleqslv closure lets calibration
# code evaluate the exact same equations at a converged solution.
source("model/v1_8/equations.R", local = TRUE)
source("model/v1_8/forcing.R", local = TRUE)

#' Build 8-Period Lag Vectors
#'
#' Constructs vectors of length 8 for variables requiring distributed lags
#' [current, t-1, t-2, ..., t-7]
#'
#' For early periods (t < 8), pulls from historical data
#' For later periods (t >= 8), pulls from simulation results
#'
#' @param t Current period index (1-based)
#' @param current_value Current period value (from solver guess or exog)
#' @param sim_results Simulation results data frame
#' @param hist_data Historical data frame
#' @param var_name Variable name in data frames
#' @return Vector of length 8: [current, lag1, lag2, ..., lag7]
build_lag_vector_8 <- function(t, current_value, sim_results, hist_data, var_name) {

  lag_vec <- numeric(8)
  lag_vec[1] <- current_value  # Current period

  # Build lags 1-7
  for (i in 1:7) {
    lag_period <- t - i

    if (lag_period >= 1) {
      # Pull from simulation results
      lag_vec[i + 1] <- sim_results[[var_name]][lag_period]
    } else {
      # Pull from historical data. The anchor is the year before the first
      # simulated year: with a first year of 2026, t=1 needs 2025, ..., 2019.
      hist_year <- sim_results$year[1] - 1 + lag_period
      hist_row <- hist_data[hist_data$year == hist_year, ]

      if (nrow(hist_row) == 0) {
        stop(sprintf("Historical data for year %d not found (needed for lag %d of period %d)",
                     hist_year, i, t))
      }

      lag_vec[i + 1] <- hist_row[[var_name]]
    }
  }

  return(lag_vec)
}

#' Evaluate the Structural Simultaneous Block (v1.8)
#'
#' Pure structural-equation evaluation at a candidate set of endogenous values.
#' Residuals and forcing are deliberately excluded.
#'
#' @param t Period index (1-based)
#' @param candidate Named list/vector with xgap, u, pi, pie, rf, mpe10, tp, r10, rg
#' @param sim_results Simulation results through period t - 1
#' @param hist_data Historical data used for early distributed lags
#' @param exog_period Exogenous values for the current period
#' @param lag_values One-period lag values for the current period
#' @param params Model parameters
#' @param expectations_speed Fast expectations adjustment flag
#' @return Named list of the eight forceable structural values
compute_structural_values_v1_8 <- function(t, candidate, sim_results, hist_data,
                                            exog_period, lag_values, params,
                                            expectations_speed = FALSE) {
  required <- c("xgap", "u", "pi", "pie", "rf", "mpe10", "tp", "r10", "rg")
  if (is.null(names(candidate)) || !all(required %in% names(candidate))) {
    stop("candidate must contain named values: ", paste(required, collapse = ", "))
  }

  R10_vec <- build_lag_vector_8(t, candidate[["r10"]], sim_results, hist_data, "R10")
  PIE_vec <- build_lag_vector_8(t, candidate[["pie"]], sim_results, hist_data, "PIE")
  rbar10_vec <- build_lag_vector_8(t, exog_period$rbar10, sim_results, hist_data, "rbar10")
  rbudp_star_vec <- build_lag_vector_8(
    t, exog_period$rbudp_star, sim_results, hist_data, "rbudp_star"
  )

  list(
    xgap_struct = output_gap_struct_v1_8(
      lag_values$xgap_lag, R10_vec, PIE_vec, rbar10_vec, rbudp_star_vec, params
    ),
    U_struct = unemployment_struct_v1_8(
      exog_period$UN_path, candidate[["xgap"]], lag_values$xgap_lag, params
    ),
    PI_struct = inflation_struct_v1_8(
      lag_values$pi_lag, lag_values$pie_lag, exog_period$UN_path,
      candidate[["u"]], params
    ),
    PIE_struct = expected_inflation_struct_v1_8(
      lag_values$pie_lag, candidate[["pi"]], exog_period$PISTAR,
      params, expectations_speed
    ),
    RF_struct = federal_funds_struct_v1_8(
      exog_period$rfstar, candidate[["pi"]], candidate[["pie"]],
      exog_period$PISTAR, exog_period$UN_path, candidate[["u"]], params
    ),
    MPE10_struct = mpe10_struct_v1_8(
      candidate[["rf"]], exog_period$rfstar, candidate[["pie"]],
      exog_period$PISTAR, params
    ),
    TP_struct = term_premium_struct_v1_8(exog_period$tp_0),
    RG_struct = effective_rate_struct_v1_8(
      lag_values$rg_lag, candidate[["rf"]], candidate[["r10"]], params
    )
  )
}

#' Solve Simultaneous Block for One Period (v1.8)
#'
#' Solves the 9 simultaneous equations with 8-period distributed lags
#' Optionally applies forcing to override structural equations
#'
#' @param t Period index (1-based, 1 = first forecast year)
#' @param sim_results Simulation results so far (for lags)
#' @param hist_data Historical data (for early period lags)
#' @param exog_period Exogenous data for this period (list)
#' @param resid_period Residuals for this period (list)
#' @param forcing_spec Forcing specification (NULL if no forcing)
#' @param lag_values Lagged values for this period (list)
#' @param params Parameters
#' @param expectations_speed Fast expectations adjustment flag
#' @return List with solved values and diagnostics
solve_period_v1_8 <- function(t, sim_results, hist_data, exog_period, resid_period,
                              forcing_spec = NULL, lag_values, params,
                              expectations_speed = FALSE) {

  if (is.null(forcing_spec)) forcing_spec <- create_forcing_spec(t)

  # ============================================================================
  # DEFINE SIMULTANEOUS SYSTEM
  # ============================================================================
  system_eqs <- function(x) {
    names(x) <- c("xgap", "u", "pi", "pie", "rf", "mpe10", "tp", "r10", "rg")
    structural_values <- compute_structural_values_v1_8(
      t, x, sim_results, hist_data, exog_period, lag_values, params,
      expectations_speed
    )
    xgap_struct <- structural_values$xgap_struct
    U_struct <- structural_values$U_struct
    PI_struct <- structural_values$PI_struct
    PIE_struct <- structural_values$PIE_struct
    RF_struct <- structural_values$RF_struct
    MPE10_struct <- structural_values$MPE10_struct
    TP_struct <- structural_values$TP_struct
    RG_struct <- structural_values$RG_struct

    # ========================================================================
    # APPLY FORCING (if active)
    # ========================================================================
    if (!is.null(forcing_spec) && is_forcing_active(forcing_spec)) {
      # Apply forcing to get actual values
      actual_values <- apply_forcing_all_variables(
        structural_values, resid_period, forcing_spec, t
      )

      xgap_actual <- actual_values$xgap
      u_actual <- actual_values$u
      pi_actual <- actual_values$pi
      pie_actual <- actual_values$pie
      rf_actual <- actual_values$rf
      mpe10_actual <- actual_values$mpe10
      tp_actual <- actual_values$tp
      rg_actual <- actual_values$rg

    } else {
      # No forcing: structural + residual
      xgap_actual <- xgap_struct + resid_period$epsxgap
      u_actual <- U_struct + resid_period$epsu
      pi_actual <- PI_struct + resid_period$epspi
      pie_actual <- PIE_struct + resid_period$epspie
      rf_actual <- RF_struct + resid_period$epsrf
      mpe10_actual <- MPE10_struct + resid_period$epsmpe
      tp_actual <- TP_struct + resid_period$epstp
      rg_actual <- RG_struct + resid_period$epsrg
    }

    # ========================================================================
    # R10 IDENTITY
    # ========================================================================
    r10_actual <- r10_yield_v1_8(mpe10_actual, tp_actual)

    # ========================================================================
    # EQUATION RESIDUALS (should be zero)
    # ========================================================================
    eq <- numeric(9)

    eq[1] <- x[["xgap"]] - xgap_actual
    eq[2] <- x[["u"]] - u_actual
    eq[3] <- x[["pi"]] - pi_actual
    eq[4] <- x[["pie"]] - pie_actual
    eq[5] <- x[["rf"]] - rf_actual
    eq[6] <- x[["mpe10"]] - mpe10_actual
    eq[7] <- x[["tp"]] - tp_actual
    eq[8] <- x[["r10"]] - r10_actual
    eq[9] <- x[["rg"]] - rg_actual

    return(eq)
  }

  # ============================================================================
  # INITIAL GUESS
  # ============================================================================
  x0 <- as.numeric(c(
    lag_values$xgap_lag,   # xgap
    lag_values$u_lag,      # u
    lag_values$pi_lag,     # pi
    lag_values$pie_lag,    # pie
    lag_values$rf_lag,     # rf
    lag_values$mpe10_lag,  # mpe10
    lag_values$tp_lag,     # tp
    lag_values$r10_lag,    # r10
    lag_values$rg_lag      # rg
  ))

  # ============================================================================
  # SOLVE SYSTEM
  # ============================================================================
  solution <- nleqslv(x0, system_eqs, control = list(maxit = 1000))

  converged <- solution$termcd %in% c(1, 2)
  if (!converged) {
    warning(sprintf("Period %d: Solver did not converge. Termination code: %d",
                    t, solution$termcd))
  }

  eq_at_solution <- system_eqs(solution$x)
  sse <- sum(eq_at_solution^2)
  names(solution$x) <- c("xgap", "u", "pi", "pie", "rf", "mpe10", "tp", "r10", "rg")
  structural_values <- compute_structural_values_v1_8(
    t, solution$x, sim_results, hist_data, exog_period, lag_values, params,
    expectations_speed
  )

  # ============================================================================
  # EXTRACT SOLUTION
  # ============================================================================
  result <- list(
    xgap = solution$x[1],
    u = solution$x[2],
    pi = solution$x[3],
    pie = solution$x[4],
    rf = solution$x[5],
    mpe10 = solution$x[6],
    tp = solution$x[7],
    r10 = solution$x[8],
    rg = solution$x[9],

    # Derived variables
    ugap = exog_period$UN_path - solution$x[2],
    real_r10 = solution$x[8] - solution$x[4],

    # Solver diagnostics
    solver_sse = sse,
    solver_converged = converged,
    solver_termcd = solution$termcd,
    solver_fvec = eq_at_solution,
    structural_values = structural_values
  )

  # ============================================================================
  # RECOMPUTE RESIDUALS IF FORCING ACTIVE
  # ============================================================================
  result$final_residuals <- recompute_all_residuals(
    result, structural_values, resid_period, forcing_spec, t
  )
  result$forcing_was_active <- is_forcing_active(forcing_spec)

  return(result)
}

#' Solve Fiscal Block for One Period
#'
#' Computes fiscal identities given solved macro variables
#'
#' @param solved Solved simultaneous block results
#' @param exog_period Exogenous data for this period
#' @param presim_period Pre-sim results for this period
#' @param lag_values Lagged values
#' @return List with fiscal variables
solve_fiscal_block_v1_8 <- function(solved, exog_period, presim_period, lag_values) {

  source("model/v1_8/equations.R", local = TRUE)

  # Real GDP
  GDP <- real_gdp_v1_8(presim_period$GDPstar, solved$xgap)

  # Price level
  PGDP <- price_level_v1_8(lag_values$PGDP_lag, solved$pi)

  # Nominal potential GDP (from GDP identity, not GDP$star2)
  GDP_dollar_star <- nominal_potential_gdp_v1_8(presim_period$GDPstar, PGDP)

  # Nominal GDP
  GDP_dollar <- nominal_gdp_v1_8(GDP, PGDP)

  # Primary budget balance
  BUDP <- primary_budget_v1_8(GDP_dollar_star, exog_period$rbudp_star)

  # Net interest (using closed-form to avoid simultaneity)
  NI <- net_interest_v1_8(lag_values$D_lag, BUDP, solved$rg)

  # Budget balance
  BUD <- budget_balance_v1_8(BUDP, NI)

  # Debt evolution
  D <- debt_evolution_v1_8(lag_values$D_lag, BUD)

  # Debt as percent of GDP
  D_pct_GDP <- (D / GDP_dollar) * 100

  return(list(
    GDP = GDP,
    PGDP = PGDP,
    `GDP$star` = GDP_dollar_star,
    `GDP$` = GDP_dollar,
    BUDP = BUDP,
    NI = NI,
    BUD = BUD,
    D = D,
    D_pct_GDP = D_pct_GDP
  ))
}

#' Initialize Lag Values from Historical Data
#'
#' Extract all lag values needed for first forecast period
#'
#' @param hist_data Historical data frame
#' @param year_lag Year to extract lags from (the year before the first simulated year)
#' @return List with all required lag values
initialize_all_lags_from_history <- function(hist_data, year_lag) {

  lag_row <- hist_data[hist_data$year == year_lag, ]

  if (nrow(lag_row) == 0) {
    stop(sprintf("Year %d not found in historical data", year_lag))
  }

  # Also need year before for some variables
  lag_row_2 <- hist_data[hist_data$year == (year_lag - 1), ]

  lag_values <- list(
    # Macro variables
    xgap_lag = as.numeric(lag_row$xgap),
    u_lag = as.numeric(lag_row$U),
    pi_lag = as.numeric(lag_row$PI),
    pie_lag = as.numeric(lag_row$PIE),
    rf_lag = as.numeric(lag_row$RF),
    mpe10_lag = as.numeric(lag_row$MPE10),
    tp_lag = as.numeric(lag_row$TP),
    r10_lag = as.numeric(lag_row$R10),
    rg_lag = as.numeric(lag_row$RG),

    # Fiscal variables
    D_lag = as.numeric(lag_row$D),
    PGDP_lag = as.numeric(lag_row$PGDP),

    # Pre-sim variables
    UN_lag = as.numeric(lag_row$UN),
    LFstar_lag = as.numeric(lag_row$LFstar),
    LQstar_lag = as.numeric(lag_row$LQstar),
    GDPstar_lag = as.numeric(lag_row$GDPstar),
    `GDP$star2_lag` = as.numeric(lag_row[["GDP$star2"]])
  )

  return(lag_values)
}
