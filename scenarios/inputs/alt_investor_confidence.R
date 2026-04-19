# +100 bp persistent shock to tp_0 (term premium).
# Baseline tp_0 (FY2026-2035): 0.7, 0.85, 1.0, 1.0, 1.0, 1.0, 1.0,
#                              1.0, 1.0, 1.0
baseline_tp_0 <- c(0.7, 0.85, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
scenario <- list(
  id    = "alt_investor_confidence",
  label = "Investor confidence scenario",
  color = "#2166AC",
  exog_override = list(
    tp_0 = baseline_tp_0 + 1.0
  )
)