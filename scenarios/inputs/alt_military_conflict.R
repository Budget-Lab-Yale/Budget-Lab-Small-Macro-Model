# Defense outlays +1.5 pp in FY2027, +0.5-0.8 pp thereafter.
# EXACT year-by-year path awaiting confirmation from Ryan — these are
# reasonable placeholders consistent with the PDF description.
scenario <- list(
  id    = "alt_military_conflict",
  label = "Military conflict scenario",
  color = "#4DAC26",
  user_deltas = list(
    # FY2026, FY2027, FY2028-2035
    user_delta_rgfop = c(0.0, 1.5, 0.8, 0.7, 0.7, 0.6, 0.6, 0.5, 0.5, 0.5)
  )
)