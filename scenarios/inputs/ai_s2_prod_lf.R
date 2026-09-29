# LF deltas: Karger et al. (2026) Moderate Economists LFPR medians (60.7% in
# 2030, 57.0% in 2050; Tables 25-26), converted from calendar to fiscal years.
#
# Implied LFPR path (FY2025 labor force 171.557 million):
#   FY2026: 62.09%   FY2031: 60.26%
#   FY2027: 61.71%   FY2032: 59.97%
#   FY2028: 61.33%   FY2033: 59.71%
#   FY2029: 60.95%   FY2034: 59.46%
#   FY2030: 60.57%   FY2035: 59.24%

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
