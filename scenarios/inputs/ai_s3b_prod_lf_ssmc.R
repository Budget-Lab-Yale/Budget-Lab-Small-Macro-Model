scenario <- list(
  id    = "ai_s3b_prod_lf_ssmc",
  label = "S3b: Prod+LF+SSMC",
  color = "#C51B7D",
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
                        -0.379559281),
    user_delta_rgfop = c(0.115879477,
                         0.225495918,
                         0.325900512,
                         0.416761993,
                         0.500936683,
                         0.563853204,
                         0.615504756,
                         0.659649669,
                         0.70115302,
                         0.739367151)
  )
)
