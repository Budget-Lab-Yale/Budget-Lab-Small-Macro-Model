# Generates the 3 figures for AI_scenario.pdf
source("scenarios/lib/blsmm_theme.R")
source("scenarios/lib/plot_helpers.R")

# Load in an order that determines plotting order (baseline first)
results_ai <- list(
  "Baseline"           = readRDS("scenarios/results/baseline.rds"),
  "S1: Prod"           = readRDS("scenarios/results/ai_s1_productivity.rds"),
  "S2: Prod+LF"        = readRDS("scenarios/results/ai_s2_prod_lf.rds"),
  "S3a: Prod+LF+UI"    = readRDS("scenarios/results/ai_s3a_prod_lf_ui.rds"),
  "S3b: Prod+LF+SSMC"  = readRDS("scenarios/results/ai_s3b_prod_lf_ssmc.rds")
)

out_dir <- "scenarios/figures/ai_article"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Figure 2: Budget Deficit as % of GDP
p2 <- bl_line(
  gather_var(results_ai, transform = tf_budget_pct_gdp),
  title    = "Budget Deficit as % of GDP",
  subtitle = "More positive = larger deficit",
  ylab     = "Percent of GDP"
) + geom_hline(yintercept = 0, linetype = "dotted", color = "gray50")
ggsave(file.path(out_dir, "fig2_budget_deficit.png"), p2,
       width = 8, height = 5, dpi = 300)

# Figure 3: Debt as % of GDP
p3 <- bl_line(
  gather_var(results_ai, var = "D_pct_GDP"),
  title    = "Debt as % of GDP",
  subtitle = "AI productivity shock dramatically reduces debt trajectory",
  ylab     = "Percent of GDP"
)
ggsave(file.path(out_dir, "fig3_debt.png"), p3,
       width = 8, height = 5, dpi = 300)

# Figure 4: Real GDP Growth
p4 <- bl_line(
  gather_var(results_ai, transform = tf_real_gdp_growth),
  title    = "Real GDP Growth",
  subtitle = "Productivity gains drive substantial GDP growth",
  ylab     = "Percent change",
  y_format = function(x) paste0(x, "%")
)
ggsave(file.path(out_dir, "fig4_real_gdp_growth.png"), p4,
       width = 8, height = 5, dpi = 300)

cat("AI article figures written to", out_dir, "\n")