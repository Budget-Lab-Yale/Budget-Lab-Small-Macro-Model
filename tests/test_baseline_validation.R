# ==============================================================================
# BLSMM v1.8 Baseline Validation Test
# ==============================================================================
#
# Purpose: Validate that the current modular v1.8 model loads, runs, and produces
# internally consistent baseline results.
#
# Run from the repository root:
#   Rscript tests/test_baseline_validation.R
#
# ==============================================================================

source("model/v1_8/parameters.R")
source("model/v1_8/simulation.R")

baseline_exog <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
hist_data <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)

pass <- function(message) cat("  PASS:", message, "\n")
fail <- function(message) stop(paste("FAIL:", message), call. = FALSE)

cat("\n================================================================================\n")
cat("BLSMM v1.8 BASELINE VALIDATION TEST\n")
cat("================================================================================\n\n")

cat("Test 1: Model loading\n")
params <- create_parameters_v1_8()
if (length(params) < 30) fail("parameter set did not load correctly")
if (nrow(baseline_exog) < 10) fail("baseline exogenous data has fewer than 10 rows")
if (nrow(baseline_resid) < 10) fail("baseline residual data has fewer than 10 rows")
if (nrow(hist_data) == 0) fail("historical data did not load")
pass(sprintf("loaded %d parameters and required data files", length(params)))

cat("\nTest 2: Baseline simulation\n")
baseline <- simulate_blsmm_v1_8(
  n_periods = 10,
  baseline_exog = baseline_exog,
  baseline_resid = baseline_resid,
  hist_data = hist_data,
  user_deltas = NULL,
  forcing_spec = NULL,
  params = params,
  expectations_speed = FALSE,
  verbose = FALSE
)
if (nrow(baseline) != 10) fail("baseline simulation did not return 10 periods")
if (!all(baseline$solver_converged)) fail("solver failed to converge for at least one period")
if (max(baseline$solver_sse, na.rm = TRUE) >= 1e-9) fail("solver SSE exceeded 1e-9")
pass("simulation completed with solver convergence in all periods")

cat("\nTest 3: Economic ranges\n")
ranges <- list(
  xgap = c(-5, 5),
  U = c(2, 10),
  PI = c(-2, 10),
  RF = c(0, 10),
  R10 = c(0, 10),
  D_pct_GDP = c(50, 150)
)
for (var in names(ranges)) {
  vals <- baseline[[var]]
  bounds <- ranges[[var]]
  if (min(vals, na.rm = TRUE) < bounds[1] || max(vals, na.rm = TRUE) > bounds[2]) {
    fail(sprintf("%s outside expected range [%.1f, %.1f]", var, bounds[1], bounds[2]))
  }
}
pass("key variables are within expected ranges")

cat("\nTest 4: Accounting identities\n")
budget_error <- max(abs(baseline$BUD - (baseline$BUDP - baseline$NI)), na.rm = TRUE)
debt_error <- max(abs(baseline$D[-1] - (baseline$D[-10] - baseline$BUD[-1])), na.rm = TRUE)
r10_error <- max(abs(baseline$R10 - (baseline$MPE10 + baseline$TP)), na.rm = TRUE)
ugap_error <- max(abs(baseline$ugap - (baseline$UN_path - baseline$U)), na.rm = TRUE)

if (budget_error >= 1e-8) fail(sprintf("budget identity error %.3e", budget_error))
if (debt_error >= 1e-8) fail(sprintf("debt identity error %.3e", debt_error))
if (r10_error >= 1e-8) fail(sprintf("R10 identity error %.3e", r10_error))
if (ugap_error >= 1e-8) fail(sprintf("ugap definition error %.3e", ugap_error))
pass("budget, debt, R10, and ugap identities hold")

cat("\nTest 5: Data completeness\n")
key_vars <- c("xgap", "U", "PI", "RF", "R10", "D_pct_GDP", "GDP", "BUD")
na_counts <- sapply(baseline[key_vars], function(x) sum(is.na(x)))
if (sum(na_counts) > 0) {
  fail(sprintf("missing values detected: %s", paste(names(na_counts[na_counts > 0]), collapse = ", ")))
}
pass("no missing values in key variables")

cat("\n================================================================================\n")
cat("ALL BASELINE VALIDATION TESTS PASSED\n")
cat("================================================================================\n\n")
