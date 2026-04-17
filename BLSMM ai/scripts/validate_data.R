# Data Integrity Validation Script

cat("\n=== DATA INTEGRITY CHECK ===\n\n")

# Load all results
files <- c(
  "baseline" = "BLSMM ai/results/ai_baseline.rds",
  "s1_productivity" = "BLSMM ai/results/ai_scenario_1_productivity.rds",
  "s2_prod_lf" = "BLSMM ai/results/ai_scenario_2_prod_lf.rds",
  "s3a_prod_lf_ui" = "BLSMM ai/results/ai_scenario_3a_prod_lf_ui.rds",
  "s3b_prod_lf_ssmc" = "BLSMM ai/results/ai_scenario_3b_prod_lf_ssmc.rds"
)

all_pass <- TRUE

for (name in names(files)) {
  cat(sprintf("Testing: %s\n", name))

  # Load RDS
  tryCatch({
    result <- readRDS(files[name])

    # Check structure
    cat(sprintf("  ✓ RDS loaded: %d rows, %d columns\n", nrow(result), ncol(result)))

    # Check for expected columns
    required_cols <- c("year", "D_pct_GDP", "BUD", "GDP$", "GDP", "U", "PI", "RF", "R10")
    missing_cols <- setdiff(required_cols, names(result))
    if (length(missing_cols) > 0) {
      cat(sprintf("  ✗ MISSING COLUMNS: %s\n", paste(missing_cols, collapse=", ")))
      all_pass <- FALSE
    } else {
      cat("  ✓ All required columns present\n")
    }

    # Check for NA values in key columns
    key_vars <- c("D_pct_GDP", "BUD", "GDP", "U", "PI", "RF", "R10")
    na_counts <- sapply(result[key_vars], function(x) sum(is.na(x)))
    if (any(na_counts > 0)) {
      cat(sprintf("  ✗ NA VALUES FOUND: %s\n", paste(names(na_counts[na_counts > 0]), collapse=", ")))
      all_pass <- FALSE
    } else {
      cat("  ✓ No NA values in key variables\n")
    }

    # Check for Inf values
    inf_counts <- sapply(result[key_vars], function(x) sum(is.infinite(x)))
    if (any(inf_counts > 0)) {
      cat(sprintf("  ✗ INF VALUES FOUND: %s\n", paste(names(inf_counts[inf_counts > 0]), collapse=", ")))
      all_pass <- FALSE
    } else {
      cat("  ✓ No infinite values\n")
    }

    # Check years are 2026-2035
    expected_years <- 2026:2035
    if (!all(result$year == expected_years)) {
      cat("  ✗ YEAR MISMATCH\n")
      all_pass <- FALSE
    } else {
      cat("  ✓ Years correct (2026-2035)\n")
    }

    # Check reasonable value ranges
    checks_passed <- TRUE
    if (any(result$D_pct_GDP < 0) || any(result$D_pct_GDP > 500)) {
      cat("  ✗ Debt/GDP out of reasonable range\n")
      checks_passed <- FALSE
      all_pass <- FALSE
    }
    if (any(result$U < 0) || any(result$U > 20)) {
      cat("  ✗ Unemployment out of reasonable range\n")
      checks_passed <- FALSE
      all_pass <- FALSE
    }
    if (any(result$PI < -5) || any(result$PI > 20)) {
      cat("  ✗ Inflation out of reasonable range\n")
      checks_passed <- FALSE
      all_pass <- FALSE
    }
    if (any(result$RF < 0) || any(result$RF > 20)) {
      cat("  ✗ Fed Funds out of reasonable range\n")
      checks_passed <- FALSE
      all_pass <- FALSE
    }
    if (checks_passed) {
      cat("  ✓ All values in reasonable ranges\n")
    }

    # Check CSV matches RDS
    csv_file <- sub(".rds$", ".csv", files[name])
    csv_data <- read.csv(csv_file, check.names = FALSE)
    if (nrow(csv_data) != nrow(result)) {
      cat(sprintf("  ✗ CSV/RDS ROW MISMATCH: CSV=%d, RDS=%d\n", nrow(csv_data), nrow(result)))
      all_pass <- FALSE
    } else {
      cat("  ✓ CSV matches RDS row count\n")
    }

  }, error = function(e) {
    cat(sprintf("  ✗ ERROR: %s\n", e$message))
    all_pass <<- FALSE
  })

  cat("\n")
}

cat("================================================================================\n")
if (all_pass) {
  cat("✓ ALL DATA INTEGRITY CHECKS PASSED\n")
} else {
  cat("✗ SOME DATA INTEGRITY CHECKS FAILED\n")
}
cat("================================================================================\n\n")
