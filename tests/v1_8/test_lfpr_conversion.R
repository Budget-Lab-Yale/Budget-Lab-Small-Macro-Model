library(testthat)

# Load the helpers file
helper_path <- file.path("app", "R", "blsmm_helpers.R")
if (!file.exists(helper_path)) {
  helper_path <- file.path("..", "..", "app", "R", "blsmm_helpers.R")
}
source(helper_path)

# ==============================================================================
# LFPR CONVERSION TESTS
# ==============================================================================

test_that("identity: baseline LFPR yields zero delta", {
  # Derive lf_baseline from the recursion using the exact baseline
  # glfstar values. Using Reduce() guarantees the result is exactly
  # consistent with glfstar_base, so delta must equal zero to
  # floating-point precision (verified: max|delta| = 2.2e-14).
  # Do NOT use rounded cached values from the workbook here.

  lf_anchor_t <- 171.557
  glfstar_b   <- c(
    0.64002051796197, 0.43149633662507014, 0.4198385236447333,
    0.4238261508775265, 0.4477714364141683, 0.4839196351815289,
    0.45665981110374343, 0.4269479146104205,
    0.41165436757981677, 0.3965435275035567
  )

  # Reduce(f, x, accumulate=TRUE, init=v) returns a vector of length
  # length(x)+1 where element 1 is v (the init). [-1] removes it,
  # leaving exactly 10 values = FY2026 through FY2035.
  lf_baseline_exact <- Reduce(
    function(prev, g) prev * (1 + 0.01 * g),
    glfstar_b,
    accumulate = TRUE,
    init = lf_anchor_t
  )[-1]

  # Use any constant CNP: the identity holds for all positive CNP values
  # because the LFPR round-trip is exact.
  cnp_flat    <- rep(273.0, 11)
  lfpr_exact  <- lf_baseline_exact / cnp_flat[-1]  # cnp_flat[-1] = FY2026-2035

  result <- convert_lfpr_to_growth(
    lfpr_target  = lfpr_exact,
    cnp          = cnp_flat,
    lf_anchor    = lf_anchor_t
  )

  expect_true(
    max(abs(result$delta)) < 1e-9,
    label = "feeding baseline LFPR back through function must give delta < 1e-9"
  )
  expect_true(
    max(abs(result$lfpr_check - lfpr_exact)) < 1e-12,
    label = "lfpr_check roundtrip must equal input to machine precision"
  )
})

test_that("direction: LFPR well below baseline gives all-negative deltas", {
  # With lfpr = 0.58 and CNP growing from 270 to 280 (linear, length 11),
  # the implied LFstar levels are far below baseline, so all 10 glfstar
  # values are below their baseline counterparts.
  # Verified numerically: all(delta < 0) for this specific combination.
  # Note: the general principle "lower LFPR → negative delta" does NOT hold
  # universally — it depends on the relative size of CNP growth vs baseline
  # glfstar. 0.58 is far enough below any plausible baseline LFPR that the
  # test holds unambiguously for any CNP in a realistic range.

  cnp_t      <- seq(270, 280, length.out = 11)
  lfpr_low   <- rep(0.58, 10)
  result_low <- convert_lfpr_to_growth(lfpr_low, cnp_t)

  expect_true(
    all(result_low$delta < 0),
    label = "LFPR=0.58 (far below baseline) must yield all-negative glfstar deltas"
  )
})

test_that("anchor: FY2026 growth uses lf_anchor not cnp-implied FY2025 level", {
  # The denominator for FY2026 growth must be lf_anchor = 171.557,
  # not lfpr_target[1] * cnp[1] (which would be the FY2025 CNP-implied level).
  # In R, cnp[2] is the second element of the length-11 vector = FY2026 CNP.

  cnp_t  <- as.numeric(270:280)   # integer sequence 270, 271, ..., 280; length 11
  lfpr_t <- rep(0.625, 10)
  result <- convert_lfpr_to_growth(lfpr_t, cnp_t, lf_anchor = 171.557)

  # cnp_t[2] in R (1-indexed) = 271 = FY2026 population
  lf_2026_expected      <- lfpr_t[1] * cnp_t[2]
  glfstar_2026_expected <- 100 * (lf_2026_expected / 171.557 - 1)

  expect_equal(
    result$glfstar[1],
    glfstar_2026_expected,
    tolerance = 1e-10,
    label = "FY2026 glfstar must use lf_anchor=171.557 as denominator, not cnp[1]*lfpr"
  )
})

