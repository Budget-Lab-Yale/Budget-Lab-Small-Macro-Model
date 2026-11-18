library(testthat)

find_project_root <- function(start = getwd()) {
  path <- normalizePath(start, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(path, "calibration", "source_manifest.csv"))) return(path)
    parent <- dirname(path)
    if (identical(parent, path)) stop("Could not locate BLSMM project root")
    path <- parent
  }
}

project_root <- find_project_root()
old_wd <- setwd(project_root)
on.exit(setwd(old_wd), add = TRUE)

source("model/v1_8/simulation.R")
source("model/v1_8/neutral_rate.R")
source("model/v1_8/parameters.R")

test_that("committed LTBO extraction has the intended concepts and identities", {
  manifest <- read.csv("calibration/source_manifest.csv", stringsAsFactors = FALSE)
  budget_source <- manifest[manifest$source_id == "ltbo_budget", ]
  expect_match(budget_source$path, "51119-2026-02-11-LTBO-Budget\\.xlsx$")
  expect_equal(
    budget_source$sha256,
    "ef50f314198629c77c8bb926de6915f5a5e965ba7ce50a254cad012528370ca0"
  )

  economic <- read.csv("calibration/golden/ltbo_2026_economic.csv")
  budget <- read.csv("calibration/golden/ltbo_2026_budget.csv")
  inputs <- read.csv("calibration/golden/ltbo_2026_model_inputs_partial.csv")
  targets <- read.csv("calibration/golden/ltbo_2026_targets_partial.csv")

  expect_equal(economic$year, 2026:2056)
  expect_equal(targets$xgap,
               100 * (economic$real_gdp / economic$real_potential_gdp - 1),
               tolerance = 1e-12)
  compounded_potential_growth <- 100 * (
    (1 + economic$glfstar / 100) * (1 + economic$glqstar / 100) - 1
  )
  expect_equal(inputs$gstar, compounded_potential_growth, tolerance = 0.002)
  expect_equal(inputs$rbudp_star, inputs$rgfr_star - inputs$rgfop_star,
               tolerance = 1e-12)
  expect_lt(max(abs(budget$primary_balance_rounding_gap)), 0.002)

  prior_debt <- c(
    budget$net_interest_dollars[1] / (economic$published_debt_rate[1] / 100),
    head(budget$debt_dollars, -1)
  )
  expect_equal(
    budget$effective_rate_average_debt,
    100 * budget$net_interest_dollars / ((prior_debt + budget$debt_dollars) / 2),
    tolerance = 1e-12
  )
  expect_false(all(c("pistar", "rfstar", "tp_0", "rbar10") %in% names(inputs)))
})

test_that("neutral-rate display phase-in is capped after year ten", {
  params <- create_parameters_v1_8()
  baseline <- data.frame(rfstar = 1)
  exog <- data.frame(
    glfstar = 1, glfstar_base = 0,
    glqstar = 2, glqstar_base = 0
  )
  result <- compute_rfstar_v1_8(
    baseline, exog, year_index = 20,
    debt_proxy_user = 100, debt_proxy_base = 100,
    user_delta_rfstar_direct = 0, params = params
  )
  expect_equal(result$phase_in_share, 1)
  expect_equal(result$growth_contrib, result$GR_LR)
})

extend_baseline <- function(n_periods) {
  exog <- read.csv("data/blsmm_v1_8_forecast_exog.csv", check.names = FALSE)
  resid <- read.csv("data/blsmm_v1_8_forecast_resid.csv", check.names = FALSE)
  if (n_periods > nrow(exog)) {
    extra_n <- n_periods - nrow(exog)
    extra_exog <- exog[rep(nrow(exog), extra_n), , drop = FALSE]
    extra_exog$year <- (max(exog$year) + 1):(max(exog$year) + extra_n)
    exog <- rbind(exog, extra_exog)

    extra_resid <- resid[rep(nrow(resid), extra_n), , drop = FALSE]
    extra_resid$year <- extra_exog$year
    for (variable in setdiff(names(extra_resid), "year")) extra_resid[[variable]] <- 0
    resid <- rbind(resid, extra_resid)
  }
  list(exog = exog, resid = resid)
}

test_that("15-, 20-, and 31-year horizons converge without changing overlap years", {
  history <- read.csv("data/blsmm_v1_8_historical.csv", check.names = FALSE)
  baseline <- run_baseline_v1_8(verbose = FALSE)

  for (n_periods in c(15, 20, 31)) {
    extended <- extend_baseline(n_periods)
    result <- simulate_blsmm_v1_8(
      n_periods, extended$exog, extended$resid, history, verbose = FALSE
    )
    expect_true(all(result$solver_converged), info = paste("horizon", n_periods))
    expect_equal(result$xgap[1:10], baseline$xgap, tolerance = 1e-12)
    numeric_result <- result[vapply(result, is.numeric, logical(1))]
    expect_true(all(is.finite(as.matrix(numeric_result))))
  }
})
