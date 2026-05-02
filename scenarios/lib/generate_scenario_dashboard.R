# scenarios/lib/generate_scenario_dashboard.R
#
# Generate the full Excel-style chart set for a single scenario, writing
# one PNG per chart plus a combined `dashboard.png` grid to
#   scenarios/figures/dashboards/<scenario_id>/
#
# Usage from the shell:
#   Rscript scenarios/lib/generate_scenario_dashboard.R <scenario_id> ["Label"]
# From R:
#   source("scenarios/lib/generate_scenario_dashboard.R")
#   generate_scenario_dashboard("alt_investor_confidence")
#
# The scenario must already have been run (i.e. results/<id>.rds exists).
# Three Excel charts (Total Receipts, Total Outlays, Primary Outlays) are
# omitted because the v1.8 fiscal block only emits aggregate BUD/BUDP/NI.

source("scenarios/lib/blsmm_theme.R")
source("scenarios/lib/plot_helpers.R")

generate_scenario_dashboard <- function(scenario_id,
                                        scenario_label = NULL,
                                        results_dir = "scenarios/results",
                                        out_root    = "scenarios/figures/dashboards") {
  rds_path     <- file.path(results_dir, paste0(scenario_id, ".rds"))
  baseline_rds <- file.path(results_dir, "baseline.rds")
  if (!file.exists(rds_path)) {
    stop(sprintf("Results not found: %s. Run the scenario first.", rds_path))
  }
  if (!file.exists(baseline_rds)) {
    stop("Baseline results not found at ", baseline_rds,
         ". Run baseline.R first.")
  }

  baseline <- readRDS(baseline_rds)
  scenario <- readRDS(rds_path)

  if (is.null(scenario_label) || !nzchar(scenario_label)) {
    scenario_label <- scenario_id
  }

  # Ensure the theme has palette/linetype entries for this label.
  if (!(scenario_label %in% names(bl_palette)))   bl_palette[[scenario_label]]   <<- "#2166AC"
  if (!(scenario_label %in% names(bl_linetypes))) bl_linetypes[[scenario_label]] <<- "solid"

  results <- setNames(list(baseline, scenario), c("Baseline", scenario_label))

  out_dir <- file.path(out_root, scenario_id)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  # --- Transforms ---
  tf_pbudget_pct_gdp <- function(r) r$BUDP / r$`GDP$` * -100
  tf_gdp_growth      <- function(r) c(NA, 100 * (r$GDP[-1] / r$GDP[-length(r$GDP)] - 1))

  zero_line <- geom_hline(yintercept = 0, linetype = "dotted", color = "gray50")

  charts <- list(
    unemployment = bl_line(gather_var(results, var = "U"),
                           title = "Unemployment Rate", ylab = "Percent"),
    inflation    = bl_line(gather_var(results, var = "PI"),
                           title = "Inflation (PCE, Y/Y)", ylab = "Percent"),
    real_gdp     = bl_line(gather_var(results, transform = tf_real_gdp_tril),
                           title = "Real GDP", ylab = "Trillions of 2017 dollars",
                           y_format = function(x) paste0("$", x, "T")),
    real_gdp_growth = bl_line(gather_var(results, transform = tf_gdp_growth),
                              title = "Real GDP Growth (Y/Y)", ylab = "Percent"),
    output_gap   = bl_line(gather_var(results, var = "xgap"),
                           title = "Output Gap", ylab = "Percent") + zero_line,
    fed_funds    = bl_line(gather_var(results, var = "RF"),
                           title = "Federal Funds Rate", ylab = "Percent"),
    r10          = bl_line(gather_var(results, var = "R10"),
                           title = "10-Year Treasury Yield", ylab = "Percent"),
    real_r10     = bl_line(gather_var(results, var = "real_r10"),
                           title = "Real 10-Year Treasury Yield", ylab = "Percent"),
    avg_rate     = bl_line(gather_var(results, var = "RG"),
                           title = "Average Interest Rate on Federal Debt",
                           ylab = "Percent"),
    budget       = bl_line(gather_var(results, transform = tf_budget_pct_gdp),
                           title = "Budget Deficit as % of GDP",
                           ylab = "Percent of GDP") + zero_line,
    primary_budget = bl_line(gather_var(results, transform = tf_pbudget_pct_gdp),
                             title = "Primary Budget Deficit as % of GDP",
                             ylab = "Percent of GDP") + zero_line,
    debt         = bl_line(gather_var(results, var = "D_pct_GDP"),
                           title = "Debt as % of GDP", ylab = "Percent of GDP")
  )

  # Individual PNGs (numbered so they sort in dashboard order)
  for (i in seq_along(charts)) {
    fname <- sprintf("%02d_%s.png", i, names(charts)[i])
    ggsave(file.path(out_dir, fname), charts[[i]],
           width = 6, height = 4, dpi = 150)
  }

  # Combined dashboard grid (3 cols x 4 rows)
  dashboard <- bl_grid(charts, ncol = 3) +
    patchwork::plot_annotation(
      title    = sprintf("BLSMM Dashboard - %s", scenario_label),
      subtitle = sprintf("Scenario id: %s - Baseline shown dashed", scenario_id)
    )
  ggsave(file.path(out_dir, "dashboard.png"), dashboard,
         width = 16, height = 18, dpi = 150)

  cat(sprintf("Dashboard for '%s' written to %s\n", scenario_id, out_dir))
  invisible(out_dir)
}

# --- CLI entry ---
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 1) {
    generate_scenario_dashboard(
      scenario_id    = args[[1]],
      scenario_label = if (length(args) >= 2) args[[2]] else NULL
    )
  }
}