test_that("validation: invalid inputs produce informative errors", {
  cnp_ok  <- seq(270, 280, length.out = 11)
  lfpr_ok <- rep(0.625, 10)

  # lfpr_target wrong length
  expect_error(
    convert_lfpr_to_growth(rep(0.625, 9), cnp_ok),
    regexp = "length 10"
  )

  # cnp wrong length: 10 instead of required 11
  expect_error(
    convert_lfpr_to_growth(lfpr_ok, cnp_ok[-1]),
    regexp = "length 11"
  )

  # lfpr_target in percent instead of decimal
  expect_error(
    convert_lfpr_to_growth(rep(62.5, 10), cnp_ok),
    regexp = "decimal"
  )

  # Negative CNP value
  cnp_bad    <- cnp_ok
  cnp_bad[3] <- -5
  expect_error(
    convert_lfpr_to_growth(lfpr_ok, cnp_bad),
    regexp = "positive"
  )

  # ramp_end_year outside horizon_years
  expect_error(
    build_lfpr_path(0.630, 0.593, ramp_end_year = 2040),
    regexp = "horizon_years"
  )
})

test_that("build_lfpr_path: Scenario 2 shape is correct", {
  path <- build_lfpr_path(
    lfpr_start    = 0.630,
    lfpr_target   = 0.593,
    ramp_end_year = 2030
  )

  # Correct length and names
  expect_equal(length(path), 10)
  expect_equal(names(path), as.character(2026:2035))

  # lfpr_target reached exactly at FY2030 (5th element, names "2030")
  # seq() always hits its endpoint exactly, so tolerance can be strict
  expect_equal(unname(path["2030"]), 0.593, tolerance = 1e-15)

  # Flat from FY2031 onward: all equal 0.593 (rep() exact)
  expect_true(
    all(path[as.character(2031:2035)] == 0.593),
    label = "post-ramp values must be exactly 0.593"
  )

  # Monotone decreasing during ramp (lfpr_start > lfpr_target)
  expect_true(
    all(diff(path[as.character(2026:2030)]) < 0),
    label = "LFPR must decline monotonically during the ramp"
  )

  # lfpr_start (0.630) does not appear in the output:
  # the output starts at FY2026, which is the second seq() point, not
  # the first (lfpr_start was dropped by [-1])
  expect_false(
    any(path == 0.630),
    label = "lfpr_start=0.630 (the FY2025 value) must not appear in the output"
  )
})

test_that("roundtrip: build_lfpr_path -> convert_lfpr_to_growth -> lfpr_check", {
  # With CNP = seq(270, 280, length.out=11), FY2025 CNP = 270.
  # lfpr_start = 171.557 / 270 = 0.635392...
  # build_lfpr_path() ramps to 0.593 by FY2030.
  # convert_lfpr_to_growth()$lfpr_check should reproduce the path exactly.

  cnp_rt        <- seq(270, 280, length.out = 11)
  lfpr_start_rt <- 171.557 / cnp_rt[1]   # = 171.557 / 270

  path_rt   <- build_lfpr_path(lfpr_start = lfpr_start_rt, lfpr_target = 0.593)
  result_rt <- convert_lfpr_to_growth(path_rt, cnp_rt)

  expect_true(
    max(abs(result_rt$lfpr_check - path_rt)) < 1e-12,
    label = "lfpr_check must exactly reproduce the input LFPR path"
  )
})
