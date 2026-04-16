# ==============================================================================
# BLSMM Pre-Simulation Deterministic Block
# ==============================================================================
# Source: BLSMM_v1_8_exact_equation_sheet.pdf
# Section 3.3: Pre-sim deterministic block (page 5)
# ==============================================================================

#' Pre-Simulation Deterministic Calculations
#'
#' Implements PDF Section 3.3
#' These calculations happen BEFORE solving the simultaneous block
#' They determine potential output and related variables
#'
#' Variables computed:
#'   - gstar: Potential real GDP growth rate
#'   - LFstar, LQstar, CEstar: Labor force and productivity levels
#'   - GDPstar: Potential real GDP level
#'   - GDP$star2: Nominal potential GDP (special tracker)
#'   - ratio: GDP$star2 / GDPstar * 100 (diagnostic)
#'
#' @param exog User-inclusive exogenous data (must have glqstar, glfstar, UN)
#' @param lag_values Lagged values (must have UN_lag, LFstar_lag, LQstar_lag, GDPstar_lag, GDP$star2_lag)
#' @return List with all pre-sim variables
compute_presim_deterministic_v1_8 <- function(exog, lag_values) {

  # ============================================================================
  # POTENTIAL REAL GDP GROWTH RATE (PDF row 57)
  # ============================================================================
  # gstar = 100 * ((1 + glqstar/100) * (1 + glfstar/100) * (1 - UN/100) / (1 - UN(-1)/100) - 1)
  #
  # This decomposes potential growth into:
  #   - Productivity growth (glqstar)
  #   - Labor force growth (glfstar)
  #   - NAIRU change effect (UN vs UN_lag)

  gstar <- 100 * ((1 + exog$glqstar/100) *
                  (1 + exog$glfstar/100) *
                  (1 - exog$UN/100) / (1 - lag_values$UN_lag/100) - 1)

  # ============================================================================
  # LABOR FORCE AND PRODUCTIVITY LEVELS (PDF rows 104-105)
  # ============================================================================
  # These accumulate over time

  # LFstar = LFstar(-1) * (1 + 0.01 * glfstar)
  LFstar <- lag_values$LFstar_lag * (1 + 0.01 * exog$glfstar)

  # LQstar = LQstar(-1) * (1 + 0.01 * glqstar)
  LQstar <- lag_values$LQstar_lag * (1 + 0.01 * exog$glqstar)

  # ============================================================================
  # POTENTIAL EMPLOYMENT (PDF row 106)
  # ============================================================================
  # CEstar = LFstar * (1 - UN/100)
  # Potential labor force adjusted for NAIRU

  CEstar <- LFstar * (1 - exog$UN/100)

  # ============================================================================
  # POTENTIAL REAL GDP LEVEL (PDF row 107)
  # ============================================================================
  # GDPstar = GDPstar(-1) * (1 + 0.01 * gstar)

  GDPstar <- lag_values$GDPstar_lag * (1 + 0.01 * gstar)

  # ============================================================================
  # NOMINAL POTENTIAL GDP (GDP$star2) (PDF row 108)
  # ============================================================================
  # GDP$star2 = GDP$star2(-1) * (1 + gstar/100) * (1 + PISTAR/100)
  #
  # This is a SEPARATE tracker from the regular GDP$star (used in identity block).
  # GDP$star2 is used for:
  #   1. Debt proxy calculations
  #   2. Solver error scaling for BUDP and BUD
  #
  # It grows at nominal potential rate (real growth + inflation target)

  GDP_dollar_star2 <- lag_values[["GDP$star2_lag"]] * (1 + gstar/100) * (1 + exog$PISTAR/100)

  # ============================================================================
  # DIAGNOSTIC RATIO (PDF row 109)
  # ============================================================================
  # ratio = GDP$star2 / GDPstar * 100
  # This should roughly track the price level path

  ratio <- GDP_dollar_star2 / GDPstar * 100

  # ============================================================================
  # RETURN ALL COMPUTED VALUES
  # ============================================================================
  return(list(
    gstar = gstar,
    LFstar = LFstar,
    LQstar = LQstar,
    CEstar = CEstar,
    GDPstar = GDPstar,
    `GDP$star2` = GDP_dollar_star2,
    ratio = ratio
  ))
}

#' Initialize Pre-Sim Lag Values from Historical Data
#'
#' Extract lag values needed for pre-sim block from historical data
#'
#' @param hist_data Historical data frame (must have 2025 or most recent year)
#' @param year_lag Year to extract lags from (default 2025)
#' @return List with lag values for pre-sim block
initialize_presim_lags_from_history <- function(hist_data, year_lag = 2025) {

  # Find row for lag year
  lag_row <- hist_data[hist_data$year == year_lag, ]

  if (nrow(lag_row) == 0) {
    stop(sprintf("Year %d not found in historical data", year_lag))
  }

  # Extract required lags
  lag_values <- list(
    UN_lag = lag_row$UN,
    LFstar_lag = lag_row$LFstar,
    LQstar_lag = lag_row$LQstar,
    GDPstar_lag = lag_row$GDPstar,
    `GDP$star2_lag` = lag_row[["GDP$star2"]]
  )

  return(lag_values)
}

#' Print Pre-Sim Summary
#'
#' Display pre-sim calculations for debugging
#'
#' @param presim_results Results from compute_presim_deterministic_v1_8()
#' @param exog Exogenous data for context
#' @param year_label Optional year label
print_presim_summary <- function(presim_results, exog, year_label = NULL) {

  if (!is.null(year_label)) {
    cat(sprintf("\n=== Pre-Simulation Block Summary for %s ===\n\n", year_label))
  } else {
    cat("\n=== Pre-Simulation Block Summary ===\n\n")
  }

  cat("GROWTH COMPONENTS:\n")
  cat(sprintf("  glqstar (productivity growth):     %.4f%%\n", exog$glqstar))
  cat(sprintf("  glfstar (labor force growth):      %.4f%%\n", exog$glfstar))
  cat(sprintf("  UN (NAIRU):                        %.4f%%\n", exog$UN))
  cat(sprintf("  COMPUTED gstar (potential growth): %.4f%%\n", presim_results$gstar))

  cat("\nLEVEL VARIABLES:\n")
  cat(sprintf("  LFstar (potential labor force):    %.2f\n", presim_results$LFstar))
  cat(sprintf("  LQstar (potential productivity):   %.2f\n", presim_results$LQstar))
  cat(sprintf("  CEstar (potential employment):     %.2f\n", presim_results$CEstar))
  cat(sprintf("  GDPstar (potential real GDP):      %.2f\n", presim_results$GDPstar))
  cat(sprintf("  GDP$star2 (nominal potential):     %.2f\n", presim_results[["GDP$star2"]]))

  cat("\nDIAGNOSTIC:\n")
  cat(sprintf("  ratio (GDP$star2/GDPstar*100):     %.2f\n", presim_results$ratio))

  cat("\n================================================================================\n\n")
}
