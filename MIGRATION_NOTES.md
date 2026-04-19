# BLSMM v1.8 System Migration Notes

## Migration from `BLSMM ai/` to `scenarios/`
Date: 2024-04-18

### What Changed

The BLSMM figure generation system has been completely refactored from the old `BLSMM ai/` folder to the new `scenarios/` system.

### Key Improvements

1. **Corrected Calibration**
   - OLD: LFPR reached 60.68% at FY2030 (incorrect)
   - NEW: LFPR reaches exactly 59.3% at FY2030 (matches Karger et al.)
   - Labor force deltas computed via `convert_lfpr_to_growth()` function

2. **Expanded Scenarios**
   - OLD: 4 AI scenarios only
   - NEW: 8 scenarios (5 AI + 3 alternate scenarios)
   - Added: Inflation, Investor Confidence, Military Conflict scenarios

3. **Modular Architecture**
   - OLD: Monolithic scripts with repeated code
   - NEW: Modular libraries with single-command rebuild
   - Master script: `scenarios/make_all_figures.R`

4. **Fixed Bugs**
   - Outlays were 1000× too small (now correctly multiplied by 100)
   - Term premium implemented via `exog_override` (not `user_deltas`)
   - Baseline convention: NULL for zero deltas

### File Mapping

| Old Location | New Location | Notes |
|--------------|--------------|-------|
| `BLSMM ai/scripts/run_ai_scenarios.R` | `scenarios/lib/run_scenario.R` | Generalized runner |
| `BLSMM ai/scripts/plot_ai_scenarios.R` | `scenarios/lib/figures_ai_article.R` | Cleaner plotting |
| `BLSMM ai/results/*.rds` | `scenarios/results/*.rds` | 8 scenarios vs 4 |
| `BLSMM ai/figures/*.png` | `scenarios/figures/ai_article/*.png` | Publication-ready |

### Why Remove `BLSMM ai/`?

1. **Incorrect calibration** - LF deltas produced wrong LFPR trajectory
2. **Superseded** - All functionality now in `scenarios/` with improvements
3. **Avoid confusion** - Single source of truth for figure generation
4. **Git hygiene** - Remove obsolete code

### How to Use New System

```r
# From project root
source("scenarios/make_all_figures.R")

# This runs all 8 scenarios and generates all 7 figures
# Output: scenarios/figures/ai_article/ (3 figures)
#         scenarios/figures/alt_article/ (4 figures)
```

### Outstanding Issues

1. **Military scenario** uses placeholder values - needs Ryan's exact defense outlays
2. **Investor confidence** shows counterintuitive R10 behavior (document in paper)

### Baseline Verification

The new system produces IDENTICAL baseline results to the old system:
- Debt/GDP FY2035: 118.16%
- Real GDP FY2035: $28,538B
- All variables match exactly

### Contact

For questions about this migration, see the complete documentation in the original refactoring chat.