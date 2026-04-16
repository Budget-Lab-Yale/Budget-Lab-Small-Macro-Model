# ==============================================================================
# BLSMM Baseline Validation Test
# ==============================================================================
#
# Purpose: Validate that the model baseline matches expected values
#
# This script tests:
# 1. Model loads without errors
# 2. Baseline simulation runs successfully
# 3. Output variables are within reasonable ranges
# 4. Key economic relationships hold
#
# Run this test after any model modifications to ensure accuracy.
#
# ==============================================================================

# Load model
source("model/BLSMM_Recreation.R")

cat("\n", rep("=", 80), "\n", sep = "")
cat("BLSMM BASELINE VALIDATION TEST\n")
cat(rep("=", 80), "\n\n", sep = "")

# ==============================================================================
# Test 1: Model Loads Successfully
# ==============================================================================

cat("Test 1: Model Loading\n")
cat(rep("-", 60), "\n", sep = "")

tryCatch({
  params <- create_default_parameters()
  initial <- get_initial_values_2024()
  exog <- get_baseline_exog()
  resid <- get_baseline_residuals()

  cat("  ✓ Parameters loaded:", length(params), "parameters\n")
  cat("  ✓ Initial values loaded:", length(initial), "variables\n")
  cat("  ✓ Exogenous data loaded:", nrow(exog), "years\n")
  cat("  ✓ Residuals loaded:", nrow(resid), "years\n")
  cat("  ✓ Test PASSED\n\n")

}, error = function(e) {
  cat("  ✗ Test FAILED:", e$message, "\n\n")
  stop("Model loading failed")
})

# ==============================================================================
# Test 2: Baseline Simulation Runs
# ==============================================================================

cat("Test 2: Baseline Simulation\n")
cat(rep("-", 60), "\n", sep = "")

tryCatch({
  baseline <- run_baseline_scenario(n_periods = 10)

  cat("  ✓ Simulation completed successfully\n")
  cat("  ✓ Periods simulated:", nrow(baseline), "\n")
  cat("  ✓ Variables computed:", ncol(baseline), "\n")
  cat("  ✓ Test PASSED\n\n")

}, error = function(e) {
  cat("  ✗ Test FAILED:", e$message, "\n\n")
  stop("Baseline simulation failed")
})

# ==============================================================================
# Test 3: Variable Ranges Are Reasonable
# ==============================================================================

cat("Test 3: Variable Range Validation\n")
cat(rep("-", 60), "\n", sep = "")

all_valid <- TRUE

# Define reasonable ranges for key variables
ranges <- list(
  xgap = c(-5, 5),          # Output gap: -5% to +5%
  u = c(3, 8),              # Unemployment: 3% to 8%
  pi = c(-1, 5),            # Inflation: -1% to 5%
  rf = c(0, 10),            # Fed funds: 0% to 10%
  r10 = c(0, 10),           # 10-year yield: 0% to 10%
  real_gdp_growth = c(-5, 10),  # Real GDP growth: -5% to 10%
  D_pct_GDP = c(50, 150)    # Debt/GDP: 50% to 150%
)

for (var in names(ranges)) {
  min_val <- min(baseline[[var]])
  max_val <- max(baseline[[var]])
  lower <- ranges[[var]][1]
  upper <- ranges[[var]][2]

  in_range <- (min_val >= lower) && (max_val <= upper)

  status <- if (in_range) "✓" else "✗"
  cat(sprintf("  %s %-20s: [%.2f, %.2f] (valid: [%.0f, %.0f])\n",
              status, var, min_val, max_val, lower, upper))

  if (!in_range) all_valid <- FALSE
}

if (all_valid) {
  cat("  ✓ Test PASSED - All variables in valid ranges\n\n")
} else {
  cat("  ✗ Test FAILED - Some variables out of range\n\n")
}

# ==============================================================================
# Test 4: Economic Relationships
# ==============================================================================

cat("Test 4: Economic Relationship Validation\n")
cat(rep("-", 60), "\n", sep = "")

# Test 4a: Real GDP growth formula
calc_growth <- baseline$gstar + c(NA, diff(baseline$xgap))
growth_match <- all(abs(baseline$real_gdp_growth[-1] - calc_growth[-1]) < 0.01,
                   na.rm = TRUE)

cat(sprintf("  %s Real GDP growth = gstar + Δxgap\n",
            ifelse(growth_match, "✓", "✗")))

# Test 4b: 10-year yield > Fed funds (usually)
avg_spread <- mean(baseline$r10 - baseline$rf)
spread_positive <- avg_spread > 0

cat(sprintf("  %s Average term spread positive: %.2f pp\n",
            ifelse(spread_positive, "✓", "✗"), avg_spread))

