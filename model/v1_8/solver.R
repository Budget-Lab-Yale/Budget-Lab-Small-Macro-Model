# ==============================================================================
# BLSMM Solver with 8-Period Lag Management and Forcing
# ==============================================================================
# Source: BLSMM_v1_8_exact_equation_sheet.pdf
# Sections 3.5-3.7: Structural simultaneous block and identities
# ==============================================================================

library(nleqslv)

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
      # Pull from historical data
      # Historical data years: 2018-2025 (rows 1-8)
      # When t=1 (2026), need lags from 2025, 2024, ..., 2019
      hist_year <- 2025 + lag_period  # e.g., t=1, i=1 → 2025; i=7 → 2019
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

  # Source required functions
  source("model/v1_8/equations.R", local = TRUE)
  source("model/v1_8/forcing.R", local = TRUE)

  # ============================================================================
  # DEFINE SIMULTANEOUS SYSTEM
  # ============================================================================
  system_eqs <- function(x) {
    # Unpack solver variables
    xgap_guess <- x[1]
    u_guess <- x[2]
    pi_guess <- x[3]
    pie_guess <- x[4]
    rf_guess <- x[5]
    mpe10_guess <- x[6]
    tp_guess <- x[7]
    r10_guess <- x[8]
    rg_guess <- x[9]

    # Build 8-period lag vectors using solver guesses for current period
    R10_vec <- build_lag_vector_8(t, r10_guess, sim_results, hist_data, "R10")
    PIE_vec <- build_lag_vector_8(t, pie_guess, sim_results, hist_data, "PIE")

    # rbar10 vector (need current period rbar10 from exog_period)
    rbar10_vec <- build_lag_vector_8(t, exog_period$rbar10, sim_results, hist_data, "rbar10")

    # rbudp* vector (exogenous, from exog data)
    rbudp_star_vec <- build_lag_vector_8(t, exog_period$rbudp_star, sim_results, hist_data, "rbudp_star")

    # ========================================================================
    # STRUCTURAL EQUATIONS
    # ========================================================================

    # 1. Output gap structural
    xgap_struct <- output_gap_struct_v1_8(
      lag_values$xgap_lag, R10_vec, PIE_vec, rbar10_vec, rbudp_star_vec, params
    )

    # 2. Unemployment structural
    U_struct <- unemployment_struct_v1_8(
      exog_period$UN_path, xgap_guess, lag_values$xgap_lag, params
    )

    # 3. Inflation structural
    PI_struct <- inflation_struct_v1_8(
      lag_values$pi_lag, lag_values$pie_lag, exog_period$UN_path, u_guess, params
    )

    # 4. Expected inflation structural
    PIE_struct <- expected_inflation_struct_v1_8(
      lag_values$pie_lag, pi_guess, exog_period$PISTAR, params, expectations_speed
    )

    # 5. Federal funds rate structural
    RF_struct <- federal_funds_struct_v1_8(
      exog_period$rfstar, pi_guess, pie_guess, exog_period$PISTAR,
      exog_period$UN_path, u_guess, params
    )

    # 6. MPE10 structural
    MPE10_struct <- mpe10_struct_v1_8(
      rf_guess, exog_period$rfstar, pie_guess, exog_period$PISTAR, params
    )

    # 7. Term premium structural
    TP_struct <- term_premium_struct_v1_8(exog_period$tp_0)

    # 8. Effective rate structural
    RG_struct <- effective_rate_struct_v1_8(
      lag_values$rg_lag, rf_guess, r10_guess, params
    )

    # Store structural values for potential forcing
    structural_values <- list(
      xgap_struct = xgap_struct, U_struct = U_struct, PI_struct = PI_struct,
      PIE_struct = PIE_struct, RF_struct = RF_struct, MPE10_struct = MPE10_struct,
      TP_struct = TP_struct, RG_struct = RG_struct
    )

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

    eq[1] <- xgap_guess - xgap_actual
    eq[2] <- u_guess - u_actual
    eq[3] <- pi_guess - pi_actual
    eq[4] <- pie_guess - pie_actual
    eq[5] <- rf_guess - rf_actual
    eq[6] <- mpe10_guess - mpe10_actual
    eq[7] <- tp_guess - tp_actual
    eq[8] <- r10_guess - r10_actual
    eq[9] <- rg_guess - rg_actual

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
    solver_fvec = eq_at_solution
  )

  # ============================================================================
  # RECOMPUTE RESIDUALS IF FORCING ACTIVE
  # ============================================================================
  if (!is.null(forcing_spec) && is_forcing_active(forcing_spec)) {
    # INCOMPLETE: recompute_all_residuals() is defined in forcing.R
    # but is not called here. Implied residuals for the forced path
    # are therefore NOT stored in the returned simulation output.
    # The original baseline residuals remain in the eps* columns.
    # See the EXPERIMENTAL header at the top of forcing.R for details.
    result$forcing_was_active <- TRUE
  } else {
    result$forcing_was_active <- FALSE
  }

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
#' @param year_lag Year to extract lags from (default 2025)
#' @return List with all required lag values
initialize_all_lags_from_history <- function(hist_data, year_lag = 2025) {

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
