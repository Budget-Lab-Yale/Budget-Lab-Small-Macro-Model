# AI Scenario Analysis for BLSMM v1.8

This folder contains all scripts, results, and figures for the AI scenario analysis based on the Karger et al. Rapid AI scenario (50th percentile).

## Directory Structure

```
BLSMM ai/
├── scripts/           # All R scripts for running scenarios and validation
├── results/           # Simulation outputs (RDS and CSV files)
├── figures/           # Publication-quality figures (300 DPI PNG)
└── README.md          # This file
```

## Scripts

### Main Analysis Scripts

1. **run_ai_scenarios.R** - Main simulation script that runs baseline + 4 cumulative scenarios
2. **plot_ai_scenarios.R** - Generates all visualization figures
3. **generate_report.R** - Creates comprehensive markdown report

### Validation Scripts

4. **validate_data.R** - Data integrity checks (NA, Inf, ranges, CSV/RDS consistency)
5. **validate_convergence.R** - Solver convergence and mathematical identity verification
6. **validate_scenarios.R** - Cross-scenario consistency validation
7. **run_all_validations.R** - Master script that runs all validation checks

## Scenarios (CUMULATIVE)

- **Baseline**: CBO February 2026 projection
- **S1**: Productivity shock only (+1.50 to +1.80 pp)
- **S2**: S1 + Labor force shock (LFPR decline to 0.593 by FY2030)
- **S3a**: S2 + UI outlays increase (+0.0003 to +0.0012 pp)
- **S3b**: S2 + SS/Medicare outlays increase (+0.0022 to +0.0095 pp)

**Note**: Each scenario builds on the previous. S2 includes all S1 effects, S3a/S3b include all S2 effects, etc.

## Usage

### Run Full Analysis

```r
# 1. Run scenarios (takes ~30 seconds)
source("scripts/run_ai_scenarios.R")

# 2. Generate figures
source("scripts/plot_ai_scenarios.R")

# 3. Generate report
source("scripts/generate_report.R")

# 4. Run all validations
source("scripts/run_all_validations.R")
```

### Or run individual scripts as needed

All scripts automatically set their working directory to the BLSMM ai folder and reference model components from the main project directory.

## Output Files

### Results (results/)

- `ai_baseline.{rds,csv}` - Baseline projection
- `ai_scenario_1_productivity.{rds,csv}` - S1 results
- `ai_scenario_2_prod_lf.{rds,csv}` - S2 results
- `ai_scenario_3a_prod_lf_ui.{rds,csv}` - S3a results
- `ai_scenario_3b_prod_lf_ssmc.{rds,csv}` - S3b results
- `AI_SCENARIO_REPORT.md` - Full analysis report

Each result file contains 10 rows (FY2026-FY2035) with 55 economic variables.

### Figures (figures/)

All figures are 300 DPI PNG format suitable for publication:

- `debt_gdp.png` - Debt as % of GDP
- `budget_balance.png` - Budget balance as % of GDP
- `real_gdp.png` - Real GDP ($ trillions)
- `unemployment.png` - Unemployment rate
- `inflation.png` - PCE inflation rate
- `fed_funds.png` - Federal funds rate
- `treasury_10y.png` - 10-year Treasury yield
- `combined_all_variables.png` - All variables in single figure

## Key Findings (FY2035)

| Scenario | Debt/GDP | Deficit/GDP | Real GDP |
|----------|----------|-------------|----------|
| Baseline | 118.2%   | -6.2%       | $28.5T   |
| S1       | 87.6%    | -1.9%       | $33.5T   |
| S2       | 94.9%    | -2.7%       | $32.1T   |
| S3a      | 94.9%    | -2.7%       | $32.1T   |
| S3b      | 95.0%    | -2.7%       | $32.1T   |

**Insight**: Productivity gains dominate fiscal outcomes. Even with declining labor force participation, debt trajectory improves dramatically (118% → 95% by FY2035).

## Dependencies

- R packages: ggplot2, gridExtra, nleqslv
- BLSMM v1.8 model components (in main project directory)
- CBO baseline data files (in main project data/ directory)

## Validation Status

All validation checks pass:
- ✓ Data integrity (no NA/Inf values, all values in reasonable ranges)
- ✓ Solver convergence (SSE < 1e-9 for all scenarios)
- ✓ Mathematical consistency (fiscal identities hold)
- ✓ Cross-scenario consistency (cumulative structure verified)
- ✓ Figure validation (all PNG files valid, correct sizes)
- ✓ Report validation (all required sections present)

---

**Date Created**: 2026-04-17
**Model Version**: BLSMM v1.8
**Scenario Source**: Karger et al. Rapid AI scenario (50th percentile)
