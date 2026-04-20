# LF deltas from the corrected internal LFPR calibration file,
# "LF Growth Delta (pp)" column.
#
# Source: Karger et al. Table 25, properly converted from CY to FY.
# These values replace an earlier calibration that reached the target
# LFPR too late in the forecast window.
#
# Expected LFPR path produced by these deltas (using BLSMM anchor):
#   FY2026: 61.81%   FY2031: 59.17%
#   FY2027: 61.15%   FY2032: 59.17%
#   FY2028: 60.49%   FY2033: 59.17%
#   FY2029: 59.83%   FY2034: 59.17%
#   FY2030: 59.17%   FY2035: 59.17%
#
# LFPR hits ~59.3% at FY2030 (matching Karger's stated target),
# then holds flat through FY2035.
#
# The small POSITIVE values in FY2031-2034 are correct: to hold
# LFPR flat at 59.2% while population grows ~0.4-0.5% per year,
# the labor force must grow at roughly that same rate. In years
# where this required growth exceeds CBO baseline growth, the delta
# is positive. That reflects the labor force keeping pace with
# population growth, not workers re-entering relative to the target.

scenario <- list(
  id    = "ai_s2_prod_lf",
  label = "S2: Prod+LF",
  color = "#E8601C",
  user_deltas = list(
    user_delta_prod = c(1.60, 1.50, 1.50, 1.60, 1.60,
                        1.70, 1.70, 1.80, 1.80, 1.80),
    user_delta_lf   = c(-0.970721149839408,
                        -0.9754136575901038,
                        -0.9805932852958139,
                        -0.9796612370806357,
                        -0.9897753880747566,
                         0.09195901775637783,
                         0.08816839320827746,
                         0.0715411112743643,
                         0.031805969525750266,
                        -0.001241724459414617)
  )
)
