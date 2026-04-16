# ==============================================================================
# BLSMM Neutral Rate and rbar10 Block
# ==============================================================================
# Source: BLSMM_v1_8_exact_equation_sheet.pdf
# Section 3.2: Neutral-rate and rbar10 block (pages 3-4)
# ==============================================================================

#' Compute rfstar with Gradual Growth Pass-Through
#'
#' Implements PDF Section 3.2, rows 33-45
#'
#' Formula: rfstar = rfstar^B + debt_contrib + gradual_growth + direct_user_delta
#'
#' Gradual growth mechanism:
#'   - Growth deviations affect rfstar over a 10-year phase-in
#'   - Year 1: 10% of long-run effect
#'   - Year 10: 100% of long-run effect
#'   - Formula: (year_index / 10) * (kappa_1 * LF_growth_dev + kappa_2 * prod_growth_dev)
#'
#' @param baseline_exog Baseline exogenous data (must have rfstar^B)
#' @param exog User-inclusive exogenous data (from compute_user_inclusive_exog)
#' @param year_index Year of simulation (1 for first forecast year, 10 for last)
#' @param debt_proxy_user User-adjusted debt proxy
#' @param debt_proxy_base Baseline debt proxy
#' @param user_delta_rfstar_direct Direct rfstar adjustment from user
#' @param params Parameter list from create_parameters_v1_8()
#' @return List with rfstar and components
compute_rfstar_v1_8 <- function(baseline_exog, exog, year_index,
                                debt_proxy_user, debt_proxy_base,
                                user_delta_rfstar_direct, params) {

  # ============================================================================
  # LONG-RUN GROWTH EFFECTS (PDF rows 38-39)
  # ============================================================================
  # kappa_1 = 2/3: Labor force growth effect on neutral rate
  # kappa_2 = 2/3: Productivity growth effect on neutral rate

  # Growth deviations from baseline
  LF_growth_dev <- exog$glfstar - exog$glfstar_base
  prod_growth_dev <- exog$glqstar - exog$glqstar_base

  # Long-run effects
  LF_rf_LR <- params$kappa_1 * LF_growth_dev
  PROD_rf_LR <- params$kappa_2 * prod_growth_dev
  GR_LR <- LF_rf_LR + PROD_rf_LR  # Total long-run growth effect (PDF row 37)

  # ============================================================================
  # GRADUAL PASS-THROUGH (PDF rows 35-36)
  # ============================================================================
  # Gradual phase-in: (year_index / 10) * long_run_effect
  # Year 1: 10%, Year 2: 20%, ..., Year 10: 100%

  gradual_LF <- (year_index / 10) * LF_rf_LR
  gradual_prod <- (year_index / 10) * PROD_rf_LR
  gradual_growth <- gradual_LF + gradual_prod  # PDF row 34

  # ============================================================================
  # DEBT PROXY CONTRIBUTION (PDF row 40)
  # ============================================================================
  # kappa_3 = 0.02: Debt proxy effect
  # Higher debt → higher neutral rate

  debt_contrib <- params$kappa_3 * (debt_proxy_user - debt_proxy_base)

  # ============================================================================
  # TOTAL RFSTAR (PDF row 33)
  # ============================================================================
  # rfstar = baseline + debt effect + gradual growth + direct user delta

  rfstar <- baseline_exog$rfstar + debt_contrib + gradual_growth + user_delta_rfstar_direct

  # Return components for inspection/debugging
  return(list(
    rfstar = rfstar,
    rfstar_base = baseline_exog$rfstar,
    debt_contrib = debt_contrib,
    gradual_growth = gradual_growth,
    gradual_LF = gradual_LF,
    gradual_prod = gradual_prod,
    LF_rf_LR = LF_rf_LR,
    PROD_rf_LR = PROD_rf_LR,
    GR_LR = GR_LR,
    LF_growth_dev = LF_growth_dev,
    prod_growth_dev = prod_growth_dev,
    user_delta_rfstar_direct = user_delta_rfstar_direct
  ))
}

