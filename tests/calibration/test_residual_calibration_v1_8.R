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

project_root <- find_project_root()
old_wd <- setwd(project_root)
on.exit(setwd(old_wd), add = TRUE)

source("model/v1_8/calibration.R")
source("model/v1_8/parameters.R")

baseline_exog <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
baseline_resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
hist_data <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)

gold_value <- function(golden, section, variable) {
  golden$value[golden$section == section & golden$variable == variable]
}

test_that("original v1.8 workbook solution and structures remain the baseline golden", {
  golden <- read.csv("calibration/golden/original_v1_8_model.csv")
  result <- run_baseline_v1_8(verbose = FALSE, diagnostics = TRUE)

  solution_map <- c(
    xgap = "xgap", U = "U", PI = "PI", PIE = "PIE", RF = "RF",
    MPE10 = "MPE10", TP = "TP", R10 = "R10", RG = "RG"
  )
  structural_map <- c(
    xgap = "xgap_struct", U = "U_struct", PI = "PI_struct",
    PIE = "PIE_struct", RF = "RF_struct", MPE10 = "MPE10_struct",
    TP = "TP_struct", RG = "RG_struct"
  )

  for (variable in names(solution_map)) {
    expect_equal(result[[solution_map[[variable]]]],
                 gold_value(golden, "solution", variable), tolerance = 2e-8)
  }
  for (variable in names(structural_map)) {
    expect_equal(result[[structural_map[[variable]]]],
                 gold_value(golden, "structural_value", variable), tolerance = 2e-8)
  }
  residual_map <- c(
    epsxgap = "epsxgap", epsu = "epsu", epspi = "epspi", epspie = "epspie",
    epsrf = "epsrf", epsmpe = "epsmpe", epstp = "epstp", epsrg = "epsrg"
  )
  for (variable in names(residual_map)) {
    expect_equal(result[[residual_map[[variable]]]],
                 gold_value(golden, "baseline_residual", variable), tolerance = 1e-12)
  }
  expect_equal(result$epsxgap_final, result$epsxgap, tolerance = 1e-12)
})

test_that("reconstructed original force mask regenerates baseline residuals", {
  golden <- read.csv("calibration/golden/original_v1_8_model.csv")
  forcing <- create_forcing_spec(10)
  forcing_map <- c(
    xgap = "xgap", U = "u", PI = "pi", PIE = "pie",
    RF = "rf", MPE10 = "mpe", TP = "tp", RG = "rg"
  )

  # The saved workbook has all force flags reset to zero. Its historical
  # calibration mask is reconstructed from the populated target rows: XGAP, U,
  # PI, RF, MPE10, and RG are populated; PIE and TP are blank and remain
  # structural. This inferred mask exactly regenerates rows 81-88.
  for (variable in names(forcing_map)) {
    suffix <- forcing_map[[variable]]
    target <- gold_value(golden, "forced_value", variable)
    forcing[[paste0("force_", suffix)]] <- as.integer(!is.na(target))
    forcing[[paste0("forced_", suffix)]] <- target
  }

  calibration <- calibrate_residuals_v1_8(
    baseline_exog, baseline_resid, hist_data, forcing, verbose = FALSE
  )
  residual_map <- c(
    epsxgap = "epsxgap_final", epsu = "epsu_final", epspi = "epspi_final",
    epspie = "epspie_final", epsrf = "epsrf_final", epsmpe = "epsmpe_final",
    epstp = "epstp_final", epsrg = "epsrg_final"
  )
  for (variable in names(residual_map)) {
    expect_equal(calibration$forced[[residual_map[[variable]]]],
                 gold_value(golden, "baseline_residual", variable), tolerance = 1e-8)
  }
  expect_lt(calibration$max_abs_roundtrip_error, 3e-8)
})

