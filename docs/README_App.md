# BLSMM Interactive Application

**The Budget Lab's Small Macro Model - Shiny Web Interface**

Interactive policy simulation and analysis tool for U.S. macroeconomic forecasting and fiscal policy analysis.

**Last updated: 2026-04-20**

---

## Overview

The BLSMM Interactive Application is a web-based interface for running macroeconomic policy simulations using Yale Budget Lab's Small Macro Model. The app provides year-by-year control over fiscal and monetary policy, with real-time visualization of economic impacts.

**Key Features:**
- **9 input types** for comprehensive policy control
- **Year-by-year tables** (FY2026-FY2035) for precise scenario design
- **12 dashboard charts** showing real-time macroeconomic impacts
- **8 deviation charts** comparing scenarios to baseline
- **Preset scenarios** for common policy analyses
- **Solver diagnostics** showing convergence status
- **Data export** to CSV and Excel formats

---

## Quick Start

### Launch the Application

```r
# Navigate to project directory
setwd("path/to/Small Macro Model")

# Launch the app (choose one method):
source("app.R")
shiny::runApp(".")
```

Or in RStudio: Open `app.R` and click **"Run App"**

The app will open in your default web browser.

---

## User Interface Overview

### Sidebar Panel (Left Side)

**1. Action Buttons**
- **Run Simulation**: Compute scenario results (blue button)
- **Reset to Defaults**: Clear all inputs to baseline (gray button)

**2. Simulation Settings**
- The simulation horizon is fixed at 10 years (FY2026-FY2035)

**3. Preset Scenarios** (3 buttons)
- Quick-load common policy scenarios: AI Adoption, Persistent Inflation, Higher Defense Spending
- One-click setup for standard analyses

**4. Input Tables** (9 collapsible panels)
- Year-by-year editable tables (FY2026-FY2035)
- Each shows Baseline, User Delta, and resulting User Level
- Edit yellow "User Delta" cells to create scenarios

**5. Quick Actions**
- Export results to CSV
- Export results to Excel

### Main Panel (Tabbed Interface)

**Tab 1: Dashboard**
- 12 interactive charts showing baseline vs. scenario
- Hover for exact values
- Real-time updates after each simulation

**Tab 2: Deviation Charts**
- 8 deviation plots (scenario minus baseline)
- Zero reference lines
- Fiscal multiplier calculations

**Tab 3: Deviation Tables**
- Detailed numeric deviations
- Summary statistics
- Sortable and filterable

**Tab 4: Detailed Results**
- Three sub-tabs: Baseline, Alternative, All Deviations
- Complete variable set with fiscal year labels
- Exportable data tables

**Tab 5: Debug / Diagnostics**
- Solver convergence status
- Residuals inspection
- Technical validation

**Tab 6: About**
- Model documentation
- Quick reference guide
- Contact information

---

## The 9 Input Types

Each input type has its own year-by-year table with 10 columns (FY2026-FY2035).

### 1. Labor Force Growth (%)

**What it controls:** Annual growth rate of the labor force

**Use cases:**
- Demographic changes (aging, immigration)
- Labor force participation shifts
- Population growth scenarios

**Example:** +0.50 in all years = labor force grows 0.5pp faster annually

### 2. Productivity Growth (%)

**What it controls:** Annual growth rate of labor productivity (output per worker)

**Use cases:**
- Technology improvements
- Supply-side reforms
- Structural productivity changes

**Example:** +0.25 in all years = productivity grows 0.25pp faster, raising potential GDP growth

### 3. Receipts (% of GDP)

**What it controls:** Federal government receipts as percentage of GDP

**Use cases:**
- Tax policy changes
- Revenue projections
- Fiscal consolidation via revenue increases

**Interpretation:**
- Positive delta = higher taxes (contractionary)
- Negative delta = tax cuts (expansionary)

**Example:** +1.00 in FY2026 = receipts increase by 1% of GDP (~$250 billion)

### 4. Outlays (% of GDP)

**What it controls:** Federal government outlays as percentage of GDP

**Use cases:**
- Spending policy changes
- Discretionary fiscal stimulus
- Fiscal consolidation via spending cuts

**Interpretation:**
- Positive delta = higher spending (expansionary)
- Negative delta = spending cuts (contractionary)

