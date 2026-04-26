# ==============================================================================
# BLSMM Debt Proxy System
# ==============================================================================
# Source: BLSMM_v1_8_exact_equation_sheet.pdf
# Section 3.2: Neutral-rate and rbar10 block, rows 41-44 (page 4)
# ==============================================================================

#' Compute Debt Proxy (User Path)
#'
#' Implements PDF row 41-42: User-adjusted debt proxy with growth deviations
#'
#' Formula:
#'   debt_proxy_user = ((1 + CHI_user) / ((1 + gstar/100) * (1 + PISTAR/100)))
#'                     * debt_proxy_user(-1) - (1 + CHI_user/2) * rbudp*
#'
#' where CHI_user incorporates long-run growth effects:
#'   CHI_user = (RG_base/100 + (1-delta_1) * MIN(1/(1-delta_1), year_index) * GR_LR/100)
#'              / (1 - 0.5 * (RG_base/100 + (1-delta_1) * MIN(1/(1-delta_1), year_index) * GR_LR/100))
#'
#' The MIN operator ensures gradual phase-in over 6 years (since delta_1 = 5/6)
#'
#' @param debt_proxy_lag Lagged debt proxy
#' @param rbudp_star Current primary budget ratio
#' @param gstar Potential real GDP growth
#' @param PISTAR Inflation target
#' @param RG_base Baseline effective interest rate
#' @param GR_LR Long-run growth effect from neutral_rate calculations
#' @param year_index Year of simulation (1 for first forecast year, 10 for last)
#' @param params Parameter list (needs delta_1)
#' @return List with debt_proxy_user and CHI_user
compute_debt_proxy_user_v1_8 <- function(debt_proxy_lag, rbudp_star, gstar, PISTAR,
                                         RG_base, GR_LR, year_index, params) {

  # ============================================================================
  # CHI_USER CALCULATION (PDF row 42)
  # ============================================================================
  # The MIN operator limits the growth effect to phase in over time
  # max_year_effect = 1 / (1 - delta_1) = 1 / (1 - 5/6) = 1 / (1/6) = 6
  # So:
  #   - Years 1-6: year_index is binding (gradual phase-in)
  #   - Years 7-10: max of 6 is binding (full effect)

  max_year_effect <- 1 / (1 - params$delta_1)  # = 6
  year_factor <- min(max_year_effect, year_index)

  # Interest rate component with gradual growth effect
  # RG_base is in percent, divide by 100
  # GR_LR is long-run growth rate from neutral_rate.R
  r_component <- RG_base/100 + (1 - params$delta_1) * year_factor * GR_LR/100

  # CHI formula with denominator adjustment
  CHI_user <- r_component / (1 - 0.5 * r_component)

  # ============================================================================
  # DEBT PROXY RECURSION (PDF row 41)
  # ============================================================================
  # debt_proxy evolves based on:
  #   1. Previous debt discounted by nominal growth
  #   2. Current primary deficit adds to debt

  nominal_growth_factor <- (1 + gstar/100) * (1 + PISTAR/100)

  debt_proxy_user <- ((1 + CHI_user) / nominal_growth_factor) * debt_proxy_lag -
                     (1 + CHI_user/2) * rbudp_star

  return(list(
    debt_proxy_user = debt_proxy_user,
    CHI_user = CHI_user,
    year_factor = year_factor,
    max_year_effect = max_year_effect,
    r_component = r_component,
    nominal_growth_factor = nominal_growth_factor
  ))
}

#' Compute Debt Proxy (Baseline Path)
#'
#' Implements PDF row 43-44: Baseline debt proxy (simpler, no growth deviations)
#'
#' Formula:
#'   debt_proxy_base = ((1 + CHI_base) / ((1 + gstar^B/100) * (1 + PISTAR^B/100)))
#'                     * debt_proxy_base(-1) - (1 + CHI_base/2) * rbudp*^B
#'
#' where CHI_base = (RG_base/100) / (1 - 0.5 * RG_base/100)
#'
#' @param debt_proxy_lag Lagged debt proxy (baseline)
#' @param rbudp_star_base Baseline primary budget ratio
#' @param gstar_base Baseline potential real GDP growth
#' @param PISTAR_base Baseline inflation target
#' @param RG_base Baseline effective interest rate
#' @return List with debt_proxy_base and CHI_base
compute_debt_proxy_base_v1_8 <- function(debt_proxy_lag, rbudp_star_base,
                                         gstar_base, PISTAR_base, RG_base) {

  # ============================================================================
  # CHI_BASE CALCULATION (PDF row 44)
  # ============================================================================
  # Simpler formula: just baseline interest rate, no growth deviation

  r_component_base <- RG_base/100
  CHI_base <- r_component_base / (1 - 0.5 * r_component_base)

  # ============================================================================
  # DEBT PROXY RECURSION (PDF row 43)
  # ============================================================================
  nominal_growth_factor_base <- (1 + gstar_base/100) * (1 + PISTAR_base/100)

  debt_proxy_base <- ((1 + CHI_base) / nominal_growth_factor_base) * debt_proxy_lag -
                     (1 + CHI_base/2) * rbudp_star_base

  return(list(
    debt_proxy_base = debt_proxy_base,
    CHI_base = CHI_base,
    r_component_base = r_component_base,
    nominal_growth_factor_base = nominal_growth_factor_base
  ))
}

