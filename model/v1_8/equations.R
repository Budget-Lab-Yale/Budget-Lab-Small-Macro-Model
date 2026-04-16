# ==============================================================================
# BLSMM Equation Definitions
# ==============================================================================
# Defines all structural equations for the macroeconomic model.
# 9 simultaneous equations solved jointly via Newton-Broyden method.
# ==============================================================================

# ==============================================================================
# STRUCTURAL SIMULTANEOUS BLOCK
# ==============================================================================

#' Output Gap Equation - 8-Period Distributed Lags
#'
#' Aggregate demand equation with distributed lags on interest rates and fiscal policy.
#'
#' Formula: xgap_struct = eta*xgap(-1)
#'                        - SUM[i=0..7] sigma_i * (R10(-i) - PIE(-i) - rbar10(-i))
#'                        - SUM[i=0..7] theta_i * rbudp*(-i)
#'
#' CRITICAL: This is the STRUCTURAL value before adding residual and before forcing.
#' The actual xgap may differ if forcing is active.
#'
#' @param xgap_lag Lagged output gap (t-1)
#' @param R10_vec Vector of length 8: [R10(t), R10(t-1), ..., R10(t-7)]
#' @param PIE_vec Vector of length 8: [PIE(t), PIE(t-1), ..., PIE(t-7)]
#' @param rbar10_vec Vector of length 8: [rbar10(t), rbar10(t-1), ..., rbar10(t-7)]
#' @param rbudp_star_vec Vector of length 8: [rbudp*(t), rbudp*(t-1), ..., rbudp*(t-7)]
#' @param params Parameter list from create_parameters_v1_8()
#' @return Structural output gap (before residual)
output_gap_struct_v1_8 <- function(xgap_lag, R10_vec, PIE_vec, rbar10_vec,
                                   rbudp_star_vec, params) {

  # Verify input vectors have length 8
  if (length(R10_vec) != 8 || length(PIE_vec) != 8 ||
      length(rbar10_vec) != 8 || length(rbudp_star_vec) != 8) {
    stop("All lag vectors must have length 8 (current + 7 lags)")
  }

  # Extract sigma parameters
  sigma_vec <- c(params$sigma_0, params$sigma_1, params$sigma_2, params$sigma_3,
                 params$sigma_4, params$sigma_5, params$sigma_6, params$sigma_7)

  # Extract theta parameters
  theta_vec <- c(params$theta_0, params$theta_1, params$theta_2, params$theta_3,
                 params$theta_4, params$theta_5, params$theta_6, params$theta_7)

  # Calculate real rate deviations for all 8 lags
  real_r10_dev_vec <- R10_vec - PIE_vec - rbar10_vec

  # Distributed lag sums
  real_rate_effect <- sum(sigma_vec * real_r10_dev_vec)
  fiscal_effect <- sum(theta_vec * rbudp_star_vec)

  # Structural output gap
  xgap_struct <- params$eta * xgap_lag - real_rate_effect - fiscal_effect

  return(xgap_struct)
}

#' Unemployment Equation - Structural
#'
#' PDF Section 3.5, row 157
#' Formula: U_struct = UN - alpha_1*xgap - alpha_2*xgap(-1)
#'
#' @param UN Natural rate of unemployment (NAIRU)
#' @param xgap Current period output gap (from solver guess)
#' @param xgap_lag Lagged output gap
#' @param params Parameter list
#' @return Structural unemployment rate
unemployment_struct_v1_8 <- function(UN, xgap, xgap_lag, params) {
  U_struct <- UN - params$alpha_1 * xgap - params$alpha_2 * xgap_lag
  return(U_struct)
}

#' Inflation Equation - Structural
#'
#' PDF Section 3.5, row 158
#' Formula: PI_struct = gamma_1*PI(-1) + (1-gamma_1)*PIE(-1) + gamma_2*(UN - U)
#'
#' @param PI_lag Lagged inflation
#' @param PIE_lag Lagged expected inflation
#' @param UN Natural rate
#' @param U Current unemployment (from solver guess)
#' @param params Parameter list
#' @return Structural inflation rate
inflation_struct_v1_8 <- function(PI_lag, PIE_lag, UN, U, params) {
  ugap <- UN - U
  PI_struct <- params$gamma_1 * PI_lag +
               (1 - params$gamma_1) * PIE_lag +
               params$gamma_2 * ugap
  return(PI_struct)
}

