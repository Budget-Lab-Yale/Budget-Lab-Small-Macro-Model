# Military conflict scenario - official defense outlay path
# Source: defense_outlays_data.xlsx, column F ("Primary Outlays Delta")
# for FY2026-FY2035, retained at full precision.
#
# Formula used in the source workbook:
#   (BR2027 Discretionary Defense Outlays + BR2027 Mandatory
#    - Baseline Discretionary Defense Outlays) / Potential GDP * 100
#
# Year-by-year values (pp of potential GDP):
#   FY2026: +0.0593    FY2031: +0.8164
#   FY2027: +1.4649    FY2032: +0.7858
#   FY2028: +0.6025    FY2033: +0.7236
#   FY2029: +0.7584    FY2034: +0.6727
#   FY2030: +0.7938    FY2035: +0.6148
#
# The FY2027 spike includes $350B of one-time mandatory defense spending
# from the Administration's 2027 Budget Request.
scenario <- list(
  id    = "alt_military_conflict",
  label = "Military conflict scenario",
  color = "#4DAC26",
  user_deltas = list(
    user_delta_rgfop = c(
      0.05926643923051801,   # FY2026
      1.4648663376827828,    # FY2027
      0.6024768143143505,    # FY2028
      0.7583951483560541,    # FY2029
      0.7938454047864912,    # FY2030
      0.8164223748813694,    # FY2031
      0.785826175398481,     # FY2032
      0.7236216101604063,    # FY2033
      0.6726591880611538,    # FY2034
      0.6147969334429797     # FY2035
    )
  )
)
