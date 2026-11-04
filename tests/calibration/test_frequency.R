# Tests for the CY->FY conversion and Gate C convention application.

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

source(file.path(find_project_root(), "calibration", "R", "frequency.R"))

test_that("cy_to_fy applies the 3/4-1/4 rule", {
  # FY(t) = 0.75*CY(t) + 0.25*CY(t-1)
  expect_equal(cy_to_fy(c(4.0, 4.8)), 0.75 * 4.8 + 0.25 * 4.0)        # 4.6
  expect_equal(cy_to_fy(c(1, 2, 3)), c(1.75, 2.75))
})

test_that("a constant calendar series is unchanged in fiscal years", {
  expect_equal(cy_to_fy(rep(5.123, 6)), rep(5.123, 5))
})

test_that("a linear calendar series shifts back by one quarter", {
  # For CY(t) = a + b*t, FY(t) = a + b*t - 0.25*b
  cy <- 10 + 2 * (0:5)
  expect_equal(cy_to_fy(cy), (10 + 2 * (1:5)) - 0.25 * 2)
})

test_that("cy_to_fy rejects bad input", {
  expect_error(cy_to_fy(5), "prior and a current")
  expect_error(cy_to_fy(c(1, NA, 3)), "NA")
  expect_error(cy_to_fy(c("a", "b")), "numeric")
})

test_that("build_gate_c_targets applies recorded conventions", {
  # Three calendar years -> two fiscal-year outputs; leading year is the lag.
  cy <- data.frame(
    year = 2035:2037,
    U    = c(4.0, 4.2, 4.4),
    R10  = c(4.0, 4.4, 4.8),
    PI   = c(2.0, 2.0, 2.0),
    real_gdp           = c(100, 102, 104),
    real_potential_gdp = c(100, 101, 102)
  )
  out <- build_gate_c_targets(cy, tp_0 = 1.0, pistar = 2.0)

  expect_equal(out$year, c(2036L, 2037L))
  # R10 converted, then MPE10 = R10 - tp_0 and TP = tp_0
  expect_equal(out$R10, cy_to_fy(cy$R10))
  expect_equal(out$TP, c(1.0, 1.0))
  expect_equal(out$MPE10, out$R10 - 1.0)
  expect_equal(out$MPE10 + out$TP, out$R10)            # identity holds
  expect_equal(out$pistar, c(2.0, 2.0))
  # xgap from FY-converted GDP levels
  rgdp_fy <- cy_to_fy(cy$real_gdp); pot_fy <- cy_to_fy(cy$real_potential_gdp)
  expect_equal(out$xgap, 100 * (rgdp_fy / pot_fy - 1))
})

test_that("build_gate_c_targets accepts a term-premium path and validates length", {
  cy <- data.frame(year = 2035:2037, U = c(4,4,4), R10 = c(4,4,4), PI = c(2,2,2),
                   real_gdp = c(100,101,102), real_potential_gdp = c(100,101,102))
  out <- build_gate_c_targets(cy, tp_0 = c(0.9, 1.0))
  expect_equal(out$TP, c(0.9, 1.0))
  expect_error(build_gate_c_targets(cy, tp_0 = c(0.9, 1.0, 1.1)), "tp_0 length")
})
