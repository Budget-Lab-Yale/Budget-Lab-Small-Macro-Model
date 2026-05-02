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
source("model/v1_8/simulation.R")
N_PERIODS <- 10
baseline_exog  <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
hist_data      <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)

baseline_result <- simulate_blsmm_v1_8(
  n_periods          = N_PERIODS,
  baseline_exog      = baseline_exog,
  baseline_resid     = baseline_resid,
  hist_data          = hist_data,
  user_deltas        = NULL,
  forcing_spec       = NULL,
  params             = NULL,
  expectations_speed = FALSE,
  verbose            = FALSE
)

# Apply +0.5pp tp_0 shock via exog_override, preserving tp_0_base
# so the gap is correctly computed (same mechanism as run_scenario.R)
exog_tp              <- baseline_exog
tp0_original         <- baseline_exog$tp_0
exog_tp$tp_0         <- baseline_exog$tp_0 + 0.5
exog_tp$tp_0_base    <- tp0_original

tp_result <- simulate_blsmm_v1_8(
  n_periods          = N_PERIODS,
  baseline_exog      = exog_tp,
  baseline_resid     = baseline_resid,
  hist_data          = hist_data,
  user_deltas        = NULL,
  forcing_spec       = NULL,
  params             = NULL,
  expectations_speed = FALSE,
  verbose            = FALSE
)

r10_diffs  <- tp_result$R10       - baseline_result$R10
xgap_diffs <- tp_result$xgap      - baseline_result$xgap
debt_diffs <- tp_result$D_pct_GDP - baseline_result$D_pct_GDP

# INTENTIONAL MODEL BEHAVIOR (per alternate-scenarios article footnote):
# "In BLSMM, potential GDP growth is unaffected by the term premium
#  increase and the Federal Reserve offsets the effects of the higher
#  term premium on the output gap."
# A +0.5pp tp_0 shock raises rbar10 by +0.5pp as well, so the
# real-rate gap (R10 - PIE - rbar10) is unchanged and xgap stays
# at numerical zero. This is by design, not a bug.

# R10 should rise by approximately the shock size in all periods
if (!all(r10_diffs > 0.3)) {
  fail("term-premium shock did not raise R10")
}
if (!(r10_diffs[1] > 0.4 && r10_diffs[1] < 0.6)) {
  fail(sprintf("FY2026 R10 lift should be ~0.5pp, got %.4f", r10_diffs[1]))
}

# xgap should be essentially unchanged (within floating-point noise)
if (max(abs(xgap_diffs)) > 1e-4) {
  fail(sprintf(
    "term-premium shock unexpectedly moved xgap: max|diff|=%.2e",
    max(abs(xgap_diffs))
  ))
}

# Debt/GDP should be persistently higher than baseline and compounding
if (!all(debt_diffs > 0)) {
  fail("term-premium shock should worsen debt trajectory in all years")
}
if (!(debt_diffs[10] > debt_diffs[1])) {
  fail("debt/GDP gap should compound over time")
}

cat(sprintf("  PASS: R10 rises +%.3fpp (FY2026), xgap unchanged",
            r10_diffs[1]))
cat(sprintf(" (max|diff|=%.1e),", max(abs(xgap_diffs))))
cat(sprintf(" Debt/GDP +%.3fpp (FY2026) to +%.3fpp (FY2035)\n",
            debt_diffs[1], debt_diffs[10]))

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
