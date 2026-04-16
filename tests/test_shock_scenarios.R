# ==============================================================================
# BLSMM Shock Scenario Tests
# ==============================================================================
#
# Purpose: Test all five shock types and verify they produce expected effects
#
# This script tests:
# 1. Fiscal policy shocks (primary balance)
# 2. Supply-side shocks (potential growth)
# 3. Monetary policy shocks (inflation target)
# 4. Unexpected inflation shocks
# 5. Term premium shocks
#
# Run this test to verify shock mechanisms are working correctly.
#
# ==============================================================================

# Load model
source("model/BLSMM_Recreation.R")

cat("\n", rep("=", 80), "\n", sep = "")
cat("BLSMM SHOCK SCENARIO TESTS\n")
cat(rep("=", 80), "\n\n", sep = "")

# ==============================================================================
# Test 1: Fiscal Shock (Primary Balance)
# ==============================================================================

cat("Test 1: Fiscal Shock (Primary Balance)\n")
cat(rep("-", 60), "\n", sep = "")

results <- run_deviation_scenario(
  n_periods = 10,
  shock_rbudp = -2.0,      # 2pp deficit increase
  shock_start = 2,
  shock_duration = 3
)

# Check expansionary effect
max_xgap_dev <- max(results$deviations$d_xgap)
fiscal_expansionary <- max_xgap_dev > 0.1

# Check debt increases
final_debt_dev <- tail(results$deviations$d_D_pct_GDP, 1)
debt_increases <- final_debt_dev > 1.0

# Check Fed response
max_rf_dev <- max(results$deviations$d_rf)
fed_tightens <- max_rf_dev > 0.05

cat(sprintf("  %s Deficit increases output gap: +%.2f pp\n",
            ifelse(fiscal_expansionary, "✓", "✗"), max_xgap_dev))
cat(sprintf("  %s Deficit increases debt/GDP: +%.2f pp\n",
            ifelse(debt_increases, "✓", "✗"), final_debt_dev))
cat(sprintf("  %s Fed tightens in response: +%.2f pp\n",
            ifelse(fed_tightens, "✓", "✗"), max_rf_dev))

test1 <- fiscal_expansionary && debt_increases && fed_tightens

if (test1) {
  cat("  ✓ Test PASSED - Fiscal shock works correctly\n\n")
} else {
  cat("  ✗ Test FAILED - Unexpected fiscal shock response\n\n")
}

# ==============================================================================
# Test 2: Supply-Side Shock (Potential Growth)
# ==============================================================================

cat("Test 2: Supply-Side Shock (Potential Growth)\n")
cat(rep("-", 60), "\n", sep = "")

results <- run_deviation_scenario(
  n_periods = 10,
  shock_growth = 1.0,      # 1pp higher potential growth
  shock_start = 2,
  shock_duration = 3
)

# Check growth increases
growth_dev_shock <- results$deviations$d_real_gdp_growth[2:4]
growth_increases <- all(growth_dev_shock > 0.5)

# Check debt/GDP improves
final_debt_dev <- tail(results$deviations$d_D_pct_GDP, 1)
debt_improves <- final_debt_dev < -1.0

# Check output gap relatively stable
max_xgap_dev <- max(abs(results$deviations$d_xgap))
xgap_stable <- max_xgap_dev < 0.5

cat(sprintf("  %s Real GDP growth increases: +%.2f pp avg\n",
            ifelse(growth_increases, "✓", "✗"), mean(growth_dev_shock)))
cat(sprintf("  %s Debt/GDP ratio improves: %.2f pp\n",
            ifelse(debt_improves, "✓", "✗"), final_debt_dev))
cat(sprintf("  %s Output gap remains stable: %.2f pp max\n",
            ifelse(xgap_stable, "✓", "✗"), max_xgap_dev))

test2 <- growth_increases && debt_improves

if (test2) {
  cat("  ✓ Test PASSED - Supply shock works correctly\n\n")
} else {
  cat("  ✗ Test FAILED - Unexpected supply shock response\n\n")
}

# ==============================================================================
# Test 3: Monetary Policy Shock (Inflation Target)
# ==============================================================================

cat("Test 3: Monetary Policy Shock (Inflation Target)\n")
cat(rep("-", 60), "\n", sep = "")

results <- run_deviation_scenario(
  n_periods = 10,
  shock_pistar = 0.5,      # Raise target to 2.5%
  shock_start = 2,
  shock_duration = 5
)

# Check inflation rises
max_pi_dev <- max(results$deviations$d_pi)
inflation_rises <- max_pi_dev > 0.1

# Check output gap rises (accommodative)
max_xgap_dev <- max(results$deviations$d_xgap)
output_rises <- max_xgap_dev > 0.1

# Check expectations adjust
max_pie_dev <- max(results$deviations$d_pie)
expectations_adjust <- max_pie_dev > 0.1

cat(sprintf("  %s Inflation increases: +%.2f pp\n",
            ifelse(inflation_rises, "✓", "✗"), max_pi_dev))
cat(sprintf("  %s Output gap rises (accommodative): +%.2f pp\n",
            ifelse(output_rises, "✓", "✗"), max_xgap_dev))
cat(sprintf("  %s Expectations adjust: +%.2f pp\n",
            ifelse(expectations_adjust, "✓", "✗"), max_pie_dev))

test3 <- inflation_rises && output_rises && expectations_adjust

if (test3) {
  cat("  ✓ Test PASSED - Monetary shock works correctly\n\n")
} else {
  cat("  ✗ Test FAILED - Unexpected monetary shock response\n\n")
}

