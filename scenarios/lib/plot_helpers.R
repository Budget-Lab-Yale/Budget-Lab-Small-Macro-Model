library(ggplot2)
library(patchwork)
library(dplyr)  # for bind_rows

# Extract one variable from a named list of results into long format.
# `results` is a named list like list(Baseline = baseline_df, "S1: Prod" = s1_df).
# Either specify `var` (column name) or `transform` (fn on a result df returning
# a length-10 numeric vector).
# For transforms that use lag() (like growth rates), the first year (FY2025) will
# be NA and is automatically dropped, so data starts from FY2026.
gather_var <- function(results, var = NULL, transform = NULL) {
  years <- 2025:2035
  # Load historical data (use read.csv for compatibility)
  hist_data <- read.csv("data/blsmm_v1_8_historical.csv",
                        stringsAsFactors = FALSE, check.names = FALSE)
  hist <- tail(hist_data, 1)
  hist$GDP <- 23733.13
  hist$D_pct_GDP <- hist$D / hist[["GDP$"]] * 100
  rows <- lapply(names(results), function(nm) {
    r <- bind_rows(hist,results[[nm]])
    v <- if (!is.null(transform)) transform(r) else r[[var]]
    data.frame(Year = years, Value = v, Scenario = nm,
               stringsAsFactors = FALSE)
  })
  df <- do.call(rbind, rows)
  # Preserve the ordering from the input list
  df$Scenario <- factor(df$Scenario, levels = names(results))
  # Drop rows with NA values (e.g., first year for growth rates using lag())
  df <- df[!is.na(df$Value), ]
  df
}

# Single-panel line plot with BL styling
bl_line <- function(df, title, subtitle = NULL, ylab = "", y_format = NULL) {
  # Determine x-axis range from data
  min_year <- min(df$Year, na.rm = TRUE)
  max_year <- max(df$Year, na.rm = TRUE)

  # Set breaks starting from the first even year at or after min_year
  start_break <- if (min_year %% 2 == 0) min_year else min_year + 1

  p <- ggplot(df, aes(x = Year, y = Value,
                      color = Scenario, linetype = Scenario)) +
    geom_line(linewidth = 1.2) +
    scale_color_manual(values = bl_palette) +
    scale_linetype_manual(values = bl_linetypes) +
    scale_x_continuous(breaks = seq(start_break, max_year, 2),
                       limits = c(min_year, max_year)) +
    labs(title = title, subtitle = subtitle,
         x = "Fiscal Year", y = ylab) +
    theme_bl()
  if (!is.null(y_format)) {
    p <- p + scale_y_continuous(labels = y_format)
  }
  p
}

# Multi-panel grid using patchwork with legend below all panels
bl_grid <- function(plots, ncol = 2) {
  wrap_plots(plots, ncol = ncol, guides = "collect") &
    theme(legend.position = "bottom")
}

# Variable transforms
tf_budget_pct_gdp <- function(r) r$BUD / r$`GDP$` * -100
tf_real_gdp_tril  <- function(r) r$GDP / 1000
tf_real_gdp_growth <- function(r) (r$GDP / lag(r$GDP) - 1)*100