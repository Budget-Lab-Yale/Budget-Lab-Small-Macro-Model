# BLSMM v1.8 Scenario Analysis System

## Overview

This directory contains scenario definitions, runners, outputs, and figures for BLSMM v1.8 scenario analysis. A single command rebuilds all scenario results and figures from the current model code. Results in `results/` are tracked so that model changes show their effect on each scenario in review. Figures are generated locally and not tracked.

## Quick Start

```r
# Run everything (takes ~30 seconds)
source("scenarios/make_all_figures.R")
```

This command:
1. Runs every scenario in `inputs/` (results for the 8 scenarios listed below are tracked; `ai_rapid` and `ai_slow` outputs are generated but not tracked)
2. Saves results to `results/` (RDS and CSV)
3. Generates 7 figures (300 DPI) under `figures/`

## Scenarios

### AI Scenarios (Cumulative)
Calibrated to the Moderate Adoption scenario in Karger et al. (2026), NBER Working Paper 35046

1. **Baseline** - No shocks, CBO Feb 2026 baseline
2. **S1: Productivity** - AI raises potential labor-force productivity growth by 0.46 to 0.79 percentage points per year
3. **S2: Prod+LF** - S1 + labor force decline (LFPR near 59.3% by FY2030)
4. **S3a: Prod+LF+UI** - S2 + unemployment insurance outlays
5. **S3b: Prod+LF+SSMC** - S2 + Social Security/Medicare outlays

### Alternate Scenarios
6. **Inflation** - Front-loaded inflation shock that keeps inflation near 2.5% through FY2029
7. **Investor Confidence** - Sovereign-trust shock via `epstp`, `epsrg`, and `epspie` residual overrides
8. **Military Conflict** - Defense spending surge based on the Administration's FY2027 Budget Request

## Current Results

Current scenario values are in `results/*.csv`, one row per fiscal year. They are regenerated whenever the model changes, so this README does not repeat them.

## Reproducing Published Results

Published results are reproduced from the tagged model version, not from `main`:

```bash
git checkout v1.8.0
Rscript --vanilla -e 'source("scenarios/make_all_figures.R")'
```

| Publication | Tag | Reproducible scenarios |
|-------------|-----|------------------------|
| [What Might AI Adoption Mean for the Fiscal and Economic Outlook?](https://budgetlab.yale.edu/node/1490) (May 19, 2026 update) | `v1.8.0` | Baseline, S1–S4 (repository S1, S2, S3a, S3b) |
| [How the Budget Lab Small Macro Model Helps Explore Possible Fiscal Futures](https://budgetlab.yale.edu/node/1491) (May 6, 2026) | `v1.8.0` | Baseline, S2, persistent inflation, investor confidence, military conflict |
| [How potential AI futures would play out in the current tax system](https://budgetlab.yale.edu/research/how-potential-ai-futures-would-play-out-current-tax-system), Figure A4 | `v1.8.0` | Produced by [AI-Fiscal](https://github.com/Budget-Lab-Yale/AI-Fiscal) `code/15_blsmm_debt_gdp.R` against this model |

At `v1.8.0`, the regenerated `results/*.csv` files are byte-identical to the tracked ones, and they match every main-text series in both published data workbooks. The published charts are built from those data workbooks, so locally rendered PNGs can differ in fonts and layout.

The AI post's appendix (rapid and slow adoption, Figures A1–A6) cannot be reproduced from any tagged version: its eight S1–S4 runs were never committed, and `inputs/ai_rapid.R` was re-anchored after they were produced.

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
|-- figures/             # Generated, not tracked
|   |-- ai_article/      # 3 figures for the AI post
|   `-- alt_article/     # 4 figures for the alternate-scenarios post
`-- make_all_figures.R   # Master script
```

## Figures Generated

### AI Article (3 single-panel line charts)
- `fig2_budget_deficit.png` - Budget deficit as % of GDP
- `fig3_debt.png` - Debt as % of GDP
- `fig4_real_gdp_growth.png` - Real GDP growth

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
AI scenarios calibrated to Karger et al. (2026), NBER Working Paper 35046

## Contact

Budget Lab, Yale University
Last updated: 2026-09-29
