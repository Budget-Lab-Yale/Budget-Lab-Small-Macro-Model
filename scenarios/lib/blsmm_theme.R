library(ggplot2)

bl_palette <- c(
  "Baseline"                     = "#000000",
  "S1: Prod"                     = "#2166AC",
  "S2: Prod+LF"                  = "#E8601C",
  "S3a: Prod+LF+UI"              = "#4DAC26",
  "S3b: Prod+LF+SSMC"            = "#C51B7D",
  "Inflation scenario"           = "#2166AC",
  "Investor confidence scenario" = "#2166AC",
  "Military conflict scenario"   = "#4DAC26"
)

bl_linetypes <- c(
  "Baseline"                     = "dashed",
  "S1: Prod"                     = "solid",
  "S2: Prod+LF"                  = "solid",
  "S3a: Prod+LF+UI"              = "solid",
  "S3b: Prod+LF+SSMC"            = "solid",
  "Inflation scenario"           = "solid",
  "Investor confidence scenario" = "solid",
  "Military conflict scenario"   = "solid"
)

theme_bl <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title       = element_text(face = "bold", size = 16),
      plot.subtitle    = element_text(size = 13, color = "gray30"),
      axis.title       = element_text(size = 14),
      axis.text        = element_text(size = 12),
      legend.position  = "bottom",
      legend.title     = element_blank(),
      legend.text      = element_text(size = 13),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray90")
    )
}