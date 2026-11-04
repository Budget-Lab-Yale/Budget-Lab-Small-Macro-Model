library(testthat)

source("model/v1_8/simulation.R")

baseline_exog <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
hist_data <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)

test_that("history anchors at the year before the first baseline year", {
  full <- simulate_blsmm_v1_8(
    baseline_exog = baseline_exog, baseline_resid = baseline_resid,
    hist_data = hist_data, verbose = FALSE
  )

  # Move FY2026 into history and start the baseline in FY2027. UN is an
  # exogenous input rather than a solved column, so it comes from baseline_exog.
  row_2026 <- full[full$year == 2026, , drop = FALSE]
  row_2026$UN <- baseline_exog$UN[baseline_exog$year == 2026]
  history_2026 <- rbind(hist_data, row_2026[, names(hist_data)])

  later <- simulate_blsmm_v1_8(
    baseline_exog = baseline_exog[-1, ], baseline_resid = baseline_resid[-1, ],
    hist_data = history_2026, verbose = FALSE
  )
  expect_equal(later$year, 2027:2035)
  shared <- c("xgap", "U", "PI", "PIE", "RF", "MPE10", "TP", "R10", "RG",
              "GDP", "PGDP", "BUDP", "NI", "BUD", "D", "D_pct_GDP",
              "debt_proxy_user", "debt_proxy_base")
  for (column in shared) {
    expect_equal(later[[column]], full[[column]][-1], tolerance = 1e-9,
                 label = column)
  }
})

test_that("simulation stops when history lacks the year before the first baseline year", {
  expect_error(
    simulate_blsmm_v1_8(
      baseline_exog = baseline_exog, baseline_resid = baseline_resid,
      hist_data = hist_data[hist_data$year != 2025, ], verbose = FALSE
    ),
    "no row for 2025"
  )
  expect_error(
    simulate_blsmm_v1_8(
      baseline_exog = baseline_exog[-1, ], baseline_resid = baseline_resid[-1, ],
      hist_data = hist_data, verbose = FALSE
    ),
    "no row for 2026"
  )
  expect_error(
    simulate_blsmm_v1_8(
      baseline_exog = baseline_exog[-3, ], baseline_resid = baseline_resid[-3, ],
      hist_data = hist_data, verbose = FALSE
    ),
    "consecutive"
  )
})

test_that("a scenario that overrides baseline_exog must bring residuals and history", {
  source("scenarios/lib/run_scenario.R", local = TRUE)
  expect_error(
    run_scenario(list(id = "partial", baseline_exog = baseline_exog)),
    "not baseline_resid or hist_data"
  )
  expect_error(
    run_scenario(list(id = "partial", baseline_exog = baseline_exog,
                      baseline_resid = baseline_resid)),
    "not hist_data"
  )
})
