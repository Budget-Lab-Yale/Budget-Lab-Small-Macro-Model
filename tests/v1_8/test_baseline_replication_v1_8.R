# ==============================================================================
# BLSMM v1.8 Baseline Replication Test
# ==============================================================================
# Tests that the v1.8 model produces consistent baseline results
# Compares against reference values stored in data/blsmm_v1_8_baseline_solution.csv
# ==============================================================================

library(testthat)

# Source simulation engine (use relative paths from project root)
# Get the project root directory (2 levels up from tests/v1_8/)
project_root <- normalizePath(file.path(dirname(sys.frame(1)$ofile), "..", ".."))
setwd(project_root)
source("model/v1_8/simulation.R")

test_that("v1.8 baseline replicates reference values within tolerance", {

  # ==========================================================================
  # RUN BASELINE SIMULATION
  # ==========================================================================
  cat("\n")
  cat("================================================================================\n")
  cat("  BLSMM v1.8 Baseline Replication Test\n")
  cat("================================================================================\n")
  cat("Target: Match reference baseline values within 1e-6\n")
  cat("Reference: data/blsmm_v1_8_baseline_solution.csv\n")
  cat("================================================================================\n\n")

  baseline <- run_baseline_v1_8(n_periods = 10, verbose = TRUE)

  # ==========================================================================
  # LOAD REFERENCE VALUES
  # ==========================================================================
  target <- read.csv("data/blsmm_v1_8_baseline_solution.csv", check.names = FALSE)

  # ==========================================================================
  # TEST SOLVER CONVERGENCE
  # ==========================================================================
  cat("\n--- Solver Convergence ---\n")
  cat(sprintf("Converged periods: %d/10\n", sum(baseline$solver_converged)))
  cat(sprintf("Max SSE: %.2e\n", max(baseline$solver_sse)))
  cat(sprintf("Final SSE: %.2e\n", baseline$solver_sse[10]))

  expect_true(all(baseline$solver_converged),
              label = "All periods should converge")

  expect_lt(max(baseline$solver_sse), 1e-6,
            label = "Max SSE should be < 1e-6")

  # ==========================================================================
  # TEST EACH VARIABLE FOR EACH YEAR
  # ==========================================================================
  cat("\n--- Variable Replication ---\n")

  # Variables to test (from PDF Appendix D columns)
  test_vars <- c("GDP", "xgap", "R10", "PIE", "PGDP", "GDP$star", "GDP$",
                 "BUDP", "U", "PI", "RF", "MPE10", "TP", "RG", "NI", "D", "BUD")

  max_errors <- numeric(length(test_vars))
  names(max_errors) <- test_vars

  for (var in test_vars) {
    if (!(var %in% names(baseline))) {
      warning(sprintf("Variable %s not found in baseline results", var))
      next
    }

    if (!(var %in% names(target))) {
      warning(sprintf("Variable %s not found in target data", var))
      next
    }

    # Calculate errors
    errors <- abs(baseline[[var]] - target[[var]])
    max_error <- max(errors)
    max_errors[var] <- max_error

    # Find period with max error
    max_period <- which.max(errors)
    max_year <- baseline$year[max_period]

    # Print summary
    cat(sprintf("%-10s: max error = %.2e (year %d, sim=%.4f, target=%.4f)\n",
                var, max_error, max_year,
                baseline[[var]][max_period], target[[var]][max_period]))

    # Test with tolerance
    expect_lt(max_error, 1e-6,
              label = sprintf("%s max error should be < 1e-6", var))

    # Warn if error is larger than expected
    if (max_error > 1e-9 && max_error < 1e-6) {
      warning(sprintf("%s has error %.2e (> 1e-9 but < 1e-6)", var, max_error))
    }
  }

  # ==========================================================================
  # OVERALL SUMMARY
  # ==========================================================================
  cat("\n--- Overall Summary ---\n")
  cat(sprintf("Variables tested: %d\n", length(test_vars)))
  cat(sprintf("Max error across all variables: %.2e\n", max(max_errors)))
  cat(sprintf("Variables with error < 1e-9: %d/%d\n",
              sum(max_errors < 1e-9), length(test_vars)))
  cat(sprintf("Variables with error < 1e-6: %d/%d\n",
              sum(max_errors < 1e-6), length(test_vars)))

  if (max(max_errors) < 1e-9) {
    cat("\n*** EXCELLENT: All variables match within 1e-9 (machine precision) ***\n")
  } else if (max(max_errors) < 1e-6) {
    cat("\n*** GOOD: All variables match within 1e-6 (acceptable tolerance) ***\n")
  } else {
    cat("\n*** WARNING: Some variables have errors > 1e-6 ***\n")
  }

  # ==========================================================================
  # DETAILED PERIOD-BY-PERIOD COMPARISON (for key variables)
  # ==========================================================================
  cat("\n--- Period-by-Period Comparison (Selected Variables) ---\n\n")

  key_vars <- c("xgap", "PI", "RF", "R10", "D")

  for (var in key_vars) {
    cat(sprintf("%s:\n", var))
    cat("Year    Simulated    Target       Error\n")
    cat("----    ---------    ------       -----\n")

    for (i in 1:10) {
      sim_val <- baseline[[var]][i]
      target_val <- target[[var]][i]
      error <- sim_val - target_val

      cat(sprintf("%d    %9.4f    %9.4f    %+.2e\n",
                  baseline$year[i], sim_val, target_val, error))
    }
    cat("\n")
  }

  cat("================================================================================\n")
  cat("  Test Complete\n")
  cat("================================================================================\n\n")
})

