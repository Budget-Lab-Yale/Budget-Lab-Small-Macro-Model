# ==============================================================================
# AI Scenario Analysis for BLSMM v1.8
# ==============================================================================
# Based on: Karger et al., Rapid AI scenario (50th percentile)
#
# Scenarios (CUMULATIVE):
#   S1: Productivity only
#   S2: Productivity + Labor force
#   S3a: Productivity + Labor force + UI outlays
#   S3b: Productivity + Labor force + SS/Medicare outlays
#
# All deltas are percentage points (pp) relative to CBO February 2026 baseline
# ==============================================================================

# Set working directory to main project directory
setwd("C:/Users/jcg_g/OneDrive/Yale/Budget Lab/Macro Model/Small Macro Model")

# Source model components
source("model/v1_8/simulation.R")
source("model/v1_8/user_deltas.R")
source("app/R/blsmm_helpers.R")

cat("\n")
cat("================================================================================\n")
cat("  AI Scenario Analysis - BLSMM v1.8\n")
cat("================================================================================\n\n")

# ==============================================================================
# STEP 1: COMPUTE LABOR FORCE DELTAS
# ==============================================================================
cat("STEP 1: Computing labor force deltas from LFPR path...\n\n")

# CBO population forecast (FY2025-FY2035, millions)
cnp_cbo <- c(274.625, 276.639, 278.102, 279.557, 281.067,
             282.659, 284.287, 285.834, 287.259, 288.531, 289.670)

# Labor force growth deltas (Maddie's pre-computed values from Karger et al. Table 25)
delta_lf <- c(-0.6433, -0.4364, -0.4246, -0.4286, -0.4524,
              -0.4782, -0.4506, -0.4220, -0.4066, -0.3921)
# FY2026 through FY2035
# Units: percentage points of labor force growth per year
# Source: Maddie's LFP_Data file, "LF Growth Delta" column
# These produce LFPR declining from 62.6% to ~59.2% by FY2030,
# flat thereafter — consistent with Karger et al. Table 25

cat("Labor force growth deltas (pp):\n")
print(round(delta_lf, 4))
cat("\n\n")

# ==============================================================================
# STEP 2: DEFINE ALL SCENARIO DELTAS
# ==============================================================================
cat("STEP 2: Defining scenario parameters...\n\n")

# Productivity deltas (pp, FY2026-FY2035)
delta_prod <- c(1.60, 1.50, 1.50, 1.60, 1.60, 1.70, 1.70, 1.80, 1.80, 1.80)

# Fiscal deltas (pp, FY2026-FY2035)
# UI outlays delta
delta_ui <- c(0.000288, 0.000558, 0.000806, 0.001033, 0.001245,
              0.001181, 0.001121, 0.001068, 0.001026, 0.000993) * 100

# Social Security + Medicare outlays delta
delta_ss_medicare <- c(0.002200, 0.004255, 0.006149, 0.007887, 0.009501,
                       0.009012, 0.008555, 0.008150, 0.007830, 0.007576) * 100

cat("Productivity growth deltas (pp):\n")
print(round(delta_prod, 2))
cat("\n")

cat("UI outlay deltas (pp):\n")
print(delta_ui)
cat("\n")

cat("SS + Medicare outlay deltas (pp):\n")
print(delta_ss_medicare)
cat("\n\n")

# ==============================================================================
# STEP 3: CREATE USER DELTA STRUCTURES FOR EACH SCENARIO (CUMULATIVE)
# ==============================================================================
cat("STEP 3: Creating user delta structures for 5 scenarios (cumulative)...\n\n")

# Initialize base structure (all zeros)
user_deltas_base <- create_user_deltas(n_periods = 10)

# Scenario 1: Productivity only
user_deltas_s1 <- user_deltas_base
user_deltas_s1$user_delta_prod <- delta_prod

# Scenario 2: Productivity + Labor force (CUMULATIVE)
user_deltas_s2 <- user_deltas_base
user_deltas_s2$user_delta_prod <- delta_prod
user_deltas_s2$user_delta_lf <- delta_lf

# Scenario 3a: Productivity + Labor force + UI outlays (CUMULATIVE)
user_deltas_s3a <- user_deltas_base
user_deltas_s3a$user_delta_prod <- delta_prod
user_deltas_s3a$user_delta_lf <- delta_lf
user_deltas_s3a$user_delta_rgfop <- delta_ui

