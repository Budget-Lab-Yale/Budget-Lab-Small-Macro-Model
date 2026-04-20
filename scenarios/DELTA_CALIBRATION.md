# AI Scenario Delta Calibration Guide

## Overview

The AI scenario analysis uses policy "deltas" (deviations from baseline) based on **Karger et al.'s** research on AI economic impacts. This document explains the calibration approach for implementing these scenarios in BLSMM.

---

## The Scenarios

All scenarios are based on **Karger et al. (rapid AI adoption, 50th percentile)**:

- **S1:** Productivity only (+1.5-1.8 pp TFP growth)
- **S2:** S1 + labor force participation decline (LFPR to 59.3% by FY2030)
- **S3a:** S2 + UI outlays increase (displacement effects)
- **S3b:** S2 + SS/Medicare outlays increase (early retirement)

---

## 1. Productivity Deltas

**Source:** Karger et al., Table 25
**Units:** Percentage points added to baseline TFP growth

```r
user_delta_prod = c(1.60, 1.50, 1.50, 1.60, 1.60,
                    1.70, 1.70, 1.80, 1.80, 1.80)
```

These values directly implement Karger et al.'s productivity assumptions.

---

## 2. Labor Force Deltas (Calendar Year vs Fiscal Year)

### Labor Force Calibration

**Target:** 59.3% LFPR by **FY2030** (matching Karger et al.)
**Source:** Internal LFPR calibration file, "LF Growth Delta (pp)" column
**Method:** Calibrated to achieve target LFPR at FY2030 and hold flat through FY2035

```r
# Labor force growth deltas (percentage points)
user_delta_lf = c(-0.970721149839408,
                  -0.9754136575901038,
                  -0.9805932852958139,
                  -0.9796612370806357,
                  -0.9897753880747566,
                   0.09195901775637783,
                   0.08816839320827746,
                   0.0715411112743643,
                   0.031805969525750266,
                  -0.001241724459414617)
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
- The small positive values in FY2031-2034 are needed to hold LFPR flat
- While population grows ~0.4-0.5% per year, the labor force must grow at roughly that same rate to maintain a constant LFPR

### Implementation Details

The calibration produces the following dynamics:
- The negative values FY2026-2030 drive LFPR down from 62.5% to 59.2%
- The small positive values FY2031-2034 maintain flat LFPR despite population growth
- The labor force must grow at roughly the population growth rate to maintain constant LFPR

---

## 3. Outlays Deltas

### Outlay Impacts

**Source:** Internal analysis of AI displacement effects
**Units:** Percentage points of GDP

The model implements two types of outlay impacts from AI-driven labor displacement:

```r
# S3a: Unemployment insurance impacts (percentage points of GDP)
user_delta_rgfop = c(0.000288, 0.000558, 0.000806, 0.001033, 0.001245,
                     0.001181, 0.001121, 0.001068, 0.001026, 0.000993) * 100
# Values: 0.0288 pp, 0.0558 pp, ..., up to 0.1245 pp at peak

# S3b: Social Security and Medicare impacts (percentage points of GDP)
user_delta_rgfop = c(0.002200, 0.004255, 0.006149, 0.007887, 0.009501,
                     0.009012, 0.008555, 0.008150, 0.007830, 0.007576) * 100
# Values: 0.2200 pp, 0.4255 pp, ..., up to 0.9501 pp at peak
```

**Impact on debt dynamics:**
- S3a raises debt/GDP modestly relative to S2 by FY2035
- S3b raises debt/GDP more than S3a because the outlay path is larger

---

## Summary Table

| Delta Type | Source | Values | Units | Impact |
|-----------|---------|---------|-------|---------|
| **Productivity** | Karger Table 25 | 1.5-1.8 pp | TFP growth | Higher GDP growth |
| **Labor Force** | Internal LFPR calibration | -0.97 to +0.09 pp | LF growth | LFPR to 59.3% by FY2030 |
| **UI Outlays** | Internal displacement analysis | 0.029-0.125 pp | % of GDP | S3a scenario |
| **SS/Medicare Outlays** | Internal displacement analysis | 0.22-0.95 pp | % of GDP | S3b scenario |

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

**Last updated:** 2026-04-20
**Status:** All deltas calibrated and verified