**Example:** +2.00 for FY2026-FY2027 = temporary spending increase of 2% of GDP

### 5. r* Shocks (percentage points)

**What it controls:** Direct shocks to the neutral real interest rate (r*)

**Use cases:**
- Structural shifts in saving/investment balance
- Global financial conditions
- Long-run growth expectations

**Note:** r* also responds endogenously to potential growth and debt/GDP via model parameters `kappa_1`, `kappa_2`, `kappa_3`

**Example:** +0.50 = neutral rate rises 50 basis points above baseline

### 6. Output Gap Shocks (percentage points)

**What it controls:** Direct shocks to the output gap equation residual

**Use cases:**
- Exogenous demand disturbances
- Confidence shocks
- Foreign demand changes
- Wealth effects

**Note:** Realized output gap will differ from shock due to model feedback (interest rates, inflation, etc.)

**Example:** +2.00 = positive demand shock pushing output 2pp above potential

### 7. Inflation Shocks (percentage points)

**What it controls:** Unexpected inflation via Phillips curve residual

**Use cases:**
- Supply shocks (oil, commodities)
- Import price changes
- Wage-price spirals
- Temporary inflation surprises

**Example:** +1.50 in FY2026 = inflation 1.5pp above baseline (supply shock)

### 8. Monetary Policy Rule Shocks (percentage points)

**What it controls:** Deviations from the Taylor rule (non-systematic policy)

**Use cases:**
- Forward guidance
- Unconventional monetary policy
- Policy rate floor/ceiling
- Deliberate deviations from systematic response

**Interpretation:**
- Positive = tighter than rule (hawkish)
- Negative = looser than rule (dovish)

**Example:** -0.50 for FY2026-FY2028 = Fed keeps rates 50bp below Taylor rule

### 9. Inflation Target (percentage points)

**What it controls:** Change in Fed's long-run inflation target

**Use cases:**
- Regime change (e.g., 2% to 3% target)
- Average inflation targeting
- Make-up strategies

**Special feature:** Includes expectations speed switch
- Fast adjustment (checked): Expectations adjust quickly to new target
- Normal adjustment (unchecked): Gradual expectations formation

**Example:** +0.50 permanently = Fed raises inflation target from 2% to 2.5%

---

## The 12 Dashboard Charts

All charts show both **baseline** (dashed line) and **scenario** (solid line) projections.

### 1. Unemployment Rate (%)

- Shows unemployment rate over time
- Compare to natural rate (UN approx 4.2%)
- Higher = labor market slack
- Lower = tight labor market

### 2. Inflation Rate (%)

- Year-over-year GDP deflator inflation
- Compare to Fed target (2.0%)
- Above target = overheating
- Below target = slack/disinflation

### 3. 10-Year Treasury Yield (%)

Four series displayed:
- Expected 10-year yield (baseline)
- Expected 10-year yield (scenario)
- Actual 10-year yield (baseline)
- Actual 10-year yield (scenario)

Shows long-term interest rate dynamics and term premium evolution.

### 4. Federal Funds Rate (%)

Four series displayed:
- r* (neutral rate, baseline)
- r* (neutral rate, scenario)
- Federal funds rate (baseline)
- Federal funds rate (scenario)

Shows monetary policy stance and neutral rate evolution.

### 5. Budget Balance (% of GDP)

- Federal budget balance as percentage of GDP
- Negative = deficit
- Positive = surplus
- Shows overall fiscal position

### 6. Federal Debt (% of GDP)

- Publicly held debt as percentage of GDP
- Rising = fiscal sustainability concerns
- Falling = improving fiscal position
- Key metric for long-run fiscal health

### 7. Average Interest Rate on Federal Debt (%)

- Effective interest rate on outstanding debt
- Weighted average of past and current rates
- Affects net interest payments
- Adjusts gradually as debt turns over

### 8. Total Receipts (% of GDP)

- Federal government receipts as percentage of GDP
- Includes all revenue sources
- Shows tax policy and automatic stabilizer effects
- Cyclically sensitive

### 9. Total Outlays (% of GDP)

- Federal government outlays as percentage of GDP
- Includes all spending and net interest
- Shows spending policy and automatic stabilizers
- Cyclically sensitive

