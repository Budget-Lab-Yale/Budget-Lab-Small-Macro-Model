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
- **Fiscal feedback** - Automatic stabilizers and debt sustainability mechanisms
- **Rich dynamics** - Distributed lags and forward-looking expectations
- **Modular design** - Clean separation of components for maintainability

### Key Features

- **9 simultaneous equations** solved jointly each period
- **39 calibrated parameters** from empirical research
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

**2. Fiscal Block (Pre-simulation)**
- Labor force and productivity paths
- Potential GDP evolution
- Receipts and outlays (with fiscal feedback)
- Primary balance calculation
- Debt dynamics with closed-form solution
- Net interest payments

**3. Neutral Rate Block**
- r* responds to potential growth changes (κ₁, κ₂)
- r* responds to debt/GDP ratio (κ₃)
- Smooth adjustment to new equilibrium

### Computational Flow

```
1. Pre-simulation block runs first
   ↓ Computes potential GDP, primary balance, fiscal feedback

2. Main solver loop for each period
   ↓ Solves 9 simultaneous equations

3. Post-simulation calculations
   ↓ Computes derived variables, ratios, growth rates
```

---

## Core Equations

### 1. Output Gap (Aggregate Demand)

```
xgap(t) = η·xgap(t-1) + η₂·xgap(t-2) + ... + η₈·xgap(t-8)
          - σ₀·(real_r10(t) - r10bar(t))
          - θ₁·Δrbudp_star(t) - θ₂·Δrbudp_star(t-1) + ε_xgap(t)
```

**Interpretation:**
- Output gap persists (distributed lags η₁ through η₈)
- Higher real long-term rates reduce demand (σ₀ sensitivity)
- Fiscal tightening (Δrbudp_star > 0) is contractionary (θ₁, θ₂ multipliers)

**Key Parameters:**
- η₁-η₈: Distributed lag coefficients (sum to persistence)
- σ₀ = 2.0: Interest rate sensitivity
- θ₁ = 1.0, θ₂ = 1.0: Fiscal multipliers

### 2. Unemployment (Okun's Law)

```
U(t) = UN(t) - α₁·xgap(t) - α₂·xgap(t-1) + ε_u(t)
```

**Interpretation:**
- Unemployment revolves around natural rate UN
- Positive output gap reduces unemployment
- Distributed lag structure (current + 1 lag)

**Key Parameters:**
- α₁ = 0.45: Current output gap effect
- α₂ = 0.15: Lagged output gap effect

### 3. Inflation (Phillips Curve)

```
PI(t) = γ₁·PI(t-1) + (1-γ₁)·PIE(t-1) + γ₂·ugap(t) + ε_pi(t)

where: ugap(t) = U(t) - UN(t)
```

**Interpretation:**
- Inflation depends on past inflation (backward-looking)
- And expected inflation (forward-looking)
- Tight labor markets (ugap < 0) raise inflation

**Key Parameters:**
- γ₁ = 0.5: Inflation persistence
- γ₂ = 0.4: Phillips curve slope

### 4. Inflation Expectations

```
PIE(t) = λ₁·PIE(t-1) + λ₂·PI(t) + λ₃·PISTAR(t) + ε_pie(t)
```

**Interpretation:**
- Adaptive component: λ₁·PIE(t-1) (past expectations)
- Learning from data: λ₂·PI(t) (current inflation)
- Anchoring: λ₃·PISTAR(t) (central bank target)

**Key Parameters:**
- λ₁ = 0.7: Expectations persistence
- λ₂ = 0.2: Weight on current inflation
- λ₃ = 0.1: Weight on target

### 5. Federal Funds Rate (Taylor Rule)

```
RF(t) = rfstar(t) + PIE(t) + μ₁·(PI(t) - PISTAR(t))
        + μ₂·(PIE(t) - PISTAR(t)) + μ₃·ugap(t) + ε_rf(t)
```

**Interpretation:**
- Neutral real rate rfstar(t) is **endogenous** (from neutral rate block)
- Fed responds to inflation deviations (μ₁, μ₂)
- Fed responds to unemployment gap (μ₃)
- Fisher equation: nominal = real + expected inflation

**Key Parameters:**
- μ₁ = 1.0: Response to current inflation deviation
- μ₂ = 0.0: Response to expected inflation deviation
- μ₃ = 1.0: Response to unemployment gap

### 6. Expected Federal Funds (10-Year)

```
MPE(t) = φ₁·RF(t) + (1-φ₁)·[rfstar(t) + PIE(t) + φ₂·(PIE(t) - PISTAR(t))] + ε_mpe(t)
```

**Interpretation:**
- Weighted average of current policy rate and long-run anchor
- Long-run anchor includes endogenous r* and expected inflation
- φ₂ captures additional inflation expectations adjustment

**Key Parameters:**
- φ₁ = 0.25: Weight on current fed funds
- φ₂ = 0.25: Inflation expectations adjustment

### 7. Term Premium

```
TP(t) = tp₀ + ε_tp(t)
```

**Interpretation:**
- Constant baseline term premium tp₀
- Shocks ε_tp(t) capture risk premium changes

**Key Parameters:**
- tp₀ = 0.8: Baseline term premium (pp)

### 8. 10-Year Treasury Yield

```
R10(t) = MPE(t) + TP(t)
```

**Interpretation:**
- Long rate = expected average short rate + term premium
- Standard expectations hypothesis with risk premium

