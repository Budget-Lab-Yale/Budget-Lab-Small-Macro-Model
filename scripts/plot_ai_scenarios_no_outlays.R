# ==============================================================================
# AI Scenario Visualization Script (No Outlays Scenarios)
# ==============================================================================
# Creates comparison charts for baseline vs 2 AI scenarios (no S3a/S3b)
# ==============================================================================

# Set working directory to main project directory
setwd("C:/Users/jcg_g/OneDrive/Yale/Budget Lab/Macro Model/Small Macro Model")

# Load required packages
library(ggplot2)
library(gridExtra)

cat("\n")
cat("================================================================================\n")
cat("  AI Scenario Visualization (No Outlays)\n")
cat("================================================================================\n\n")

# ==============================================================================
# LOAD RESULTS
# ==============================================================================
cat("Loading simulation results...\n")

result_baseline <- readRDS("BLSMM ai/results/ai_baseline.rds")
result_s1 <- readRDS("BLSMM ai/results/ai_scenario_1_productivity.rds")
result_s2 <- readRDS("BLSMM ai/results/ai_scenario_2_prod_lf.rds")

cat("✓ Results loaded\n\n")

# ==============================================================================
# CREATE OUTPUT DIRECTORY
# ==============================================================================
dir.create("figures/ai_scenarios_no_outlays", recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# PREPARE DATA FOR PLOTTING
# ==============================================================================
cat("Preparing data for visualization...\n")

# Fiscal years
years <- 2026:2035

# Create long-form data for each variable (baseline + 2 scenarios = 3 total)
create_plot_data <- function(var_name, baseline, s1, s2) {
  data.frame(
    Year = rep(years, 3),
    Value = c(baseline, s1, s2),
    Scenario = rep(c("Baseline", "S1: Productivity", "S2: Productivity + LFPR"), each = 10),
    stringsAsFactors = FALSE
  )
}

# Budget balance needs calculation (BUD/GDP$ * 100)
calc_budget_ratio <- function(result) {
  result$BUD / result$`GDP$` * 100
}

# Create datasets for each variable
data_debt <- create_plot_data(
  "Debt/GDP",
  result_baseline$D_pct_GDP,
  result_s1$D_pct_GDP,
  result_s2$D_pct_GDP
)

data_budget <- create_plot_data(
  "Budget/GDP",
  calc_budget_ratio(result_baseline),
  calc_budget_ratio(result_s1),
  calc_budget_ratio(result_s2)
)

data_gdp <- create_plot_data(
  "Real GDP",
  result_baseline$GDP / 1000,  # Convert to trillions
  result_s1$GDP / 1000,
  result_s2$GDP / 1000
)

data_unemp <- create_plot_data(
  "Unemployment",
  result_baseline$U,
  result_s1$U,
  result_s2$U
)

data_infl <- create_plot_data(
  "Inflation",
  result_baseline$PI,
  result_s1$PI,
  result_s2$PI
)

data_ff <- create_plot_data(
  "Fed Funds",
  result_baseline$RF,
  result_s1$RF,
  result_s2$RF
)

data_r10 <- create_plot_data(
  "10-Year",
  result_baseline$R10,
  result_s1$R10,
  result_s2$R10
)

cat("✓ Data prepared\n\n")

# ==============================================================================
# DEFINE PLOTTING THEME AND COLORS
# ==============================================================================

# Color palette
scenario_colors <- c(
  "Baseline" = "#808080",              # Grey
  "S1: Productivity" = "#0072B2",      # Blue
  "S2: Productivity + LFPR" = "#009E73"  # Green
)

# Line types
scenario_linetypes <- c(
  "Baseline" = "dashed",
  "S1: Productivity" = "solid",
  "S2: Productivity + LFPR" = "solid"
)

# Line sizes
scenario_sizes <- c(
  "Baseline" = 1.2,
  "S1: Productivity" = 0.9,
  "S2: Productivity + LFPR" = 0.9
)

# Common theme
theme_ai <- theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray30"),
    axis.title = element_text(size = 10),
    axis.text = element_text(size = 9),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 9),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90")
  )

# ==============================================================================
# CREATE INDIVIDUAL PLOTS
# ==============================================================================
cat("Creating plots...\n")

# 1. Debt as % of GDP
p1 <- ggplot(data_debt, aes(x = Year, y = Value, color = Scenario, linetype = Scenario, size = Scenario)) +
  geom_line() +
  scale_color_manual(values = scenario_colors) +
  scale_linetype_manual(values = scenario_linetypes) +
  scale_size_manual(values = scenario_sizes) +
  scale_x_continuous(breaks = seq(2026, 2035, 2)) +
  labs(
    title = "Debt as % of GDP",
    subtitle = "AI productivity shock dramatically reduces debt trajectory",
    x = "Fiscal Year",
    y = "Percent of GDP"
  ) +
  theme_ai

ggsave("figures/ai_scenarios_no_outlays/debt_gdp.png", p1, width = 8, height = 5, dpi = 300)
cat("  ✓ Debt/GDP chart saved\n")

# 2. Budget Balance as % of GDP
p2 <- ggplot(data_budget, aes(x = Year, y = Value, color = Scenario, linetype = Scenario, size = Scenario)) +
  geom_line() +
  geom_hline(yintercept = 0, linetype = "dotted", color = "gray50") +
  scale_color_manual(values = scenario_colors) +
  scale_linetype_manual(values = scenario_linetypes) +
  scale_size_manual(values = scenario_sizes) +
  scale_x_continuous(breaks = seq(2026, 2035, 2)) +
  labs(
    title = "Budget Balance as % of GDP",
    subtitle = "More negative = larger deficit",
    x = "Fiscal Year",
    y = "Percent of GDP"
  ) +
  theme_ai

