# scenarios/lib/run_scenario.R
# Generic BLSMM scenario runner. Takes a scenario definition list and
# returns the simulation results data.frame.

source("model/v1_8/simulation.R")
source("model/v1_8/user_deltas.R")
source("app/R/blsmm_helpers.R")

# Load baseline data once
.baseline_exog  <- read.csv("data/blsmm_v1_8_forecast_exog.csv",
                            check.names = FALSE)
.baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv",
                            check.names = FALSE)
.hist_data      <- read.csv("data/blsmm_v1_8_historical.csv",
                            check.names = FALSE)

#' Run one BLSMM scenario
#' @param scenario a list with fields:
#'   id (string), label (string), color (hex), and optionally:
#'   user_deltas (named list, subset of create_user_deltas() fields)
#'   exog_override (named list, subset of baseline_exog columns)
#'   forcing_spec (forcing_spec object; see model/v1_8/forcing.R)
run_scenario <- function(scenario) {
  n <- 10

  # Build user_deltas
  ud <- create_user_deltas(n_periods = n)
  if (!is.null(scenario$user_deltas)) {
    for (k in names(scenario$user_deltas)) {
      if (!k %in% names(ud)) {
        stop(sprintf("Unknown user_delta field '%s' in scenario '%s'. Valid fields: %s",
                     k, scenario$id, paste(names(ud), collapse = ", ")))
      }
      stopifnot(length(scenario$user_deltas[[k]]) == n)
      ud[[k]] <- scenario$user_deltas[[k]]
    }
  }

  # Build exog with optional overrides
  exog <- .baseline_exog
  tp_0_original <- NULL

  if (!is.null(scenario$exog_override)) {
    # Preserve original tp_0 values for baseline comparison if overriding
    if ("tp_0" %in% names(scenario$exog_override)) {
      tp_0_original <- exog$tp_0
    }

    for (k in names(scenario$exog_override)) {
      if (!k %in% names(exog)) {
        stop(sprintf("Unknown exog column '%s' in scenario '%s'",
                     k, scenario$id))
      }
      stopifnot(length(scenario$exog_override[[k]]) == n)
      exog[[k]] <- scenario$exog_override[[k]]
    }

    # Provide original tp_0 as baseline reference for gap calculations
    if (!is.null(tp_0_original)) {
      exog$tp_0_base <- tp_0_original
    }
  }

  # If all deltas are zero, pass NULL (baseline convention)
  all_zero <- all(sapply(ud, function(x) all(x == 0)))

  simulate_blsmm_v1_8(
    n_periods          = n,
    baseline_exog      = exog,
    baseline_resid     = .baseline_resid,
    hist_data          = .hist_data,
    user_deltas        = if (all_zero) NULL else ud,
    forcing_spec       = scenario$forcing_spec,
    params             = NULL,
    expectations_speed = FALSE,
    verbose            = FALSE
  )
}

#' Run many scenarios from input files and save to results/
run_all <- function(scenario_files,
                    results_dir = "scenarios/results") {
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  out <- list()
  for (f in scenario_files) {
    env <- new.env()
    source(f, local = env)
    if (is.null(env$scenario)) {
      stop(sprintf("File '%s' does not define `scenario`", f))
    }
    sc <- env$scenario
    cat(sprintf("Running %-35s ... ", sc$id))
    res <- run_scenario(sc)
    saveRDS(res, file.path(results_dir, paste0(sc$id, ".rds")))
    write.csv(res, file.path(results_dir, paste0(sc$id, ".csv")),
              row.names = FALSE)
    out[[sc$id]] <- res
    cat("done\n")
  }
  invisible(out)
}