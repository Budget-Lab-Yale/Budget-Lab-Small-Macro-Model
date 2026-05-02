# ==============================================================================
# BLSMM Forward Simulation Engine
# ==============================================================================
# Main orchestration: ties together all model components
# ==============================================================================

#' Simulate BLSMM Model
#'
#' Complete forward simulation with all model features:
#'   - 8-period distributed lags
#'   - User delta framework
#'   - Endogenous rfstar and rbar10
#'   - Fiscal feedback
#'   - Debt proxy system
#'   - Forcing/override capability
#'
#' @param n_periods Number of forecast periods (default 10 for 2026-2035)
#' @param baseline_exog Baseline exogenous data frame
#' @param baseline_resid Baseline residuals data frame
#' @param hist_data Historical data (2018-2025)
#' @param user_deltas User delta specification (NULL for baseline)
#' @param forcing_spec Forcing specification (NULL for no forcing)
#' @param params Parameters (NULL for defaults)
#' @param expectations_speed Fast expectations flag
#' @param verbose Print progress messages
#' @return Data frame with simulation results
simulate_blsmm_v1_8 <- function(n_periods = 10,
                                baseline_exog,
                                baseline_resid,
                                hist_data,
                                user_deltas = NULL,
                                forcing_spec = NULL,
                                params = NULL,
                                expectations_speed = FALSE,
                                verbose = TRUE) {

  # Source all required modules
  source("model/v1_8/parameters.R", local = TRUE)
  source("model/v1_8/user_deltas.R", local = TRUE)
  source("model/v1_8/presim_block.R", local = TRUE)
  source("model/v1_8/neutral_rate.R", local = TRUE)
  source("model/v1_8/debt_proxy.R", local = TRUE)
  source("model/v1_8/solver.R", local = TRUE)
  source("model/v1_8/forcing.R", local = TRUE)

  # ============================================================================
  # SETUP
  # ============================================================================
  if (is.null(params)) params <- create_parameters_v1_8()
  if (is.null(user_deltas)) user_deltas <- create_user_deltas(n_periods)
  if (is.null(forcing_spec)) forcing_spec <- create_forcing_spec(n_periods)

  if (verbose) {
    cat("\n")
    cat("================================================================================\n")
    cat("  BLSMM v1.8 Simulation\n")
    cat("================================================================================\n")
    cat(sprintf("Periods: %d (2026-2035)\n", n_periods))
    cat(sprintf("User deltas active: %s\n",
                ifelse(any(user_deltas != 0), "YES", "NO")))
    cat(sprintf("Forcing active: %s\n",
                ifelse(is_forcing_active(forcing_spec), "YES", "NO")))
    cat(sprintf("Fast expectations: %s\n", ifelse(expectations_speed, "YES", "NO")))
    cat("================================================================================\n\n")
  }

  # Validate inputs
  if (nrow(baseline_exog) < n_periods) {
    stop("baseline_exog must have at least n_periods rows")
  }
  if (nrow(baseline_resid) < n_periods) {
    stop("baseline_resid must have at least n_periods rows")
  }

  # Validate forcing specification
  validation <- validate_forcing_spec(forcing_spec)
  if (!validation$is_valid) {
    stop(paste("Invalid forcing specification:",
               paste(validation$errors, collapse = "; ")))
  }

  # ============================================================================
  # COMPUTE USER-INCLUSIVE EXOGENOUS VARIABLES
  # ============================================================================
  if (verbose) cat("Computing user-inclusive exogenous variables...\n")

  exog_data <- compute_user_inclusive_exog(
    baseline_exog[1:n_periods, ],
    user_deltas,
    params,
    hist_data
  )

  resid_data <- compute_user_inclusive_resid(
    baseline_resid[1:n_periods, ],
    user_deltas
  )

  # ============================================================================
  # INITIALIZE RESULTS STORAGE
  # ============================================================================
  results <- data.frame(
    period = 1:n_periods,
    year = baseline_exog$year[1:n_periods]
  )

  # Exogenous variables
  results$glqstar <- exog_data$glqstar
  results$glfstar <- exog_data$glfstar
  results$rgfr_star <- exog_data$rgfr_star
  results$rgfop_star <- exog_data$rgfop_star
  results$rbudp_star <- exog_data$rbudp_star
  results$UN_path <- exog_data$UN_path
  results$PISTAR <- exog_data$PISTAR
  results$tp_0 <- exog_data$tp_0
  results$LF_fb <- exog_data$LF_fb
  results$PROD_fb <- exog_data$PROD_fb

  # Residuals
  results$epsxgap <- resid_data$epsxgap
  results$epsu <- resid_data$epsu
  results$epspi <- resid_data$epspi
  results$epspie <- resid_data$epspie
  results$epsrf <- resid_data$epsrf
  results$epsmpe <- resid_data$epsmpe
  results$epstp <- resid_data$epstp
  results$epsrg <- resid_data$epsrg

  # Pre-sim variables
  results$gstar <- numeric(n_periods)
  results$LFstar <- numeric(n_periods)
  results$LQstar <- numeric(n_periods)
  results$CEstar <- numeric(n_periods)
  results$GDPstar <- numeric(n_periods)
  results[["GDP$star2"]] <- numeric(n_periods)

  # Neutral rate variables
  results$rfstar <- numeric(n_periods)
  results$rbar10 <- numeric(n_periods)
  results$gradual_growth <- numeric(n_periods)
  results$debt_contrib <- numeric(n_periods)

  # Debt proxy variables
  results$debt_proxy_user <- numeric(n_periods)
  results$debt_proxy_base <- numeric(n_periods)

  # Endogenous variables (simultaneous block)
  results$xgap <- numeric(n_periods)
  results$U <- numeric(n_periods)
  results$PI <- numeric(n_periods)
  results$PIE <- numeric(n_periods)
  results$RF <- numeric(n_periods)
  results$MPE10 <- numeric(n_periods)
  results$TP <- numeric(n_periods)
  results$R10 <- numeric(n_periods)
  results$RG <- numeric(n_periods)
  results$ugap <- numeric(n_periods)
  results$real_r10 <- numeric(n_periods)

  # Fiscal variables
  results$GDP <- numeric(n_periods)
  results$PGDP <- numeric(n_periods)
  results[["GDP$star"]] <- numeric(n_periods)
  results[["GDP$"]] <- numeric(n_periods)
  results$BUDP <- numeric(n_periods)
  results$NI <- numeric(n_periods)
  results$BUD <- numeric(n_periods)
  results$D <- numeric(n_periods)
  results$D_pct_GDP <- numeric(n_periods)

  # Solver diagnostics
  results$solver_sse <- numeric(n_periods)
  results$solver_converged <- logical(n_periods)
  results$solver_termcd <- integer(n_periods)

  # ============================================================================
  # INITIALIZE FROM HISTORICAL DATA
  # ============================================================================
  if (verbose) cat("Initializing from 2025 historical data...\n")

  lag_values <- initialize_all_lags_from_history(hist_data, year_lag = 2025)

  # Initialize debt proxy lags
  debt_proxy_lags <- initialize_debt_proxy_lags_from_history(hist_data, year_lag = 2025)
  debt_proxy_user_lag <- debt_proxy_lags$debt_proxy_user_lag
  debt_proxy_base_lag <- debt_proxy_lags$debt_proxy_base_lag

  # ============================================================================
  # FORWARD SIMULATION LOOP
  # ============================================================================
  if (verbose) cat("\nStarting forward simulation...\n")

  for (t in 1:n_periods) {
    if (verbose && t %% 2 == 0) cat(sprintf("  Period %d/%d (year %d)\n", t, n_periods, results$year[t]))

    # ==========================================================================
    # PREPARE EXOGENOUS DATA FOR THIS PERIOD
    # ==========================================================================
    exog_period <- list(
      glqstar = exog_data$glqstar[t],
      glfstar = exog_data$glfstar[t],
      rgfr_star = exog_data$rgfr_star[t],
      rgfop_star = exog_data$rgfop_star[t],
      rbudp_star = exog_data$rbudp_star[t],
      UN_path = exog_data$UN_path[t],
      PISTAR = exog_data$PISTAR[t],
      tp_0 = exog_data$tp_0[t],
      glqstar_base = exog_data$glqstar_base[t],
      glfstar_base = exog_data$glfstar_base[t],
      rbudp_star_base = exog_data$rbudp_star_base[t],
      PISTAR_base = exog_data$PISTAR_base[t],
      tp_0_base = exog_data$tp_0_base[t]
    )

    resid_period <- list(
      epsxgap = resid_data$epsxgap[t],
      epsu = resid_data$epsu[t],
      epspi = resid_data$epspi[t],
      epspie = resid_data$epspie[t],
      epsrf = resid_data$epsrf[t],
      epsmpe = resid_data$epsmpe[t],
      epstp = resid_data$epstp[t],
      epsrg = resid_data$epsrg[t]
    )

    # ==========================================================================
    # PRE-SIMULATION DETERMINISTIC BLOCK
    # ==========================================================================
    presim <- compute_presim_deterministic_v1_8(exog_period, lag_values)

    results$gstar[t] <- presim$gstar
    results$LFstar[t] <- presim$LFstar
    results$LQstar[t] <- presim$LQstar
    results$CEstar[t] <- presim$CEstar
    results$GDPstar[t] <- presim$GDPstar
    results[["GDP$star2"]][t] <- presim[["GDP$star2"]]

    # ==========================================================================
    # DEBT PROXY CALCULATIONS
    # ==========================================================================
    # Used as anchor in CHI calculations for debt dynamics.
    RG_base <- params$RG_base

    # For GR_LR, need growth deviations (will be computed in neutral rate block)
    # For now, compute simplified version
    LF_growth_dev <- exog_period$glfstar - exog_period$glfstar_base
    prod_growth_dev <- exog_period$glqstar - exog_period$glqstar_base
    LF_rf_LR <- params$kappa_1 * LF_growth_dev
    PROD_rf_LR <- params$kappa_2 * prod_growth_dev
    GR_LR <- LF_rf_LR + PROD_rf_LR

    debt_proxies <- compute_debt_proxies_v1_8(
      debt_proxy_user_lag, debt_proxy_base_lag,
      exog_period$rbudp_star, exog_period$rbudp_star_base,
      presim$gstar, baseline_exog$gstar[t],
      exog_period$PISTAR, exog_period$PISTAR_base,
      RG_base, GR_LR, t, params
    )

    results$debt_proxy_user[t] <- debt_proxies$debt_proxy_user
    results$debt_proxy_base[t] <- debt_proxies$debt_proxy_base

    # ==========================================================================
    # NEUTRAL RATE AND RBAR10
    # ==========================================================================
    user_delta_rfstar_direct <- user_deltas$user_delta_rfstar_direct[t]

    neutral_rates <- compute_neutral_rates_v1_8(
      baseline_exog[t, ], exog_data[t, ], t,
      debt_proxies$debt_proxy_user, debt_proxies$debt_proxy_base,
      user_delta_rfstar_direct, params
    )

    results$rfstar[t] <- neutral_rates$rfstar
    results$rbar10[t] <- neutral_rates$rbar10
    results$gradual_growth[t] <- neutral_rates$rfstar_results$gradual_growth
    results$debt_contrib[t] <- neutral_rates$rfstar_results$debt_contrib

    # Add rfstar and rbar10 to exog_period for solver
    exog_period$rfstar <- neutral_rates$rfstar
    exog_period$rbar10 <- neutral_rates$rbar10

    # ==========================================================================
    # SOLVE SIMULTANEOUS BLOCK
    # ==========================================================================
    solved <- solve_period_v1_8(
      t, results, hist_data, exog_period, resid_period,
      forcing_spec, lag_values, params, expectations_speed
    )

    # Store simultaneous block results
    results$xgap[t] <- solved$xgap
    results$U[t] <- solved$u
    results$PI[t] <- solved$pi
    results$PIE[t] <- solved$pie
    results$RF[t] <- solved$rf
    results$MPE10[t] <- solved$mpe10
    results$TP[t] <- solved$tp
    results$R10[t] <- solved$r10
    results$RG[t] <- solved$rg
    results$ugap[t] <- solved$ugap
    results$real_r10[t] <- solved$real_r10
    results$solver_sse[t] <- solved$solver_sse
    results$solver_converged[t] <- solved$solver_converged
    results$solver_termcd[t] <- solved$solver_termcd

    # ==========================================================================
    # SOLVE FISCAL BLOCK
    # ==========================================================================
    fiscal <- solve_fiscal_block_v1_8(solved, exog_period, presim, lag_values)

    results$GDP[t] <- fiscal$GDP
    results$PGDP[t] <- fiscal$PGDP
    results[["GDP$star"]][t] <- fiscal[["GDP$star"]]
    results[["GDP$"]][t] <- fiscal[["GDP$"]]
    results$BUDP[t] <- fiscal$BUDP
    results$NI[t] <- fiscal$NI
    results$BUD[t] <- fiscal$BUD
    results$D[t] <- fiscal$D
    results$D_pct_GDP[t] <- fiscal$D_pct_GDP

    # ==========================================================================
    # UPDATE LAG VALUES FOR NEXT PERIOD
    # ==========================================================================
    lag_values <- list(
      xgap_lag = solved$xgap,
      u_lag = solved$u,
      pi_lag = solved$pi,
      pie_lag = solved$pie,
      rf_lag = solved$rf,
      mpe10_lag = solved$mpe10,
      tp_lag = solved$tp,
      r10_lag = solved$r10,
      rg_lag = solved$rg,
      D_lag = fiscal$D,
      PGDP_lag = fiscal$PGDP,
      UN_lag = exog_period$UN_path,
      LFstar_lag = presim$LFstar,
      LQstar_lag = presim$LQstar,
      GDPstar_lag = presim$GDPstar,
      `GDP$star2_lag` = presim[["GDP$star2"]]
    )

    # Update debt proxy lags
    debt_proxy_user_lag <- debt_proxies$debt_proxy_user
    debt_proxy_base_lag <- debt_proxies$debt_proxy_base
  }

  # ============================================================================
  # FINALIZE AND RETURN
  # ============================================================================
  if (verbose) {
    cat("\nSimulation complete!\n")
    cat(sprintf("Solver convergence: %d/%d periods\n",
                sum(results$solver_converged), n_periods))
    cat(sprintf("Max SSE: %.2e\n", max(results$solver_sse)))
    cat(sprintf("Final SSE: %.2e\n", results$solver_sse[n_periods]))
    cat("================================================================================\n\n")
  }

  # Add solver summary as attribute
  attr(results, "solver_summary") <- list(
    expectations_speed = expectations_speed,
    overall_converged = all(results$solver_converged),
    max_sse = max(results$solver_sse),
    final_sse = results$solver_sse[n_periods],
    forcing_active = is_forcing_active(forcing_spec),
    user_deltas_active = any(sapply(user_deltas, function(x) any(x != 0)))
  )

  return(results)
}

#' Run Baseline Scenario (v1.8)
#'
#' Convenience wrapper for baseline simulation
#'
#' @param n_periods Number of periods (default 10)
#' @param params Parameters (NULL for defaults)
#' @param expectations_speed Fast expectations flag
#' @param verbose Verbose output
#' @return Baseline simulation results
run_baseline_v1_8 <- function(n_periods = 10, params = NULL,
                              expectations_speed = FALSE, verbose = TRUE) {

  # Load data
  baseline_exog <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
  baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
  hist_data <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)

  # Run simulation
  results <- simulate_blsmm_v1_8(
    n_periods = n_periods,
    baseline_exog = baseline_exog,
    baseline_resid = baseline_resid,
    hist_data = hist_data,
    user_deltas = NULL,  # Baseline: no user deltas
    forcing_spec = NULL,  # Baseline: no forcing
    params = params,
    expectations_speed = expectations_speed,
    verbose = verbose
  )

  return(results)
}
