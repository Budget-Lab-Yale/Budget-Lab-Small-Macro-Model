# Karger (2024) Rapid Adoption variant. Productivity = 3.5% NFB output/hour
# (Karger Rapid Total median, 2030 anchor held flat — Karger 2050 anchor is 4.0%
# but the modest 2030->2050 ramp barely shows in the 2026-2035 window) less the
# CBO output/hour vs GDP/employed wedge of 0.319 pp. Yields flat lq* ~3.181%.
# LF deltas reused from ai_s2_prod_lf.R; Karger Rapid LFPR target (~59.8%) is
# closer to the existing calibration but not exact. Left as-is pending refresh.
scenario <- list(
  id    = "ai_rapid",
  label = "Rapid: Prod+LF",
  color = "#B2182B",
  user_deltas = list(
    user_delta_prod = c(1.581,
                        1.459,
                        1.493,
                        1.557,
                        1.612,
                        1.684,
                        1.724,
                        1.752,
                        1.774,
                        1.792),
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