# ==============================================================================
# Test 4: Unexpected Inflation Shock
# ==============================================================================

cat("Test 4: Unexpected Inflation Shock\n")
cat(rep("-", 60), "\n", sep = "")

results <- run_deviation_scenario(
  n_periods = 10,
  shock_epspi = 1.0,       # 1pp unexpected inflation
  shock_start = 2,
  shock_duration = 3
)

# Check inflation rises
max_pi_dev <- max(results$deviations$d_pi)
inflation_rises <- max_pi_dev > 0.5

# Check output gap falls (Fed tightening)
min_xgap_dev <- min(results$deviations$d_xgap)
output_contracts <- min_xgap_dev < -0.5

# Check unemployment rises (Okun's law)
max_u_dev <- max(results$deviations$d_u)
unemployment_rises <- max_u_dev > 0.2

cat(sprintf("  %s Inflation rises: +%.2f pp\n",
            ifelse(inflation_rises, "✓", "✗"), max_pi_dev))
cat(sprintf("  %s Output contracts (stagflation): %.2f pp\n",
            ifelse(output_contracts, "✓", "✗"), min_xgap_dev))
cat(sprintf("  %s Unemployment rises: +%.2f pp\n",
            ifelse(unemployment_rises, "✓", "✗"), max_u_dev))

test4 <- inflation_rises && output_contracts && unemployment_rises

if (test4) {
  cat("  ✓ Test PASSED - Inflation shock works correctly\n\n")
} else {
  cat("  ✗ Test FAILED - Unexpected inflation shock response\n\n")
}

# ==============================================================================
# Test 5: Term Premium Shock
# ==============================================================================

cat("Test 5: Term Premium Shock\n")
cat(rep("-", 60), "\n", sep = "")

results <- run_deviation_scenario(
  n_periods = 10,
  shock_epstp = 0.5,       # 50bp term premium increase
  shock_start = 2,
  shock_duration = 3
)

# Check 10-year yield rises
max_r10_dev <- max(results$deviations$d_r10)
r10_rises <- max_r10_dev > 0.3

# Check output contracts (financial tightening)
min_xgap_dev <- min(results$deviations$d_xgap)
output_contracts <- min_xgap_dev < -0.3

# Check debt service costs rise
max_rg_dev <- max(results$deviations$d_rg)
debt_costs_rise <- max_rg_dev > 0.05

cat(sprintf("  %s 10-year yield rises: +%.2f pp\n",
            ifelse(r10_rises, "✓", "✗"), max_r10_dev))
cat(sprintf("  %s Output contracts: %.2f pp\n",
            ifelse(output_contracts, "✓", "✗"), min_xgap_dev))
cat(sprintf("  %s Debt service costs rise: +%.2f pp\n",
            ifelse(debt_costs_rise, "✓", "✗"), max_rg_dev))

test5 <- r10_rises && output_contracts

if (test5) {
  cat("  ✓ Test PASSED - Term premium shock works correctly\n\n")
} else {
  cat("  ✗ Test FAILED - Unexpected term premium response\n\n")
}

# ==============================================================================
# Test 6: Combined Shocks
# ==============================================================================

cat("Test 6: Combined Shocks\n")
cat(rep("-", 60), "\n", sep = "")

results <- run_deviation_scenario(
  n_periods = 10,
  shock_rbudp = -1.0,
  shock_epspi = 0.5,
  shock_start = 2,
  shock_duration = 3
)

# Check both shocks are stored
both_shocks <- (results$shock_spec$rbudp == -1.0) &&
               (results$shock_spec$epspi == 0.5)

# Check combined effect on inflation
max_pi_dev <- max(results$deviations$d_pi)
inflation_elevated <- max_pi_dev > 0.5

# Check combined effect on output
max_xgap_dev <- max(abs(results$deviations$d_xgap))
output_affected <- max_xgap_dev > 0.5

cat(sprintf("  %s Both shocks stored correctly\n",
            ifelse(both_shocks, "✓", "✗")))
cat(sprintf("  %s Inflation elevated: +%.2f pp\n",
            ifelse(inflation_elevated, "✓", "✗"), max_pi_dev))
cat(sprintf("  %s Output affected: %.2f pp\n",
            ifelse(output_affected, "✓", "✗"), max_xgap_dev))

test6 <- both_shocks && inflation_elevated && output_affected

if (test6) {
  cat("  ✓ Test PASSED - Combined shocks work correctly\n\n")
} else {
  cat("  ✗ Test FAILED - Combined shocks issue\n\n")
}

# ==============================================================================
# Summary
# ==============================================================================

cat(rep("=", 80), "\n", sep = "")
cat("SHOCK TEST SUMMARY\n")
cat(rep("=", 80), "\n\n", sep = "")

tests <- c(
  "Fiscal Shock (Primary Balance)" = test1,
  "Supply Shock (Potential Growth)" = test2,
  "Monetary Shock (Inflation Target)" = test3,
  "Inflation Shock (Unexpected)" = test4,
  "Term Premium Shock" = test5,
  "Combined Shocks" = test6
)

passed <- sum(tests)
total <- length(tests)

for (test_name in names(tests)) {
  status <- ifelse(tests[test_name], "✓ PASS", "✗ FAIL")
  cat(sprintf("  %s  %s\n", status, test_name))
}

cat(sprintf("\n  Total: %d/%d shock types validated\n\n", passed, total))

if (passed == total) {
  cat("✓ ALL TESTS PASSED - All shock types working correctly\n\n")
} else {
  cat("✗ SOME TESTS FAILED - Please review errors above\n\n")
}

cat(rep("=", 80), "\n\n", sep = "")
