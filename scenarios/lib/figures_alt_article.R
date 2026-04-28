source("scenarios/lib/blsmm_theme.R")
source("scenarios/lib/plot_helpers.R")

out_dir <- "scenarios/figures/alt_article"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

baseline <- readRDS("scenarios/results/baseline.rds")

# Helper: make a 4-panel grid for {Budget, Debt, <third>, <fourth>}
four_panel <- function(results, third_var, third_title, third_ylab,
                       fourth_var, fourth_title, fourth_ylab) {
  p_budget <- bl_line(
    gather_var(results, transform = tf_budget_pct_gdp),
    title = "Budget Deficit as % of GDP", ylab = "Percent of GDP"
  ) + geom_hline(yintercept = 0, linetype = "dotted", color = "gray50")

  p_debt <- bl_line(
    gather_var(results, var = "D_pct_GDP"),
    title = "Debt as % of GDP", ylab = "Percent of GDP"
  )

  p_third <- bl_line(
    gather_var(results, var = third_var),
    title = third_title, ylab = third_ylab
  )

  p_fourth <- bl_line(
    gather_var(results, var = fourth_var),
    title = fourth_title, ylab = fourth_ylab
  )

  bl_grid(list(p_budget, p_debt, p_third, p_fourth), ncol = 2)
}

# Figure 1: AI scenario (Baseline + S2 only)
results_f1 <- list(
  "Baseline"    = baseline,
  "S2: Prod+LF" = readRDS("scenarios/results/ai_s2_prod_lf.rds")
)
# Panels: Budget, Debt, Real GDP, 10Y yield
p_budget <- bl_line(gather_var(results_f1, transform = tf_budget_pct_gdp),
                    title = "Budget Deficit as % of GDP",
                    ylab = "Percent of GDP") +
            geom_hline(yintercept = 0, linetype = "dotted", color = "gray50")
p_debt   <- bl_line(gather_var(results_f1, var = "D_pct_GDP"),
                    title = "Debt as % of GDP", ylab = "Percent of GDP")
p_gdp    <- bl_line(gather_var(results_f1, transform = tf_real_gdp_growth),
                    title = "Real GDP Growth", ylab = "Percent change",
                    y_format = function(x) paste0(x, "%"))
p_10y    <- bl_line(gather_var(results_f1, var = "R10"),
                    title = "10-Year Treasury Yield", ylab = "Percent")
fig1 <- bl_grid(list(p_budget, p_debt, p_gdp, p_10y), ncol = 2)
ggsave(file.path(out_dir, "fig1_ai.png"), fig1,
       width = 12, height = 8, dpi = 300)

# Figure 2: Persistent inflation — Budget, Debt, Inflation, 10Y
results_f2 <- list(
  "Baseline"           = baseline,
  "Inflation scenario" = readRDS("scenarios/results/alt_persistent_inflation.rds")
)
fig2 <- four_panel(results_f2,
                   third_var = "PI", third_title = "Inflation",
                   third_ylab = "Percent",
                   fourth_var = "R10", fourth_title = "10-Year Treasury Yield",
                   fourth_ylab = "Percent")
ggsave(file.path(out_dir, "fig2_inflation.png"), fig2,
       width = 12, height = 8, dpi = 300)

# Figure 3: Investor confidence — Budget, Debt, RG (avg rate on debt), 10Y
results_f3 <- list(
  "Baseline"                     = baseline,
  "Investor confidence scenario" = readRDS("scenarios/results/alt_investor_confidence.rds")
)
fig3 <- four_panel(results_f3,
                   third_var = "RG",
                   third_title = "Average Interest Rate on Federal Debt",
                   third_ylab = "Percent",
                   fourth_var = "R10", fourth_title = "10-Year Treasury Yield",
                   fourth_ylab = "Percent")
ggsave(file.path(out_dir, "fig3_investor_conf.png"), fig3,
       width = 12, height = 8, dpi = 300)

# Figure 4: Military conflict — Budget, Debt, Inflation, 10Y
results_f4 <- list(
  "Baseline"                   = baseline,
  "Military conflict scenario" = readRDS("scenarios/results/alt_military_conflict.rds")
)
fig4 <- four_panel(results_f4,
                   third_var = "PI", third_title = "Inflation",
                   third_ylab = "Percent",
                   fourth_var = "R10", fourth_title = "10-Year Treasury Yield",
                   fourth_ylab = "Percent")
ggsave(file.path(out_dir, "fig4_military.png"), fig4,
       width = 12, height = 8, dpi = 300)

cat("Alt article figures written to", out_dir, "\n")