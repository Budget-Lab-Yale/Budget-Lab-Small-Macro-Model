library(ggplot2)
library(patchwork)

# Extract one variable from a named list of results into long format.
# `results` is a named list like list(Baseline = baseline_df, "S1: Prod" = s1_df).
# Either specify `var` (column name) or `transform` (fn on a result df returning
# a length-10 numeric vector).
gather_var <- function(results, var = NULL, transform = NULL) {
  years <- 2026:2035
  rows <- lapply(names(results), function(nm) {
    r <- results[[nm]]
    v <- if (!is.null(transform)) transform(r) else r[[var]]
    data.frame(Year = years, Value = v, Scenario = nm,
               stringsAsFactors = FALSE)
  })
  df <- do.call(rbind, rows)
  # Preserve the ordering from the input list
  df$Scenario <- factor(df$Scenario, levels = names(results))
  df
}

# Single-panel line plot with BL styling
bl_line <- function(df, title, subtitle = NULL, ylab = "", y_format = NULL) {
  p <- ggplot(df, aes(x = Year, y = Value,
                      color = Scenario, linetype = Scenario)) +
    geom_line(linewidth = 1.0) +
    scale_color_manual(values = bl_palette) +
    scale_linetype_manual(values = bl_linetypes) +
    scale_x_continuous(breaks = seq(2026, 2035, 2)) +
    labs(title = title, subtitle = subtitle,
         x = "Fiscal Year", y = ylab) +
    theme_bl()
  if (!is.null(y_format)) {
    p <- p + scale_y_continuous(labels = y_format)
  }
  p
}

# Multi-panel grid using patchwork
bl_grid <- function(plots, ncol = 2) {
  combined <- Reduce(`+`, plots)
  combined + plot_layout(ncol = ncol, guides = "collect") +
    plot_annotation(theme = theme(legend.position = "bottom"))
}

# Variable transforms
tf_budget_pct_gdp <- function(r) r$BUD / r$`GDP$` * 100
tf_real_gdp_tril  <- function(r) r$GDP / 1000