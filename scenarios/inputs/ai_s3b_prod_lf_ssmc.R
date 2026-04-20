scenario <- list(
  id    = "ai_s3b_prod_lf_ssmc",
  label = "S3b: Prod+LF+SSMC",
  color = "#C51B7D",
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
    user_delta_rgfop = c(0.002200, 0.004255, 0.006149, 0.007887, 0.009501,
                         0.009012, 0.008555, 0.008150, 0.007830, 0.007576) * 100
  )
)