# ==============================================================================
# RUN ADDITIONAL DIAGNOSTIC TESTS
# ==============================================================================

test_that("v1.8 model components work correctly", {

  baseline <- run_baseline_v1_8(n_periods = 10, verbose = FALSE)

  # Test that debt evolves correctly
  expect_true(all(baseline$D > 0), "Debt should be positive")
  expect_true(all(diff(baseline$D) > 0), "Debt should increase (BUD is negative)")

  # Test that inflation is reasonable
  expect_true(all(baseline$PI > 0), "Inflation should be positive")
  expect_true(all(baseline$PI < 10), "Inflation should be < 10%")

  # Test that output gap is reasonable
  expect_true(all(abs(baseline$xgap) < 5), "Output gap should be reasonable")

  # Test that fiscal feedback accumulates
  # (LF_fb and PROD_fb should be 0 for baseline with no user deltas)
  expect_true(all(baseline$LF_fb == 0), "LF_fb should be 0 for baseline")
  expect_true(all(baseline$PROD_fb == 0), "PROD_fb should be 0 for baseline")

  # Test that rbar10 adjusts correctly
  expect_true(all(is.finite(baseline$rbar10)), "rbar10 should be finite")

  # Test that debt proxy is computed
  expect_true(all(is.finite(baseline$debt_proxy_user)), "debt_proxy_user should be finite")
  expect_true(all(is.finite(baseline$debt_proxy_base)), "debt_proxy_base should be finite")

  cat("\n*** All component tests passed ***\n")
})

# ==============================================================================
# PERFORMANCE TEST
# ==============================================================================

test_that("v1.8 simulation runs in reasonable time", {

  start_time <- Sys.time()
  baseline <- run_baseline_v1_8(n_periods = 10, verbose = FALSE)
  end_time <- Sys.time()

  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  cat(sprintf("\nSimulation time: %.2f seconds\n", elapsed))

  # Should complete in under 30 seconds (generous bound)
  expect_lt(elapsed, 30,
            label = "Simulation should complete in < 30 seconds")

  if (elapsed < 5) {
    cat("*** FAST: Simulation completed in < 5 seconds ***\n")
  } else if (elapsed < 15) {
    cat("*** GOOD: Simulation completed in < 15 seconds ***\n")
  } else {
    cat("*** SLOW: Simulation took > 15 seconds (consider optimization) ***\n")
  }
})