# Scenario 3b: Productivity + Labor force + SS/Medicare outlays (CUMULATIVE)
user_deltas_s3b <- user_deltas_base
user_deltas_s3b$user_delta_prod <- delta_prod
user_deltas_s3b$user_delta_lf <- delta_lf
user_deltas_s3b$user_delta_rgfop <- delta_ss_medicare

cat("Scenario definitions (CUMULATIVE):\n")
cat("  S1:  Productivity only\n")
cat("  S2:  S1 + Labor force\n")
cat("  S3a: S2 + UI outlays\n")
cat("  S3b: S2 + SS/Medicare outlays\n")
cat("\n\n")

# ==============================================================================
# STEP 4: RUN ALL SCENARIOS
# ==============================================================================
cat("STEP 4: Running simulations...\n\n")

# Load data files
baseline_exog <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
hist_data <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)

# Run baseline (no shocks)
cat("Running BASELINE...\n")
result_baseline <- simulate_blsmm_v1_8(
  n_periods = 10,
  baseline_exog = baseline_exog,
  baseline_resid = baseline_resid,
  hist_data = hist_data,
  user_deltas = NULL,  # No deltas = baseline
  forcing_spec = NULL,
  params = NULL,
  expectations_speed = FALSE,
  verbose = FALSE
)
cat("  ✓ Baseline complete\n\n")

# Run Scenario 1: Productivity only
cat("Running SCENARIO 1 (Productivity only)...\n")
result_s1 <- simulate_blsmm_v1_8(
  n_periods = 10,
  baseline_exog = baseline_exog,
  baseline_resid = baseline_resid,
  hist_data = hist_data,
  user_deltas = user_deltas_s1,
  forcing_spec = NULL,
  params = NULL,
  expectations_speed = FALSE,
  verbose = FALSE
)
cat("  ✓ Scenario 1 complete\n\n")

# Run Scenario 2: Productivity + Labor force
cat("Running SCENARIO 2 (Productivity + Labor force)...\n")
result_s2 <- simulate_blsmm_v1_8(
  n_periods = 10,
  baseline_exog = baseline_exog,
  baseline_resid = baseline_resid,
  hist_data = hist_data,
  user_deltas = user_deltas_s2,
  forcing_spec = NULL,
  params = NULL,
  expectations_speed = FALSE,
  verbose = FALSE
)
cat("  ✓ Scenario 2 complete\n\n")

# Run Scenario 3a: Productivity + Labor force + UI outlays
cat("Running SCENARIO 3a (Productivity + Labor force + UI outlays)...\n")
result_s3a <- simulate_blsmm_v1_8(
  n_periods = 10,
  baseline_exog = baseline_exog,
  baseline_resid = baseline_resid,
  hist_data = hist_data,
  user_deltas = user_deltas_s3a,
  forcing_spec = NULL,
  params = NULL,
  expectations_speed = FALSE,
  verbose = FALSE
)
cat("  ✓ Scenario 3a complete\n\n")

# Run Scenario 3b: Productivity + Labor force + SS/Medicare outlays
cat("Running SCENARIO 3b (Productivity + Labor force + SS/Medicare outlays)...\n")
result_s3b <- simulate_blsmm_v1_8(
  n_periods = 10,
  baseline_exog = baseline_exog,
  baseline_resid = baseline_resid,
  hist_data = hist_data,
  user_deltas = user_deltas_s3b,
  forcing_spec = NULL,
  params = NULL,
  expectations_speed = FALSE,
  verbose = FALSE
)
cat("  ✓ Scenario 3b complete\n\n")

# ==============================================================================
# STEP 5: SAVE RESULTS
# ==============================================================================
cat("STEP 5: Saving results...\n\n")

# Create output directory
dir.create("BLSMM ai/results", recursive = TRUE, showWarnings = FALSE)

# Save all results as RDS files (can be loaded later for plotting)
saveRDS(result_baseline, "BLSMM ai/results/ai_baseline.rds")
saveRDS(result_s1, "BLSMM ai/results/ai_scenario_1_productivity.rds")
saveRDS(result_s2, "BLSMM ai/results/ai_scenario_2_prod_lf.rds")
saveRDS(result_s3a, "BLSMM ai/results/ai_scenario_3a_prod_lf_ui.rds")
saveRDS(result_s3b, "BLSMM ai/results/ai_scenario_3b_prod_lf_ssmc.rds")

