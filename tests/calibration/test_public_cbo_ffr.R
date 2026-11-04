library(testthat)

source("calibration/R/build_calibration_inputs.R")
source("model/v1_8/parameters.R")
source("model/v1_8/neutral_rate.R")

test_that("public CBO FFR uses the detailed calendar forecast through 2036", {
  ffr <- build_cbo_ffr_cy(2026:2036)
  # 51135, 2. Calendar Year, F105:P105, stored publication values.
  expect_equal(ffr$year, 2026:2036)
  expect_equal(ffr$ffr,
               c(3.452, 3.389, 3.390, 3.389, 3.388, 3.383,
                 3.362, 3.347, 3.339, 3.334, 3.332), tolerance = 1e-12)
})

test_that("FFR extension uses LTBO yield changes before fiscal-year conversion", {
  ffr <- build_cbo_ffr_cy(2035:2056)
  frozen <- read.csv("calibration/golden/ltbo_2026_economic.csv")
  yields <- frozen$nominal_r10[match(2036:2056, frozen$year)]
  expect_equal(ffr$ffr[-1], 3.332 + yields - yields[1], tolerance = 1e-12)
  ci <- build_ltbo_calibration_inputs(end_year = 2037)
  rf <- ci$forced_targets$RF[ci$forced_targets$year %in% 2036:2037]
  expect_equal(rf, cy_to_fy(ffr$ffr[1:3]), tolerance = 1e-12)
})

test_that("FFR reads its rule and row label from config and fails on missing data", {
  config <- load_ltbo_config()
  config$rates$ffr$extension_rule <- "unknown_rule"
  expect_error(build_cbo_ffr_cy(config = config), "extension_rule")
  config <- load_ltbo_config()
  config$rates$ffr$detailed_forecast$label <- "Missing FFR label"
  expect_error(build_cbo_ffr_cy(config = config), "exactly one row labelled")
  expect_error(build_cbo_ffr_cy(c(2035, 2037)), "consecutive")
  expect_error(build_cbo_ffr_cy(2022:2026), "Missing requested source years")
})

test_that("source hash mismatches stop the FFR read", {
  root <- tempfile("cbo-hash-")
  dir.create(file.path(root, "calibration", "sources"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  manifest <- read.csv("calibration/source_manifest.csv")
  manifest$sha256[manifest$source_id == "cbo_economic"] <- strrep("0", 64)
  write.csv(manifest, file.path(root, "calibration", "source_manifest.csv"), row.names = FALSE)
  file.copy("calibration/sources/51135-2026-02-Economic-Projections.xlsx",
            file.path(root, "calibration", "sources"))
  expect_error(build_cbo_ffr_cy(root = root, config = load_ltbo_config()),
               "SHA-256 mismatch for cbo_economic")
})

test_that("kappa keeps the calendar ramp through ten and stays capped thereafter", {
  params <- create_parameters_v1_8()
  for (t in 1:31) {
    result <- compute_rfstar_v1_8(
      data.frame(rfstar = 1),
      data.frame(glfstar = 1, glfstar_base = 0, glqstar = 2, glqstar_base = 0),
      year_index = t, debt_proxy_user = 100, debt_proxy_base = 100,
      user_delta_rfstar_direct = 0, params = params
    )
    expect_equal(result$phase_in_share, if (t <= 10) t / 10 else 1)
    expect_equal(result$growth_contrib, result$gradual_growth)
    expect_equal(result$growth_contrib, result$phase_in_share * result$GR_LR)
    expect_equal(result$rfstar, 1 + result$growth_contrib)
  }
})

test_that("simulation and scenario override infer the extended input horizon", {
  source("scenarios/lib/run_scenario.R", local = TRUE)
  ci <- build_ltbo_calibration_inputs(end_year = 2040)
  history <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)
  direct <- simulate_blsmm_v1_8(
    baseline_exog = ci$baseline_exog, baseline_resid = ci$baseline_resid,
    hist_data = history, verbose = FALSE
  )
  scenario <- list(id = "extended", baseline_exog = ci$baseline_exog,
                   baseline_resid = ci$baseline_resid, hist_data = history)
  result <- run_scenario(scenario)
  expect_equal(result$year, 2026:2040)
  expect_equal(direct$year, result$year)
  expect_equal(result$xgap, direct$xgap, tolerance = 1e-12)
  expect_true(all(result$solver_converged))
  scenario$n_periods <- ci$n_periods + 1
  expect_error(run_scenario(scenario), "requests 16 periods")
})

test_that("calibration inputs stop on unread config rules and bad source values", {
  config <- load_ltbo_config()
  bad_rbar10 <- config
  bad_rbar10$rates$rbar10 <- "unrecognized_rule"
  expect_error(build_ltbo_calibration_inputs(end_year = 2040, config = bad_rbar10),
               "rates.rbar10")
  expect_error(build_ltbo_calibration_inputs(end_year = 2040, xgap_decay_years = -1),
               "decay_years")
  expect_error(build_ltbo_calibration_inputs(end_year = 2040, xgap_decay_residual = 0),
               "decay_residual")
  sheet <- data.frame(a = c("year", "x"), b = c("2036", "1.5"), c = c("2037", ""))
  expect_equal(numeric_row_by_year(sheet, 2, 1, 2036), 1.5)
  expect_error(numeric_row_by_year(sheet, 2, 1, 2036:2037), "2037")
})

test_that("forcing spec forces the variables the config mask lists", {
  source("model/v1_8/forcing.R", local = TRUE)
  ci <- build_ltbo_calibration_inputs(end_year = 2040)
  fs <- build_ltbo_forcing_spec(ci$forced_targets, create_forcing_spec)
  for (flag in c("force_xgap", "force_u", "force_pi", "force_rf", "force_mpe", "force_tp")) {
    expect_true(all(fs[[flag]] == 1), label = flag)
  }
  expect_true(all(fs$force_pie == 0))
  expect_true(all(fs$force_rg == 0))

  targets <- ci$forced_targets
  targets$RG <- 3
  fs_rg <- build_ltbo_forcing_spec(targets, create_forcing_spec, forced = c("RF", "RG"))
  expect_true(all(fs_rg$force_rg == 1))
  expect_equal(fs_rg$forced_rg, rep(3, nrow(targets)))
  expect_true(all(fs_rg$force_xgap == 0))

  expect_error(build_ltbo_forcing_spec(ci$forced_targets, create_forcing_spec, forced = "RG"),
               "no column")
  expect_error(build_ltbo_forcing_spec(ci$forced_targets, create_forcing_spec, forced = "R10"),
               "cannot force")
  expect_error(build_ltbo_forcing_spec(ci$forced_targets, create_forcing_spec,
                                       forced = character()), "missing or empty")
})
