# ==============================================================================
# BLSMM v1.8 Shock Scenario Tests
# ==============================================================================
#
# Purpose: Verify that current v1.8 user-delta shocks produce directionally
# sensible responses relative to the baseline.
#
# Run from the repository root:
#   Rscript tests/test_shock_scenarios.R
#
# ==============================================================================

source("scenarios/lib/run_scenario.R")

pass <- function(message) cat("  PASS:", message, "\n")
fail <- function(message) stop(paste("FAIL:", message), call. = FALSE)

run_with_deltas <- function(id, user_deltas = NULL, exog_override = NULL) {
  run_scenario(list(
    id = id,
    label = id,
    color = "#000000",
    user_deltas = user_deltas,
    exog_override = exog_override
  ))
}

delta <- function(scenario, baseline, var) scenario[[var]] - baseline[[var]]

cat("\n================================================================================\n")
cat("BLSMM v1.8 SHOCK SCENARIO TESTS\n")
cat("================================================================================\n\n")

baseline <- run_with_deltas("baseline")

cat("Test 1: Fiscal expansion through higher primary outlays\n")
fiscal <- run_with_deltas(
  "fiscal_expansion",
  user_deltas = list(user_delta_rgfop = c(2, 2, 2, rep(0, 7)))
)
if (max(delta(fiscal, baseline, "xgap")) <= 0.1) fail("fiscal expansion did not raise output gap")
if (tail(delta(fiscal, baseline, "D_pct_GDP"), 1) <= 1.0) fail("fiscal expansion did not raise debt/GDP")
pass("output gap and debt/GDP rise after outlay shock")

cat("\nTest 2: Productivity growth shock\n")
productivity <- run_with_deltas(
  "productivity_shock",
  user_deltas = list(user_delta_prod = c(rep(1, 3), rep(0, 7)))
)
growth_dev <- c(NA, diff(productivity$GDP) / head(productivity$GDP, -1) * 100) -
  c(NA, diff(baseline$GDP) / head(baseline$GDP, -1) * 100)
if (mean(growth_dev[2:4], na.rm = TRUE) <= 0.5) fail("productivity shock did not raise real GDP growth")
if (tail(delta(productivity, baseline, "D_pct_GDP"), 1) >= -1.0) fail("productivity shock did not reduce debt/GDP")
pass("real GDP growth rises and debt/GDP improves")

cat("\nTest 3: Higher inflation target\n")
target <- run_with_deltas(
  "inflation_target_shock",
  user_deltas = list(user_delta_pistar = c(rep(0.5, 5), rep(0, 5)))
)
if (max(delta(target, baseline, "PI")) <= 0.05) fail("higher inflation target did not raise inflation")
if (max(delta(target, baseline, "PIE")) <= 0.05) fail("higher inflation target did not raise expected inflation")
pass("inflation and expected inflation rise")

cat("\nTest 4: Inflation residual shock\n")
inflation <- run_with_deltas(
  "inflation_residual_shock",
  user_deltas = list(user_delta_inflshock = c(0, 1, 1, 1, rep(0, 6)))
)
if (max(delta(inflation, baseline, "PI")) <= 0.5) fail("inflation residual shock did not raise inflation")
if (min(delta(inflation, baseline, "xgap")) >= -0.3) fail("inflation residual shock did not lower output gap")
pass("inflation rises and output gap falls")

cat("\nTest 5: Term-premium shock through tp_0 override\n")
term <- run_with_deltas(
  "term_premium_shock",
  exog_override = list(tp_0 = baseline$tp_0 + c(0, 0.5, 0.5, 0.5, rep(0, 6)))
)
if (max(delta(term, baseline, "R10")) <= 0.3) fail("term-premium shock did not raise 10-year yield")
if (min(delta(term, baseline, "xgap")) >= -0.1) fail("term-premium shock did not reduce output gap")
pass("10-year yield rises and output gap falls")

cat("\nTest 6: Combined fiscal and inflation shocks\n")
combined <- run_with_deltas(
  "combined_shock",
  user_deltas = list(
    user_delta_rgfop = c(1, 1, 1, rep(0, 7)),
    user_delta_inflshock = c(0, 0.5, 0.5, 0.5, rep(0, 6))
  )
)
if (max(abs(delta(combined, baseline, "xgap"))) <= 0.1) fail("combined shock did not move output gap")
if (max(delta(combined, baseline, "PI")) <= 0.2) fail("combined shock did not raise inflation")
pass("combined shock affects output and inflation")

cat("\n================================================================================\n")
cat("ALL SHOCK SCENARIO TESTS PASSED\n")
cat("================================================================================\n\n")
