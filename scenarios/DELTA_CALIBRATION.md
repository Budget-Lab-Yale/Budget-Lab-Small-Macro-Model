# AI Scenario Delta Calibration Guide

## Overview

The AI scenario analysis uses policy "deltas" (deviations from baseline) based on **Karger et al.'s** research on AI economic impacts. This document explains the calibration approach for implementing these scenarios in BLSMM.

---

## The Scenarios

All scenarios are based on **Karger et al. (rapid AI adoption, 50th percentile)**:

- **S1:** Productivity only (+0.78-1.11 pp TFP growth)
- **S2:** S1 + labor force participation decline (LFPR to 59.3% by FY2030)
- **S3a:** S2 + UI outlays increase (displacement effects)
- **S3b:** S2 + SS/Medicare outlays increase (early retirement)

---

## 1. Productivity Deltas

**Source:** Karger et al., Table 25
**Units:** Percentage points added to baseline TFP growth

```r
user_delta_prod = c(0.90, 0.78, 0.81, 0.88, 0.93,
                    1.00, 1.04, 1.07, 1.09, 1.11)
```

These values directly implement Karger et al.'s productivity assumptions.

---

## 2. Labor Force Deltas (Calendar Year vs Fiscal Year)

### Labor Force Calibration

**Target:** 59.3% LFPR by **FY2030** (matching Karger et al.)
**Source:** Corrected internal LFPR calibration file, "LF Growth Delta (pp)" column
**Method:** Calibrated to achieve target LFPR at FY2030 and hold flat through FY2035, using the corrected CY to FY conversion now reflected in the scenario files

```r
# Labor force growth deltas (percentage points)
user_delta_lf = c(-0.519291223,
                  -0.517304306,
                  -0.514715591,
                  -0.505703745,
                  -0.507477379,
                  -0.427200888,
                  -0.391830856,
                  -0.372017336,
                  -0.377888501,
                  -0.379559281)
```

**Verified LFPR path:**
- FY2026: 61.81%
- FY2027: 61.15%
- FY2028: 60.49%
- FY2029: 59.83%
- FY2030: **59.17%** (~59.3% target achieved)
- FY2031: 59.17%
- FY2032: 59.17%
- FY2033: 59.17%
- FY2034: 59.17%
- FY2035: **59.17%** (held flat)

**Key insights:**
- LFPR hits ~59.3% at FY2030, correctly matching Karger's specification
- These are all negative deltas, but they become less negative after FY2030 as the path transitions from decline to a flat LFPR target
- The corrected calibration reaches the target on time; it replaces an earlier version that hit the target too late in the forecast window

### Implementation Details

The calibration produces the following dynamics:
- The negative values FY2026-2030 drive LFPR down from 62.5% to 59.2%
- The smaller negative values FY2031-FY2035 maintain a flat LFPR path near 59.2%
- This path is the shipped FY-converted implementation used in `ai_s2_prod_lf.R`, `ai_s3a_prod_lf_ui.R`, and `ai_s3b_prod_lf_ssmc.R`

---

## 3. Outlays Deltas

### Outlay Impacts

**Source:** Internal analysis of AI displacement effects
**Units:** Percentage points of GDP (already converted in the scenario files)

The model implements two types of outlay impacts from AI-driven labor displacement:

```r
# S3a: Unemployment insurance impacts (percentage points of GDP)
user_delta_rgfop = c(0.015184772, 0.029548841, 0.042705794, 0.054612224, 0.065642422,
                     0.073886962, 0.080655349, 0.086440070, 0.091878642, 0.096886197)
# Values: 0.0152 pp, 0.0295 pp, ..., up to 0.0969 pp by FY2035

# S3b: Social Security and Medicare impacts (percentage points of GDP)
user_delta_rgfop = c(0.115879477, 0.225495918, 0.325900512, 0.416761993, 0.500936683,
                     0.563853204, 0.615504756, 0.659649669, 0.701153020, 0.739367151)
# Values: 0.1159 pp, 0.2255 pp, ..., up to 0.7394 pp by FY2035
```

**Impact on debt dynamics:**
- S3a raises debt/GDP modestly relative to S2 by FY2035
- S3b raises debt/GDP more than S3a because the outlay path is larger

---

## Summary Table

| Delta Type | Source | Values | Units | Impact |
|-----------|---------|---------|-------|---------|
| **Productivity** | Karger Table 25 | 0.78-1.11 pp | TFP growth | Higher GDP growth |
| **Labor Force** | Corrected LFPR calibration | -0.519 to -0.372 pp | LF growth | LFPR to 59.3% by FY2030 |
| **UI Outlays** | Internal displacement analysis | 0.015-0.097 pp | % of GDP | S3a scenario |
| **SS/Medicare Outlays** | Internal displacement analysis | 0.116-0.739 pp | % of GDP | S3b scenario |

---

## How to Update Scenarios

If Karger et al. publishes revised estimates, follow this process:

### 1. Productivity Deltas
```r
# Direct copy from paper (no conversion needed)
user_delta_prod = c(value_2026, value_2027, ..., value_2035)
```

### 2. Labor Force Deltas
```r
# Use the function to ensure precise calibration
lfpr_target <- build_lfpr_path(
  start_lfpr = 0.625,           # Current LFPR
  target_lfpr = NEW_TARGET,     # From paper
  target_year = YEAR_INDEX,     # When to hit target
  hold_flat = TRUE
)

result <- convert_lfpr_to_growth(
  lfpr_target = lfpr_target,
  cnp = cnp_cbo,
  lf_anchor = 171.557,
  glfstar_base = c(...)  # From BLSMM baseline
)

user_delta_lf <- result$delta
```

### 3. Outlays Deltas
```r
# If values from paper are in decimal form:
user_delta_rgfop = c(paper_values) * 100

# If values from paper are already percentage points:
user_delta_rgfop = c(paper_values)  # No conversion needed

# The current shipped AI scenario files already store rgfop deltas
# in percentage points of GDP, so no additional conversion is applied.
```

---

## Verification

All current scenarios pass diagnostics:

```r
source("scenarios/make_all_figures.R")
# Check output: LFPR should be near 59.3% in FY2030
# Check debt/GDP ranking: S1 < S2 < S3a < S3b < Baseline
```

---

## References

- **Karger et al.:** AI rapid adoption scenario (50th percentile), Table 25
- **Internal calibration files:** LFPR and outlay delta calculations
- **BLSMM helpers:** `convert_lfpr_to_growth()` and `build_lfpr_path()` functions

---

**Last updated:** 2026-05-02
**Status:** All deltas calibrated and verified