### 10. Primary Outlays (% of GDP)

- Total outlays excluding net interest payments
- Isolates discretionary and programmatic spending
- Removes debt service component
- Shows structural spending path

### 11. Real GDP Growth (%)

- Year-over-year real GDP growth rate
- Compare to potential growth (approx 2.2%)
- Above potential = output gap closing
- Below potential = output gap widening

### 12. Primary Balance (% of GDP)

- Budget balance excluding net interest
- Receipts minus primary outlays
- Structural fiscal position
- Key for debt sustainability analysis

---

## The 8 Deviation Charts

All deviation charts show **Scenario minus Baseline** (percentage points or levels).

### 1. Budget Balance Deviation (pp of GDP)

- Change in budget balance due to scenario
- Positive = smaller deficit (fiscal improvement)
- Negative = larger deficit (fiscal deterioration)

### 2. Unemployment Deviation (pp)

- Change in unemployment rate
- Positive = higher unemployment (slack)
- Negative = lower unemployment (tightness)

### 3. Real GDP Growth Deviation (pp)

- Change in annual growth rate
- Positive = faster growth
- Negative = slower growth

### 4. Inflation Deviation (pp)

- Change in inflation rate
- Positive = higher inflation
- Negative = lower inflation (disinflation)

### 5. Debt/GDP Deviation (pp)

- Change in debt-to-GDP ratio
- Positive = higher debt ratio
- Negative = lower debt ratio (fiscal improvement)

### 6. Federal Funds Rate Deviation (pp)

- Change in policy rate
- Positive = tighter monetary policy
- Negative = easier monetary policy

### 7. 10-Year Treasury Yield Deviation (pp)

- Change in long-term interest rate
- Positive = higher long rates
- Negative = lower long rates
- Reflects both policy and term premium changes

### 8. Primary Balance Deviation (pp of GDP)

- Change in structural fiscal position
- Positive = smaller structural deficit
- Negative = larger structural deficit

**Fiscal Multiplier Display:**

Each deviation chart tab also shows calculated multipliers:
- **Impact multiplier**: FY2026 effect per unit of fiscal shock
- **Peak multiplier**: Maximum effect with timing
- **Debt multiplier**: Long-run debt change per unit of fiscal shock

---

## Preset Scenarios

3 one-click scenarios for common policy analyses:

### 1. AI Adoption
- Loads scenario S2 (Productivity + Labor Force) from the AI article, via `scenarios/inputs/ai_s2_prod_lf.R`: the Karger et al. moderate-adoption productivity boost plus the labor-force participation decline
- No outlay change; the outlay-increase variants are S3/S4 (`ai_s3a_prod_lf_ui.R`, `ai_s3b_prod_lf_ssmc.R`)
- Tests medium-term growth, labor supply, and fiscal effects from AI diffusion
- Useful starting point for the AI article scenarios

### 2. Persistent Inflation
- Front-loaded inflation shock path: 0.0, 0.1, 0.3, 0.2, then 0.0
- Tests inflation persistence and the endogenous Fed response
- Useful starting point for the alternate inflation scenario

### 3. Higher Defense Spending
- Applies the BR2027-based defense outlay increase, including the FY2027 mandatory bump
- Tests deficit, debt-service, and crowding-out effects from sustained defense spending
- Useful starting point for the alternate military-conflict scenario

---

## How to Create Custom Scenarios

### Step-by-Step Workflow

**1. Plan Your Scenario**
- Decide which input types to modify
- Sketch the time profile (temporary vs. permanent)
- Consider reasonable magnitudes

**2. Enter Year-by-Year Values**
- Click on input panel to expand
- Edit yellow "User Delta" cells
- Watch "User Level" row update automatically
- Press Tab/Enter to move between cells

**3. Run the Simulation**
- Click blue "Run Simulation" button
- Wait 1-3 seconds for computation
- Check Dashboard tab for results

**4. Analyze Results**
- View Dashboard charts for macro impacts
- Switch to Deviation Charts for detailed effects
- Check fiscal multipliers
- Review Detailed Results tables

**5. Export and Document**
- Export to Excel (includes shock specifications)
- Save scenario for future reference
- Share with colleagues

### Common Shock Patterns

