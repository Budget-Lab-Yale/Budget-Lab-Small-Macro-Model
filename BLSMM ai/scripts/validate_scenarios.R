# Cross-Scenario Validation

cat("\n=== CROSS-SCENARIO CONSISTENCY CHECK ===\n\n")

# Load all results
result_baseline <- readRDS("BLSMM ai/results/ai_baseline.rds")
result_s1 <- readRDS("BLSMM ai/results/ai_scenario_1_productivity.rds")
result_s2 <- readRDS("BLSMM ai/results/ai_scenario_2_prod_lf.rds")
result_s3a <- readRDS("BLSMM ai/results/ai_scenario_3a_prod_lf_ui.rds")
result_s3b <- readRDS("BLSMM ai/results/ai_scenario_3b_prod_lf_ssmc.rds")

all_pass <- TRUE

# Test 1: S1 should have higher GDP than baseline (productivity boost)
cat("Test 1: Productivity scenario GDP effects\n")
if (all(result_s1$GDP > result_baseline$GDP)) {
  gdp_increase <- result_s1$GDP[10] - result_baseline$GDP[10]
  cat(sprintf("  ✓ S1 GDP > Baseline all periods (FY2035: +$%.1fB)\n", gdp_increase))
} else {
  cat("  ✗ UNEXPECTED: S1 GDP not always > Baseline\n")
  all_pass <- FALSE
}

# Test 2: S1 should have lower debt/GDP than baseline (better fiscal position)
cat("\nTest 2: Productivity scenario fiscal effects\n")
if (all(result_s1$D_pct_GDP < result_baseline$D_pct_GDP)) {
  debt_decrease <- result_baseline$D_pct_GDP[10] - result_s1$D_pct_GDP[10]
  cat(sprintf("  ✓ S1 debt/GDP < Baseline all periods (FY2035: -%.1f pp)\n", debt_decrease))
} else {
  cat("  ✗ UNEXPECTED: S1 debt/GDP not always < Baseline\n")
  all_pass <- FALSE
}

# Test 3: S2 should have lower GDP than S1 (CUMULATIVE: S1 + negative LF shock due to declining LFPR)
cat("\nTest 3: S2 (Prod+LF) builds on S1 correctly\n")
if (result_s2$GDP[10] < result_s1$GDP[10]) {
  gdp_decrease <- result_s1$GDP[10] - result_s2$GDP[10]
  cat(sprintf("  ✓ S2 GDP < S1 GDP (FY2035: -$%.1fB from negative LF effect)\n", gdp_decrease))
} else {
  cat("  ✗ UNEXPECTED: S2 GDP not < S1 (LF effect should be negative due to declining LFPR)\n")
  all_pass <- FALSE
}

# Test 4: S2 should have lower debt/GDP than baseline (cumulative productivity + LF)
cat("\nTest 4: S2 cumulative fiscal effects\n")
if (all(result_s2$D_pct_GDP < result_baseline$D_pct_GDP)) {
  debt_decrease <- result_baseline$D_pct_GDP[10] - result_s2$D_pct_GDP[10]
  cat(sprintf("  ✓ S2 debt/GDP < Baseline all periods (FY2035: -%.1f pp)\n", debt_decrease))
} else {
  cat("  ✗ UNEXPECTED: S2 debt/GDP not always < Baseline\n")
  all_pass <- FALSE
}

# Test 5: S3a and S3b should have modest differences from S2 (small fiscal effects)
cat("\nTest 5: S3a and S3b fiscal additions are modest\n")
debt_diff_s3a <- abs(result_s3a$D_pct_GDP[10] - result_s2$D_pct_GDP[10])
debt_diff_s3b <- abs(result_s3b$D_pct_GDP[10] - result_s2$D_pct_GDP[10])
if (debt_diff_s3a < 1 && debt_diff_s3b < 1) {
  cat(sprintf("  ✓ S3a vs S2: %.2f pp, S3b vs S2: %.2f pp (both modest)\n", debt_diff_s3a, debt_diff_s3b))
} else {
  cat(sprintf("  ⚠ Fiscal effects larger than expected: S3a=%.2f pp, S3b=%.2f pp\n", debt_diff_s3a, debt_diff_s3b))
}

# Test 6: All scenarios should have higher GDP than baseline (productivity dominates)
cat("\nTest 6: All scenarios benefit from productivity\n")
all_higher_gdp <- all(result_s1$GDP > result_baseline$GDP) &&
                  all(result_s2$GDP > result_baseline$GDP) &&
                  all(result_s3a$GDP > result_baseline$GDP) &&
                  all(result_s3b$GDP > result_baseline$GDP)
if (all_higher_gdp) {
  cat("  ✓ All scenarios have GDP > Baseline (productivity dominates)\n")
} else {
  cat("  ✗ UNEXPECTED: Not all scenarios have GDP > Baseline\n")
  all_pass <- FALSE
}

# Test 7: Check LFPR calculation consistency for all scenarios with LF shock
cat("\nTest 7: LFPR target verification for S2, S3a, S3b\n")
source("app/R/blsmm_helpers.R")

cnp_cbo <- c(274.625, 276.639, 278.102, 279.557, 281.067,
             282.659, 284.287, 285.834, 287.259, 288.531, 289.670)

for (result_data in list(list(name = "s2_prod_lf", data = result_s2),
                         list(name = "s3a_prod_lf_ui", data = result_s3a),
                         list(name = "s3b_prod_lf_ssmc", data = result_s3b))) {
  # Calculate implied LFPR
  implied_lfpr <- result_data$data$LFstar / cnp_cbo[2:11]

  # Check if FY2030-2035 LFPR is close to 0.593
  fy2030_2035_lfpr <- implied_lfpr[5:10]

  if (all(abs(fy2030_2035_lfpr - 0.593) < 0.001)) {
    cat(sprintf("  ✓ %s: LFPR target 0.593 achieved FY2030-2035\n", result_data$name))
  } else {
    cat(sprintf("  ✗ %s: LFPR target not achieved\n", result_data$name))
    cat(sprintf("    Actual LFPR FY2030-2035: %.4f to %.4f\n",
                min(fy2030_2035_lfpr), max(fy2030_2035_lfpr)))
    all_pass <- FALSE
  }
}

cat("\n================================================================================\n")
if (all_pass) {
  cat("✓ ALL CROSS-SCENARIO CONSISTENCY CHECKS PASSED\n")
} else {
  cat("✗ SOME CROSS-SCENARIO INCONSISTENCIES DETECTED\n")
}
cat("================================================================================\n\n")
