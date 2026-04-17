# Solver Convergence and Mathematical Consistency Validation

cat("\n=== SOLVER CONVERGENCE CHECK ===\n\n")

files <- c(
  "baseline" = "BLSMM ai/results/ai_baseline.rds",
  "s1_productivity" = "BLSMM ai/results/ai_scenario_1_productivity.rds",
  "s2_prod_lf" = "BLSMM ai/results/ai_scenario_2_prod_lf.rds",
  "s3a_prod_lf_ui" = "BLSMM ai/results/ai_scenario_3a_prod_lf_ui.rds",
  "s3b_prod_lf_ssmc" = "BLSMM ai/results/ai_scenario_3b_prod_lf_ssmc.rds"
)

all_converged <- TRUE
all_consistent <- TRUE

for (name in names(files)) {
  result <- readRDS(files[name])

  cat(sprintf("Checking: %s\n", name))

  # Check solver convergence
  if ("solver_converged" %in% names(result)) {
    conv_count <- sum(result$solver_converged, na.rm = TRUE)
    total_periods <- nrow(result)

    if (conv_count == total_periods) {
      cat(sprintf("  ✓ Solver converged: %d/%d periods\n", conv_count, total_periods))
    } else {
      cat(sprintf("  ✗ CONVERGENCE ISSUES: %d/%d periods converged\n", conv_count, total_periods))
      all_converged <- FALSE

      # Show which periods failed
      failed_periods <- result$year[!result$solver_converged]
      if (length(failed_periods) > 0) {
        cat(sprintf("    Failed periods: %s\n", paste(failed_periods, collapse=", ")))
      }
    }

    # Check SSE
    if ("solver_sse" %in% names(result)) {
      max_sse <- max(result$solver_sse, na.rm = TRUE)
      if (max_sse < 1e-9) {
        cat(sprintf("  ✓ Max solver SSE: %.2e (excellent)\n", max_sse))
      } else if (max_sse < 1e-6) {
        cat(sprintf("  ⚠ Max solver SSE: %.2e (acceptable)\n", max_sse))
      } else {
        cat(sprintf("  ✗ Max solver SSE: %.2e (poor convergence)\n", max_sse))
        all_converged <- FALSE
      }
    }
  }

  # Check fiscal identities
  # BUD = BUDP - NI
  bud_error <- abs(result$BUD - (result$BUDP - result$NI))
  max_bud_error <- max(bud_error, na.rm = TRUE)
  if (max_bud_error < 0.01) {
    cat(sprintf("  ✓ Budget identity holds (max error: %.2e)\n", max_bud_error))
  } else {
    cat(sprintf("  ✗ BUDGET IDENTITY ERROR: %.2e\n", max_bud_error))
    all_consistent <- FALSE
  }

  # Check debt evolution
  # D(t) = D(t-1) - BUD(t)
  if (nrow(result) > 1) {
    debt_errors <- numeric(nrow(result) - 1)
    for (t in 2:nrow(result)) {
      expected_debt <- result$D[t-1] - result$BUD[t]
      debt_errors[t-1] <- abs(result$D[t] - expected_debt)
    }
    max_debt_error <- max(debt_errors, na.rm = TRUE)
    if (max_debt_error < 0.01) {
      cat(sprintf("  ✓ Debt evolution correct (max error: %.2e)\n", max_debt_error))
    } else {
      cat(sprintf("  ✗ DEBT EVOLUTION ERROR: %.2e\n", max_debt_error))
      all_consistent <- FALSE
    }
  }

  # Check R10 identity: R10 = MPE10 + TP
  if (all(c("R10", "MPE10", "TP") %in% names(result))) {
    r10_error <- abs(result$R10 - (result$MPE10 + result$TP))
    max_r10_error <- max(r10_error, na.rm = TRUE)
    if (max_r10_error < 0.01) {
      cat(sprintf("  ✓ R10 identity holds (max error: %.2e)\n", max_r10_error))
    } else {
      cat(sprintf("  ✗ R10 IDENTITY ERROR: %.2e\n", max_r10_error))
      all_consistent <- FALSE
    }
  }

  cat("\n")
}

cat("================================================================================\n")
if (all_converged && all_consistent) {
  cat("✓ ALL CONVERGENCE AND CONSISTENCY CHECKS PASSED\n")
} else {
  if (!all_converged) {
    cat("✗ SOME CONVERGENCE ISSUES DETECTED\n")
  }
  if (!all_consistent) {
    cat("✗ SOME MATHEMATICAL INCONSISTENCIES DETECTED\n")
  }
}
cat("================================================================================\n\n")