**Temporary Shock (2-year):**
```
FY2026: 2.00
FY2027: 2.00
FY2028-FY2035: 0.00
```

**Permanent Shift:**
```
FY2026-FY2035: 1.50
```

**Gradual Phase-In:**
```
FY2026: 0.50
FY2027: 1.00
FY2028: 1.50
FY2029-FY2035: 2.00
```

**Gradual Phase-Out:**
```
FY2026-FY2028: 2.00
FY2029: 1.50
FY2030: 1.00
FY2031: 0.50
FY2032-FY2035: 0.00
```

---

## Example Analyses

### Example 1: Infrastructure Spending with Productivity Gains

**Research Question:** What if infrastructure spending (+1% of GDP for 5 years) raises productivity growth by 0.2pp?

**Setup:**
1. Open "4. Outlays" panel -> Enter +1.00 for FY2026-FY2030
2. Open "2. Productivity Growth" panel -> Enter +0.20 for FY2027-FY2035 (1-year lag)
3. Click "Run Simulation"

**Expected Results:**
- Short-run: Demand boost, output gap rises, unemployment falls
- Medium-run: Faster potential growth, lower debt/GDP (growth effect dominates)
- Long-run: Higher real GDP level, improved fiscal sustainability

### Example 2: Fiscal Consolidation with Fed Support

**Research Question:** Can gradual deficit reduction avoid recession if Fed keeps rates low?

**Setup:**
1. Open "3. Receipts" -> Enter gradual increase: +0.50, +1.00, +1.50, +2.00, +2.00...
2. Open "8. Monetary Policy Rule Shocks" -> Enter -0.50 for FY2026-FY2030 (Fed stays accommodative)
3. Click "Run Simulation"

**Expected Results:**
- Fiscal drag partially offset by monetary accommodation
- Modest output gap decline
- Debt/GDP improves significantly
- Inflation stable or slightly below target

### Example 3: Inflation Shock with Credible Disinflation

**Research Question:** How painful is disinflation if Fed credibly commits to 2% target?

**Setup:**
1. Open "7. Inflation Shocks" -> Enter +2.00 for FY2026 (supply shock)
2. Open "8. Monetary Policy Rule Shocks" -> Enter +1.00 for FY2026-FY2028 (aggressive Fed)
3. Click "Run Simulation"

**Expected Results:**
- Inflation spike in FY2026, then rapid return to target
- Output gap falls (sacrifice ratio)
- Unemployment rises
- If credible, expectations anchor -> smaller output loss

### Example 4: Population Aging Effects

**Research Question:** What are macro impacts of slower labor force growth?

**Setup:**
1. Open "1. Labor Force Growth" -> Enter -0.50 for all years (demographic headwind)
2. Click "Run Simulation"

