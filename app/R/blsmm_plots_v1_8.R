# ==============================================================================
# BLSMM Dashboard Plots - All 13 Charts
# ==============================================================================
# This file contains rendering code for all 13 dashboard charts.
# Charts provide comprehensive visualization of macroeconomic model results.
#
# Chart List:
#  1. Unemployment rate (%)
#  2. Inflation (%)
#  3. Real GDP indexed (100 = FY2025) - combo chart
#  4. 10-year Treasury yield (%) - 4 series
#  5. Federal Funds rate (%) - 4 series
#  6. Budget balance % of nominal GDP
#  7. Debt % of GDP
#  8. Average interest rate on federal debt (%) - combo chart
#  9. Total Receipts, % of nominal GDP
# 10. Total Outlays, % of nominal GDP
# 11. Primary Outlays, % of nominal GDP
# 12. Real GDP growth (bars) - combo chart
# 13. Primary budget balance % of nominal GDP
# ==============================================================================

# Helper function to check if scenario equals baseline (no deltas applied)
is_baseline_only <- function(data) {
  # Check if a key variable is identical between baseline and scenario
  # Using unemployment rate as the check variable
  isTRUE(all.equal(data$baseline$U, data$scenario$U, tolerance = 1e-10))
}

# Chart 1: Unemployment rate (%)
output$plot_unemployment <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$U,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$U,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      add_lines(
        x = data$scenario$fy_label,
        y = data$scenario$U,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Unemployment rate (%)</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 2: Inflation (%)
output$plot_inflation <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$PI,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$PI,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      add_lines(
        x = data$scenario$fy_label,
        y = data$scenario$PI,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Inflation (%)</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent (GDP deflator)", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 4: 10-year Treasury yield (%) - 4 series
output$plot_10yr_yield <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  # Calculate real 10-year yields
  baseline_real_r10 <- data$baseline$R10 - data$baseline$PI
  scenario_real_r10 <- data$scenario$R10 - data$scenario$PI

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline lines when no deltas
    p <- p %>%
      # Nominal 10-year baseline
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$R10,
        name = "Nominal 10Y",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Real 10-year baseline
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_real_r10,
        name = "Real 10Y",
        line = list(color = th$line_secondary, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  } else {
    # Show all 4 lines when there are deltas
    p <- p %>%
      # Nominal 10-year baseline
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$R10,
        name = "Nominal 10Y (Baseline)",
        line = list(color = th$line_baseline, dash = "dash", width = 2),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Nominal 10-year scenario
      add_lines(
        x = data$scenario$fy_label,
        y = data$scenario$R10,
        name = "Nominal 10Y (Scenario)",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Real 10-year baseline
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_real_r10,
        name = "Real 10Y (Baseline)",
        line = list(color = th$line_secondary, dash = "dash", width = 2),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Real 10-year scenario
      add_lines(
        x = data$scenario$fy_label,
        y = scenario_real_r10,
        name = "Real 10Y (Scenario)",
        line = list(color = th$line_secondary, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>10-year Treasury yield (%)</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 5: Federal Funds rate (%) - 4 series
output$plot_federal_funds <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline lines when no deltas
    p <- p %>%
      # r* baseline
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$rfstar,
        name = "r*",
        line = list(color = th$line_secondary, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Federal Funds baseline
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$RF,
        name = "Fed Funds",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  } else {
    # Show all 4 lines when there are deltas
    p <- p %>%
      # r* baseline
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$rfstar,
        name = "r* (Baseline)",
        line = list(color = th$line_secondary, dash = "dash", width = 2),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # r* scenario
      add_lines(
        x = data$scenario$fy_label,
        y = data$scenario$rfstar,
        name = "r* (Scenario)",
        line = list(color = th$line_secondary, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Federal Funds baseline
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$RF,
        name = "Fed Funds (Baseline)",
        line = list(color = th$line_baseline, dash = "dash", width = 2),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Federal Funds scenario
      add_lines(
        x = data$scenario$fy_label,
        y = data$scenario$RF,
        name = "Fed Funds (Scenario)",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Federal Funds rate (%)</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 6: Budget balance % of nominal GDP
output$plot_budget_balance <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  # Calculate total budget balance as % of GDP
  # BUD is already in $B, need to convert to % of nominal GDP
  # Total budget = Primary balance - Net Interest
  # But BUD should already be the total
  baseline_budget_pct <- (data$baseline$BUD / data$baseline[["GDP$"]]) * 100
  scenario_budget_pct <- (data$scenario$BUD / data$scenario[["GDP$"]]) * 100

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_budget_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_budget_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      ) %>%
      add_lines(
        x = data$scenario$fy_label,
        y = scenario_budget_pct,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Budget Balance % of GDP</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent of GDP (negative = deficit)", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 7: Debt % of GDP
output$plot_debt <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$D_pct_GDP,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.1f}%<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$D_pct_GDP,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.1f}%<extra></extra>")
      ) %>%
      add_lines(
        x = data$scenario$fy_label,
        y = data$scenario$D_pct_GDP,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.1f}%<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Debt % of GDP</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent of GDP", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 8: Average interest rate on federal debt (%) - Combo chart
output$plot_avg_interest_rate <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$RG,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      # Baseline line
      add_lines(
        x = data$baseline$fy_label,
        y = data$baseline$RG,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Scenario line
      add_lines(
        x = data$scenario$fy_label,
        y = data$scenario$RG,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Average interest rate on federal debt (%)</b>",
      xaxis = list(title = "", gridcolor = th$grid),
      yaxis = list(
        title = "Percent",
        gridcolor = th$grid,
        zerolinecolor = th$zero
      ),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 9: Total Receipts, % of nominal GDP
output$plot_total_receipts <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  # Calculate total receipts as % of nominal GDP
  # Convert from % of potential GDP to % of actual GDP using real GDP ratio
  # Note: Uses GDPstar/GDP ratio for consistency with Excel model
  baseline_receipts_pct <- data$baseline$rgfr_star * (data$baseline$GDPstar / data$baseline$GDP)
  scenario_receipts_pct <- data$scenario$rgfr_star * (data$scenario$GDPstar / data$scenario$GDP)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_receipts_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_receipts_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      ) %>%
      add_lines(
        x = data$scenario$fy_label,
        y = scenario_receipts_pct,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Total Receipts % of GDP</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent of GDP", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 10: Total Outlays, % of nominal GDP
output$plot_total_outlays <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  # Calculate total outlays as % of nominal GDP
  # Total outlays = Primary outlays (converted to % of actual GDP) + Net interest
  # Note: Uses GDPstar/GDP ratio for consistency with Excel model
  baseline_outlays_pct <- (data$baseline$rgfop_star * (data$baseline$GDPstar / data$baseline$GDP)) +
                          ((data$baseline$NI / data$baseline[["GDP$"]]) * 100)
  scenario_outlays_pct <- (data$scenario$rgfop_star * (data$scenario$GDPstar / data$scenario$GDP)) +
                          ((data$scenario$NI / data$scenario[["GDP$"]]) * 100)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_outlays_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_outlays_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      ) %>%
      add_lines(
        x = data$scenario$fy_label,
        y = scenario_outlays_pct,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Total Outlays % of GDP</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent of GDP", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 11: Primary Outlays, % of nominal GDP
output$plot_primary_outlays <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  # Calculate primary outlays as % of nominal GDP
  # Convert from % of potential GDP to % of actual GDP using real GDP ratio
  # Note: Uses GDPstar/GDP ratio for consistency with Excel model
  baseline_outlays_pct <- data$baseline$rgfop_star * (data$baseline$GDPstar / data$baseline$GDP)
  scenario_outlays_pct <- data$scenario$rgfop_star * (data$scenario$GDPstar / data$scenario$GDP)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_outlays_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_outlays_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      ) %>%
      add_lines(
        x = data$scenario$fy_label,
        y = scenario_outlays_pct,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Primary Outlays % of GDP</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent of GDP", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 12: Real GDP growth (bars) - Combo chart
output$plot_real_gdp_growth <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  # All values should be valid now (FY2025 growth is calculated from FY2024)
  # But check just in case
  valid_idx <- !is.na(data$baseline$real_gdp_growth)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label[valid_idx],
        y = data$baseline$real_gdp_growth[valid_idx],
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      # Baseline growth line
      add_lines(
        x = data$baseline$fy_label[valid_idx],
        y = data$baseline$real_gdp_growth[valid_idx],
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      ) %>%
      # Scenario growth line
      add_lines(
        x = data$scenario$fy_label[valid_idx],
        y = data$scenario$real_gdp_growth[valid_idx],
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}%<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Real GDP growth (%)</b>",
      xaxis = list(title = "", gridcolor = th$grid),
      yaxis = list(
        title = "Percent",
        gridcolor = th$grid,
        zerolinecolor = th$zero
      ),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})

# Chart 13: Primary budget balance % of nominal GDP
output$plot_primary_balance <- renderPlotly({
  req(simulation_results_for_plots())

  data <- simulation_results_for_plots()
  th <- plot_theme()
  baseline_only <- is_baseline_only(data)

  # Calculate primary balance as % of actual GDP
  # Note: Uses GDPstar/GDP ratio for consistency with Excel model
  baseline_primary_pct <- data$baseline$rbudp_star * (data$baseline$GDPstar / data$baseline$GDP)
  scenario_primary_pct <- data$scenario$rbudp_star * (data$scenario$GDPstar / data$scenario$GDP)

  p <- plot_ly()

  if (baseline_only) {
    # Only show baseline line when no deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_primary_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  } else {
    # Show both lines when there are deltas
    p <- p %>%
      add_lines(
        x = data$baseline$fy_label,
        y = baseline_primary_pct,
        name = "Baseline",
        line = list(color = th$line_baseline, dash = "dash", width = 2.5),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      ) %>%
      add_lines(
        x = data$scenario$fy_label,
        y = scenario_primary_pct,
        name = "Scenario",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f}% of GDP<extra></extra>")
      )
  }

  p %>%
    layout(
      title = "<b>Primary Budget Balance % of GDP</b>",
      xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
      yaxis = list(title = "Percent of GDP (negative = deficit)", gridcolor = th$grid, zerolinecolor = th$zero),
      hovermode = "x unified",
      dragmode = FALSE,
      legend = list(orientation = "h", x = 0.5, y = -0.2, xanchor = "center", yanchor = "top", bgcolor = th$legend_bg),
      paper_bgcolor = th$paper_bg,
      plot_bgcolor = th$plot_bg,
      font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
})
