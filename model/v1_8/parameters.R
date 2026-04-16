# ==============================================================================
# BLSMM Parameter Definitions
# ==============================================================================
# Defines all 39 calibrated parameters for the structural macroeconomic model.
# Parameters are calibrated to U.S. data and empirical literature.
# ==============================================================================

#' Create Parameter Set
#'
#' Returns all 39 parameters from BLSMM (36 primary + 3 computed)
#' Key features:
#'   - Output gap: 8-period distributed lags (17 parameters total: eta + 8 sigma + 8 theta)
#'   - Behavioral parameters: Okun (alpha), Phillips (gamma), expectations (lambda)
#'   - Neutral rate parameters: kappa_1, kappa_2, kappa_3
#'   - Fiscal feedback parameters: psi_1, psi_2
#'
#' @return Named list of 39 parameters (36 primary calibrated + 3 computed)
create_parameters_v1_8 <- function() {
  params <- list(
    # ========================================================================
    # OUTPUT GAP EQUATION (17 parameters)
    # ========================================================================
    # Lagged output gap
    eta = 0.4,           # Coefficient on xgap(-1)

    # Real rate distributed lag (8 periods)
    # Applied to (R10 - PIE - rbar10) at lags 0 through 7
    sigma_0 = 1.2,       # t (current period)
    sigma_1 = 2.0,       # t-1
    sigma_2 = 0.9,       # t-2
    sigma_3 = 0.8,       # t-3
    sigma_4 = 0.5,       # t-4
    sigma_5 = 0.25,      # t-5
    sigma_6 = 0,         # t-6
    sigma_7 = 0,         # t-7

    # Fiscal distributed lag (8 periods)
    # Applied to rbudp* at lags 0 through 7
    theta_0 = 1.3,       # t (current period)
    theta_1 = 0.4,       # t-1
    theta_2 = 0.4,       # t-2
    theta_3 = 0.3,       # t-3
    theta_4 = 0.2,       # t-4
    theta_5 = 0.1,       # t-5
    theta_6 = 0,         # t-6
    theta_7 = 0,         # t-7

    # ========================================================================
    # UNEMPLOYMENT EQUATION (2 parameters)
    # ========================================================================
    alpha_1 = 0.4,       # Coefficient on xgap(t)
    alpha_2 = 0.2,       # Coefficient on xgap(t-1)

    # ========================================================================
    # INFLATION EQUATION (2 parameters)
    # ========================================================================
    gamma_1 = 0.5,       # Weight on PI(-1) vs PIE(-1)
    gamma_2 = 0.25,      # Coefficient on unemployment gap

    # ========================================================================
    # EXPECTED INFLATION EQUATION (3 parameters)
    # ========================================================================
    lambda_1 = 0.6,      # Weight on PIE(-1)
    lambda_2 = 0.3,      # Weight on PI(t)
    lambda_3 = 0.1,      # Weight on PISTAR

    # ========================================================================
    # FEDERAL FUNDS RATE EQUATION (3 parameters)
    # ========================================================================
    mu_1 = 1.0,          # Coefficient on (PI - PISTAR)
    mu_2 = 0.0,          # Coefficient on (PIE - PISTAR)
    mu_3 = 1.0,          # Coefficient on unemployment gap

    # ========================================================================
    # MPE10 EQUATION (2 parameters)
    # ========================================================================
    phi_1 = 0.25,        # Weight on current RF
    phi_2 = 0.25,        # Coefficient on (PIE - PISTAR) in anchor

    # ========================================================================
    # EFFECTIVE INTEREST RATE EQUATION (2 parameters)
    # ========================================================================
    delta_1 = 5/6,       # Coefficient on RG(-1)
    delta_2 = 0.4,       # Weight on RF vs R10

    # ========================================================================
    # NEUTRAL RATE / RBAR10 PARAMETERS (3 NEW parameters)
    # ========================================================================
    kappa_1 = 2/3,       # Labor force growth effect on rfstar (0.6666666666)
    kappa_2 = 2/3,       # Productivity growth effect on rfstar (0.6666666666)
    kappa_3 = 0.02,      # Debt proxy effect on rfstar

    # ========================================================================
    # FISCAL FEEDBACK PARAMETERS (2 NEW parameters)
    # ========================================================================
    psi_1 = -0.134,      # Labor force growth to outlays ratio
    psi_2 = -0.229       # Productivity growth to outlays ratio
  )

  # Add computed parameters
  params$theta_sum <- params$theta_0 + params$theta_1 + params$theta_2 + params$theta_3 +
                      params$theta_4 + params$theta_5 + params$theta_6 + params$theta_7
  # theta_sum = 2.7

  params$sigma_sum <- params$sigma_0 + params$sigma_1 + params$sigma_2 + params$sigma_3 +
                      params$sigma_4 + params$sigma_5 + params$sigma_6 + params$sigma_7
  # sigma_sum = 5.65

  params$theta_sigma_ratio <- params$theta_sum / params$sigma_sum
  # theta_sigma_ratio = 2.7 / 5.65 = 0.4778761061946903 ≈ 0.478

  return(params)
}