# Also save as CSV for easy inspection
write.csv(result_baseline, "BLSMM ai/results/ai_baseline.csv", row.names = FALSE)
write.csv(result_s1, "BLSMM ai/results/ai_scenario_1_productivity.csv", row.names = FALSE)
write.csv(result_s2, "BLSMM ai/results/ai_scenario_2_prod_lf.csv", row.names = FALSE)
write.csv(result_s3a, "BLSMM ai/results/ai_scenario_3a_prod_lf_ui.csv", row.names = FALSE)
write.csv(result_s3b, "BLSMM ai/results/ai_scenario_3b_prod_lf_ssmc.csv", row.names = FALSE)

cat("Saved RDS files:\n")
cat("  - BLSMM ai/results/ai_baseline.rds\n")
cat("  - BLSMM ai/results/ai_scenario_1_productivity.rds\n")
cat("  - BLSMM ai/results/ai_scenario_2_prod_lf.rds\n")
cat("  - BLSMM ai/results/ai_scenario_3a_prod_lf_ui.rds\n")
cat("  - BLSMM ai/results/ai_scenario_3b_prod_lf_ssmc.rds\n\n")

cat("Saved CSV files:\n")
cat("  - BLSMM ai/results/ai_baseline.csv\n")
cat("  - BLSMM ai/results/ai_scenario_1_productivity.csv\n")
cat("  - BLSMM ai/results/ai_scenario_2_prod_lf.csv\n")
cat("  - BLSMM ai/results/ai_scenario_3a_prod_lf_ui.csv\n")
cat("  - BLSMM ai/results/ai_scenario_3b_prod_lf_ssmc.csv\n\n")

# ==============================================================================
# STEP 6: QUICK SUMMARY
# ==============================================================================
cat("================================================================================\n")
cat("  SUMMARY - FY2035 Values\n")
cat("================================================================================\n\n")

# Extract FY2035 (period 10) values for key variables
fy2035_idx <- 10

summary_table <- data.frame(
  Variable = c("Debt/GDP (%)", "Budget Balance/GDP (%)", "Real GDP ($ trillion)",
               "Unemployment (%)", "Inflation (%)", "Fed Funds (%)", "10-Year Yield (%)"),
  Baseline = c(
    result_baseline$D_pct_GDP[fy2035_idx],
    result_baseline$BUD[fy2035_idx] / result_baseline$`GDP$`[fy2035_idx] * 100,
    result_baseline$GDP[fy2035_idx] / 1000,  # Convert to trillions
    result_baseline$U[fy2035_idx],
    result_baseline$PI[fy2035_idx],
    result_baseline$RF[fy2035_idx],
    result_baseline$R10[fy2035_idx]
  ),
  S1_Prod = c(
    result_s1$D_pct_GDP[fy2035_idx],
    result_s1$BUD[fy2035_idx] / result_s1$`GDP$`[fy2035_idx] * 100,
    result_s1$GDP[fy2035_idx] / 1000,
    result_s1$U[fy2035_idx],
    result_s1$PI[fy2035_idx],
    result_s1$RF[fy2035_idx],
    result_s1$R10[fy2035_idx]
  ),
  S2_Prod_LF = c(
    result_s2$D_pct_GDP[fy2035_idx],
    result_s2$BUD[fy2035_idx] / result_s2$`GDP$`[fy2035_idx] * 100,
    result_s2$GDP[fy2035_idx] / 1000,
    result_s2$U[fy2035_idx],
    result_s2$PI[fy2035_idx],
    result_s2$RF[fy2035_idx],
    result_s2$R10[fy2035_idx]
  ),
  S3a_Prod_LF_UI = c(
    result_s3a$D_pct_GDP[fy2035_idx],
    result_s3a$BUD[fy2035_idx] / result_s3a$`GDP$`[fy2035_idx] * 100,
    result_s3a$GDP[fy2035_idx] / 1000,
    result_s3a$U[fy2035_idx],
    result_s3a$PI[fy2035_idx],
    result_s3a$RF[fy2035_idx],
    result_s3a$R10[fy2035_idx]
  ),
  S3b_Prod_LF_SSMC = c(
    result_s3b$D_pct_GDP[fy2035_idx],
    result_s3b$BUD[fy2035_idx] / result_s3b$`GDP$`[fy2035_idx] * 100,
    result_s3b$GDP[fy2035_idx] / 1000,
    result_s3b$U[fy2035_idx],
    result_s3b$PI[fy2035_idx],
    result_s3b$RF[fy2035_idx],
    result_s3b$R10[fy2035_idx]
  ),
  stringsAsFactors = FALSE
)

print(summary_table, row.names = FALSE)

cat("\n")
cat("================================================================================\n")
cat("  Analysis complete! Results saved to BLSMM ai/results/\n")
cat("================================================================================\n\n")
