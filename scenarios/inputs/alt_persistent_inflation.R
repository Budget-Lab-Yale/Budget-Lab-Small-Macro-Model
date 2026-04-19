# Target: inflation ~2.5% through FY2029, converging to 2.0% by ~FY2032.
# Tuned in Phase 6 - Final (Iteration 3)
# Final shock values produce:
#   FY2026-2029: ~2.5% (target 2.5%)
#   FY2030: ~2.4% (target 2.4%)
#   FY2031: ~2.3% (target 2.3%)
#   FY2032-2035: converges toward 2.0%
scenario <- list(
  id    = "alt_persistent_inflation",
  label = "Inflation scenario",
  color = "#2166AC",
  user_deltas = list(
    # FY2026-2035 - Final tuned values
    user_delta_inflshock = c(-0.313, 0.191, 0.31, 0.296, 0.176, 0.115, 0.061, -0.002, -0.053, -0.023)
  )
)