#' Print Parameter Summary
#'
#' Displays all v1.8 parameters with their values
print_parameters_v1_8 <- function(params = NULL) {
  if (is.null(params)) params <- create_parameters_v1_8()

  cat("\n")
  cat("================================================================================\n")
  cat("  BLSMM v1.8 Parameter Summary\n")
  cat("================================================================================\n\n")

  cat("OUTPUT GAP EQUATION (16 parameters):\n")
  cat(sprintf("  eta        = %.2f (lagged output gap)\n", params$eta))
  cat("\n  Real rate distributed lag (sigma):\n")
  cat(sprintf("    sigma_0  = %.2f (current)\n", params$sigma_0))
  cat(sprintf("    sigma_1  = %.2f (t-1)\n", params$sigma_1))
  cat(sprintf("    sigma_2  = %.2f (t-2)\n", params$sigma_2))
  cat(sprintf("    sigma_3  = %.2f (t-3)\n", params$sigma_3))
  cat(sprintf("    sigma_4  = %.2f (t-4)\n", params$sigma_4))
  cat(sprintf("    sigma_5  = %.2f (t-5)\n", params$sigma_5))
  cat(sprintf("    sigma_6  = %.2f (t-6)\n", params$sigma_6))
  cat(sprintf("    sigma_7  = %.2f (t-7)\n", params$sigma_7))
  cat(sprintf("    SUM      = %.2f\n", params$sigma_sum))
  cat("\n  Fiscal distributed lag (theta):\n")
  cat(sprintf("    theta_0  = %.2f (current)\n", params$theta_0))
  cat(sprintf("    theta_1  = %.2f (t-1)\n", params$theta_1))
  cat(sprintf("    theta_2  = %.2f (t-2)\n", params$theta_2))
  cat(sprintf("    theta_3  = %.2f (t-3)\n", params$theta_3))
  cat(sprintf("    theta_4  = %.2f (t-4)\n", params$theta_4))
  cat(sprintf("    theta_5  = %.2f (t-5)\n", params$theta_5))
  cat(sprintf("    theta_6  = %.2f (t-6)\n", params$theta_6))
  cat(sprintf("    theta_7  = %.2f (t-7)\n", params$theta_7))
  cat(sprintf("    SUM      = %.2f\n", params$theta_sum))
  cat(sprintf("  theta/sigma ratio = %.4f (used in rbar10 calc)\n", params$theta_sigma_ratio))

  cat("\nUNEMPLOYMENT EQUATION (2 parameters):\n")
  cat(sprintf("  alpha_1    = %.2f\n", params$alpha_1))
  cat(sprintf("  alpha_2    = %.2f\n", params$alpha_2))

  cat("\nINFLATION EQUATION (2 parameters):\n")
  cat(sprintf("  gamma_1    = %.2f\n", params$gamma_1))
  cat(sprintf("  gamma_2    = %.2f\n", params$gamma_2))

  cat("\nEXPECTED INFLATION EQUATION (3 parameters):\n")
  cat(sprintf("  lambda_1   = %.2f\n", params$lambda_1))
  cat(sprintf("  lambda_2   = %.2f\n", params$lambda_2))
  cat(sprintf("  lambda_3   = %.2f\n", params$lambda_3))

  cat("\nFEDERAL FUNDS RATE EQUATION (3 parameters):\n")
  cat(sprintf("  mu_1       = %.2f\n", params$mu_1))
  cat(sprintf("  mu_2       = %.2f\n", params$mu_2))
  cat(sprintf("  mu_3       = %.2f\n", params$mu_3))

  cat("\nMPE10 EQUATION (2 parameters):\n")
  cat(sprintf("  phi_1      = %.2f\n", params$phi_1))
  cat(sprintf("  phi_2      = %.2f\n", params$phi_2))

  cat("\nEFFECTIVE INTEREST RATE EQUATION (2 parameters):\n")
  cat(sprintf("  delta_1    = %.4f (5/6)\n", params$delta_1))
  cat(sprintf("  delta_2    = %.2f\n", params$delta_2))

  cat("\nNEUTRAL RATE / RBAR10 PARAMETERS (3 NEW parameters):\n")
  cat(sprintf("  kappa_1    = %.4f (2/3) [LF growth effect]\n", params$kappa_1))
  cat(sprintf("  kappa_2    = %.4f (2/3) [Prod growth effect]\n", params$kappa_2))
  cat(sprintf("  kappa_3    = %.2f [Debt proxy effect]\n", params$kappa_3))

  cat("\nFISCAL FEEDBACK PARAMETERS (2 NEW parameters):\n")
  cat(sprintf("  psi_1      = %.3f [LF to outlays]\n", params$psi_1))
  cat(sprintf("  psi_2      = %.3f [Prod to outlays]\n", params$psi_2))

  cat("\n================================================================================\n")
  cat(sprintf("Total parameters: 39 (36 primary calibrated + 3 computed)\n"))
  cat(sprintf("  Primary: 36 | Computed: 3 (theta_sum, sigma_sum, theta_sigma_ratio)\n"))
  cat("================================================================================\n\n")
}
