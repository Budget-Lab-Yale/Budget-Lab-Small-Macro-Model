# ==============================================================================
# Write R reference runs to js/test/fixtures/ for the JS parity test.
# ==============================================================================
# Run from the repository root:   Rscript js/make-fixtures.R
#
# Fixtures are not committed: R's solver output differs across platforms in
# the last few bits, so CI regenerates them on every run instead of diffing a
# stored copy. Each fixture holds the scenario inputs and every column of
# simulate_blsmm_v1_8()'s result.
# ==============================================================================

source("js/write-json.R")
source("model/v1_8/parameters.R")
source("model/v1_8/user_deltas.R")
source("model/v1_8/simulation.R")

N <- 10
baseline_exog <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
hist_data <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)

out_dir <- "js/test/fixtures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
unlink(file.path(out_dir, "*.json"))

DELTA_KEYS <- names(create_user_deltas(N))

run_fixture <- function(name, deltas, fast) {
  ud <- create_user_deltas(N)
  for (k in names(deltas)) ud[[k]] <- deltas[[k]]
  res <- simulate_blsmm_v1_8(
    n_periods = N, baseline_exog = baseline_exog, baseline_resid = baseline_resid,
    hist_data = hist_data, user_deltas = ud, expectations_speed = fast, verbose = FALSE
  )
  write_json_file(
    list(
      name = name,
      fast_expectations = fast,
      deltas = lapply(as.list(ud), I),
      columns = df_columns(res)
    ),
    file.path(out_dir, paste0(name, ".json"))
  )
  cat("  ", name, "\n")
}

load_preset_deltas <- function(path) {
  env <- new.env()
  sys.source(path, envir = env)
  env$scenario$user_deltas
}

cat("Writing fixtures to", out_dir, "\n")

run_fixture("baseline", list(), FALSE)
run_fixture("baseline_fast", list(), TRUE)

for (f in c("ai_s2_prod_lf", "alt_persistent_inflation", "alt_military_conflict")) {
  d <- load_preset_deltas(file.path("scenarios/inputs", paste0(f, ".R")))
  run_fixture(f, d, FALSE)
  run_fixture(paste0(f, "_fast"), d, TRUE)
}

# One fixture per input at a shape the UI offers, so each delta path is
# exercised alone.
single_magnitude <- c(
  user_delta_prod = 0.5, user_delta_lf = -0.5, user_delta_rgfr = 1,
  user_delta_rgfop = 1, user_delta_rfstar_direct = 0.25, user_delta_pistar = 0.5,
  user_delta_ADshock = 2, user_delta_inflshock = 1, user_delta_MPshock = 0.5
)
for (k in names(single_magnitude)) {
  run_fixture(paste0("single_", k), setNames(list(rep(single_magnitude[[k]], N)), k), FALSE)
}

# Seeded random scenarios: random subsets of inputs, random shapes, and some
# year-by-year noise, at magnitudes up to several times what the UI suggests.
set.seed(20261005)
scale <- c(
  user_delta_prod = 1.5, user_delta_lf = 1.5, user_delta_rgfr = 4,
  user_delta_rgfop = 4, user_delta_rfstar_direct = 1.5, user_delta_pistar = 1.5,
  user_delta_ADshock = 5, user_delta_inflshock = 3, user_delta_MPshock = 3
)
shape_path <- function(shape, m) {
  switch(shape,
    onetime = c(m, rep(0, N - 1)),
    temporary3 = c(rep(m, 3), rep(0, N - 3)),
    permanent = rep(m, N),
    ramp = seq(0, m, length.out = N),
    noise = round(runif(N, -abs(m), abs(m)), 2)
  )
}
for (i in seq_len(40)) {
  keys <- sample(DELTA_KEYS, sample(1:5, 1))
  deltas <- list()
  for (k in keys) {
    m <- round(runif(1, -scale[[k]], scale[[k]]), 3)
    deltas[[k]] <- shape_path(sample(c("onetime", "temporary3", "permanent", "ramp", "noise"), 1), m)
  }
  run_fixture(sprintf("random_%02d", i), deltas, runif(1) < 0.3)
}

cat("Done.\n")
