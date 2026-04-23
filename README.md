# The Budget Lab's Small Macro Model (BLSMM)

**Yale Budget Lab \| Macroeconomic Policy Analysis Tool** **Last updated: 2026-04-20**

A structural macroeconomic model for fiscal policy analysis, medium-term forecasting, and scenario simulation.

------------------------------------------------------------------------

## Overview

The Budget Lab's Small Macro Model (BLSMM) is a calibrated structural macroeconomic model designed for analyzing U.S. fiscal policy and economic forecasts. This repository contains:

1.  **Core Model** (`model/v1_8/`) - Modular R implementation with endogenous r\* and fiscal feedback
2.  **Interactive App** (`app.R`) - Shiny web application for policy simulations
3.  **Test Suite** (`tests/`) - Validation and testing scripts
4.  **Documentation** (`docs/`) - Comprehensive usage guides

------------------------------------------------------------------------

## Quick Start

### Installation

**1. Install R** (version ≥ 4.0.0) - Download from: <https://cran.r-project.org/>

**2. Install Required Packages**

``` r
install.packages(c(
  "nleqslv",        # Nonlinear equation solver
  "dplyr",          # Data manipulation
  "shiny",          # Web application framework
  "bslib",          # Modern UI themes
  "plotly",         # Interactive charts
  "DT",             # Interactive tables
  "openxlsx",       # Excel export
  "shinyjs",        # JavaScript utilities
  "rhandsontable"   # Editable tables
))
```

**3. Download the Model**

Clone or download this repository to your local machine.

### Launch the Interactive App

``` r
# Navigate to the project directory
setwd("path/to/Small Macro Model")

# Launch the app (choose one method):
source("app.R")                 # Method 1: Direct execution
shiny::runApp(".")              # Method 2: Using shiny
# Or in RStudio: Open app.R and click "Run App" button
```

The application will open instantly in your web browser thanks to baseline caching.

**Note:** First-time users should run `source("cache_baseline.R")` to pre-compute the baseline scenario for instant app loading.

### Project Structure

```
Small Macro Model/
├── app.R                          # Main Shiny app launcher
├── cache_baseline.R               # Baseline pre-computation script
├── README.md                      # This file
├── app/                           # Shiny app components
│   └── R/
│       ├── blsmm_ui.R             # User interface definition
│       ├── blsmm_server.R         # Server logic (with caching)
│       ├── blsmm_plots_v1_8.R     # All 13 dashboard charts
│       └── blsmm_helpers.R        # Helper functions
├── model/
│   └── v1_8/                      # Core model implementation
│       ├── simulation.R           # Main simulation engine
│       ├── solver.R               # Equation solver
│       ├── equations.R            # Core equations
│       ├── parameters.R           # Model parameters (39 total)
│       ├── debt_proxy.R           # Debt dynamics
│       ├── forcing.R              # Forcing variables
│       ├── neutral_rate.R         # Endogenous r* calculations
│       ├── presim_block.R         # Pre-simulation setup
│       └── user_deltas.R          # User input handling
├── data/                          # Model data files
│   ├── blsmm_v1_8_baseline_solution.csv
│   ├── blsmm_v1_8_forecast_exog.csv
│   ├── blsmm_v1_8_forecast_resid.csv
│   └── blsmm_v1_8_historical.csv
├── tests/
│   ├── test_baseline_validation.R
│   ├── test_shock_scenarios.R
│   └── v1_8/
│       ├── test_baseline_replication_v1_8.R
│       ├── test_model_functionality_v1_8.R
│       └── test_lfpr_conversion.R
└── docs/
    ├── README_App.md              # Application user guide
    └── README_Model.md            # Complete model documentation
```

------------------------------------------------------------------------

## Model Features

### Structure