**Expected Results:**
- Potential GDP growth falls by ~0.50pp
- Real GDP growth slows
- Debt/GDP rises (denominator effect)
- r* may fall (model's `kappa_1` and `kappa_2` parameters)
- Neutral policy rate declines

---

## Understanding the Results

### Output Gap
- **Positive:** Economy above potential (overheating, inflationary pressure)
- **Negative:** Economy below potential (slack, disinflationary pressure)
- **Zero:** Economy at potential (full employment)

### Unemployment
- Compare to natural rate (UN ≈ 4.2% in baseline)
- 1 percentage point below natural = tight labor market
- 1 percentage point above natural = significant slack

### Inflation
- Compare to Fed target (2.0%)
- Persistent deviation = policy challenge
- Temporary spike = supply shock

### Interest Rates
- **Fed funds above r*:** Contractionary policy stance
- **Fed funds below r*:** Expansionary policy stance
- **10-year above fed funds:** Normal term premium (upward-sloping yield curve)

### Fiscal Variables
- **Budget balance:** Flow measure (deficit/surplus this year)
- **Debt/GDP:** Stock measure (cumulative debt burden)
- **Primary balance:** Excludes interest, shows structural position

### Fiscal Multipliers
- **Impact multiplier (first year):** Typically 0.5-1.5 depending on Fed response
- **Peak multiplier:** Often occurs in year 2-3
- **Debt multiplier:** Long-run debt increase per unit of deficit shock
  - > 1.0 means debt rises more than initial deficit (snowball effect)
  - < 1.0 means partial offset via growth/inflation

---

## Technical Requirements

### R Version
- R >= 4.0.0 recommended
- Developed and tested on R 4.3+

### Required Packages

```r
install.packages(c(
  "shiny",          # Web application framework
  "bslib",          # Modern UI themes
  "plotly",         # Interactive charts
  "DT",             # Interactive tables
  "openxlsx",       # Excel export
  "shinyjs",        # JavaScript utilities
  "dplyr",          # Data manipulation
  "nleqslv"         # Equation solver
))
```

### Performance

**Typical simulation:** 1-3 seconds
**Horizon:** Fixed 10-year simulation (FY2026-FY2035)
**Memory usage:** < 50 MB
**Browser compatibility:** Chrome, Firefox, Safari, Edge (modern versions)

---

## Data Export

### CSV Export

**File naming:** `BLSMM_simulation_YYYY-MM-DD.csv`

**Contents:**
- Fiscal year labels (FY2026-FY2035)
- Baseline values (prefix: `baseline_`)
- Scenario values (prefix: `scenario_`)
- Deviations (prefix: `d_`)

**Usage:**
```r
# Load exported data
data <- read.csv("BLSMM_simulation_2026-04-06.csv")

# Quick plot
plot(data$d_xgap, type = "l", main = "Output Gap Deviation")
```

### Excel Export

**File naming:** `BLSMM_simulation_YYYY-MM-DD.xlsx`

**Five sheets:**
1. **Baseline:** Complete baseline simulation
2. **Scenario:** Complete scenario simulation
3. **Deviations:** All deviation variables
4. **Parameters:** Model parameters used (39 total)
5. **Shocks:** Year-by-year shock values for all 9 input types

**Usage:**
- Open in Excel for charts and analysis
- Archive complete simulation setup
- Share scenarios with collaborators
- Compare to external forecasts

---

## Troubleshooting

### Launch Issues

**Error: "cannot find function 'simulate_blsmm'"**
- Ensure model files exist in `model/v1_8/`
- Check that `app.R` sources model correctly
- Verify working directory is project root

**Error: Package not found**
- Install all required packages (see Requirements section)
- Use `install.packages()` with `dependencies = TRUE`

**App won't open in browser**
- Check R console for error messages
- Try manually opening: http://127.0.0.1:#### (port shown in console)
- Disable popup blockers

### Simulation Issues

**Solver doesn't converge**
- Extreme shock values may be infeasible
- Try more moderate magnitudes (< 5 percentage points)
- Check Debug tab for diagnostic info
- Click "Run Simulation" again (may need 2-3 iterations)

**Blank charts**
- Simulation hasn't run yet
- Click "Run Simulation" button
- Wait for completion message

**Unexpected results**
- Verify shock values in input tables (check yellow cells)
- Review Debug tab residuals
- Compare to preset scenarios to validate setup
- Check that model assumptions are appropriate for scenario

### Table Editing Issues

**Can't edit cells**
- Only yellow "User Delta" row is editable
- Gray rows (Baseline, User Level) are read-only

**Values don't persist**
- Click outside table after editing
- Click "Run Simulation" to process changes
- Don't use browser refresh (resets app)

**Numbers show as NA**
- Enter only numeric values
- Use negative sign if needed (e.g., -2.00)
- Don't use commas or currency symbols

### Performance Issues

**Slow response**
- Close unused browser tabs
- Restart R session to clear memory
- Collapse unused input panels

---

## Best Practices

### Simulation Workflow

1. **Start with baseline:** Run with all inputs at zero to verify baseline
2. **One input at a time:** Test individual inputs before combining
3. **Build gradually:** Start with simple shocks, add complexity
4. **Check convergence:** Always verify solver status before interpreting
5. **Document thoroughly:** Export results and note scenario specifications
6. **Validate results:** Compare to economic intuition and known multipliers

### Input Design

1. **Use realistic magnitudes:** Extreme shocks may exceed model validity
   - Fiscal: +/- 2-3% of GDP typical
   - Interest rates: +/- 1-2 percentage points typical
   - Growth: +/- 0.5-1.0 percentage points typical
2. **Consider persistence:** Permanent vs. temporary shocks have very different effects
3. **Think about timing:** Front-loaded vs. back-loaded fiscal paths matter
4. **Verify levels:** Check "User Level" row to ensure combined values make sense

### Results Interpretation

1. **Focus on deviations:** The difference from baseline is what matters
2. **Note peak timing:** Maximum impact may occur after shock period
3. **Watch for dynamics:** Effects persist beyond shock duration
4. **Consider credibility:** Model assumes expectations are model-consistent
5. **Assess realism:** Very large multipliers may indicate model limitations
6. **Check all channels:** Fiscal -> Output -> Inflation -> Fed -> Interest rates -> Debt

### Presenting Findings

1. **Lead with scenario description:** Clearly state the policy change
2. **Show shock path:** Display year-by-year input values
3. **Highlight key results:** Output, unemployment, inflation, debt
4. **Explain transmission:** Walk through economic channels
5. **Quantify multipliers:** Impact, peak, and debt multipliers
6. **Discuss uncertainty:** Model is calibrated, not estimated
7. **Compare alternatives:** Show multiple scenarios when relevant

---

## Advanced Features

### Debug / Diagnostics Tab

**Use this tab to:**
- Verify solver convergence (SSE < 0.001 required)
- Inspect baseline residuals (should match data files)
- Inspect shocked residuals (baseline + your deltas)
- Validate shock application (compare baseline vs. shocked)
- Troubleshoot unexpected results

### Fiscal Year Labels

All data uses **fiscal years** (October 1 - September 30):
- **FY2026** = Oct 1, 2025 - Sep 30, 2026
- Matches U.S. federal budget convention
- Consistent with CBO and OMB publications

### Batch Simulations

For research projects, run multiple scenarios programmatically:

```r
# Source model functions
source("model/v1_8/simulation.R")

# Define scenarios
scenarios <- list(
  scenario_1 = list(outlays = c(2, 2, 1, 0, 0, 0, 0, 0, 0, 0)),
  scenario_2 = list(outlays = c(1, 1, 1, 1, 1, 0, 0, 0, 0, 0)),
  scenario_3 = list(receipts = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
)

# Run all scenarios
results <- lapply(scenarios, function(s) {
  # Call simulation function with appropriate deltas
  # Process and store results
})

# Compare outcomes
compare_debt_impacts(results)
```

---

## Frequently Asked Questions

**Q: How do I replicate the baseline forecast?**
A: Leave all User Delta cells at 0.00 and click "Run Simulation"

**Q: Can I extend beyond FY2035?**
A: Yes, but requires modifying model data files and code (see model/v1_8/ files)

**Q: What's the difference between Receipts/Outlays and Primary Balance?**
A: Both affect fiscal position. Use Receipts/Outlays for direct control of tax and spending policies. The model derives primary balance automatically from receipts minus primary outlays.

**Q: How do I model a recession?**
A: Use negative Output Gap Shock and/or negative Productivity Growth. Or use Fed tightening (Monetary Policy Rule Shock) to induce recession.

**Q: Why does debt/GDP sometimes improve with deficit spending?**
A: If growth response (numerator effect) exceeds deficit increase (denominator effect). Depends on multipliers and time horizon.

**Q: Can I modify the Taylor rule parameters?**
A: Yes, but requires editing `model/v1_8/parameters.R` file (`mu_1`, `mu_2`, `mu_3` parameters)

**Q: What determines the fiscal multiplier?**
A: Fed response, automatic stabilizers (`psi_1`), debt feedback (`psi_2`), openness, timing, and expectations

**Q: How is r* determined in the model?**
A: Endogenously responds to potential growth (`kappa_1`, `kappa_2`) and debt/GDP (`kappa_3`), plus direct r* shocks

---

## Related Documentation

**Model technical details:** See `docs/README_Model.md`
**Project overview:** See `README.md`
**Quick launch:** See the Quick Start section in the project README.

---

## Contact & Support

**The Budget Lab at Yale**
Website: https://budgetlab.yale.edu
Email: budget.lab@yale.edu

For technical issues:
- Check Debug tab for diagnostics
- Verify shock specifications in input tables
- Review model documentation for equation details
- Test with preset scenarios to validate setup

---

**BLSMM Interactive Application - Complete User Guide**
