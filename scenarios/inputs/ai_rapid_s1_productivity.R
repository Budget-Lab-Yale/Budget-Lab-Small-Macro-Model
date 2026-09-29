# AI post appendix, Rapid Adoption variant, scenario S1.
# Reproduces the published appendix series (What Might AI Adoption Mean for the
# Fiscal and Economic Outlook?, May 19, 2026 update, Figures A1-A6) at BLSMM v1.8.1.
#
# user_delta_prod: Karger et al. (2026) Rapid Economists NFB output/hour
#   target 3.2% (2030 anchor, held flat) less the 0.319 pp NFB-to-GDP/employed wedge; flat
#   glqstar target 2.881% less CBO baseline glqstar.

scenario <- list(
  id    = "ai_rapid_s1_productivity",
  label = "Rapid S1: Prod",
  color = "#2166AC",
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
      1.492)
  )
)