**9 Core Simultaneous Equations:** 1. Output gap (aggregate demand with distributed lags) 2. Unemployment (Okun's law with dynamics) 3. Inflation (Phillips curve) 4. Inflation expectations (adaptive-rational hybrid) 5. Federal funds rate (Taylor rule with endogenous r\*) 6. Expected fed funds (10-year average) 7. Term premium 8. 10-year Treasury yield 9. Effective interest rate on government debt

**Fiscal Block:** - Government budget identity - Debt dynamics with fiscal feedback - Net interest payments - Primary balance tracking - Real GDP growth decomposition

\*\*Neutral Rate Block (Endogenous r\*):\*\* - r\* responds to potential growth (κ₁, κ₂ parameters) - r\* responds to debt/GDP ratio (κ₃ parameter) - Gradual adjustment dynamics

**Fiscal Feedback Mechanisms:** - Outlays respond to unemployment gap (ψ₁ parameter) - Outlays respond to debt/GDP (ψ₂ parameter) - Automatic stabilizers and debt sustainability

### Policy Analysis Capabilities

**Nine Input Types (Year-by-Year Control):**

1.  **Labor Force Growth** - Population and participation changes
2.  **Productivity Growth** - Trend GDP growth changes
3.  **Receipts (% GDP)** - Tax policy changes
4.  **Outlays (% GDP)** - Spending policy changes
5.  **Direct r\* Shocks** - Neutral rate adjustments
6.  **Output Gap Shocks** - Demand disturbances
7.  **Inflation Shocks** - Supply/demand price shocks
8.  **Monetary Policy Rule Shocks** - Deviations from Taylor rule
9.  **Inflation Target Changes** - Fed's price stability goal

**Key Outputs:** - Output gap and real GDP growth - Unemployment rate - Inflation and expectations - Interest rates (short, long, and r\*) - Federal debt dynamics - Fiscal multipliers - Budget balance projections

**Advanced Utilities:**
- **LFPR Conversion Tools** (`app/R/blsmm_helpers.R`) - Convert labor force participation rate (LFPR) scenarios into model-compatible growth rate inputs
  - `convert_lfpr_to_growth()` - Transform LFPR targets to glfstar deltas
  - `build_lfpr_path()` - Create LFPR paths with linear ramps
  - `summarise_lfpr_scenario()` - Generate audit tables for verification

### Calibration

-   **39 parameters** calibrated to U.S. data and empirical literature
-   **Baseline validation**: High accuracy vs. official forecasts
-   **Annual frequency** (FY2026-FY2035 baseline)
-   **Empirically-grounded** multipliers and transmission mechanisms
-   **Endogenous r**\* adjusts to growth and debt conditions
-   **Fiscal feedback** provides automatic stabilization

------------------------------------------------------------------------

## Interactive Application

### Dashboard Features

**13 Real-Time Charts:** 1. Unemployment rate (%) 2. Inflation rate (%) 3. Real GDP indexed (FY2025=100) 4. 10-year Treasury yield (%) - 4 series 5. Federal Funds rate (%) - 4 series 6. Budget balance (% of nominal GDP) 7. Debt (% of GDP) 8. Average interest rate on federal debt (%) 9. Total Receipts (% of nominal GDP) 10. Total Outlays (% of nominal GDP) 11. Primary Outlays (% of nominal GDP) 12. Real GDP growth (%) 13. Primary balance (% of nominal GDP)

**8 Deviation Charts:** 1. Budget Balance deviation 2. Unemployment deviation 3. Real GDP growth deviation 4. Inflation deviation 5. Debt/GDP deviation 6. Federal Funds rate deviation 7. 10-Year Treasury yield deviation 8. Primary Balance deviation

**User Features:** - Year-by-year input tables (9 input types) - Editable cells for precise scenario control - Preset scenarios for common analyses - Export to CSV and Excel - Debug/Diagnostics tab with solver details - Detailed results tables (Baseline, Alternative, All Deviations)

------------------------------------------------------------------------

## Deployment & Embedding

The app is designed to be embedded on the Budget Lab website (budgetlab.yale.edu) via an iframe.

### Hosting options

Two practical paths for running the server:

1.  **shinyapps.io** (Posit-hosted, good for development previews and low-traffic production)
    - Install `rsconnect` once: `install.packages("rsconnect")`
    - Configure your account: `rsconnect::setAccountInfo(name, token, secret)`
    - Deploy from the project root: `rsconnect::deployApp()`
    - Free tier: 25 active hours/month (fine for dev and stakeholder review). Standard tier ($99/mo) removes the active-hour limit.
2.  **Posit Connect via Yale** (preferred for production if available)
    - Ask Yale ITS whether the university licenses Posit Connect. If so, deploy via `rsconnect::deployApp(server = "...")`. No active-hour limits, stable URL, SSO-friendly.
    - If Yale does not have a Posit Connect license, upgrade shinyapps.io to the Standard tier.

Other paths (Shinylive / WebAssembly, Docker on Yale infra) are possible but more work; iframe + server-side Shiny is the recommended pattern.

### Local preview of the narrow-embed layout

`docs/embed_preview.html` iframes the running app at three widths (400 / 600 / 900 px) so you can see how it behaves under a narrow embed. To use it:

1.  Run `source("app.R")` in RStudio. The app pins itself to port `8100` via `options(shiny.port = 8100)` so the preview URL is stable.
2.  Open `docs/embed_preview.html` in a browser (double-click is fine).
3.  Each iframe auto-sizes to the app's content height — no nested scrollbars — via the [iframe-resizer](https://github.com/davidjbradshaw/iframe-resizer) library (v4.4.5, CDN-loaded).

### Embedding on budgetlab.yale.edu

The app loads the `iframeResizer.contentWindow` child script internally (see `app/R/blsmm_ui.R`). The host page needs three things:

1.  An `<iframe>` element pointing at the deployed Shiny URL, with `scrolling="no"` and no fixed `height`.
2.  The parent script: `<script src="https://cdn.jsdelivr.net/npm/iframe-resizer@4.4.5/js/iframeResizer.min.js"></script>`
3.  An init call after the iframe is in the DOM: `iFrameResize({ log: false, checkOrigin: false, heightCalculationMethod: 'lowestElement' }, '#blsmm-iframe');`

Fonts and colors are bundled inside the iframe (Mallory/YaleNew stack with Source Sans 3 fallback), so the embed does not depend on the parent page's stylesheet.

------------------------------------------------------------------------

## Use Cases

### 1. Fiscal Policy Analysis

**Questions BLSMM Can Answer:** - What is the output impact of a tax cut or spending increase? - How does fiscal consolidation affect unemployment? - What are the debt sustainability implications of policy changes? - How do fiscal multipliers vary with Fed response and fiscal feedback? - How does automatic stabilization work through ψ₁ and ψ₂?

**Example Scenarios:** - Analyze 1% of GDP tax cut with endogenous r\* response - Model gradual fiscal consolidation with debt feedback - Assess infrastructure spending with productivity spillovers

### 2. Medium-Term Forecasting

**Questions BLSMM Can Answer:** - Where is the economy headed under current policy? - When will the output gap close? - What is the debt/GDP trajectory? - How will r\* evolve with changing growth and debt?

### 3. Monetary-Fiscal Interaction

**Questions BLSMM Can Answer:** - How does Fed policy offset/amplify fiscal shocks? - What if the Fed changes its inflation target? - How do interest rate changes affect debt dynamics? - How does endogenous r\* affect the transmission of shocks? - What happens if r\* falls due to low growth or high debt?

### 4. Scenario Analysis

**Questions BLSMM Can Answer:** - What if we face another supply shock? - How bad could a fiscal crisis get with r\* rising due to high debt? - What's the growth impact of structural reforms on r\*? - How do automatic stabilizers perform in recessions?

### 5. Educational Applications

**Topics BLSMM Illustrates:** - IS-LM dynamics with endogenous natural rate - Phillips curve trade-offs - Fiscal policy with r\* and debt feedback - Automatic stabilizers and discretionary policy - Monetary-fiscal coordination

Perfect for: - Macro courses (undergraduate/graduate) - Policy analysis training - Economic literacy programs - Interactive demonstrations

------------------------------------------------------------------------

## Technical Specifications

### System Requirements

**Software:** - R ≥ 4.0.0 - RStudio (recommended, not required) - Modern web browser (Chrome, Firefox, Safari, Edge)

**Hardware:** - Any standard desktop or laptop - 4GB RAM recommended - No GPU required

**Operating Systems:** - Windows 10/11 - macOS 10.14+ - Linux (Ubuntu, Fedora, etc.)

### Dependencies

**Core Packages:** - `nleqslv` - Nonlinear equation solver - `dplyr` - Data manipulation

**App Packages:** - `shiny` - Web application framework - `bslib` - Modern UI themes - `plotly` - Interactive visualization - `DT` - Data tables - `openxlsx` - Excel export - `shinyjs` - JavaScript utilities - `rhandsontable` - Editable tables

All packages available on CRAN.

### Performance

**Typical Simulation:** - 10-year horizon: 1-2 seconds - Convergence: 1-2 solver iterations - Memory usage: \< 50 MB

------------------------------------------------------------------------

## Model Components

### Core Equations (9 simultaneous)

1.  **Output Gap** - Aggregate demand with interest rate sensitivity and fiscal multipliers
2.  **Unemployment** - Okun's law with current and lagged output gap
3.  **Inflation** - Phillips curve with backward/forward-looking expectations
4.  **Inflation Expectations** - Adaptive-rational hybrid
5.  **Federal Funds Rate** - Taylor rule with endogenous r\*
6.  **Expected Fed Funds** - 10-year average policy rate
7.  **Term Premium** - Risk premium on long-term bonds
8.  **10-Year Yield** - Expected policy path plus term premium
9.  **Effective Debt Rate** - Weighted average of past and current rates

### Fiscal Block

-   **Budget Identity:** D(t) = D(t-1) - BUD(t)
-   **Primary Balance:** BUDP = Receipts - Primary Outlays
-   **Net Interest:** NI = average_debt × effective_rate
-   **Debt Dynamics:** Closed-form solution with simultaneity
-   **Fiscal Feedback:** Outlays = f(unemployment_gap, debt/GDP)

### Neutral Rate Block (r\*)

-   **Potential Growth Channel:** r\* = κ₁ × g\* + κ₂ × Δg\*
-   **Debt Channel:** r\* adjustment based on D/GDP via κ₃
-   **Gradual Adjustment:** Smooth transition to new equilibrium
-   **Fed Funds Response:** Taylor rule uses endogenous r\*

### Parameters (39 total)

Key parameters include: - **Macro dynamics:** η (persistence), σ₀ (interest sensitivity), θ₁,θ₂ (fiscal multipliers) - **Labor market:** α₁,α₂ (Okun coefficients), UN (natural rate) - **Inflation:** γ₁ (persistence), γ₂ (Phillips slope) - **Monetary policy:** μ₁,μ₂,μ₃ (Taylor rule coefficients) - **Neutral rate:** κ₁,κ₂ (growth response), κ₃ (debt response) - **Fiscal feedback:** ψ₁ (stabilization), ψ₂ (debt sustainability)

See `model/v1_8/parameters.R` for complete list with documentation.

------------------------------------------------------------------------

## Getting Help

### Documentation

1.  **Model equations & functions**: See `docs/README_Model.md`
2.  **App usage**: See `docs/README_App.md`
3.  **Quick launch**: See the Quick Start section above.

### Common Issues

**Problem: Package installation fails** - Solution: Update R to latest version - Check: `install.packages()` with `dependencies = TRUE`

**Problem: Solver doesn't converge** - Cause: Extreme shock values - Solution: Use more moderate shocks (\< 5 pp) - Check: Debug tab for convergence diagnostics

**Problem: App won't launch** - Check: All packages installed - Check: Working directory is project root - Try: Restart R session

### Support

**Website:** <https://budgetlab.yale.edu>

**Email:** [budget.lab@yale.edu](mailto:budget.lab@yale.edu)

------------------------------------------------------------------------

## Citation

If you use BLSMM in your research or analysis, please cite:

```         
The Budget Lab at Yale (2026). The Budget Lab's Small Macro Model (BLSMM).
Retrieved from https://budgetlab.yale.edu
```

------------------------------------------------------------------------

## License

This model is provided for educational and research purposes. Please contact the Budget Lab at Yale for commercial use inquiries.

------------------------------------------------------------------------

**Ready to get started?**

1.  Install required packages (see Installation section)
2.  Launch the app: `source("app.R")`
3.  Try the preset scenarios
4.  Read `docs/README_App.md` for detailed usage guide
5.  Read `docs/README_Model.md` for technical documentation
