scenario <- list(
  id    = "ai_s3a_prod_lf_ui",
  label = "S3a: Prod+LF+UI",
  color = "#4DAC26",
  user_deltas = list(
    user_delta_prod  = c(1.60, 1.50, 1.50, 1.60, 1.60,
                         1.70, 1.70, 1.80, 1.80, 1.80),
    user_delta_lf    = c(-0.970721149839408,
                         -0.9754136575901038,
                         -0.9805932852958139,
                         -0.9796612370806357,
                         -0.9897753880747566,
                          0.09195901775637783,
                          0.08816839320827746,
                          0.0715411112743643,
                          0.031805969525750266,
                         -0.001241724459414617),
    # Source values are decimal fractions of GDP; multiply by 100 for
    # BLSMM percentage-point inputs.
    user_delta_rgfop = c(0.000288, 0.000558, 0.000806, 0.001033, 0.001245,
                         0.001181, 0.001121, 0.001068, 0.001026, 0.000993) * 100
  )
)