#' Compute Both User and Baseline Debt Proxies
#'
#' Convenience wrapper to compute both debt proxy paths
#'
#' @param debt_proxy_user_lag Lagged user debt proxy
#' @param debt_proxy_base_lag Lagged baseline debt proxy
#' @param rbudp_star Current (user-adjusted) primary budget ratio
#' @param rbudp_star_base Baseline primary budget ratio
#' @param gstar Current (user-adjusted) potential growth
#' @param gstar_base Baseline potential growth
#' @param PISTAR Current (user-adjusted) inflation target
#' @param PISTAR_base Baseline inflation target
#' @param RG_base Baseline effective interest rate (constant parameter, in percent)
#' @param GR_LR Long-run growth effect (from neutral_rate.R)
#' @param year_index Year of simulation (1-10)
#' @param params Parameter list
#' @return List with both debt proxy results
compute_debt_proxies_v1_8 <- function(debt_proxy_user_lag, debt_proxy_base_lag,
                                      rbudp_star, rbudp_star_base,
                                      gstar, gstar_base,
                                      PISTAR, PISTAR_base,
                                      RG_base, GR_LR, year_index, params) {

  # Compute user path
  user_results <- compute_debt_proxy_user_v1_8(
    debt_proxy_user_lag, rbudp_star, gstar, PISTAR,
    RG_base, GR_LR, year_index, params
  )

  # Compute baseline path
  base_results <- compute_debt_proxy_base_v1_8(
    debt_proxy_base_lag, rbudp_star_base, gstar_base, PISTAR_base, RG_base
  )

  # Combine results
  return(list(
    user_results = user_results,
    base_results = base_results,
    debt_proxy_user = user_results$debt_proxy_user,
    debt_proxy_base = base_results$debt_proxy_base,
    debt_proxy_gap = user_results$debt_proxy_user - base_results$debt_proxy_base
  ))
}

#' Initialize Debt Proxy Lags from Historical Data
#'
#' Extract initial debt proxy values from historical data
#'
#' NOTE: Debt proxy is only initialized at 2025 in the workbook.
#' The exact workbook value is 99.37172136945937 for both user and base.
#' Calculated as: 100 * D(2025) / GDP$star2(2025) = 100 * 30172 / 30362.76275
#'
#' @param hist_data Historical data frame
#' @param year_lag Year to extract from (default 2025)
#' @return List with debt_proxy_user_lag and debt_proxy_base_lag
initialize_debt_proxy_lags_from_history <- function(hist_data, year_lag = 2025) {

  # Debt proxy columns should exist in historical data (model feature)
  if ("debt_proxy_user" %in% names(hist_data) && "debt_proxy_base" %in% names(hist_data)) {
    lag_row <- hist_data[hist_data$year == year_lag, ]

    # Convert to numeric (CSV reading may make them character)
    debt_proxy_user <- as.numeric(lag_row$debt_proxy_user)
    debt_proxy_base <- as.numeric(lag_row$debt_proxy_base)

    # Check for NA (which is expected for years < 2025)
    if (is.na(debt_proxy_user) || is.na(debt_proxy_base)) {
      stop(sprintf("Debt proxy values for year %d are NA. Debt proxy is only initialized at 2025.", year_lag))
    }

    return(list(
      debt_proxy_user_lag = debt_proxy_user,
      debt_proxy_base_lag = debt_proxy_base
    ))
  } else {
    # Fallback: use workbook-exact initialization value
    warning("Debt proxy columns not found in historical data. Using workbook initialization value for 2025.")

    return(list(
      debt_proxy_user_lag = 99.37172136945937,
      debt_proxy_base_lag = 99.37172136945937
    ))
  }
}

#' Print Debt Proxy Summary
#'
#' Display debt proxy calculations for debugging
#'
#' @param debt_results Results from compute_debt_proxies_v1_8()
#' @param year_label Optional year label
print_debt_proxy_summary <- function(debt_results, year_label = NULL) {

  user_res <- debt_results$user_results
  base_res <- debt_results$base_results

  if (!is.null(year_label)) {
    cat(sprintf("\n=== Debt Proxy Summary for %s ===\n\n", year_label))
  } else {
    cat("\n=== Debt Proxy Summary ===\n\n")
  }

  cat("USER PATH (with growth deviations):\n")
  cat(sprintf("  CHI_user:                     %.6f\n", user_res$CHI_user))
  cat(sprintf("  Year factor (MIN applied):    %.2f\n", user_res$year_factor))
  cat(sprintf("  Max year effect:              %.2f\n", user_res$max_year_effect))
  cat(sprintf("  R component:                  %.6f\n", user_res$r_component))
  cat(sprintf("  Nominal growth factor:        %.6f\n", user_res$nominal_growth_factor))
  cat(sprintf("  Debt proxy (user):            %.4f\n", user_res$debt_proxy_user))

  cat("\nBASELINE PATH:\n")
  cat(sprintf("  CHI_base:                     %.6f\n", base_res$CHI_base))
  cat(sprintf("  R component (base):           %.6f\n", base_res$r_component_base))
  cat(sprintf("  Nominal growth factor (base): %.6f\n", base_res$nominal_growth_factor_base))
  cat(sprintf("  Debt proxy (base):            %.4f\n", base_res$debt_proxy_base))

  cat("\nGAP:\n")
  cat(sprintf("  Debt proxy gap (user - base): %+.4f\n", debt_results$debt_proxy_gap))
  cat(sprintf("  Effect on rfstar (×%.3f):     %+.4f\n",
              0.02,  # kappa_3
              0.02 * debt_results$debt_proxy_gap))

  cat("\n================================================================================\n\n")
}
