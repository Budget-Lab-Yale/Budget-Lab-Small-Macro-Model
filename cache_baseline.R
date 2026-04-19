# ==============================================================================
# Cache Baseline Scenario for BLSMM v1.8
# ==============================================================================
# This script pre-computes the baseline scenario and saves it to an RDS file
# for instant loading when the Shiny app starts.
# Run this script whenever the baseline parameters change.
# ==============================================================================

# Load required files
source("model/v1_8/simulation.R")
source("model/v1_8/parameters.R")
source("model/v1_8/equations.R")
source("model/v1_8/debt_proxy.R")
source("model/v1_8/forcing.R")
source("model/v1_8/neutral_rate.R")
source("model/v1_8/presim_block.R")
source("model/v1_8/solver.R")
source("model/v1_8/user_deltas.R")

# Load data files (same as app.R)
baseline_exog_v1_8 <<- read.csv('data/blsmm_v1_8_forecast_exog.csv', check.names = FALSE)
baseline_resid_v1_8 <<- read.csv('data/blsmm_v1_8_forecast_resid.csv', check.names = FALSE)
hist_data_v1_8 <<- read.csv('data/blsmm_v1_8_historical.csv', check.names = FALSE)

# Set parameters
N_PERIODS <- 10

# Function to run baseline (same as in blsmm_server.R)
run_baseline_v1_8 <- function(n_periods = 10, params = NULL,
                              expectations_speed = FALSE, verbose = FALSE) {

  # Use default parameters if none provided
  if (is.null(params)) {
    params <- create_parameters_v1_8()
  }

  # Baseline uses no user deltas (passing NULL)
  baseline_result <- simulate_blsmm_v1_8(
    n_periods = n_periods,
    baseline_exog = baseline_exog_v1_8,
    baseline_resid = baseline_resid_v1_8,
    hist_data = hist_data_v1_8,
    user_deltas = NULL,
    forcing_spec = NULL,
    params = params,
    expectations_speed = expectations_speed,
    verbose = verbose
  )

  return(baseline_result)
}

# Compute baseline
cat("Computing baseline scenario for", N_PERIODS, "periods...\n")
start_time <- Sys.time()

baseline_v1_8 <- run_baseline_v1_8(
  n_periods = N_PERIODS,
  params = NULL,
  expectations_speed = FALSE,
  verbose = FALSE
)

end_time <- Sys.time()
computation_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# Add metadata to the cached object
cached_baseline <- list(
  data = baseline_v1_8,
  timestamp = Sys.time(),
  n_periods = N_PERIODS,
  computation_time = computation_time,
  r_version = R.version.string,
  cache_version = "1.0"
)

# Ensure data directory exists
if (!dir.exists("data")) {
  dir.create("data")
}

# Save to RDS file
cache_file <- "data/baseline_v1_8_cached.rds"
saveRDS(cached_baseline, cache_file)

# Report results
file_size <- file.info(cache_file)$size / 1024  # Size in KB
cat("\n=== Baseline Caching Complete ===\n")
cat("Computation time:", round(computation_time, 2), "seconds\n")
cat("Cache file:", cache_file, "\n")
cat("File size:", round(file_size, 1), "KB\n")
cat("Timestamp:", format(cached_baseline$timestamp, "%Y-%m-%d %H:%M:%S"), "\n")
cat("\nThe Shiny app will now load instantly using this cached baseline.\n")
cat("Re-run this script if baseline parameters change.\n")