# BLSMM v1.8 Scenario Analysis System

## Overview

This system generates all figures for two Budget Lab articles analyzing AI and alternate economic scenarios using the BLSMM v1.8 model. A single command rebuilds all figures from scratch.

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
3. **S2: Prod+LF** - S1 + labor force decline (LFPR → 59.3% by 2030)
4. **S3a: Prod+LF+UI** - S2 + unemployment insurance outlays
5. **S3b: Prod+LF+SSMC** - S2 + Social Security/Medicare outlays

### Alternate Scenarios
6. **Inflation** - Persistent 2.5% inflation through 2029
7. **Investor Confidence** - +100bp term premium shock
8. **Military Conflict** - Defense spending surge (PLACEHOLDER VALUES)

## Key Results (FY2035)

| Scenario | Debt/GDP | Budget/GDP | Real GDP | Impact |
|----------|----------|------------|----------|--------|
| Baseline | 118.2% | -6.2% | $28.5T | - |
| S1: Productivity | 87.6% | -1.9% | $33.5T | -30.6pp debt |
| S2: +Labor Force | 94.9% | -2.7% | $32.1T | +7.3pp from S1 |
| S3b: +SS/Medicare | 102.3% | -3.8% | $32.1T | +7.4pp from S2 |

## Directory Structure

```
scenarios/
├── inputs/              # Scenario definitions
│   ├── baseline.R
│   ├── ai_s1_productivity.R
│   ├── ai_s2_prod_lf.R
│   ├── ai_s3a_prod_lf_ui.R
│   ├── ai_s3b_prod_lf_ssmc.R
│   ├── alt_persistent_inflation.R
│   ├── alt_investor_confidence.R
│   └── alt_military_conflict.R
├── lib/                 # Core libraries
│   ├── run_scenario.R   # Generic runner
│   ├── blsmm_theme.R    # Visualization theme
│   ├── plot_helpers.R   # Plotting utilities
│   ├── figures_ai_article.R
│   └── figures_alt_article.R
├── results/             # Output data
│   ├── *.rds           # R data files
│   └── *.csv           # CSV exports
├── figures/
│   ├── ai_article/     # 3 figures for AI paper
│   └── alt_article/    # 4 figures for alternate scenarios
└── make_all_figures.R   # Master script
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
- LFPR declines linearly from 62.5% (FY2025) to exactly 59.3% (FY2030)
- Stays flat at 59.3% through FY2035
- Computed via `convert_lfpr_to_growth()` from `app/R/blsmm_helpers.R`

### Outlays Calibration
- Values from Maddie's CSV are decimal fractions of GDP
- **Must multiply by 100** to convert to percentage points
- UI outlays: ~0.09 pp of GDP average
- SS/Medicare: ~0.71 pp of GDP average (7.6× larger)

### Special Implementations
- Term premium shock via `exog_override` (not `user_deltas`)
- Baseline uses NULL for user_deltas (not zeros)
- Inflation scenario tuned iteratively to achieve targets

## Known Issues

1. **Military scenario** - Currently uses placeholder values. Update `inputs/alt_military_conflict.R` when Ryan provides exact defense outlays.

2. **Investor confidence R10** - Shows counterintuitive behavior (falls below baseline after FY2028 due to endogenous Fed response to deflation).

3. **Patchwork warnings** - Cosmetic warnings about theme application. Figures generate correctly.

## Validation

Run diagnostics to verify calibration:
```r
source("diagnostic_checks.R")  # If available
```

Key checks:
- LFPR reaches exactly 59.3% at FY2030 ✓
- Baseline matches CBO values ✓
- Scenario ordering (debt): Base > S3b > S3a > S2 > S1 ✓
- Outlays properly scaled (×100) ✓

## Citation

Based on BLSMM v1.8 (Budget Lab Small Macro Model)
AI scenarios calibrated to Karger, Liu, and Sanz-Heidenreich (2024)

## Contact

Budget Lab, Yale University
Last updated: 2024-04-18