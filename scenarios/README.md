# BLSMM v1.8 Scenario Analysis System

## Overview

This directory contains scenario definitions, runners, outputs, and figures for BLSMM v1.8 scenario analysis. A single command rebuilds all scenario results and publication figures from the current model code.

## Quick Start

```r
# Run everything (takes ~30 seconds)
source("scenarios/make_all_figures.R")
```

This command:
1. Runs all 8 scenarios
2. Saves results to `results/` (RDS and CSV)
3. Generates 7 publication-ready figures (300 DPI)

## Scenarios

### AI Scenarios (Cumulative)
Based on Karger et al. (2024) "The Macroeconomic Effects of AI"

1. **Baseline** - No shocks, CBO Feb 2026 baseline
2. **S1: Productivity** - AI boosts productivity +1.5-1.8 pp/year
3. **S2: Prod+LF** - S1 + labor force decline (LFPR near 59.3% by FY2030)
4. **S3a: Prod+LF+UI** - S2 + unemployment insurance outlays
5. **S3b: Prod+LF+SSMC** - S2 + Social Security/Medicare outlays

### Alternate Scenarios
6. **Inflation** - Front-loaded inflation shock that keeps inflation near 2.5% through FY2029
7. **Investor Confidence** - Sovereign-trust shock via `epstp`, `epsrg`, and `epspie` residual overrides
8. **Military Conflict** - Defense spending surge based on the Administration's FY2027 Budget Request

## Key Results (FY2035)

| Scenario | Debt/GDP | Budget/GDP | Real GDP | Impact |
|----------|----------|------------|----------|--------|
| Baseline | 118.2% | -6.2% | $28.5T | - |
| S1: Productivity | 87.6% | -1.9% | $33.5T | -30.6pp debt |
| S2: +Labor Force | 95.3% | -2.7% | $32.0T | +7.7pp from S1 |
| S3b: +SS/Medicare | 102.6% | -3.9% | $32.0T | +7.3pp from S2 |

## Directory Structure

```
scenarios/
|-- inputs/              # Scenario definitions
|   |-- baseline.R
|   |-- ai_s1_productivity.R
|   |-- ai_s2_prod_lf.R
|   |-- ai_s3a_prod_lf_ui.R
|   |-- ai_s3b_prod_lf_ssmc.R
|   |-- alt_persistent_inflation.R
|   |-- alt_investor_confidence.R
|   `-- alt_military_conflict.R
|-- lib/                 # Core libraries
|   |-- run_scenario.R   # Generic runner
|   |-- blsmm_theme.R    # Visualization theme
|   |-- plot_helpers.R   # Plotting utilities
|   |-- figures_ai_article.R
|   `-- figures_alt_article.R
|-- results/             # Output data
|   |-- *.rds            # R data files
|   `-- *.csv            # CSV exports
|-- figures/
|   |-- ai_article/      # 3 figures for AI paper
|   `-- alt_article/     # 4 figures for alternate scenarios
`-- make_all_figures.R   # Master script
```

## Figures Generated

### AI Article (3 single-panel line charts)
- `fig2_budget_balance.png` - Budget balance as % of GDP
- `fig3_debt.png` - Debt as % of GDP
- `fig4_real_gdp.png` - Real GDP in trillions

### Alternate Scenarios (4 multi-panel grids)
- `fig1_ai.png` - AI scenario (S2) vs baseline
- `fig2_inflation.png` - Inflation scenario vs baseline
- `fig3_investor_conf.png` - Investor confidence vs baseline
- `fig4_military.png` - Military conflict vs baseline

## Technical Details

### Labor Force Calibration
- LFPR declines from about 62.5% (FY2025) to about 59.2% by FY2030
- Stays flat near 59.2% through FY2035
- Computed via `convert_lfpr_to_growth()` from `app/R/blsmm_helpers.R`

### Outlays Calibration
- Source values are decimal fractions of GDP
- **Must multiply by 100** to convert to percentage points
- UI outlays: about 0.09 pp of GDP on average
- Social Security and Medicare outlays: about 0.71 pp of GDP on average

### Special Implementations
- Investor confidence uses `resid_override` (`epstp`, `epsrg`, `epspie`) rather than `user_deltas`
- Baseline uses NULL for user_deltas (not zeros)
- Inflation scenario uses the documented workbook shock path

## Notes and Caveats

1. **Military scenario** - Uses the official defense outlay path documented in `inputs/alt_military_conflict.R`.

2. **Investor confidence** - Implements a sovereign-confidence shock through `epstp`, `epsrg`, and `epspie`, raising long rates, effective debt-service costs, and inflation expectations throughout the forecast horizon.

3. **Package version notices** - R may report package build-version notices. These do not affect scenario outputs.

## Validation

Run diagnostics to verify calibration:
```r
source("scenarios/make_all_figures.R")
source("tests/v1_8/test_lfpr_conversion.R")
```

Key checks:
- LFPR reaches the target path by FY2030
- Baseline matches CBO values
- Scenario ordering for debt is internally consistent
- Outlays are scaled from decimals to percentage points

## Citation

Based on BLSMM v1.8 (Budget Lab Small Macro Model)
AI scenarios calibrated to Karger, Liu, and Sanz-Heidenreich (2024)

## Contact

Budget Lab, Yale University
Last updated: 2026-04-20
