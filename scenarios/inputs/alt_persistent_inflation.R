# Persistent inflation scenario - official shock path
# Source: BLSMM_1_8_20260326_links_persistentinflation.xlsm
#         User sheet row 79 ("User delta, in percentage points of
#         inflation shock"), cols J-S (FY2026-FY2035).
#
# Short, front-loaded shock to epspi (3 nonzero years):
#   FY2026: 0.0      FY2031-FY2035: 0.0
#   FY2027: +0.1
#   FY2028: +0.3 (peak)
#   FY2029: +0.2
#   FY2030: 0.0
#
# This is the official workbook path. Do not recalibrate it in this file.
scenario <- list(
  id    = "alt_persistent_inflation",
  label = "Inflation scenario",
  color = "#2166AC",
  user_deltas = list(
    user_delta_inflshock = c(0.0, 0.1, 0.3, 0.2, 0.0,
                             0.0, 0.0, 0.0, 0.0, 0.0)
  )
)
