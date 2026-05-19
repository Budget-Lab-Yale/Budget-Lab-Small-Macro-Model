# Karger (2024) Rapid Adoption variant, anchored to the Economists response.
# Productivity target: 3.2% NFB output/hour (Karger Rapid Economists 2030 anchor,
# held flat) less the 0.319 pp CBO concept wedge, yielding flat lq* ~2.881%.
# LF deltas reused from ai_s2_prod_lf.R; Karger Rapid LFPR target (~59.8%) is
# close to the existing calibration but not exact.
scenario <- list(
  id    = "ai_rapid",
  label = "Rapid: Prod+LF",
  color = "#B2182B",
  user_deltas = list(
    user_delta_prod = c(1.281,
                        1.159,
                        1.193,
                        1.257,
                        1.312,
                        1.384,
                        1.424,
                        1.452,
                        1.474,
                        1.492),
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