test_that("SPF forced calibration matches Excel implied residuals and round trips", {
  golden <- read.csv("calibration/golden/spf_model.csv")
  user_golden <- read.csv("calibration/golden/spf_user_deltas.csv")

  user_deltas <- create_user_deltas(10)
  for (variable in unique(user_golden$variable)) {
    user_deltas[[variable]] <- user_golden$value[user_golden$variable == variable]
  }

  forcing <- create_forcing_spec(10)
  forcing_map <- c(
    xgap = "xgap", U = "u", PI = "pi", PIE = "pie",
    RF = "rf", MPE10 = "mpe", TP = "tp", RG = "rg"
  )
  for (variable in names(forcing_map)) {
    suffix <- forcing_map[[variable]]
    forcing[[paste0("force_", suffix)]] <- gold_value(golden, "force_flag", variable)
    forcing[[paste0("forced_", suffix)]] <- gold_value(golden, "forced_value", variable)
  }

  # The saved SPF scenario embeds a revised 2025 output-gap anchor. All other
  # historical anchors match the original v1.8 baseline.
  spf_history <- hist_data
  spf_history$xgap[spf_history$year == 2025] <-
    gold_value(golden, "historical_solution", "xgap")

  calibration <- calibrate_residuals_v1_8(
    baseline_exog, baseline_resid, spf_history, forcing,
    user_deltas = user_deltas, verbose = FALSE
  )

  solution_map <- c(
    xgap = "xgap", U = "U", PI = "PI", PIE = "PIE", RF = "RF",
    MPE10 = "MPE10", TP = "TP", R10 = "R10", RG = "RG"
  )
  for (variable in names(solution_map)) {
    expect_equal(calibration$forced[[solution_map[[variable]]]],
                 gold_value(golden, "solution", variable), tolerance = 2e-6)
  }

  residual_map <- c(
    epsxgap = "epsxgap_final", epsu = "epsu_final", epspi = "epspi_final",
    epspie = "epspie_final", epsrf = "epsrf_final", epsmpe = "epsmpe_final",
    epstp = "epstp_final", epsrg = "epsrg_final"
  )
  # Excel uses immediate growth pass-through, R the capped calendar ramp, so
  # Excel's rfstar and rbar10 are higher by the immediate-minus-ramp
  # contribution. With xgap, RF, and MPE10 forced, the difference shows up in
  # three implied residuals: RF lower by the contribution, MPE10 lower by
  # (1 - phi_1) times it, and xgap through the real-rate distributed lags of
  # the output-gap equation, -sum(sigma_k * contribution[t - k]). The other
  # residuals are unchanged.
  params <- create_parameters_v1_8()
  immediate <- params$kappa_1 * user_deltas$user_delta_lf +
    params$kappa_2 * user_deltas$user_delta_prod
  kappa_difference <- immediate * (1 - pmin(seq_len(10) / 10, 1))
  sigma <- unlist(params[paste0("sigma_", 0:7)], use.names = FALSE)
  xgap_lag_effect <- vapply(seq_len(10), function(t) {
    lags <- t - 0:7
    valid <- lags > 0
    -sum(sigma[valid] * kappa_difference[lags[valid]])
  }, numeric(1))
  expected_excel_minus_r <- list(
    epsxgap = xgap_lag_effect,
    epsrf = -kappa_difference,
    epsmpe = -(1 - params$phi_1) * kappa_difference
  )
  for (variable in names(residual_map)) {
    if (variable %in% names(expected_excel_minus_r)) {
      expect_equal(
        gold_value(golden, "implied_residual", variable) -
          calibration$forced[[residual_map[[variable]]]],
        expected_excel_minus_r[[variable]], tolerance = 1e-5
      )
    } else {
      expect_equal(calibration$forced[[residual_map[[variable]]]],
                   gold_value(golden, "implied_residual", variable), tolerance = 1e-5)
    }
  }

  expect_lt(calibration$max_abs_roundtrip_error, 2e-8)
  expect_true(all(calibration$forced$solver_converged))
  expect_true(all(calibration$unforced$solver_converged))
})

test_that("calibrated baseline residuals do not double count user shocks", {
  baseline <- run_baseline_v1_8(verbose = FALSE)
  forcing <- create_forcing_spec(10)
  forcing$force_xgap[] <- 1
  forcing$forced_xgap <- baseline$xgap + 0.2
  deltas <- create_user_deltas(10)
  deltas$user_delta_ADshock <- seq(0.01, 0.10, by = 0.01)

  calibration <- calibrate_residuals_v1_8(
    baseline_exog, baseline_resid, hist_data, forcing,
    user_deltas = deltas, verbose = FALSE
  )

  expect_equal(
    calibration$calibrated_resid$epsxgap + deltas$user_delta_ADshock,
    calibration$forced$epsxgap_final,
    tolerance = 1e-12
  )
  expect_lt(calibration$max_abs_roundtrip_error, 2e-8)
})

test_that("forcing validation rejects missing targets and wrong horizons", {
  missing_target <- create_forcing_spec(10)
  missing_target$force_pi[1] <- 1
  expect_false(validate_forcing_spec(missing_target, 10)$is_valid)

  wrong_horizon <- create_forcing_spec(9)
  expect_false(validate_forcing_spec(wrong_horizon, 10)$is_valid)
  expect_error(
    simulate_blsmm_v1_8(
      10, baseline_exog, baseline_resid, hist_data,
      forcing_spec = wrong_horizon, verbose = FALSE
    ),
    "length 10"
  )
})

test_that("default output keeps the published columns the app cache uses", {
  cached <- readRDS("data/baseline_v1_8_cached.rds")$data
  result <- run_baseline_v1_8(verbose = FALSE)
  expect_identical(names(result), names(cached))
  with_diagnostics <- run_baseline_v1_8(verbose = FALSE, diagnostics = TRUE)
  expect_true(all(c("growth_contrib", "xgap_struct", "epsxgap_final") %in%
                    names(with_diagnostics)))
})