### 9. Effective Interest Rate on Debt

```
RG(t) = δ₁·RG(t-1) + (1-δ₁)·[δ₂·RF(t) + (1-δ₂)·R10(t)] + ε_rg(t)
```

**Interpretation:**
- Weighted average of past rate (debt rollover)
- New issuance blends short and long rates
- Gradual adjustment to current market conditions

**Key Parameters:**
- δ₁ = 0.833: Effective rate smoothing
- δ₂ = 0.4: Weight on short rate

---

## Fiscal Block

The fiscal block runs in the **pre-simulation phase** to compute potential GDP, primary balance, and fiscal feedback effects before the main solver loop.

### Components

**1. Labor Force Path**
```
LF(t) = LF(t-1) × (1 + glf(t)/100)
```

**2. Productivity Path**
```
PROD(t) = PROD(t-1) × (1 + gprod(t)/100)
```

**3. Potential GDP**
```
GDP*(t) = LF(t) × PROD(t)
```

**4. Potential GDP Growth**
```
g*(t) = (GDP*(t) - GDP*(t-1)) / GDP*(t-1) × 100
```

**5. Receipts**
```
RECEIPTS(t) = receipts_pct_gdp(t) × GDP$(t) / 100
```

**6. Primary Outlays (with fiscal feedback)**
```
OUTLAYS_PRIMARY(t) = outlays_pct_gdp(t) × GDP$(t) / 100
                     + ψ₁ × ugap(t) × GDP*(t)
                     + ψ₂ × D_pct_GDP(t) × GDP*(t)
```

Where:
- ψ₁ < 0: Outlays rise when unemployment is high (automatic stabilizers)
- ψ₂ < 0: Outlays fall when debt/GDP is high (fiscal consolidation)

**7. Primary Balance**
```
BUDP(t) = RECEIPTS(t) - OUTLAYS_PRIMARY(t)
rbudp_star(t) = BUDP(t) / GDP*(t) × 100
```

**8. Debt Dynamics (Closed-Form Solution)**

Given the average-debt specification for net interest:
```
NI(t) = (D(t) + D(t-1))/2 × RG(t)/100
```

The system is solved algebraically:

```
D(t) = [(1 + 0.5·r(t)) × D(t-1) - BUDP(t)] / (1 - 0.5·r(t))

NI(t) = r(t) × [D(t-1) - 0.5·BUDP(t)] / (1 - 0.5·r(t))

BUD(t) = [BUDP(t) - r(t)·D(t-1)] / (1 - 0.5·r(t))

where r(t) = RG(t)/100
```

This eliminates simultaneity while preserving the economic structure.

**9. Debt/GDP Ratio**
```
D_pct_GDP(t) = D(t) / GDP$(t) × 100
```

---

## Neutral Rate Block

The neutral real interest rate (r*) is **endogenous** and responds to economic fundamentals.

### r* Equation

```
rfstar(t) = κ₁ × g*(t) + κ₂ × Δg*(t) + κ₃ × f(D_pct_GDP(t)) + rfstar_shock(t)
```

Where:
- **Potential Growth Channel:** κ₁ captures long-run relationship between r* and growth
- **Growth Change Channel:** κ₂ captures transitional dynamics
- **Debt Channel:** κ₃ captures fiscal sustainability effects on r*
- **Direct Shocks:** rfstar_shock(t) allows user to override

### Functional Forms

**Potential Growth Response:**
```
κ₁ × g*(t)  where κ₁ > 0
```
Higher potential growth → higher r*

**Growth Change Response:**
```
κ₂ × Δg*(t)  where κ₂ > 0
```
Accelerating growth → temporarily higher r*

**Debt Response:**
```
κ₃ × f(D_pct_GDP(t))  where κ₃ > 0
```
Higher debt/GDP → higher r* (risk premium channel)

### Key Parameters

- κ₁ = 1.0: Long-run r* sensitivity to potential growth
- κ₂ = 0.5: Transitional r* sensitivity to growth changes
- κ₃ = 0.01: r* sensitivity to debt/GDP

### Economic Interpretation

1. **Growth slowdown** → r* falls → more accommodative monetary policy
2. **High debt** → r* rises → tighter financial conditions (sustainability constraint)
3. **Productivity boom** → r* rises → Fed can raise rates without slowing economy

---

## Parameters

### Complete Parameter List (39 total)

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
kappa1 = 1.0         # r* sensitivity to potential growth
kappa2 = 0.5         # r* sensitivity to growth changes
kappa3 = 0.01        # r* sensitivity to debt/GDP
```

**Fiscal Feedback (2 parameters)**
```r
psi1 = -0.05         # Automatic stabilization (outlays respond to ugap)
psi2 = -0.01         # Debt sustainability (outlays respond to D/GDP)
```

**Exogenous Variables (10 parameters/paths)**
```r
UN(t)                # Natural unemployment rate
PISTAR(t)            # Inflation target
glf(t)               # Labor force growth
gprod(t)             # Productivity growth
receipts_pct_gdp(t)  # Receipts as % GDP
outlays_pct_gdp(t)   # Outlays as % GDP (before feedback)
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
├── forcing.R          # Forcing variables (GDP*, r*, etc.)
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
- Computes forcing variables (GDP*, r*, etc.)
- Called before solver each period
- Provides context for equation system

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
