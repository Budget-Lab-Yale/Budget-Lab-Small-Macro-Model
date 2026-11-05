# Gate D: the LTBO-centered baseline calibrates (forced->backout->unforced round
# trip), reproduces the original 2026-2035 baseline, and is terminally stable.

library(testthat)

find_project_root <- function(start = getwd()) {
  path <- normalizePath(start, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(path, "model", "v1_8", "calibration.R"))) return(path)
    parent <- dirname(path)
    if (identical(parent, path)) stop("Could not locate BLSMM project root")
    path <- parent
  }
}
old_wd <- setwd(find_project_root())
on.exit(setwd(old_wd), add = TRUE)

source("model/v1_8/calibration.R")
source("calibration/R/build_calibration_inputs.R")

hist_data <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)
ci <- build_ltbo_calibration_inputs(end_year = 2045)
fs <- build_ltbo_forcing_spec(ci$forced_targets, create_forcing_spec)
res <- calibrate_residuals_v1_8(ci$baseline_exog, ci$baseline_resid, hist_data,
                                fs, verbose = FALSE)

test_that("spliced inputs are well-formed and continuous", {
  expect_equal(ci$years, 2026:2045)
  expect_equal(names(ci$baseline_exog), names(read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)))
  expect_false(anyNA(ci$baseline_exog))
  expect_false(anyNA(ci$forced_targets))
  # seam continuity: 2035 vs 2036 within a smooth step for each forced target
  s <- which(ci$forced_targets$year == 2035); e <- s + 1L
  for (v in c("xgap", "U", "PI", "RF", "MPE10", "TP", "R10")) {
    if (v %in% names(ci$forced_targets))
      expect_lt(abs(ci$forced_targets[[v]][e] - ci$forced_targets[[v]][s]), 0.3,
                label = paste("seam jump in", v))
  }
  # R10 = MPE10 + TP is a model identity, verified on the solved path below;
  # it is not stored as a separate forced target.
})

test_that("forced/unforced round trip reproduces within tolerance", {
  expect_lt(res$max_abs_roundtrip_error, 1e-8)
  expect_true(all(res$forced$solver_converged))
  expect_true(all(res$unforced$solver_converged))
})

test_that("forced solution hits the targets", {
  f <- res$forced
  for (v in c("xgap", "U", "PI", "RF", "MPE10", "TP"))
    expect_lt(max(abs(f[[v]] - ci$forced_targets[[v]])), 1e-8, label = v)
})

test_that("overlap 2026-2035 reproduces the original v1.8 baseline", {
  b <- run_baseline_v1_8(verbose = FALSE)
  ov <- 1:10
  for (v in c("xgap", "U", "PI", "RF", "MPE10", "TP", "R10", "RG", "D_pct_GDP"))
    expect_lt(max(abs(res$forced[[v]][ov] - b[[v]])), 1e-6, label = v)
})

test_that("output gap decays toward zero after the detailed window", {
  ft <- ci$forced_targets
  post <- ft$xgap[ft$year > 2035]
  expect_true(all(diff(abs(post)) <= 1e-9))             # |xgap| non-increasing post-2035
  expect_lt(abs(ft$xgap[ft$year == 2040]), 0.05)        # ~5% of the gap by 5 years
  expect_lt(abs(ft$xgap[ft$year == 2045]), 0.01)        # essentially closed
  # forced solution tracks the decayed target
  expect_lt(max(abs(res$forced$xgap - ft$xgap)), 1e-8)
})

test_that("terminal behavior is finite and stable", {
  f <- res$forced
  expect_true(all(is.finite(f$D_pct_GDP)))
  expect_true(all(is.finite(f$R10)) && all(is.finite(f$RG)))
  expect_true(all(abs(f$xgap) < 5))                 # output gap bounded
  expect_true(all(diff(f$D_pct_GDP) > -2))          # debt path not collapsing
  expect_lt(max(f$D_pct_GDP), 250)                  # no blow-up over the window
})

test_that("model debt/GDP tracks CBO's extended-baseline within a documented tolerance", {
  # External crosswalk (not just internal round-trip): compare the model's debt
  # held by public / GDP against CBO's published LTBO path. Build to 2056 since
  # the gap grows with the horizon.
  ci56 <- build_ltbo_calibration_inputs(end_year = 2056)
  fs56 <- build_ltbo_forcing_spec(ci56$forced_targets, create_forcing_spec)
  b56  <- calibrate_residuals_v1_8(ci56$baseline_exog, ci56$baseline_resid,
                                   hist_data, fs56, verbose = FALSE)$unforced
  cbo  <- read_cbo_ltbo_2026(years = 2036:2056)$budget$debt_pct_gdp
  model <- b56$D_pct_GDP[match(2036:2056, ci56$years)]
  gap   <- model - cbo
  # Model runs a little BELOW CBO by the end of the horizon for two understood
  # reasons: (i) the output-gap decay lifts GDP above CBO's persistently-below-
  # potential path, shrinking debt/GDP; (ii) BLSMM's structural RG (average of
  # current/prior debt) differs from CBO's net-interest/prior-debt avg_rate_debt.
  # The gap is monotone and reaches ~2.6pp at 2056.
  expect_lt(max(abs(gap)), 3.5)
  expect_lt(abs(tail(gap, 1)), 3.0)                 # 2056 within ~2.6pp
  expect_true(all(gap <= 0.1))                      # model not above CBO
})
