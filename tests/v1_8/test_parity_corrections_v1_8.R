# ==============================================================================
# BLSMM v1.8 Excel-Parity Regression Tests
# ==============================================================================
# Purpose: Protect two R/Excel parity corrections
#   1. psi fiscal feedback includes the first forecast year's growth deviation
#      (workbook Model!O27 = 0, Model!P27 = O27 + psi_1 * deviation)
#   2. The debt-proxy CHI anchor uses the year-specific baseline effective rate
#      (RG_base column; workbook User!J232), falling back to params$RG_base
# ==============================================================================

library(testthat)

# Locate the project root without depending on how this file was invoked.
find_project_root <- function(start = getwd()) {
  path <- normalizePath(start, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(path, "model", "v1_8", "simulation.R"))) {
      return(path)
    }
    parent <- dirname(path)
    if (identical(parent, path)) stop("Could not locate BLSMM project root")
    path <- parent
  }
}

setwd(find_project_root())
source("model/v1_8/simulation.R")
source("model/v1_8/parameters.R")
source("model/v1_8/user_deltas.R")

baseline_exog <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
hist_data <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)
params <- create_parameters_v1_8()
n <- 10

run <- function(user_deltas = NULL, exog = baseline_exog) {
  simulate_blsmm_v1_8(
    n_periods = n, baseline_exog = exog, baseline_resid = baseline_resid,
    hist_data = hist_data, user_deltas = user_deltas, forcing_spec = NULL,
    params = params, expectations_speed = FALSE, verbose = FALSE
  )
}

exog_without_rg <- baseline_exog[, names(baseline_exog) != "RG_base"]
exog_constant_rg <- baseline_exog
exog_constant_rg$RG_base <- params$RG_base

# ==============================================================================
# TEST 1: First-year psi feedback
# ==============================================================================
test_that("A first-year growth deviation enters psi feedback and persists", {
  ud <- create_user_deltas(n)
  ud$user_delta_prod[1] <- 0.5
  ud$user_delta_lf[1] <- -0.3
  sim <- run(ud)
  base <- run()

  expect_equal(sim$PROD_fb[1], params$psi_2 * 0.5, tolerance = 1e-12)
  expect_equal(sim$LF_fb[1], params$psi_1 * -0.3, tolerance = 1e-12)
  # Cumulative: no later deviation, so the first-year feedback carries forward
  expect_equal(sim$PROD_fb, rep(params$psi_2 * 0.5, n), tolerance = 1e-12)
  expect_equal(sim$LF_fb, rep(params$psi_1 * -0.3, n), tolerance = 1e-12)
  expect_equal(sim$rgfop_star - base$rgfop_star,
               sim$PROD_fb + sim$LF_fb, tolerance = 1e-12)
})

# ==============================================================================
# TEST 2: Year-specific RG_base anchor
# ==============================================================================
test_that("RG_base must be present and vary by year in the forecast exog", {
  expect_true("RG_base" %in% names(baseline_exog))
  expect_gt(diff(range(baseline_exog$RG_base[1:n])), 0.1)
})

test_that("The debt proxy uses the year-specific RG_base path", {
  ud <- create_user_deltas(n)
  ud$user_delta_prod <- rep(0.5, n)
  with_path <- run(ud)
  with_constant <- run(ud, exog_constant_rg)

  gap_path <- with_path$debt_proxy_user - with_path$debt_proxy_base
  gap_constant <- with_constant$debt_proxy_user - with_constant$debt_proxy_base
  expect_gt(max(abs(gap_path - gap_constant)), 1e-6)
})

test_that("A missing RG_base column falls back to params$RG_base", {
  ud <- create_user_deltas(n)
  ud$user_delta_prod <- rep(0.5, n)
  fallback <- run(ud, exog_without_rg)
  constant <- run(ud, exog_constant_rg)

  expect_true(all(fallback$solver_converged))
  expect_equal(fallback$debt_proxy_user, constant$debt_proxy_user, tolerance = 1e-10)
  expect_equal(fallback$D_pct_GDP, constant$D_pct_GDP, tolerance = 1e-10)
})

test_that("The RG_base anchor leaves the no-delta baseline economics unchanged", {
  with_path <- run()
  without <- run(exog = exog_without_rg)

  expect_equal(with_path$debt_proxy_user, with_path$debt_proxy_base, tolerance = 1e-12)
  for (v in c("xgap", "U", "PI", "RF", "R10", "RG", "D", "D_pct_GDP")) {
    expect_equal(with_path[[v]], without[[v]], tolerance = 1e-10, label = v)
  }
})

cat("✓ Parity-correction regression tests complete\n")
