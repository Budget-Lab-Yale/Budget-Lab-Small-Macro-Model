# AI post appendix, Slow Adoption variant, scenario S2.
# Reproduces the published appendix series (What Might AI Adoption Mean for the
# Fiscal and Economic Outlook?, May 19, 2026 update, Figures A1-A6) at BLSMM v1.8.1.
#
# user_delta_prod: Karger et al. (2026) Slow Economists NFB output/hour
#   target 2.0% (flat across 2030 and 2050 anchors) less the 0.319 pp NFB-to-GDP/employed wedge; flat
#   glqstar target 1.681% less CBO baseline glqstar.
# user_delta_lf: FY2026-FY2030 ramps LFPR linearly from 62.48% (FY2025) to the
#   Karger Slow Economists 2030 median (61.5%), using the step
#   (target - 62.6%) / 5 and CBO baseline LF growth rounded to 3 decimals, as in the
#   internal LFPR calibration workbook ("LFP Data.xlsx"). FY2031-FY2035 continue the
#   decline toward the Karger 2050 median (59.2%); these five values were
#   recovered from the published data because the construction file was not retained.

scenario <- list(
  id    = "ai_slow_s2_prod_lf",
  label = "Slow S2: Prod+LF",
  color = "#E8601C",
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
    user_delta_lf   = c(-0.261331264785,
      -0.25737754601,
      -0.252275876992,
      -0.240653800178,
      -0.239752770183,
      -0.191541373166,
      -0.175828181049,
      -0.174211983937,
      -0.196899934596,
      -0.214063273739)
  )
)
