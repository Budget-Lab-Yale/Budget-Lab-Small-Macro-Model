#!/usr/bin/env Rscript

source("calibration/R/read_cbo_ltbo_2026.R")

ltbo <- read_cbo_ltbo_2026()
output_dir <- file.path(find_calibration_root(), "calibration", "golden")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(ltbo$economic, file.path(output_dir, "ltbo_2026_economic.csv"),
          row.names = FALSE, na = "")
write.csv(ltbo$budget, file.path(output_dir, "ltbo_2026_budget.csv"),
          row.names = FALSE, na = "")
write.csv(ltbo$model_inputs, file.path(output_dir, "ltbo_2026_model_inputs_partial.csv"),
          row.names = FALSE, na = "")
write.csv(ltbo$targets, file.path(output_dir, "ltbo_2026_targets_partial.csv"),
          row.names = FALSE, na = "")
write.csv(ltbo$provenance, file.path(output_dir, "ltbo_2026_provenance.csv"),
          row.names = FALSE, na = "")

cat("Wrote LTBO extracted inputs to", output_dir, "\n")
