scenario <- list(
  id    = "ai_s3a_prod_lf_ui",
  label = "S3a: Prod+LF+UI",
  color = "#4DAC26",
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
    user_delta_rgfop = c(0.015184772,
                         0.029548841,
                         0.042705794,
                         0.054612224,
                         0.065642422,
                         0.073886962,
                         0.080655349,
                         0.08644007,
                         0.091878642,
                         0.096886197)
  )
)
