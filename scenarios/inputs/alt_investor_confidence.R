# Investor confidence scenario — sovereign-trust shock to U.S. Treasuries.
#
# Design
# ------
# Models a UK/Argentina-style loss of confidence in U.S. Treasuries via
# three permanent residual wedges. BLSMM is closed-economy and has no FX /
# fiscal-dominance / monetization-risk channels, so the financial and
# credibility components of a sovereign-confidence event have to enter
# through residuals.
#
#   1. epstp  = +1.0 permanent   # broad term-premium repricing
#                                 # (panic / duration-risk reassessed)
#
#   2. epsrg  = +0.5 -> ~+0.13   # Treasury-market dysfunction, tapering
#                                 # (auction tails, dealer balance-sheet
#                                 # stress, foreign CB withdrawal — gradually
#                                 # heals as plumbing normalizes)
#
#   3. epspie = +0.5 permanent   # inflation expectations un-anchoring
#                                 # (fiscal-dominance risk priced in)
#
# Channel (1) raises long rates broadly through the term premium, opening
# a real-rate gap that drives the demand impulse. Channel (2) bypasses
# R10 and lifts RG directly through its own residual, representing the
# idea that the rate at which Treasury issues new debt diverges from the
# broad long-rate environment because of plumbing stress. Channel (3)
# prevents inflation from collapsing through the Phillips curve when
# output contracts — without it the model would produce a counterfactual
# disinflation that doesn't match real-world sovereign-crisis dynamics.
#
# Together these reproduce the headline features of a sovereign-trust
# crisis: higher real long rates, higher effective interest costs on
# federal debt, a negative output gap, deteriorating deficits, and
# inflation that runs hot rather than collapsing.
#
# Monetary policy: unconstrained — RF solves via the Taylor rule. With
# rising PI/PIE the Fed faces a stagflation dilemma; whether it leans
# against the output gap or the inflation overshoot is part of what we
# want to observe.

# (1) Term premium residual: panic, permanent
tp_resid       <- rep(1.0, 10)

# (2) RG residual: Treasury-market dysfunction, exponentially tapering
#     from +0.5 with a 5-year half-life.
rg_hl          <- 5
rg_resid       <- 0.5 * exp(-log(2) / rg_hl * 0:9)

# (3) PIE residual: expectations un-anchoring, permanent
pie_resid      <- rep(0.5, 10)

scenario <- list(
  id    = "alt_investor_confidence",
  label = "Investor confidence scenario",
  color = "#2166AC",
  resid_override = list(
    epstp  = tp_resid,
    epsrg  = rg_resid,
    epspie = pie_resid
  )
)
