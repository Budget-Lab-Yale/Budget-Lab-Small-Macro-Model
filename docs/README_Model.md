# BLSMM Model - Technical Documentation

**The Budget Lab's Small Macro Model (BLSMM)**
Complete technical documentation for the model implementation.

**Last updated: 2026-04-20**

---

## Table of Contents

1. [Overview](#overview)
2. [Model Structure](#model-structure)
3. [Core Equations](#core-equations)
4. [Fiscal Block](#fiscal-block)
5. [Neutral Rate Block](#neutral-rate-block)
6. [Parameters](#parameters)
7. [Model Files](#model-files)
8. [Functions](#functions)
9. [Data Inputs](#data-inputs)
10. [Validation](#validation)

---

## Overview

BLSMM is a medium-scale structural macroeconomic model designed for fiscal policy analysis and medium-term forecasting. The model combines traditional macro relationships with modern features including:

- **Endogenous neutral rate (r*)** - Responds to potential growth and debt/GDP
- **Fiscal feedback** - Primary outlays respond to potential labor-force and productivity growth through calibrated feedback coefficients
- **Rich dynamics** - Distributed lags and forward-looking expectations
- **Modular design** - Clean separation of components for maintainability

### Key Features

- **9 simultaneous equations** solved jointly each period
- **40 parameters** (37 calibrated, 3 computed)
- **Annual frequency** simulations (FY2026-FY2035 baseline)
- **Modular file structure** for easy extension and modification
- **Fast convergence** - Typically 1-2 solver iterations

---

## Model Structure

### Three Main Blocks

**1. Core Macro Block (9 equations)**
- Output gap with distributed lags
- Unemployment (Okun's law)
- Inflation (Phillips curve)
- Inflation expectations
- Federal funds rate (Taylor rule with r*)
- Expected fed funds (10-year)
- Term premium
- 10-year Treasury yield
- Effective interest rate on debt

**2. Fiscal Block**
- Before the solver: receipts and outlay ratios, including psi feedback, and potential GDP paths
- After each period's solve: primary balance, net interest (closed form), and debt

**3. Neutral Rate Block**
- r* responds to potential growth changes (`kappa_1`, `kappa_2`)
- r* responds to debt/GDP ratio (`kappa_3`)
- Smooth adjustment to new equilibrium

### Computational Flow

```
1. Pre-simulation block runs first
   -> Computes user-inclusive exogenous paths (including psi feedback) and potential GDP

2. Main solver loop for each period
   -> Solves 9 simultaneous equations

3. Post-solve calculations for each period
   -> Computes the primary balance, net interest, debt, and derived ratios
```

---

## Core Equations

### 1. Output Gap (Aggregate Demand)

```
xgap(t) = eta*xgap(t-1) + eta_2*xgap(t-2) + ... + eta_8*xgap(t-8)
          - sigma_0*(real_r10(t) - r10bar(t))
          - theta_1*Delta_rbudp_star(t) - theta_2*Delta_rbudp_star(t-1) + eps_xgap(t)
```

**Interpretation:**
- Output gap persists (distributed lags eta_1 through eta_8)
- Higher real long-term rates reduce demand (sigma_0 sensitivity)
- Fiscal tightening (Delta_rbudp_star > 0) is contractionary (theta_1, theta_2 multipliers)

**Key Parameters:**
- eta_1-eta_8: Distributed lag coefficients (sum to persistence)
- sigma_0 = 2.0: Interest rate sensitivity
- theta_1 = 1.0, theta_2 = 1.0: Fiscal multipliers

### 2. Unemployment (Okun's Law)

```
U(t) = UN(t) - alpha_1*xgap(t) - alpha_2*xgap(t-1) + eps_u(t)
```

**Interpretation:**
- Unemployment revolves around natural rate UN
- Positive output gap reduces unemployment
- Distributed lag structure (current + 1 lag)

**Key Parameters:**
- alpha_1 = 0.45: Current output gap effect
- alpha_2 = 0.15: Lagged output gap effect

### 3. Inflation (Phillips Curve)

```
PI(t) = gamma_1*PI(t-1) + (1-gamma_1)*PIE(t-1) + gamma_2*ugap(t) + eps_pi(t)

where: ugap(t) = U(t) - UN(t)
```

**Interpretation:**
- Inflation depends on past inflation (backward-looking)
- And expected inflation (forward-looking)
- Tight labor markets (ugap < 0) raise inflation

**Key Parameters:**
- gamma_1 = 0.5: Inflation persistence
- gamma_2 = 0.4: Phillips curve slope

### 4. Inflation Expectations

```
PIE(t) = lambda_1*PIE(t-1) + lambda_2*PI(t) + lambda_3*PISTAR(t) + eps_pie(t)
```

**Interpretation:**
- Adaptive component: lambda_1*PIE(t-1) (past expectations)
- Learning from data: lambda_2*PI(t) (current inflation)
- Anchoring: lambda_3*PISTAR(t) (central bank target)

**Key Parameters:**
- lambda_1 = 0.7: Expectations persistence
- lambda_2 = 0.2: Weight on current inflation
- lambda_3 = 0.1: Weight on target

### 5. Federal Funds Rate (Taylor Rule)

```
RF(t) = rfstar(t) + PIE(t) + mu_1*(PI(t) - PISTAR(t))
        + mu_2*(PIE(t) - PISTAR(t)) + mu_3*ugap(t) + eps_rf(t)
```

**Interpretation:**
- Neutral real rate rfstar(t) is **endogenous** (from neutral rate block)
- Fed responds to inflation deviations (mu_1, mu_2)
- Fed responds to unemployment gap (mu_3)
- Fisher equation: nominal = real + expected inflation

**Key Parameters:**
- mu_1 = 1.0: Response to current inflation deviation
- mu_2 = 0.0: Response to expected inflation deviation
- mu_3 = 1.0: Response to unemployment gap

### 6. Expected Federal Funds (10-Year)

```
MPE(t) = phi_1*RF(t) + (1-phi_1)*[rfstar(t) + PIE(t) + phi_2*(PIE(t) - PISTAR(t))] + eps_mpe(t)
```

**Interpretation:**
- Weighted average of current policy rate and long-run anchor
- Long-run anchor includes endogenous r* and expected inflation
- phi_2 captures additional inflation expectations adjustment

**Key Parameters:**
- phi_1 = 0.25: Weight on current fed funds
- phi_2 = 0.25: Inflation expectations adjustment

### 7. Term Premium

```
TP(t) = tp_0 + eps_tp(t)
```

**Interpretation:**
- Constant baseline term premium tp_0
- Shocks eps_tp(t) capture risk premium changes

**Key Parameters:**
- tp_0 = 0.8: Baseline term premium (pp)

### 8. 10-Year Treasury Yield

```
R10(t) = MPE(t) + TP(t)
```

**Interpretation:**
- Long rate = expected average short rate + term premium
- Standard expectations hypothesis with risk premium

### 9. Effective Interest Rate on Debt

```
RG(t) = delta_1*RG(t-1) + (1-delta_1)*[delta_2*RF(t) + (1-delta_2)*R10(t)] + eps_rg(t)
```

**Interpretation:**
- Weighted average of past rate (debt rollover)
- New issuance blends short and long rates
- Gradual adjustment to current market conditions

**Key Parameters:**
- delta_1 = 0.833: Effective rate smoothing
- delta_2 = 0.4: Weight on short rate

---

## Fiscal Block

Fiscal ratios and psi feedback are computed before the main solver loop. The primary balance, net interest, and debt are computed from the solved values after each period (`solver.R`).

### Components

**1. Labor Force Path**
```
LF(t) = LF(t-1) * (1 + glf(t)/100)
```

**2. Productivity Path**
```
PROD(t) = PROD(t-1) * (1 + gprod(t)/100)
```

**3. Potential GDP**
```
GDP*(t) = LF(t) * PROD(t)
```

**4. Potential GDP Growth**
```
g*(t) = (GDP*(t) - GDP*(t-1)) / GDP*(t-1) * 100
```

**5. Receipts**
```
RECEIPTS(t) = rgfr_star(t) * GDP$star(t) / 100
rgfr_star(t) = rgfr_star_base(t) + user_delta_rgfr(t)
```

`GDP$star` is nominal potential GDP (real potential GDP times the GDP price level).

**6. Primary Outlays (with fiscal feedback)**
```
OUTLAYS_PRIMARY(t) = rgfop_star(t) * GDP$star(t) / 100
rgfop_star(t) = rgfop_star_base(t) + LF_fb(t) + PROD_fb(t) + user_delta_rgfop(t)
LF_fb(t)   = LF_fb(t-1)   + psi_1 * (glfstar(t) - glfstar_base(t))
PROD_fb(t) = PROD_fb(t-1) + psi_2 * (glqstar(t) - glqstar_base(t))
```

`LF_fb` and `PROD_fb` start from zero in the last history year, so the first forecast year's deviation is included.

Where:
- psi_1 < 0: Outlays ratio falls when potential labor force growth accelerates
- psi_2 < 0: Outlays ratio falls when potential productivity growth accelerates

Both receipts and primary outlays scale with nominal potential GDP. Neither responds to the output gap or unemployment, so the model has no automatic stabilizers.

**7. Primary Balance**
```
rbudp_star(t) = rgfr_star(t) - rgfop_star(t)
BUDP(t) = rbudp_star(t) * GDP$star(t) / 100
```

**8. Debt Dynamics (Closed-Form Solution)**

Given the average-debt specification for net interest:
```
NI(t) = (D(t) + D(t-1))/2 * RG(t)/100
```

The system is solved algebraically:

```
D(t) = [(1 + 0.5*r(t)) * D(t-1) - BUDP(t)] / (1 - 0.5*r(t))

NI(t) = r(t) * [D(t-1) - 0.5*BUDP(t)] / (1 - 0.5*r(t))

BUD(t) = [BUDP(t) - r(t)*D(t-1)] / (1 - 0.5*r(t))

where r(t) = RG(t)/100
```

This eliminates simultaneity while preserving the economic structure.

**9. Debt/GDP Ratio**
```
D_pct_GDP(t) = D(t) / GDP$(t) * 100
```

---

## Neutral Rate Block

The neutral real interest rate (r*) is **endogenous** and responds to economic fundamentals.

### r* Equation

```
rfstar(t) = rfstar_base(t)
          + (t / 10) * [kappa_1 * (glfstar(t) - glfstar_base(t))
                        + kappa_2 * (glqstar(t) - glqstar_base(t))]
          + kappa_3 * (debt_proxy_user(t) - debt_proxy_base(t))
          + user_delta_rfstar_direct(t)
```

Where:
- **Growth channel:** same-year deviations of potential labor-force and productivity growth from baseline, phased in linearly with the simulation year (`t / 10`, 10% in the first forecast year, 100% in the tenth). The Excel workbook applies the full effect immediately; see `neutral_rate.R`.
- **Debt channel:** the gap between user and baseline debt proxies, a simplified debt/GDP recursion anchored on the baseline effective rate (`RG_base`).
- **Direct shocks:** `user_delta_rfstar_direct(t)` adds a user-specified change.

### Key Parameters

- kappa_1 = 2/3: r* response to potential labor-force growth deviation
- kappa_2 = 2/3: r* response to potential productivity growth deviation
- kappa_3 = 0.02: r* response to the debt-proxy gap

### Economic Interpretation

1. **Growth slowdown** -> r* falls -> more accommodative monetary policy
2. **High debt** -> r* rises -> tighter financial conditions (sustainability constraint)
3. **Productivity boom** -> r* rises -> Fed can raise rates without slowing economy

---

## Parameters

### Complete Parameter List

**Output Gap (9 parameters)**
```r
eta1 through eta8    # Distributed lag coefficients
sigma0 = 2.0         # Interest rate sensitivity
theta0 = 0.0         # Fiscal level effect
theta1 = 1.0         # Fiscal multiplier (current)
theta2 = 1.0         # Fiscal multiplier (lag)
```

**Unemployment (2 parameters)**
```r
alpha1 = 0.45        # Okun coefficient (current)
alpha2 = 0.15        # Okun coefficient (lag)
```

**Inflation (2 parameters)**
```r
gamma1 = 0.5         # Inflation persistence
gamma2 = 0.4         # Phillips curve slope
```

**Inflation Expectations (3 parameters)**
```r
lambda1 = 0.7        # Expectations persistence
lambda2 = 0.2        # Weight on current inflation
lambda3 = 0.1        # Weight on target
```

**Monetary Policy (3 parameters)**
```r
mu1 = 1.0            # Taylor rule inflation response
mu2 = 0.0            # Taylor rule expected inflation response
mu3 = 1.0            # Taylor rule unemployment response
```

**Term Structure (3 parameters)**
```r
phi1 = 0.25          # MPE weight on current RF
phi2 = 0.25          # MPE inflation adjustment
tp0 = 0.8            # Baseline term premium
```

**Effective Rate (2 parameters)**
```r
delta1 = 0.8333      # Effective rate smoothing
delta2 = 0.4         # Weight on short rate
```

**Neutral Rate (3 parameters)**
```r
kappa_1 = 2/3        # r* response to potential labor-force growth deviation
kappa_2 = 2/3        # r* response to potential productivity growth deviation
kappa_3 = 0.02       # r* response to the debt-proxy gap
```

**Fiscal Feedback (2 parameters)**
```r
psi1 = -0.134        # Labor force growth feedback (outlays ratio responds to LF growth)
psi2 = -0.229        # Productivity growth feedback (outlays ratio responds to productivity growth)
```

**Exogenous Variables (10 parameters/paths)**
```r
UN(t)                # Natural unemployment rate
PISTAR(t)            # Inflation target
glf(t)               # Labor force growth
gprod(t)             # Productivity growth
rgfr_star(t)         # Receipts as % of nominal potential GDP
rgfop_star(t)        # Primary outlays as % of nominal potential GDP (before psi feedback)
RG_base(t)           # Baseline effective interest rate on debt (debt-proxy anchor)
rfstar_shock(t)      # Direct r* shocks
epsxgap(t)           # Output gap shocks
epspi(t)             # Inflation shocks
epsrf(t)             # Monetary policy shocks
```

See `model/v1_8/parameters.R` for implementation.

---

## Model Files

### Modular Structure

The model is organized into separate files for maintainability:

```
model/v1_8/
├── simulation.R       # Main simulation engine (simulate_blsmm_v1_8)
├── solver.R           # Equation solver (solve_period_v1_8)
├── equations.R        # 9 core equations
├── parameters.R       # All 39 parameters with documentation
├── debt_proxy.R       # Fiscal block and debt dynamics
├── forcing.R          # Experimental endogenous-variable forcing module
├── neutral_rate.R     # Endogenous r* calculations
├── presim_block.R     # Pre-simulation setup
└── user_deltas.R      # User input processing
```

### File Descriptions

**simulation.R**
- Main entry point: `simulate_blsmm_v1_8()`
- Coordinates presim → solver loop → post-processing
- Handles initial conditions and data structures

**solver.R**
- Period-by-period equation solver
- Uses `nleqslv` package for Newton-Broyden method
- Returns solved endogenous variables

**equations.R**
- Defines all 9 simultaneous equations
- Pure functions: equations_v1_8(vars, params, forcing, lags)
- Clean separation of equation logic

**parameters.R**
- `create_default_parameters()` function
- All 39 parameters with documentation
- Easy to modify for sensitivity analysis

**debt_proxy.R**
- Fiscal block implementation
- Closed-form debt solution
- Fiscal feedback calculations

**forcing.R**
- Experimental module for overriding endogenous variables (xgap, u, pi, rf, etc.) with user-specified paths. See file header for current status and known limitations.

**neutral_rate.R**
- Endogenous r* calculations
- Growth and debt channels
- Returns rfstar(t) and rbar10(t)

**presim_block.R**
- Pre-simulation setup
- Computes potential GDP path
- Calculates primary balance with fiscal feedback

**user_deltas.R**
- Processes user inputs (9 types)
- Maps app tables to model variables
- Applies shocks to baseline

---

## Functions

### Main Simulation Function

```r
simulate_blsmm_v1_8(
  n_periods,              # Number of periods to simulate
  baseline_exog,          # Exogenous inputs data frame
  baseline_resid,         # Residuals for exact replication
  hist_data,              # Historical data for lags
  user_deltas = NULL,     # User shocks (9 types)
  forcing_spec = NULL,    # Advanced forcing options
  params = NULL,          # Custom parameters (default if NULL)
  expectations_speed = FALSE,  # Fast expectations adjustment
  verbose = FALSE         # Print diagnostics
)
```

**Returns:** Data frame with all endogenous and exogenous variables

### Helper Functions

**run_baseline_v1_8()**
```r
# Convenience wrapper for baseline simulation
results <- run_baseline_v1_8(n_periods = 10)
```

**create_default_parameters()**
```r
# Get all 39 parameters
params <- create_default_parameters()
```

**create_user_deltas()**
```r
# Create empty user deltas structure
deltas <- create_user_deltas(n_periods = 10)
```

---

## Data Inputs

### Required Data Files

Located in `data/` directory:

**blsmm_v1_8_baseline_solution.csv**
- Official baseline projection
- Used for validation
- Contains all variables (FY2026-FY2035)

**blsmm_v1_8_forecast_exog.csv**
- Exogenous variable paths
- Labor force growth, productivity, receipts, outlays
- Natural unemployment, inflation target

**blsmm_v1_8_forecast_resid.csv**
- Equation residuals for exact baseline replication
- 9 residual series (one per equation)
- Ensures model matches official baseline exactly

**blsmm_v1_8_historical.csv**
- Historical data for initial lags
- FY2018-FY2025 data
- Provides 8 lags for distributed lag structures

### Data Format

All CSV files use fiscal year labels (FY2026, FY2027, etc.) and include:
- `fy_label`: Fiscal year identifier
- Variable columns: Numeric values
- Comments: # prefix for metadata

---

## Validation

### Baseline Accuracy

The model replicates the official baseline with high precision:

| Variable | Max Error | Typical Error |
|----------|-----------|---------------|
| Output gap | < 0.01 pp | ~0.001 pp |
| Unemployment | < 0.01 pp | ~0.001 pp |
| Inflation | < 0.01 pp | ~0.001 pp |
| Fed funds | < 0.05 pp | ~0.01 pp |
| 10-year yield | < 0.05 pp | ~0.01 pp |
| Debt/GDP | < 0.1 pp | ~0.01 pp |

### Multiplier Validation

Fiscal multipliers consistent with empirical literature:

- **Impact multiplier** (Year 1): ~0.7
- **Peak multiplier** (Year 2-3): ~1.0-1.2
- **Long-run multiplier**: Near zero (Fed offset)

### Convergence

- **Typical iterations**: 1-2 per period
- **Tolerance**: 1e-6 on equation residuals
- **Success rate**: >99% for reasonable shocks

---

## Technical Notes

### Solver Algorithm

Uses Newton-Broyden method via `nleqslv` package:
- Hybrid approach: Newton with Broyden updates
- Robust to poor initial guesses
- Typically converges in 5-15 function evaluations

### Initial Conditions

Simulations start in FY2026 using FY2025 as initial conditions:
- All lags come from historical data
- Distributed lag structures use 8 periods of history
- Initial debt from historical data

### Fiscal Year Convention

All years are fiscal years (October 1 - September 30):
- FY2026 = Oct 1, 2025 - Sep 30, 2026
- Matches federal budget convention
- Consistent with official forecasts

### Real vs. Nominal

- GDP: Real (chained 2017 dollars)
- Interest rates: Nominal (%)
- Inflation: GDP price index (%)
- Real rates: Computed as nominal - expected inflation

---

## Extending the Model

### Adding New Equations

1. Edit `model/v1_8/equations.R`
2. Add equation to `equations_v1_8()` function
3. Update solver to include new endogenous variable
4. Add any new parameters to `parameters.R`

### Modifying Parameters

1. Edit `model/v1_8/parameters.R`
2. Update `create_default_parameters()` function
3. Document parameter meaning and source
4. Re-run validation tests

### Extending Horizon

1. Extend data files in `data/` to cover additional years
2. Update `N_PERIODS` constant
3. Ensure all lag structures are properly initialized

---

## References

For questions about model specification or implementation:

**Documentation:** See main README.md and README_App.md
**Support:** budget.lab@yale.edu
**Website:** https://budgetlab.yale.edu

---

**BLSMM Model Technical Documentation**
The Budget Lab at Yale | 2026
