# Rebuilds everything: runs all scenarios, then generates all figures.
# Run from repo root: source("scenarios/make_all_figures.R")
source("scenarios/lib/run_scenario.R")

scenario_files <- list.files("scenarios/inputs",
                            pattern = "\\.R$", full.names = TRUE)
cat("Running", length(scenario_files), "scenarios...\n\n")
run_all(scenario_files, results_dir = "scenarios/results")

cat("\nGenerating AI article figures...\n")
source("scenarios/lib/figures_ai_article.R")

cat("\nGenerating alternate-scenarios article figures...\n")
source("scenarios/lib/figures_alt_article.R")

cat("\nDone. All figures under scenarios/figures/\n")