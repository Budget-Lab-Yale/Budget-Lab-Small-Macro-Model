# AI post appendix, Rapid Adoption variant, scenario S2.
# Reproduces the published appendix series (What Might AI Adoption Mean for the
# Fiscal and Economic Outlook?, May 19, 2026 update, Figures A1-A6) at BLSMM v1.8.1.
#
# user_delta_prod: Karger et al. (2026) Rapid Economists NFB output/hour
#   target 3.2% (2030 anchor, held flat) less the 0.319 pp NFB-to-GDP/employed wedge; flat
#   glqstar target 2.881% less CBO baseline glqstar.
# user_delta_lf: FY2026-FY2030 ramps LFPR linearly from 62.48% (FY2025) to the
#   Karger Rapid Economists 2030 median (59.3%), using the step
#   (target - 62.6%) / 5 and CBO baseline LF growth rounded to 3 decimals, as in the
#   internal LFPR calibration workbook ("LFP Data.xlsx"). FY2031-FY2035 continue the
#   decline toward the Karger 2050 median (55.0%); these five values were
#   recovered from the published data because the construction file was not retained.

scenario <- list(
  id    = "ai_rapid_s2_prod_lf",
  label = "Rapid S2: Prod+LF",
  color = "#E8601C",
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
    user_delta_lf   = c(-0.970721149839,
      -0.97541365759,
      -0.980593285296,
      -0.979661237081,
      -0.989775388075,
      -0.954687835082,
      -0.825965257057,
      -0.725687376871,
      -0.662585549639,
      -0.605486750779)
  )
)