#' Expected Inflation Equation - Structural
#'
#' PDF Section 3.5, row 159
#' Formula: PIE_struct = lambda_1*PIE(-1) + lambda_2*PI + lambda_3*PISTAR
#'
#' @param PIE_lag Lagged expected inflation
#' @param PI Current inflation (from solver guess)
#' @param PISTAR Inflation target
#' @param params Parameter list
#' @param expectations_speed Optional fast adjustment mode
#' @return Structural expected inflation
expected_inflation_struct_v1_8 <- function(PIE_lag, PI, PISTAR, params,
                                           expectations_speed = FALSE) {
  if (isTRUE(expectations_speed)) {
    # Fast adjustment: more weight on current inflation
    lambda_1 <- 0.40
    lambda_2 <- 0.50
    lambda_3 <- 0.10
  } else {
    lambda_1 <- params$lambda_1
    lambda_2 <- params$lambda_2
    lambda_3 <- params$lambda_3
  }

  PIE_struct <- lambda_1 * PIE_lag + lambda_2 * PI + lambda_3 * PISTAR
  return(PIE_struct)
}

#' Federal Funds Rate Equation - Structural
#'
#' PDF Section 3.5, row 160
#' Formula: RF_struct = rfstar + PI + mu_1*(PI - PISTAR) + mu_2*(PIE - PISTAR) + mu_3*(UN - U)
#'
#' @param rfstar Neutral real federal funds rate
#' @param PI Current inflation (from solver guess)
#' @param PIE Current expected inflation (from solver guess)
#' @param PISTAR Inflation target
#' @param UN Natural rate
#' @param U Current unemployment (from solver guess)
#' @param params Parameter list
#' @return Structural federal funds rate
federal_funds_struct_v1_8 <- function(rfstar, PI, PIE, PISTAR, UN, U, params) {
  ugap <- UN - U
  RF_struct <- rfstar + PI +
               params$mu_1 * (PI - PISTAR) +
               params$mu_2 * (PIE - PISTAR) +
               params$mu_3 * ugap
  return(RF_struct)
}

#' Expected Federal Funds Rate (10-year average) - Structural
#'
#' PDF Section 3.5, row 161
#' Formula: MPE10_struct = phi_1*RF + (1-phi_1)*(rfstar + PIE + phi_2*(PIE - PISTAR))
#'
#' @param RF Current federal funds rate (from solver guess)
#' @param rfstar Neutral real federal funds rate
#' @param PIE Current expected inflation (from solver guess)
#' @param PISTAR Inflation target
#' @param params Parameter list
#' @return Structural MPE10
mpe10_struct_v1_8 <- function(RF, rfstar, PIE, PISTAR, params) {
  anchor <- rfstar + PIE + params$phi_2 * (PIE - PISTAR)
  MPE10_struct <- params$phi_1 * RF + (1 - params$phi_1) * anchor
  return(MPE10_struct)
}

#' Term Premium Equation - Structural
#'
#' PDF Section 3.5, row 162
#' Formula: TP_struct = tp_0
#'
#' @param tp_0 Baseline term premium assumption
#' @return Structural term premium
term_premium_struct_v1_8 <- function(tp_0) {
  TP_struct <- tp_0
  return(TP_struct)
}

#' Effective Interest Rate - Structural
#'
#' PDF Section 3.5, row 163
#' Formula: RG_struct = delta_1*RG(-1) + (1-delta_1)*(delta_2*RF + (1-delta_2)*R10)
#'
#' @param RG_lag Lagged effective rate
#' @param RF Current federal funds rate (from solver guess)
#' @param R10 Current 10-year rate (from solver guess)
#' @param params Parameter list
#' @return Structural effective interest rate
effective_rate_struct_v1_8 <- function(RG_lag, RF, R10, params) {
  market_rate_mix <- params$delta_2 * RF + (1 - params$delta_2) * R10
  RG_struct <- params$delta_1 * RG_lag + (1 - params$delta_1) * market_rate_mix
  return(RG_struct)
}

