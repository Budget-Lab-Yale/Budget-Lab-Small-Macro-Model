# AI Scenario Delta Calibration Guide

## Overview

The AI scenario analysis uses policy "deltas" (deviations from baseline) based on **Karger et al.'s** research on AI economic impacts. This document explains the calibration approach for implementing these scenarios in BLSMM.

---

## The Scenarios

All scenarios use the same **Karger et al. moderate AI adoption productivity path** and then layer on additional labor-market and fiscal channels:

- **S1:** Productivity only, calibrated from Karger labor productivity to BLSMM potential productivity
- **S2:** S1 + labor force participation decline (LFPR to 59.3% by FY2030)
- **S3a:** S2 + UI outlays increase (displacement effects)
- **S3b:** S2 + SS/Medicare outlays increase (early retirement)

S1-S3b are cumulative channel scenarios layered on the moderate adoption productivity path. Two severity variants — `ai_slow.R` and `ai_rapid.R` — sit alongside them and use the same labor force deltas as S2 but with Karger Slow and Rapid productivity targets respectively (see "Severity Variants" below).

---

## 1. Productivity Deltas

**Source:** Karger et al. labor productivity estimates for the moderate adoption scenario
**Survey concept:** Nonfarm business output per hour
**BLSMM concept:** Potential productivity growth, GDP per employed civilian worker (`glqstar`)
**Units:** Percentage points added to baseline BLSMM potential productivity growth

Karger's labor productivity measure is closer to nonfarm business output per hour than to BLSMM's GDP-per-employed-worker productivity concept. The R implementation therefore applies the same concept crosswalk used in the SPF calibration:

```text
CBO GDP/employed growth, 2031-2035 avg     1.330%
CBO NFB output/hour growth, 2031-2035 avg  1.649%
Concept wedge                              -0.319 pp
```

The AI scenarios target a flat BLSMM productivity level of about `2.18%` per year:

```text
Karger moderate NFB output/hour growth  2.500%
Less NFB-to-GDP/employed wedge         -0.319 pp
Target BLSMM glqstar level              2.181%
```

The `user_delta_prod` vector is this target level less CBO baseline `glqstar` in each year:

```r
user_delta_prod = c(0.581, 0.461, 0.491, 0.561, 0.611,
                    0.681, 0.721, 0.751, 0.771, 0.791)
```

This vector appears in each AI scenario file as the productivity component of the stacked calibration.

---

## 2. Labor Force Deltas (Calendar Year vs Fiscal Year)

### Labor Force Calibration

**Target:** 59.3% LFPR by **FY2030** (matching Karger et al.)
**Source:** Internal LFPR calibration file, "LF Growth Delta (pp)" column
**Method:** Calibrated to achieve target LFPR at FY2030 and hold flat through FY2035, using a CY-to-FY conversion for the scenario files

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

**LFPR path:**
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

**Calibration notes:**
- LFPR hits ~59.3% at FY2030, correctly matching Karger's specification
- These are all negative deltas, but they become less negative after FY2030 as the path transitions from decline to a flat LFPR target

### Implementation Details

The calibration produces the following dynamics:
- The negative values FY2026-2030 drive LFPR down from 62.5% to 59.2%
- The smaller negative values FY2031-FY2035 maintain a flat LFPR path near 59.2%
- This path is the FY-converted implementation used in `ai_s2_prod_lf.R`, `ai_s3a_prod_lf_ui.R`, and `ai_s3b_prod_lf_ssmc.R`

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

## Severity Variants (Slow / Rapid)

`ai_slow.R` and `ai_rapid.R` mirror `ai_s2_prod_lf.R` (productivity + LF deltas) but swap in Karger's Slow and Rapid adoption productivity targets. The same -0.319 pp NFB-to-GDP/employed wedge is applied.

| Variant | Karger NFB target | BLSMM `glqstar` target | `user_delta_prod` range |
|---------|-------------------|------------------------|-------------------------|
| Slow    | 2.0% (flat 2030 & 2050 anchors) | 1.681% | -0.041 to 0.292 pp |
| Moderate (S2) | 2.5% (2025-30 median) | 2.181% | 0.461 to 0.791 pp |
| Rapid   | 3.5% (2030 anchor, held flat) | 3.181% | 1.459 to 1.792 pp |

Notes:
- The Slow target is below CBO baseline `glqstar` in 2027 and 2028 (which peak at 1.72% and 1.69%); deltas are slightly negative there. From 2029 on the gap widens in Slow's favor as CBO's baseline drifts down.
- LF deltas in both variants are inherited from `ai_s2_prod_lf.R`. Karger's Slow LFPR target (~62%) and Rapid LFPR target (~59.8%) differ from the moderate calibration; refresh via `convert_lfpr_to_growth()` if scenario-consistent LF paths are needed.

---

## Summary Table

| Delta Type | Source | Values | Units | Impact |
|-----------|---------|---------|-------|---------|
| **Productivity** | Karger moderate labor productivity, adjusted by -0.319 pp concept wedge | 0.461-0.791 pp | `glqstar` growth | Higher GDP growth |
| **Labor Force** | Internal LFPR calibration | -0.519 to -0.372 pp | LF growth | LFPR to 59.3% by FY2030 |
| **UI Outlays** | Internal displacement analysis | 0.015-0.097 pp | % of GDP | S3a scenario |
| **SS/Medicare Outlays** | Internal displacement analysis | 0.116-0.739 pp | % of GDP | S3b scenario |

---

## How to Update Scenarios

If Karger et al. publishes revised estimates, follow this process:

### 1. Productivity Deltas
```r
# Convert survey output/hour targets to BLSMM GDP/employed targets,
# then subtract CBO baseline glqstar.
nfb_to_lq_wedge <- -0.319
target_lq_level <- survey_nfb_productivity_level + nfb_to_lq_wedge
user_delta_prod <- target_lq_level - cbo_glqstar
```

Do not directly copy survey labor productivity values into `user_delta_prod`. The survey values are levels in an output/hour concept; BLSMM expects percentage-point deltas to GDP/employed productivity growth.

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

# The AI scenario files store rgfop deltas
# in percentage points of GDP, so no additional conversion is applied.
```

---

## Verification

After changing the scenario input files, rebuild results and rerun diagnostics:

```r
source("scenarios/make_all_figures.R")
# Check output: LFPR should be near 59.3% in FY2030
# Check debt/GDP ranking: S1 < S2 < S3a < S3b < Baseline
```

---

## References

- **Karger et al.:** AI moderate adoption labor productivity scenario
- **SPF calibration:** NFB output/hour to GDP/employed productivity crosswalk
- **Internal calibration files:** LFPR and outlay delta calculations
- **BLSMM helpers:** `convert_lfpr_to_growth()` and `build_lfpr_path()` functions

---

**Last updated:** 2026-05-15
**Status:** Calibration documented; rebuild scenario outputs after changing input files
