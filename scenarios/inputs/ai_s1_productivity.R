scenario <- list(
  id    = "ai_s1_productivity",
  label = "S1: Prod",
  color = "#2166AC",
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
                        0.791)
  )
)