# Karger (2024) Slow Adoption variant. Productivity = 2.0% NFB output/hour
# (Karger Slow Total median, flat across 2030 and 2050) less the CBO output/hour
# vs GDP/employed wedge of 0.319 pp. Yields flat lq* ~1.681%.
# LF deltas reused from ai_s2_prod_lf.R; Karger Slow LFPR target (~62%) differs
# slightly from the calibration target there but is left as-is pending refresh.
scenario <- list(
  id    = "ai_slow",
  label = "Slow: Prod+LF",
  color = "#4393C3",
  user_deltas = list(
    user_delta_prod = c(0.081,
                        -0.041,
                        -0.007,
                        0.057,
                        0.112,
                        0.184,
                        0.224,
                        0.252,
                        0.274,
                        0.292),
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