ggsave("figures/ai_scenarios_no_outlays/budget_balance.png", p2, width = 8, height = 5, dpi = 300)
cat("  ✓ Budget balance chart saved\n")

# 3. Real GDP
p3 <- ggplot(data_gdp, aes(x = Year, y = Value, color = Scenario, linetype = Scenario, size = Scenario)) +
  geom_line() +
  scale_color_manual(values = scenario_colors) +
  scale_linetype_manual(values = scenario_linetypes) +
  scale_size_manual(values = scenario_sizes) +
  scale_x_continuous(breaks = seq(2026, 2035, 2)) +
  scale_y_continuous(labels = function(x) paste0("$", x, "T")) +
  labs(
    title = "Real GDP",
    subtitle = "Productivity gains drive substantial GDP growth",
    x = "Fiscal Year",
    y = "Trillions of 2017 dollars"
  ) +
  theme_ai

ggsave("figures/ai_scenarios_no_outlays/real_gdp.png", p3, width = 8, height = 5, dpi = 300)
cat("  ✓ Real GDP chart saved\n")

# 4. Unemployment Rate
p4 <- ggplot(data_unemp, aes(x = Year, y = Value, color = Scenario, linetype = Scenario, size = Scenario)) +
  geom_line() +
  scale_color_manual(values = scenario_colors) +
  scale_linetype_manual(values = scenario_linetypes) +
  scale_size_manual(values = scenario_sizes) +
  scale_x_continuous(breaks = seq(2026, 2035, 2)) +
  labs(
    title = "Unemployment Rate",
    subtitle = "Labor force participation changes affect structural unemployment",
    x = "Fiscal Year",
    y = "Percent"
  ) +
  theme_ai

ggsave("figures/ai_scenarios_no_outlays/unemployment.png", p4, width = 8, height = 5, dpi = 300)
cat("  ✓ Unemployment chart saved\n")

# 5. Inflation
p5 <- ggplot(data_infl, aes(x = Year, y = Value, color = Scenario, linetype = Scenario, size = Scenario)) +
  geom_line() +
  geom_hline(yintercept = 2, linetype = "dotted", color = "gray50", alpha = 0.5) +
  scale_color_manual(values = scenario_colors) +
  scale_linetype_manual(values = scenario_linetypes) +
  scale_size_manual(values = scenario_sizes) +
  scale_x_continuous(breaks = seq(2026, 2035, 2)) +
  labs(
    title = "Inflation Rate (PCE)",
    subtitle = "Fed target: 2% (dotted line)",
    x = "Fiscal Year",
    y = "Percent"
  ) +
  theme_ai

ggsave("figures/ai_scenarios_no_outlays/inflation.png", p5, width = 8, height = 5, dpi = 300)
cat("  ✓ Inflation chart saved\n")

# 6. Fed Funds Rate
p6 <- ggplot(data_ff, aes(x = Year, y = Value, color = Scenario, linetype = Scenario, size = Scenario)) +
  geom_line() +
  scale_color_manual(values = scenario_colors) +
  scale_linetype_manual(values = scenario_linetypes) +
  scale_size_manual(values = scenario_sizes) +
  scale_x_continuous(breaks = seq(2026, 2035, 2)) +
  labs(
    title = "Federal Funds Rate",
    subtitle = "Policy response to changing economic conditions",
    x = "Fiscal Year",
    y = "Percent"
  ) +
  theme_ai

ggsave("figures/ai_scenarios_no_outlays/fed_funds.png", p6, width = 8, height = 5, dpi = 300)
cat("  ✓ Fed Funds chart saved\n")

# 7. 10-Year Treasury Yield
p7 <- ggplot(data_r10, aes(x = Year, y = Value, color = Scenario, linetype = Scenario, size = Scenario)) +
  geom_line() +
  scale_color_manual(values = scenario_colors) +
  scale_linetype_manual(values = scenario_linetypes) +
  scale_size_manual(values = scenario_sizes) +
  scale_x_continuous(breaks = seq(2026, 2035, 2)) +
  labs(
    title = "10-Year Treasury Yield",
    subtitle = "Long-term interest rate dynamics",
    x = "Fiscal Year",
    y = "Percent"
  ) +
  theme_ai

ggsave("figures/ai_scenarios_no_outlays/treasury_10y.png", p7, width = 8, height = 5, dpi = 300)
cat("  ✓ 10-Year Treasury chart saved\n")

# ==============================================================================
# CREATE COMBINED FIGURE
# ==============================================================================
cat("\nCreating combined figure...\n")

# Create a 3x3 grid (7 plots + empty spaces)
combined_plot <- grid.arrange(
  p1, p2, p3,
  p4, p5, p6,
  p7,
  ncol = 3,
  top = "AI Scenario Analysis: Baseline vs 2 Alternative Scenarios (FY2026-FY2035)"
)

ggsave("figures/ai_scenarios_no_outlays/combined_all_variables.png", combined_plot,
       width = 16, height = 12, dpi = 300)

cat("  ✓ Combined figure saved\n\n")

# ==============================================================================
# SUMMARY
# ==============================================================================
cat("================================================================================\n")
cat("  Visualization Complete!\n")
cat("================================================================================\n\n")

cat("Individual charts saved to figures/ai_scenarios_no_outlays/:\n")
cat("  - debt_gdp.png\n")
cat("  - budget_balance.png\n")
cat("  - real_gdp.png\n")
cat("  - unemployment.png\n")
cat("  - inflation.png\n")
cat("  - fed_funds.png\n")
cat("  - treasury_10y.png\n")
cat("  - combined_all_variables.png\n\n")

cat("All charts created at 300 DPI for publication quality.\n\n")