#' Compute Endogenous rbar10
#'
#' Implements PDF Section 3.2, rows 48-55
#'
#' Formula: rbar10 = RBAR10_base + (rfstar - rfstar^B) + (tp_0 - tp_0^B)
#'                   + (theta(1)/sigma(1)) * (rbudp* - rbudp*^B)
#'
#' IMPORTANT: The fiscal adjustment term is POSITIVE in the workbook formula,
#' despite the row-52 label having a leading minus sign.
#'
#' Economic interpretation:
#'   - Higher neutral rate → higher rbar10
#'   - Higher term premium → higher rbar10
#'   - Larger deficit (more negative rbudp*) → higher rbar10
#'     (via positive theta/sigma ratio ≈ 0.478)
#'
#' @param RBAR10_base Baseline rbar10 (constant in baseline)
#' @param rfstar Current neutral real fed funds rate
#' @param rfstar_base Baseline rfstar
#' @param tp_0 Current term premium assumption
#' @param tp_0_base Baseline term premium
#' @param rbudp_star Current primary budget ratio
#' @param rbudp_star_base Baseline primary budget ratio
#' @param params Parameter list (needs theta_sum, sigma_sum, theta_sigma_ratio)
#' @return List with rbar10 and components
compute_rbar10_v1_8 <- function(RBAR10_base, rfstar, rfstar_base,
                                tp_0, tp_0_base,
                                rbudp_star, rbudp_star_base, params) {

  # ============================================================================
  # GAPS FROM BASELINE (PDF rows 50-51)
  # ============================================================================
  rfstar_gap <- rfstar - rfstar_base
  tp_0_gap <- tp_0 - tp_0_base

  # ============================================================================
  # FISCAL ADJUSTMENT TERM (PDF row 52)
  # ============================================================================
  # NOTE: Formula is POSITIVE despite row label saying "- theta(1)/sigma(1)*(...)"
  # This is confirmed in PDF page 1: "The rbar10 adjustment term is positive
  # in the actual workbook formula even though the row-52 label carries a
  # leading minus sign."

  # theta(1) = sum of theta_0 through theta_7 = 2.7
  # sigma(1) = sum of sigma_0 through sigma_7 = 5.65
  # ratio = 2.7 / 5.65 = 0.4778761061946903

  theta_sigma_ratio <- params$theta_sigma_ratio

  # Budget gap (more negative = larger deficit)
  rbudp_gap <- rbudp_star - rbudp_star_base

  # Positive formula: larger deficit → higher rbar10
  positive_budget_term <- theta_sigma_ratio * rbudp_gap

  # ============================================================================
  # TOTAL RBAR10 GAP (PDF row 49)
  # ============================================================================
  rbar10_gap <- rfstar_gap + tp_0_gap + positive_budget_term

  # ============================================================================
  # TOTAL RBAR10 (PDF row 48)
  # ============================================================================
  rbar10 <- RBAR10_base + rbar10_gap

  # Return components for inspection/debugging
  return(list(
    rbar10 = rbar10,
    RBAR10_base = RBAR10_base,
    rbar10_gap = rbar10_gap,
    rfstar_gap = rfstar_gap,
    tp_0_gap = tp_0_gap,
    positive_budget_term = positive_budget_term,
    theta_sigma_ratio = theta_sigma_ratio,
    rbudp_gap = rbudp_gap
  ))
}

#' Compute Both rfstar and rbar10
#'
#' Convenience wrapper to compute both neutral rate components
#'
#' @param baseline_exog Baseline exogenous data
#' @param exog User-inclusive exogenous data
#' @param year_index Year of simulation (1-10)
#' @param debt_proxy_user User-adjusted debt proxy
#' @param debt_proxy_base Baseline debt proxy
#' @param user_delta_rfstar_direct Direct rfstar adjustment
#' @param params Parameter list
#' @return List with both rfstar and rbar10 results
compute_neutral_rates_v1_8 <- function(baseline_exog, exog, year_index,
                                       debt_proxy_user, debt_proxy_base,
                                       user_delta_rfstar_direct, params) {

  # Compute rfstar
  rfstar_results <- compute_rfstar_v1_8(
    baseline_exog, exog, year_index,
    debt_proxy_user, debt_proxy_base,
    user_delta_rfstar_direct, params
  )

  # Compute rbar10
  rbar10_results <- compute_rbar10_v1_8(
    baseline_exog$rbar10,          # RBAR10_base
    rfstar_results$rfstar,          # rfstar
    baseline_exog$rfstar,           # rfstar_base
    exog$tp_0,                      # tp_0
    exog$tp_0_base,                 # tp_0_base
    exog$rbudp_star,                # rbudp_star
    exog$rbudp_star_base,           # rbudp_star_base
    params
  )

  # Combine results
  return(list(
    rfstar_results = rfstar_results,
    rbar10_results = rbar10_results,
    rfstar = rfstar_results$rfstar,
    rbar10 = rbar10_results$rbar10
  ))
}

#' Print Neutral Rate Summary
#'
#' Display rfstar and rbar10 calculations for debugging
#'
#' @param neutral_results Results from compute_neutral_rates_v1_8()
#' @param year_label Optional year label for display
print_neutral_rate_summary <- function(neutral_results, year_label = NULL) {

  rfstar_res <- neutral_results$rfstar_results
  rbar10_res <- neutral_results$rbar10_results

  if (!is.null(year_label)) {
    cat(sprintf("\n=== Neutral Rate Summary for %s ===\n\n", year_label))
  } else {
    cat("\n=== Neutral Rate Summary ===\n\n")
  }

  cat("RFSTAR CALCULATION:\n")
  cat(sprintf("  Baseline rfstar:          %.4f\n", rfstar_res$rfstar_base))
  cat(sprintf("  Debt contribution:        %+.4f\n", rfstar_res$debt_contrib))
  cat(sprintf("  Gradual growth effect:    %+.4f\n", rfstar_res$gradual_growth))
  cat(sprintf("    - LF component:         %+.4f\n", rfstar_res$gradual_LF))
  cat(sprintf("    - Prod component:       %+.4f\n", rfstar_res$gradual_prod))
  cat(sprintf("  Direct user delta:        %+.4f\n", rfstar_res$user_delta_rfstar_direct))
  cat(sprintf("  TOTAL rfstar:             %.4f\n", rfstar_res$rfstar))

  cat("\nRBAR10 CALCULATION:\n")
  cat(sprintf("  Baseline RBAR10:          %.4f\n", rbar10_res$RBAR10_base))
  cat(sprintf("  rfstar gap:               %+.4f\n", rbar10_res$rfstar_gap))
  cat(sprintf("  tp_0 gap:                 %+.4f\n", rbar10_res$tp_0_gap))
  cat(sprintf("  Fiscal term (positive):   %+.4f\n", rbar10_res$positive_budget_term))
  cat(sprintf("    - theta/sigma ratio:    %.4f\n", rbar10_res$theta_sigma_ratio))
  cat(sprintf("    - rbudp* gap:           %+.4f\n", rbar10_res$rbudp_gap))
  cat(sprintf("  TOTAL rbar10:             %.4f\n", rbar10_res$rbar10))

  cat("\n================================================================================\n\n")
}
