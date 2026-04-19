# LF deltas computed via convert_lfpr_to_growth() from app/R/blsmm_helpers.R
# using BLSMM's FY2025 LFstar anchor (171.557) and CBO Feb 2026 CNP series.
# These produce LFPR declining linearly from ~62.5% (FY2025) to exactly 59.3%
# at FY2030, then held flat at 59.3% through FY2035.
# The small positive values in FY2031-2034 are required to keep LFPR flat
# while population grows.

scenario <- list(
  id    = "ai_s2_prod_lf",
  label = "S2: Prod+LF",
  color = "#E8601C",
  user_deltas = list(
    user_delta_prod = c(1.60, 1.50, 1.50, 1.60, 1.60,
                        1.70, 1.70, 1.80, 1.80, 1.80),
    user_delta_lf   = c(-0.9288, -0.9332, -0.9378, -0.9360, -0.9450,
                         0.0920,  0.0875,  0.0716,  0.0312, -0.0018)
  )
)