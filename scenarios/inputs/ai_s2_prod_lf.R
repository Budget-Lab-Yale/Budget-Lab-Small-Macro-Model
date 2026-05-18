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
  # user_delta_prod: Karger (2024) Moderate NFB output/hour growth (~2.5%) less the
  # CBO output/hour-vs-GDP/employed wedge (-0.319 pp, 2031-35 avg). Yields flat lq* ~2.18%.
  user_deltas = list(
    user_delta_prod = c(0.581,
                        0.461,
                        0.491,
                        0.561,
                        0.611,
                        0.681,
                        0.721,
                        0.751,
                        0.771,
                        0.791),
    user_delta_lf   = c(-0.519291223,
                        -0.517304306,
                        -0.514715591,
                        -0.505703745,
                        -0.507477379,
                        -0.427200888,
                        -0.391830856,
                        -0.372017336,
                        -0.377888501,
                        -0.379559281)
  )
)