# Test 4c: Debt increases when budget is negative
debt_increases <- all(diff(baseline$D) > 0)
cat(sprintf("  %s Debt increases over time (deficit baseline)\n",
            ifelse(debt_increases, "✓", "✗")))

# Test 4d: Unemployment gap consistent with output gap
# ugap should have same sign as xgap (ugap = UN - u, both positive in strong economy)
okun_correlation <- cor(baseline$xgap, baseline$ugap)
okun_valid <- okun_correlation > 0.5

cat(sprintf("  %s Okun's law holds: correlation = %.2f\n",
            ifelse(okun_valid, "✓", "✗"), okun_correlation))

relationships_valid <- growth_match && spread_positive &&
                      debt_increases && okun_valid

if (relationships_valid) {
  cat("  ✓ Test PASSED - Economic relationships valid\n\n")
} else {
  cat("  ✗ Test FAILED - Some relationships invalid\n\n")
}

# ==============================================================================
# Test 5: No Missing Values
# ==============================================================================

cat("Test 5: Data Completeness\n")
cat(rep("-", 60), "\n", sep = "")

# Check for NAs in key variables
key_vars <- c("xgap", "u", "pi", "rf", "r10", "D_pct_GDP", "real_gdp_growth")
na_counts <- sapply(baseline[key_vars], function(x) sum(is.na(x)))

if (sum(na_counts) == 0) {
  cat("  ✓ No missing values in key variables\n")
  cat("  ✓ Test PASSED\n\n")
  no_nas <- TRUE
} else {
  cat("  ✗ Missing values detected:\n")
  for (var in names(na_counts[na_counts > 0])) {
    cat(sprintf("    - %s: %d NAs\n", var, na_counts[var]))
  }
  cat("  ✗ Test FAILED\n\n")
  no_nas <- FALSE
}

# ==============================================================================
# Test 6: Deviation Analysis Works
# ==============================================================================

cat("Test 6: Deviation Analysis\n")
cat(rep("-", 60), "\n", sep = "")

tryCatch({
  # Run zero-shock scenario (should have zero deviations)
  results <- run_deviation_scenario(
    n_periods = 10,
    shock_rbudp = 0,
    shock_growth = 0,
    shock_pistar = 0,
    shock_epspi = 0,
    shock_epstp = 0
  )

  # Check deviations are near zero
  max_dev <- max(abs(results$deviations$d_xgap))
  deviations_zero <- max_dev < 1e-10

  cat(sprintf("  %s Zero shock produces zero deviation: %.2e\n",
              ifelse(deviations_zero, "✓", "✗"), max_dev))

  # Run non-zero shock
  results2 <- run_deviation_scenario(
    n_periods = 10,
    shock_rbudp = -1.0,
    shock_duration = 5
  )

  # Check deviations are non-zero
  max_dev2 <- max(abs(results2$deviations$d_xgap))
  deviations_nonzero <- max_dev2 > 0.01

  cat(sprintf("  %s Non-zero shock produces deviation: %.2f pp\n",
              ifelse(deviations_nonzero, "✓", "✗"), max_dev2))

  if (deviations_zero && deviations_nonzero) {
    cat("  ✓ Test PASSED\n\n")
    deviation_valid <- TRUE
  } else {
    cat("  ✗ Test FAILED\n\n")
    deviation_valid <- FALSE
  }

}, error = function(e) {
  cat("  ✗ Test FAILED:", e$message, "\n\n")
  deviation_valid <- FALSE
})

# ==============================================================================
# Summary
# ==============================================================================

cat(rep("=", 80), "\n", sep = "")
cat("VALIDATION SUMMARY\n")
cat(rep("=", 80), "\n\n", sep = "")

tests <- c(
  "Model Loading" = TRUE,  # If we got here, it passed
  "Baseline Simulation" = TRUE,  # If we got here, it passed
  "Variable Ranges" = all_valid,
  "Economic Relationships" = relationships_valid,
  "Data Completeness" = no_nas,
  "Deviation Analysis" = deviation_valid
)

passed <- sum(tests)
total <- length(tests)

for (test_name in names(tests)) {
  status <- ifelse(tests[test_name], "✓ PASS", "✗ FAIL")
  cat(sprintf("  %s  %s\n", status, test_name))
}

cat(sprintf("\n  Total: %d/%d tests passed\n\n", passed, total))

if (passed == total) {
  cat("✓ ALL TESTS PASSED - Model is validated and ready to use\n\n")
} else {
  cat("✗ SOME TESTS FAILED - Please review errors above\n\n")
}

cat(rep("=", 80), "\n\n", sep = "")
