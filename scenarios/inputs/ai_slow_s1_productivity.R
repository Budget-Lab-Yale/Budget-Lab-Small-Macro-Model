# AI post appendix, Slow Adoption variant, scenario S1.
# Reproduces the published appendix series (What Might AI Adoption Mean for the
# Fiscal and Economic Outlook?, May 19, 2026 update, Figures A1-A6) at BLSMM v1.8.1.
#
# user_delta_prod: Karger et al. (2026) Slow Economists NFB output/hour
#   target 2.0% (flat across 2030 and 2050 anchors) less the 0.319 pp NFB-to-GDP/employed wedge; flat
#   glqstar target 1.681% less CBO baseline glqstar.

scenario <- list(
  id    = "ai_slow_s1_productivity",
  label = "Slow S1: Prod",
  color = "#2166AC",
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
      0.292)
  )
)
