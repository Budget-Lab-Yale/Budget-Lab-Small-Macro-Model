# ==============================================================================
# Write js/model-data.json, the inputs js/blsmm-model.js runs on.
# ==============================================================================
# Run from the repository root:   Rscript js/export-data.R
#
# Sources: the three data/*.csv files the model reads, create_parameters_v1_8(),
# and the preset scenario files the interactive offers. Re-run after changing
# any of them and commit the result; CI fails if the committed file is stale.
# ==============================================================================

source("js/write-json.R")
source("model/v1_8/parameters.R")

# Presets offered by the interactive, in display order.
PRESET_FILES <- c(
  "scenarios/inputs/ai_s2_prod_lf.R",
  "scenarios/inputs/alt_persistent_inflation.R",
  "scenarios/inputs/alt_military_conflict.R"
)

read_data <- function(name) {
  read.csv(file.path("data", name), check.names = FALSE)
}

load_preset <- function(path) {
  env <- new.env()
  sys.source(path, envir = env)
  s <- env$scenario
  if (is.null(s)) stop(sprintf("%s does not define `scenario`", path))
  list(
    id = s$id,
    label = s$label,
    source_file = path,
    user_deltas = lapply(s$user_deltas, I)
  )
}

presets <- lapply(PRESET_FILES, load_preset)
names(presets) <- vapply(presets, function(p) p$id, character(1))

params <- create_parameters_v1_8()

out <- list(
  model_version = "v1_8",
  params = params,
  forecast_exog = df_columns(read_data("blsmm_v1_8_forecast_exog.csv")),
  forecast_resid = df_columns(read_data("blsmm_v1_8_forecast_resid.csv")),
  historical = df_columns(read_data("blsmm_v1_8_historical.csv")),
  presets = presets
)

write_json_file(out, "js/model-data.json")
cat("Wrote js/model-data.json\n")