# ==============================================================================
# IDENTITY BLOCK (Section 3.7)
# ==============================================================================

#' 10-Year Treasury Yield Identity
#'
#' PDF Section 3.7, row 168
#' Formula: R10 = MPE10 + TP
#'
#' @param MPE10 Expected federal funds rate
#' @param TP Term premium
#' @return 10-year Treasury yield
r10_yield_v1_8 <- function(MPE10, TP) {
  R10 <- MPE10 + TP
  return(R10)
}

#' Real GDP Identity
#'
#' PDF Section 3.7, row 166
#' Formula: GDP = GDPstar * (1 + xgap/100)
#'
#' @param GDPstar Potential real GDP
#' @param xgap Output gap (percent)
#' @return Real GDP
real_gdp_v1_8 <- function(GDPstar, xgap) {
  GDP <- GDPstar * (1 + xgap/100)
  return(GDP)
}

#' Price Level Identity
#'
#' PDF Section 3.7, row 170
#' Formula: PGDP = PGDP(-1) * (1 + PI/100)
#'
#' @param PGDP_lag Lagged price level
#' @param PI Current inflation rate (percent)
#' @return Price level
price_level_v1_8 <- function(PGDP_lag, PI) {
  PGDP <- PGDP_lag * (1 + PI/100)
  return(PGDP)
}

#' Nominal Potential GDP Identity
#'
#' PDF Section 3.7, row 171
#' Formula: GDP$star = GDPstar * PGDP / 100
#'
#' @param GDPstar Potential real GDP
#' @param PGDP Price level
#' @return Nominal potential GDP
nominal_potential_gdp_v1_8 <- function(GDPstar, PGDP) {
  GDP_dollar_star <- GDPstar * PGDP / 100
  return(GDP_dollar_star)
}

#' Nominal GDP Identity
#'
#' PDF Section 3.7, row 172
#' Formula: GDP$ = GDP * PGDP / 100
#'
#' @param GDP Real GDP
#' @param PGDP Price level
#' @return Nominal GDP
nominal_gdp_v1_8 <- function(GDP, PGDP) {
  GDP_dollar <- GDP * PGDP / 100
  return(GDP_dollar)
}

#' Primary Budget Balance Identity
#'
#' PDF Section 3.7, row 173
#' Formula: BUDP = GDP$star * rbudp* / 100
#'
#' @param GDP_dollar_star Nominal potential GDP
#' @param rbudp_star Primary budget as percent of potential GDP
#' @return Primary budget balance (billions)
primary_budget_v1_8 <- function(GDP_dollar_star, rbudp_star) {
  BUDP <- GDP_dollar_star * rbudp_star / 100
  return(BUDP)
}

#' Net Interest Payments
#'
#' PDF Section 3.7, row 180
#' Formula: NI = 0.5 * (D(-1) + D) * RG / 100
#'
#' Note: This creates simultaneity. Using closed-form solution:
#' NI = (RG/100) * (D(-1) - 0.5*BUDP) / (1 - 0.5*RG/100)
#'
#' @param D_lag Lagged publicly held debt
#' @param BUDP Primary budget balance
#' @param RG Effective interest rate (percent)
#' @return Net interest payments (billions)
net_interest_v1_8 <- function(D_lag, BUDP, RG) {
  r <- RG / 100
  NI <- r * (D_lag - 0.5 * BUDP) / (1 - 0.5 * r)
  return(NI)
}

#' Budget Balance Identity
#'
#' PDF Section 3.7, row 182
#' Formula: BUD = BUDP - NI
#'
#' @param BUDP Primary budget balance
#' @param NI Net interest payments
#' @return Total budget balance (billions, negative = deficit)
budget_balance_v1_8 <- function(BUDP, NI) {
  BUD <- BUDP - NI
  return(BUD)
}

#' Publicly Held Debt Evolution
#'
#' PDF Section 3.7, row 181
#' Formula: D = D(-1) - BUD
#'
#' @param D_lag Lagged debt
#' @param BUD Budget balance (negative = deficit)
#' @return Publicly held debt (billions)
debt_evolution_v1_8 <- function(D_lag, BUD) {
  D <- D_lag - BUD
  return(D)
}
