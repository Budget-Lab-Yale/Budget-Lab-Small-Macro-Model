# Investor confidence scenario - +100bp persistent term premium shock
# Source: BLSMM_1_8_20260326_links_lostconfidence.xlsm
#         Model tab row 47 (tp_0), cols P-Y (sim yr 1-10).
#
# In the source workbook, tp_0 is shifted by +1.0 in every year:
#   Baseline tp_0:  0.70, 0.85, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00
#   Shocked tp_0:   1.70, 1.85, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00
#
# The User sheet has no shocks. The +1.0 shift is applied directly to
# the exogenous tp_0 path on the Model tab.
#
# We reproduce this with exog_override. compute_rbar10_v1_8() computes
# rbar10 endogenously as a function of tp_0, so overriding tp_0 is
# sufficient to match the Excel behavior.
baseline_tp_0 <- c(0.70, 0.85, 1.00, 1.00, 1.00,
                   1.00, 1.00, 1.00, 1.00, 1.00)

scenario <- list(
  id    = "alt_investor_confidence",
  label = "Investor confidence scenario",
  color = "#2166AC",
  exog_override = list(
    tp_0 = baseline_tp_0 + 1.0
  )
)
