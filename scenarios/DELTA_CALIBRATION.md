# AI Scenario Delta Calibration Guide

## Overview

The AI scenario analysis uses policy "deltas" (deviations from baseline) based on **Karger et al.'s** research on AI economic impacts. This document explains the calibration approach for implementing these scenarios in BLSMM.

---

## The Scenarios

All scenarios use the same **Karger et al. moderate AI adoption productivity path** and then layer on additional labor-market and fiscal channels:

- **S1:** Productivity only, calibrated from Karger labor productivity to BLSMM potential productivity
- **S2:** S1 + labor force participation decline (LFPR about 60.6% in FY2030, 59.2% by FY2035)
- **S3a:** S2 + UI outlays increase (displacement effects)
- **S3b:** S2 + SS/Medicare outlays increase (early retirement)

S1-S3b are cumulative channel scenarios layered on the moderate adoption productivity path. The AI post's appendix repeats all four for the Slow and Rapid adoption variants (`ai_slow_*.R`, `ai_rapid_*.R`; see "Severity Variants" below).

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

The wedge is taken directly from CBO's February 2026 *Budget and Economic Outlook* as the gap between its two published productivity projections (GDP per employed worker vs nonfarm-business output per hour), averaged over fiscal years 2031-2035. The same convention is used in the SPF calibration.

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

## 2. Labor Force Deltas

**Target:** Karger et al. (2026) Moderate Economists median LFPR, 60.7% in 2030 and 57.0% in 2050 (Table 25 and Table 26)
**Method:** Karger's January-dated targets converted from calendar to fiscal years. LFPR continues to decline after FY2030, consistent with interpolation toward the 2050 median

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

**Implied LFPR path** (FY2025 labor force 171.557 million, CBO civilian noninstitutional population):

| FY | 2026 | 2027 | 2028 | 2029 | 2030 | 2031 | 2032 | 2033 | 2034 | 2035 |
|----|------|------|------|------|------|------|------|------|------|------|
| LFPR (%) | 62.09 | 61.71 | 61.33 | 60.95 | 60.57 | 60.26 | 59.97 | 59.71 | 59.46 | 59.24 |

This path is used in `ai_s2_prod_lf.R`, `ai_s3a_prod_lf_ui.R`, and `ai_s3b_prod_lf_ssmc.R`.

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

The AI post's appendix (Figures A1-A6) repeats S1-S3b for Karger's Slow and Rapid adoption scenarios, all anchored to the **Karger Economists response**. Each variant has four input files, `ai_{slow,rapid}_{s1_productivity,s2_prod_lf,s3a_prod_lf_ui,s3b_prod_lf_ssmc}.R`, and reproduces the published appendix series at tag `v1.8.1`.

**Productivity.** The same -0.319 pp NFB-to-GDP/employed wedge is applied:

| Variant | Karger NFB target (Economists) | BLSMM `glqstar` target | `user_delta_prod` range |
|---------|--------------------------------|------------------------|-------------------------|
| Slow    | 2.0% (flat 2030 & 2050 anchors) | 1.681% | -0.041 to 0.292 pp |
| Moderate (S1-S3b) | 2.5% (2025-30 median) | 2.181% | 0.461 to 0.791 pp |
| Rapid   | 3.2% (2030 anchor, held flat) | 2.881% | 1.159 to 1.492 pp |

The Slow target is below CBO baseline `glqstar` in 2027 and 2028, so its deltas are slightly negative there.

**Labor force.** The variants use a different construction from the moderate path. LFPR ramps linearly from 62.48% in FY2025 to the Karger Economists 2030 median by FY2030, with step (target - 62.6%) / 5 and CBO baseline labor-force growth rounded to three decimals, as in the internal LFPR calibration workbook. LFPR then continues to decline toward the 2050 median.

| Variant | 2030 target | 2050 median | Implied LFPR FY2030 | Implied LFPR FY2035 |
|---------|-------------|-------------|---------------------|---------------------|
| Slow    | 61.5% | 59.2% | 61.37% | 60.62% |
| Rapid   | 59.3% | 55.0% | 59.17% | 56.82% |

Implied LFPR uses the same method as the S2 table (FY2025 labor force 171.557 million), so it differs from the workbook's ramp endpoints (61.38% and 59.18% in FY2030) by about 0.01 point. The FY2026-FY2030 deltas follow the workbook formula exactly. The FY2031-FY2035 deltas were recovered from the published appendix data because the file that constructed them was not retained; the exact interpolation rule is not documented.

**Outlays.** S3a and S3b apply the moderate cost factors to each variant's lost participants: $5.56 thousand (UI) and $42.43 thousand (Social Security plus Medicare) per lost participant, as a percentage of CBO potential GDP.

---

## Summary Table

| Delta Type | Source | Values | Units | Impact |
|-----------|---------|---------|-------|---------|
| **Productivity** | Karger moderate labor productivity, adjusted by -0.319 pp concept wedge | 0.461-0.791 pp | `glqstar` growth | Higher GDP growth |
| **Labor Force** | Karger moderate LFPR, CY-to-FY converted | -0.519 to -0.372 pp | LF growth | LFPR about 60.6% in FY2030 |
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
# Check output: S2 LFPR should be near 60.6% in FY2030
# Check debt/GDP ranking: S1 < S2 < S3a < S3b < Baseline
```

---

## References

- **Karger et al.:** AI moderate adoption labor productivity scenario
- **SPF calibration:** NFB output/hour to GDP/employed productivity crosswalk
- **Internal calibration files:** LFPR and outlay delta calculations
- **BLSMM helpers:** `convert_lfpr_to_growth()` and `build_lfpr_path()` functions

---

**Last updated:** 2026-09-29
**Status:** Calibration documented; rebuild scenario outputs after changing input files
