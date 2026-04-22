ui <- fluidPage(
  # Enable shinyjs
  useShinyjs(),

  # Custom CSS for Excel-like styling
  tags$head(
    # Budget Lab design tokens (colors, fonts, spacing) as CSS custom properties
    bl_webfonts_block(),
    bl_css_vars_block(),
    # Brand overrides: body/heading fonts, primary colors
    bl_brand_overrides_block(),
    tags$style(HTML("
      /* Yellow highlight for editable row (User Delta row = row 2) */
      .handsontable tbody tr:nth-child(2) td {
        background-color: #FFF9E6 !important;
        font-weight: normal;
      }

      /* Gray background for read-only rows (Baseline = row 1, Level = row 3) */
      .handsontable tbody tr:nth-child(1) td,
      .handsontable tbody tr:nth-child(3) td {
        background-color: #F9FAFB !important;
        color: #6B7280;
      }

      /* Keep first column (Row labels) readable */
      .handsontable tbody tr td:first-child {
        background-color: #F3F4F6 !important;
        font-weight: bold;
        color: #374151;
      }

      /* Green highlight for deviation tables */
      .deviation-highlight {
        background-color: #E2EFDA !important;
      }

      /* SSE indicator styling */
      .sse-display {
        font-size: 16px;
        font-weight: bold;
        padding: 8px;
        margin: 8px 0;
        border-radius: 8px;
        border: 2px solid #ddd;
      }

      /* Dark mode base styling */
      [data-bs-theme='dark'] .sse-display {
        border-color: #4b5563;
        color: #e5e7eb;
      }

      /* Light mode colors */
      .sse-solved {
        background-color: #d4edda;
        color: #155724;
        border-color: #c3e6cb;
      }

      .sse-not-solved {
        background-color: #fff3cd;
        color: #856404;
        border-color: #ffeaa7;
      }

      /* Dark mode colors - darker backgrounds with lighter text */
      [data-bs-theme='dark'] .sse-solved {
        background-color: #1e4620;
        color: #a8e6a8 !important;
        border-color: #2d6930;
      }

      [data-bs-theme='dark'] .sse-not-solved {
        background-color: #4d3800;
        color: #ffdf80 !important;
        border-color: #665000;
      }

      /* Input table styling */
      .handsontable td {
        text-align: right;
      }

      .handsontable .htDimmed {
        color: #999;
      }

      /* Dark mode table styling (all input/output tables) */
      html[data-bs-theme='dark'] .handsontable tbody tr:nth-child(2) td {
        background-color: #6B5D2F !important;
        color: #FEFCE8 !important;
      }
      html[data-bs-theme='dark'] .handsontable tbody tr:nth-child(1) td,
      html[data-bs-theme='dark'] .handsontable tbody tr:nth-child(3) td {
        background-color: #1F2937 !important;
        color: #D1D5DB !important;
      }
      html[data-bs-theme='dark'] .handsontable tbody tr td:first-child {
        background-color: #374151 !important;
        color: #F3F4F6 !important;
      }
      html[data-bs-theme='dark'] .handsontable td,
      html[data-bs-theme='dark'] .handsontable th {
        border-color: #4b5563 !important;
      }
      html[data-bs-theme='dark'] .handsontable .htDimmed {
        color: #b6bec9 !important;
      }

      /* Dark mode DataTables styling */
      html[data-bs-theme='dark'] table.dataTable,
      html[data-bs-theme='dark'] table.dataTable tbody tr,
      html[data-bs-theme='dark'] table.dataTable tbody td,
      html[data-bs-theme='dark'] table.dataTable thead th {
        background-color: #1f2630 !important;
        color: #e9ecef !important;
        border-color: #3a424a !important;
      }
      html[data-bs-theme='dark'] table.dataTable.stripe tbody tr.odd,
      html[data-bs-theme='dark'] table.dataTable.display tbody tr.odd {
        background-color: #242d37 !important;
      }
      html[data-bs-theme='dark'] .dataTables_wrapper .dataTables_info,
      html[data-bs-theme='dark'] .dataTables_wrapper .dataTables_paginate,
      html[data-bs-theme='dark'] .dataTables_wrapper .dataTables_length,
      html[data-bs-theme='dark'] .dataTables_wrapper .dataTables_filter,
      html[data-bs-theme='dark'] .dataTables_wrapper .dataTables_processing {
        color: #c9d1d9 !important;
      }
      html[data-bs-theme='dark'] .dataTables_wrapper .dataTables_paginate .paginate_button {
        color: #c9d1d9 !important;
      }
      html[data-bs-theme='dark'] .dataTables_wrapper .dataTables_paginate .paginate_button.current,
      html[data-bs-theme='dark'] .dataTables_wrapper .dataTables_paginate .paginate_button:hover {
        background: #2f81f7 !important;
        color: #ffffff !important;
        border-color: #2f81f7 !important;
      }

      /* Fiscal year note */
      .fy-note {
        font-size: 0.875em;
        color: #666;
        font-style: italic;
        margin-top: -8px;
        margin-bottom: 8px;
      }
      html[data-bs-theme='dark'] .fy-note {
        color: #9ca3af;
      }

      /* Run status pill */
      .run-status {
        font-family: monospace;
        font-size: 0.875em;
        font-weight: 700;
        border-radius: 999px;
        padding: 8px 16px;
        display: inline-block;
        border: 1px solid transparent;
      }
      .run-ready { background: #e9ecef; color: #343a40; border-color: #ced4da; }
      .run-dirty { background: #fff3cd; color: #856404; border-color: #ffe69c; }
      .run-running { background: #cfe2ff; color: #084298; border-color: #9ec5fe; }
      .run-solved { background: #d1e7dd; color: #0f5132; border-color: #a3cfbb; }
      .run-error { background: #f8d7da; color: #842029; border-color: #f1aeb5; }

      /* Dark mode run status pills */
      html[data-bs-theme='dark'] .run-ready { background: #374151; color: #d1d5db; border-color: #4b5563; }
      html[data-bs-theme='dark'] .run-dirty { background: #78350f; color: #fcd34d; border-color: #a16207; }
      html[data-bs-theme='dark'] .run-running { background: #1e3a8a; color: #93c5fd; border-color: #2563eb; }
      html[data-bs-theme='dark'] .run-solved { background: #14532d; color: #86efac; border-color: #166534; }
      html[data-bs-theme='dark'] .run-error { background: #7f1d1d; color: #fca5a5; border-color: #991b1b; }

      /* Muted text color class */
      .text-muted-custom {
        color: #666;
      }
      html[data-bs-theme='dark'] .text-muted-custom {
        color: #9ca3af;
      }

      /* Link color class */
      .text-link {
        color: #0066cc;
      }
      html[data-bs-theme='dark'] .text-link {
        color: #60a5fa;
      }

      /* Warning text color */
      .text-warning-custom {
        color: #cc0000;
      }
      html[data-bs-theme='dark'] .text-warning-custom {
        color: #f87171;
      }

      /* Info box backgrounds */
      .bg-info-light {
        background-color: #f8f9fa;
      }
      html[data-bs-theme='dark'] .bg-info-light {
        background-color: #1f2937;
      }

      .bg-blue-light {
        background-color: #e7f3ff;
        border-left: 4px solid #0066cc;
      }
      html[data-bs-theme='dark'] .bg-blue-light {
        background-color: #1e3a5f;
        border-left: 4px solid #3b82f6;
      }

      .bg-yellow-light {
        background-color: #fff9e6;
      }
      html[data-bs-theme='dark'] .bg-yellow-light {
        background-color: #3f2f1a;
      }

      .bg-blue-pale {
        background-color: #f0f8ff;
      }
      html[data-bs-theme='dark'] .bg-blue-pale {
        background-color: #1e293b;
      }

      .bg-red-light {
        background-color: #fff0f0;
      }
      html[data-bs-theme='dark'] .bg-red-light {
        background-color: #3f1f1f;
      }

      /* SSE Display Box */
      .sse-box {
        font-family: monospace;
        font-size: 0.875em;
        padding: 8px;
        background: #f5f5f5;
        border-radius: 4px;
        border: 1px solid #dee2e6;
      }
      html[data-bs-theme='dark'] .sse-box {
        background: #2b3138;
        border-color: #4b5563;
        color: #e9ecef;
      }

      /* Dark mode button improvements */
      html[data-bs-theme='dark'] .btn-outline-primary {
        color: #60a5fa;
        border-color: #3b82f6;
        background-color: rgba(59, 130, 246, 0.1);
      }
      html[data-bs-theme='dark'] .btn-outline-primary:hover {
        color: #ffffff;
        background-color: #3b82f6;
        border-color: #3b82f6;
      }
      html[data-bs-theme='dark'] .btn-outline-danger {
        color: #f87171;
        border-color: #dc2626;
        background-color: rgba(220, 38, 38, 0.1);
      }
      html[data-bs-theme='dark'] .btn-outline-danger:hover {
        color: #ffffff;
        background-color: #dc2626;
        border-color: #dc2626;
      }
      html[data-bs-theme='dark'] .btn-outline-success {
        color: #86efac;
        border-color: #16a34a;
        background-color: rgba(22, 163, 74, 0.1);
      }
      html[data-bs-theme='dark'] .btn-outline-success:hover {
        color: #ffffff;
        background-color: #16a34a;
        border-color: #16a34a;
      }
      html[data-bs-theme='dark'] .btn-outline-warning {
        color: #fcd34d;
        border-color: #ca8a04;
        background-color: rgba(202, 138, 4, 0.1);
      }
      html[data-bs-theme='dark'] .btn-outline-warning:hover {
        color: #000000;
        background-color: #fbbf24;
        border-color: #ca8a04;
      }

      /* Sidebar section styling for visual separation */
      .sidebar-section {
        padding: 16px;
        margin-bottom: 16px;
        border-radius: 8px;
        background-color: #f8f9fa;
        border: 1px solid #e9ecef;
      }
      html[data-bs-theme='dark'] .sidebar-section {
        background-color: #1f2937;
        border-color: #374151;
      }

      .sidebar-section h4 {
        margin-top: 0;
        margin-bottom: 16px;
        font-size: 1.125em;
      }

      /* Accessibility helpers */
      .skip-link {
        position: absolute;
        left: -9999px;
        top: 0;
        z-index: 9999;
        background: #ffffff;
        color: #000000;
        padding: 8px 16px;
        border: 2px solid #000;
      }
      .skip-link:focus {
        left: 8px;
        top: 8px;
      }
      button:focus-visible,
      a:focus-visible,
      input:focus-visible,
      select:focus-visible,
      textarea:focus-visible {
        outline: 3px solid #1f6feb !important;
        outline-offset: 2px;
      }

      /* Emphasize primary tabs (Inputs and Dashboard) */
      .nav-tabs .nav-link[data-value='inputs'],
      .nav-tabs .nav-link[data-value='dashboard'] {
        font-weight: 600;
        border-bottom: 3px solid transparent;
      }

      .nav-tabs .nav-link[data-value='inputs'].active,
      .nav-tabs .nav-link[data-value='dashboard'].active {
        border-bottom: 3px solid #0066cc;
      }

      /* Add subtle background highlight to primary tabs */
      .nav-tabs .nav-link[data-value='inputs']:not(.active),
      .nav-tabs .nav-link[data-value='dashboard']:not(.active) {
        background-color: rgba(0, 102, 204, 0.05);
      }

      /* Dark mode support for primary tabs */
      [data-bs-theme='dark'] .nav-tabs .nav-link[data-value='inputs']:not(.active),
      [data-bs-theme='dark'] .nav-tabs .nav-link[data-value='dashboard']:not(.active) {
        background-color: rgba(96, 165, 250, 0.1);
      }

      [data-bs-theme='dark'] .nav-tabs .nav-link[data-value='inputs'].active,
      [data-bs-theme='dark'] .nav-tabs .nav-link[data-value='dashboard'].active {
        border-bottom: 3px solid #60a5fa;
      }
    ")),
    tags$script(HTML("
      // rhandsontable can mis-measure width when rendered in hidden tabs.
      // Refresh dimensions whenever a tab becomes visible.
      function refreshAllHotTables() {
        if (!window.HTMLWidgets || !HTMLWidgets.find) return;
        document.querySelectorAll('.rhandsontable').forEach(function(el) {
          var widget = HTMLWidgets.find('#' + el.id);
          if (widget && widget.hot) {
            try {
              widget.hot.render();
              if (widget.hot.refreshDimensions) widget.hot.refreshDimensions();
            } catch (e) {}
          }
        });
        window.dispatchEvent(new Event('resize'));
      }

      document.addEventListener('shown.bs.tab', function() {
        setTimeout(refreshAllHotTables, 80);
      });

      document.addEventListener('DOMContentLoaded', function() {
        setTimeout(refreshAllHotTables, 120);
      });

      // Keyboard shortcuts for faster workflow.
      document.addEventListener('keydown', function(e) {
        if (e.altKey && !e.shiftKey && (e.key === 'r' || e.key === 'R')) {
          var runBtn = document.getElementById('run_sim');
          if (runBtn) runBtn.click();
        }
      });

      // Add explicit ARIA labels to controls after DOM load.
      document.addEventListener('DOMContentLoaded', function() {
        var labels = {
          run_sim: 'Run simulation',
          reset_inputs: 'Reset inputs to defaults',
          ['preset_' + 'rapid_ai']: 'Apply rapid AI adoption preset',
          ['preset_' + 'persistent_infl']: 'Apply persistent inflation preset',
          ['preset_' + 'military_conflict']: 'Apply military conflict preset',
          download_csv: 'Download results as CSV',
          download_excel: 'Download results as Excel workbook'
        };
        Object.keys(labels).forEach(function(id) {
          var el = document.getElementById(id);
          if (el) el.setAttribute('aria-label', labels[id]);
        });
      });
    "))
  ),

  # Budget Lab-themed bslib theme.
  # Bootstrap 5 defaults (no bootswatch). "flatly" brought in a green-teal
  # accent that clashed with the Budget Lab palette; with flatly dropped we
  # set brand colors directly.
  theme = bs_theme(
    version      = 5,
    base_font    = font_google("Source Sans 3"),
    heading_font = font_google("Source Sans 3"),
    primary      = bl_colors$navy,
    secondary    = "#6c757d",
    success      = "#2a7a2a",
    info         = bl_colors$blue,
    warning      = "#b45309",
    danger       = "#9b2226"
  ),

  tags$a(href = "#main-content", class = "skip-link", "Skip to main content"),

  # Application title with dark mode toggle
  fluidRow(
    column(10,
      h2("The Budget Lab's Small Macro Model (BLSMM)"),
      h4("Interactive Policy Simulation Tool", class = "text-muted-custom"),
      div(class = "fy-note",
          "Note: All years are fiscal years (October 1 - September 30)")
    ),
    column(2, style = "text-align: right; padding-top: 15px;",
      input_dark_mode(id = "dark_mode", mode = "light")
    )
  ),

  br(),

  # Responsive sidebar layout (bslib).
  # On narrow screens the sidebar collapses into a toggle button.
  # fillable = FALSE so the main content scrolls naturally (many plots).
  layout_sidebar(
    fillable = FALSE,
    sidebar = sidebar(
      width = 280,
      open = list(desktop = "open", mobile = "closed"),
      title = "Controls",

      # SSE Display - simplified
      div(class = "blsmm-solver-status",
          style = "position: sticky; top: 8px; z-index: 100; background: var(--bs-body-bg); padding-bottom: 8px;",
          h4("Solver Status"),
          div(class = "sse-box",
              textOutput("sse_display", inline = TRUE))
      ),
      div(
        class = "blsmm-run-status-wrap",
        role = "status",
        `aria-live` = "polite",
        style = "margin-top: 8px;",
        uiOutput("run_status_bar")
      ),

      # Main action buttons
      div(class = "sidebar-section",
        h4("Simulation Controls"),
        actionButton("run_sim",
                     "Run Simulation",
                     icon = icon("play"),
                     class = "btn-primary blsmm-action-btn",
                     style = "width: 100%; margin-bottom: 8px;"),

        actionButton("reset_inputs",
                     "Reset to Defaults",
                     icon = icon("rotate-right"),
                     class = "btn-secondary blsmm-action-btn",
                     style = "width: 100%; margin-bottom: 16px;"),

        helpText("Configure shocks in the Inputs tab, then click Run Simulation."),
        helpText("Keyboard shortcut: Alt+R = Run")
      ),

      # Preset Scenarios
      div(class = "sidebar-section",
        h4("Preset Scenarios"),
        p("Quick-start common scenarios:", class = "text-muted-custom", style = "font-size: 0.875em; margin-bottom: 16px;"),

        helpText("Productivity boost + LFPR decline + outlay rise (Karger et al.)",
                 style = "margin-top: -4px; margin-bottom: 8px; font-size: 0.875em;"),
        actionButton("preset_rapid_ai",
                     "Rapid AI Adoption",
                     class = "btn-outline-primary btn-sm blsmm-preset-btn",
                     style = "width: 100%; margin-bottom: 8px;"),

        helpText("Inflation shock peaking at +0.3 pp in FY2028, returning to baseline by FY2030",
                 style = "margin-top: -4px; margin-bottom: 8px; font-size: 0.875em;"),
        actionButton("preset_persistent_infl",
                     "Persistent Inflation",
                     class = "btn-outline-warning btn-sm blsmm-preset-btn",
                     style = "width: 100%; margin-bottom: 8px;"),

        helpText("Defense outlays rise per BR2027 (incl. +$350B FY2027 mandatory)",
                 style = "margin-top: -4px; font-size: 0.875em;"),
        actionButton("preset_military_conflict",
                     "Higher Defense Spending",
                     class = "btn-outline-danger btn-sm blsmm-preset-btn",
                     style = "width: 100%; margin-bottom: 8px;")
      ),

      # Export section
      div(class = "sidebar-section",
        h4("Export Results"),
        downloadButton("download_csv",
                      "Export to CSV",
                      class = "btn-outline-primary",
                      style = "width: 100%; margin-bottom: 8px;"),

        downloadButton("download_excel",
                      "Export to Excel",
                      class = "btn-outline-primary",
                      style = "width: 100%;")
      ),

      div(class = "text-muted-custom", style = "text-align: center; font-size: 0.875em; margin-top: 24px;",
          "Version 1.0. Updated April 2026.")
    ),

    # Main content area
    div(
      id = "main-content",
      class = "blsmm-main",

      tabsetPanel(
        id = "main_tabs",
        selected = "dashboard",

        # ======================================================================
        # TAB 1: INPUTS
        # ======================================================================
        tabPanel(
          value = "inputs",
          tagList(icon("sliders"), " ", tags$b(tags$u("Inputs"))),
          br(),

          # Streamlined Introduction
          p(style = "font-size: 1.1em; margin-bottom: 16px;",
            strong("Enter policy changes below."), " Edit yellow cells to create your scenario. ",
            strong("Zeros = no change from baseline."),
            " Click 'Run Simulation' when ready."
          ),

          p(class = "text-muted-custom", style = "margin-bottom: 24px;",
            icon("info-circle"), " ",
            strong("New users:"), " Start with Primary Budget Balance to simulate a tax or spending policy. ",
            strong("Note:"), " \"pp\" = percentage points (e.g., a change from 2.0% to 2.5% is +0.5 pp)."
          ),

          # Sub-tabs for organizing inputs by category
          tabsetPanel(
            id = "input_subtabs",
            selected = "fiscal_policy",

            # Sub-tab 1: Potential Growth
            tabPanel(
              value = "potential_growth",
              "Potential Growth",
              br(),

              p(strong("What this does: "), "Adjust long-run economic growth by changing labor force and productivity growth rates.", style = "font-size: 1.05em;"),
              p(icon("info-circle"), " Changes here automatically affect the neutral interest rate (r*) and government spending.", class = "text-muted-custom", style = "margin-bottom: 16px;"),

              h4("Potential Productivity Growth Delta (pp)"),
              p(strong("Example:"), " +0.20 increases productivity (GDP per worker) growth by 0.2 percentage points per year"),
              rHandsontableOutput("table_productivity", height = "180px"),
              br(),

              h4("Potential Labor Force Growth Delta (pp)"),
              p(strong("Example:"), " +0.10 increases labor force growth rate by 0.1 percentage points per year"),
              rHandsontableOutput("table_lf_growth", height = "180px")
            ),

            # Sub-tab 2: Primary Budget Balance
            tabPanel(
              value = "fiscal_policy",
              "Primary Budget Balance",
              br(),

              p(strong("What this does: "), "Simulate tax and spending policies by changing federal receipts and outlays as a percent of GDP.", style = "font-size: 1.05em;"),
              p(icon("arrow-right"), " ", strong("How to use: "), "Enter positive values to increase receipts or outlays, negative values to decrease them.", class = "text-muted-custom", style = "margin-bottom: 16px;"),

              h4("Federal Receipts Delta (pp of GDP)"),
              p(strong("Example:"), " +1.00 = tax increase of 1% of GDP | -1.00 = tax cut of 1% of GDP"),
              rHandsontableOutput("table_receipts", height = "180px"),
              br(),

              h4("Federal Primary Outlays Delta (pp of GDP)"),
              p(strong("Example:"), " +1.00 = spending increase of 1% of GDP | -1.00 = spending cut of 1% of GDP"),
              p(class = "text-muted-custom", style = "font-size: 0.875em; margin-top: -8px;", icon("info-circle"), " Primary outlays exclude interest payments on the debt"),
              rHandsontableOutput("table_outlays", height = "180px"),
              br(),
              br(),

              tags$details(
                tags$summary(strong("Advanced: View calculated effects"), class = "text-link", style = "cursor: pointer;"),
                br(),
                h5("Additional Outlay Changes from Economic Growth"),
                p("The model automatically adjusts outlays when economic growth changes:"),
                verbatimTextOutput("outlays_indirect_display"),
                br(),
                h5("Implied Primary Budget Balance Delta"),
                p("Primary balance = Receipts - Outlays (excluding interest payments)"),
                verbatimTextOutput("primary_balance_derived")
              )
            ),

            # Sub-tab 3: Neutral Rate (r*)
            tabPanel(
              value = "neutral_rate",
              "Neutral Rate (r*)",
              br(),

              p(strong("What this does: "), "Change the neutral interest rate - the rate that neither stimulates nor restrains the economy.", style = "font-size: 1.05em;"),
              p(icon("info-circle"), " Use this to model structural changes like demographic shifts or global savings trends.", class = "text-muted-custom", style = "margin-bottom: 16px;"),

              h4("Real Neutral Federal Funds Rate Direct Delta (pp)"),
              p(strong("Example:"), " +0.25 increases r* by 0.25 percentage points | -0.25 decreases r* by 0.25 pp"),
              rHandsontableOutput("table_rfstar", height = "180px"),
              br(),

              tags$details(
                tags$summary(strong("Advanced: View automatic r* adjustments"), class = "text-link", style = "cursor: pointer;"),
                br(),
                p("The neutral rate adjusts automatically based on economic growth and government debt levels:"),
                verbatimTextOutput("rfstar_indirect_display")
              )
            ),

            # Sub-tab 4: Monetary Policy
            tabPanel(
              value = "monetary_policy",
              "Monetary Policy",
              br(),

              h4("Inflation Target Delta (pp)"),
              p(strong("Example:"), " +0.50 = Fed raises target from 2.0% to 2.5% | -0.50 = Fed lowers target to 1.5%"),
              rHandsontableOutput("table_inflation_target", height = "180px"),
              br(),
              checkboxInput("expectations_speed",
                           "Fast Expectations Adjustment",
                           value = FALSE),
              helpText("Check this box if the public immediately adjusts inflation expectations. Uncheck for gradual adjustment."),

              hr(),

              h4("Fed Interest Rate Adjustment (pp)"),
              p("Sets interest rates higher or lower than the Fed would normally choose based on economic conditions. Use this to model unusual Fed actions like forward guidance."),
              p(strong("Example:"), " +0.50 = Fed Funds rate is 0.5 pp higher than normal | -0.50 = 0.5 pp lower than normal"),
              rHandsontableOutput("table_monetary_rule", height = "180px")
            ),

            # Sub-tab 5: Demand Shocks
            tabPanel(
              value = "demand_shocks",
              "Demand Shocks",
              br(),
              h4("Output Gap Shock Delta (pp)"),
              p("Model changes in private sector demand (consumer/business confidence, wealth effects from stock markets)."),
              p(strong("Example:"), " +2.00 = positive demand shock pushing output 2 pp above potential | -2.00 = negative demand shock"),
              rHandsontableOutput("table_output_gap", height = "180px")
            ),

            # Sub-tab 6: Unexpected Shocks
            tabPanel(
              value = "unexpected_shocks",
              "Unexpected Shocks",
              br(),

              h4("Unexpected Inflation Shock Delta (pp)"),
              p("Model temporary supply shocks like oil price spikes or pandemic disruptions. These are one-time events."),
              p(strong("Example:"), " +1.00 means inflation is 1 percentage point higher than baseline for that year"),
              rHandsontableOutput("table_inflation_shock", height = "180px")
            ),

            # Sub-tab 7: User Deltas Summary
            tabPanel(
              value = "user_deltas_summary",
              tagList(icon("list-check"), " User Deltas Summary"),
              br(),

              h4("Consolidated View of All User Inputs"),
              helpText("This table consolidates all your inputs from the Inputs tab. All values are read-only. If any value is non-zero, that scenario is active."),

              br(),

              DTOutput("summary_all_deltas")
            )
          )
        ),

        # ======================================================================
        # TAB 3: DASHBOARD
        # ======================================================================
        tabPanel(
          value = "dashboard",
          tagList(icon("gauge-high"), " ", tags$b(tags$u("Dashboard"))),
          br(),

          div(class = "alert alert-secondary",
              strong("Getting started: "),
              "Configure your inputs in the sidebar and click 'Run Simulation' to see results. ",
              strong("How to read: "),
              "All charts compare Baseline (dashed) vs Scenario (solid). ",
              "Rates and inflation are percentage points; debt and balances are percent of GDP. ",
              "For budget charts, more negative values indicate larger deficits."
          ),

          # KPI Value Boxes (stack under narrow widths)
          layout_column_wrap(
            width = "280px",
            value_box(
              title = "Final Debt Impact",
              value = textOutput("kpi_final_debt"),
              showcase = icon("scale-balanced"),
              theme = "primary",
              p("Change in debt/GDP ratio", style = "font-size: 0.85em;")
            ),
            value_box(
              title = "Max Unemployment Effect",
              value = textOutput("kpi_max_unemployment"),
              showcase = icon("users"),
              theme = "primary",
              p("Peak change in unemployment", style = "font-size: 0.85em;")
            )
          ),

          br(),

          # 13 dashboard plots in a responsive grid.
          # Single column below ~800px container; two columns above.
          layout_column_wrap(
            width = "400px",
            plotlyOutput("plot_unemployment",       height = "360px"),
            plotlyOutput("plot_inflation",          height = "360px"),
            plotlyOutput("plot_real_gdp_indexed",   height = "360px"),
            plotlyOutput("plot_10yr_yield",         height = "360px"),
            plotlyOutput("plot_federal_funds",      height = "360px"),
            plotlyOutput("plot_budget_balance",     height = "360px"),
            plotlyOutput("plot_debt",               height = "360px"),
            plotlyOutput("plot_avg_interest_rate",  height = "360px"),
            plotlyOutput("plot_total_receipts",     height = "360px"),
            plotlyOutput("plot_total_outlays",      height = "360px"),
            plotlyOutput("plot_primary_outlays",    height = "360px"),
            plotlyOutput("plot_real_gdp_growth",    height = "360px"),
            plotlyOutput("plot_primary_balance",    height = "360px")
          )
        ),

        # ======================================================================
        # TAB 4: DEVIATIONS
        # ======================================================================
        tabPanel(
          tagList(icon("chart-line"), " Deviations"),
          br(),

          # Key Variable Deviations Table
          h4("Key Variable Deviations"),
          helpText("Difference between scenario and baseline (Scenario - Baseline)"),
          DTOutput("deviation_table"),

          br(),
          hr(),

          # Deviation Charts
          h4("Impact Analysis"),
          helpText("Deviations = Scenario - Baseline. Positive means the scenario is higher than baseline; negative means lower."),

          br(),

          # 8 deviation plots — same responsive pattern as Dashboard
          layout_column_wrap(
            width = "400px",
            plotlyOutput("dev_plot_output_gap",      height = "360px"),
            plotlyOutput("dev_plot_unemployment",    height = "360px"),
            plotlyOutput("dev_plot_real_gdp_growth", height = "360px"),
            plotlyOutput("dev_plot_inflation",       height = "360px"),
            plotlyOutput("dev_plot_debt",            height = "360px"),
            plotlyOutput("dev_plot_federal_funds",   height = "360px"),
            plotlyOutput("dev_plot_10yr_yield",      height = "360px"),
            plotlyOutput("dev_plot_primary_balance", height = "360px")
          ),

          br(),
          hr(),

          # Fiscal Multiplier and Summary Statistics
          fluidRow(
            column(6,
                   h4("Fiscal Multiplier"),
                   verbatimTextOutput("multiplier_display")
            ),
            column(6,
                   h4("Deviation Summary Statistics"),
                   verbatimTextOutput("deviation_summary")
            )
          )
        ),

        # ======================================================================
        # TAB 6: ABOUT
        # ======================================================================
        tabPanel(
          tagList(icon("info-circle"), " About"),
          br(),

          h3("The Budget Lab's Small Macro Model"),

          div(class = "bg-info-light", style = "font-size: 1.05em; padding: 24px; border-radius: 8px; margin-bottom: 24px;",
              p(strong("What is BLSMM?"), style = "margin-bottom: 8px;"),
              p("An interactive tool for exploring how fiscal and monetary policies affect the economy over 10 years. Simulate the interactions between government spending, taxation, Federal Reserve policy, economic growth, interest rates, and national debt.", style = "margin-bottom: 16px;"),

              p(strong("Who should use it:"), style = "margin-bottom: 8px;"),
              tags$ul(style = "margin-bottom: 16px;",
                tags$li("Policy analysts studying tax and spending proposals"),
                tags$li("Researchers exploring fiscal-monetary interactions"),
                tags$li("Students learning macroeconomic policy dynamics")
              ),

              p(strong("What you can learn:"), style = "margin-bottom: 8px;"),
              tags$ul(style = "margin-bottom: 0;",
                tags$li("How policy changes affect growth, unemployment, inflation, and debt"),
                tags$li("Automatic economic responses (e.g., Fed reacts to inflation, interest costs rise with debt)"),
                tags$li("Trade-offs and side effects of policy choices")
              )
          ),

          h4(icon("rocket"), " Quick Start: Your First Simulation", style = "margin-top: 32px; margin-bottom: 16px;"),

          div(class = "card bg-blue-light", style = "padding: 24px; margin-bottom: 24px; border-radius: 8px;",
              tags$ol(style = "line-height: 2;",
                tags$li(strong("Go to the Inputs tab"), " (first tab at top)"),
                tags$li(strong("Click 'Primary Budget Balance'"), " sub-tab (selected by default)"),
                tags$li(strong("Click on a yellow cell"), " in the Receipts table (e.g., FY2027 column)"),
                tags$li(strong("Type: 1.0"), " and press Enter (simulates a 1% of GDP tax increase)"),
                tags$li(strong("Click 'Run Simulation'"), " in the left sidebar"),
                tags$li(strong("Wait for 'Complete'"), " status"),
                tags$li(strong("Explore results:"),
                  tags$ul(
                    tags$li("Dashboard tab - all economic variables over time"),
                    tags$li("Deviations tab - how your scenario differs from baseline")
                  )
                )
              ),
              p(style = "margin-top: 16px; font-style: italic; margin-bottom: 0;",
                icon("check-circle"), " Success! You've simulated a tax increase and seen its economic effects.")
          ),

          h4("How to Use", style = "margin-top: 32px; margin-bottom: 16px;"),

          tags$ol(style = "line-height: 1.8; margin-bottom: 16px;",
            tags$li(strong("Inputs tab:"), " Enter policy changes (zeros = no change from baseline)"),
            tags$li(strong("Run Simulation:"), " Click button in sidebar and wait for 'Complete' status"),
            tags$li(strong("Dashboard:"), " View all economic variables over time"),
            tags$li(strong("Deviations:"), " See how your scenario differs from baseline"),
            tags$li(strong("Export:"), " Download results as CSV or Excel")
          ),

          p(icon("info-circle"), " ", strong("Tip: "), "Most scenarios only need 1-2 input categories. Start with Primary Budget Balance for fiscal policy.", class = "text-link", style = "margin-bottom: 32px;"),

          h4("Example Use Cases", style = "margin-bottom: 16px;"),

          div(class = "bg-yellow-light", style = "padding: 24px; border-radius: 8px; margin-bottom: 32px;",
              tags$ul(style = "line-height: 1.8; margin-bottom: 0;",
                tags$li(strong("Tax Reform Analysis:"), " Model a corporate tax cut and see effects on growth, deficits, and interest rates"),
                tags$li(strong("Fiscal Consolidation:"), " Test different paths to reduce debt-to-GDP (spending cuts vs. tax increases vs. growth)"),
                tags$li(strong("Fed Policy Changes:"), " Explore higher inflation targets or unconventional monetary policy"),
                tags$li(strong("Growth Scenarios:"), " Study effects of productivity slowdowns or labor force changes"),
                tags$li(strong("Policy Interactions:"), " See how fiscal and monetary policies work together or in opposition")
              )
          ),

          h4("Understanding Your Results", style = "margin-bottom: 16px;"),

          p("After running a simulation, here's what to look for:", style = "margin-bottom: 16px;"),

          div(class = "bg-blue-pale", style = "padding: 24px; border-radius: 8px; margin-bottom: 16px;",
              p(strong("Key Variables to Watch:"), style = "margin-bottom: 8px;"),
              tags$ul(style = "margin-bottom: 0; line-height: 1.8;",
                tags$li(strong("Output Gap:"), " Positive = economy overheating. Negative = economic slack. The Fed tries to close this gap."),
                tags$li(strong("Unemployment:"), " How your policy affects jobs. Connected to output gap through Okun's Law."),
                tags$li(strong("Inflation:"), " Higher than baseline means your policy is inflationary. Watch how it evolves over time."),
                tags$li(strong("Debt/GDP:"), " The key long-run fiscal indicator. Rising debt means policy worsens the fiscal outlook."),
                tags$li(strong("Interest Rates:"), " Shows Fed response and market rates. Higher rates can dampen stimulus effects."),
                tags$li(strong("Primary Balance:"), " Deficit before interest costs. Compare to Debt/GDP for sustainability.")
              )
          ),

          div(class = "bg-red-light", style = "padding: 24px; border-radius: 8px; margin-bottom: 32px;",
              p(strong("Warning Signs:"), class = "text-warning-custom", style = "margin-bottom: 8px;"),
              tags$ul(style = "margin-bottom: 0; line-height: 1.8;",
                tags$li("Debt/GDP rising sharply without stabilizing"),
                tags$li("Inflation persistently far from the Fed's 2% target"),
                tags$li("Interest rates hitting zero (model has limitations at zero lower bound)"),
                tags$li("Unrealistic combinations (e.g., large deficits with no interest rate response)")
              )
          ),

          tags$details(
            tags$summary(strong("Advanced: Technical Details"), class = "text-muted-custom", style = "cursor: pointer; font-size: 1.1em;"),
            br(),

            h5("Model Overview"),
            tags$ul(
              tags$li(strong("Type:"), " Structural macroeconomic model"),
              tags$li(strong("Frequency:"), " Annual (Fiscal Years: October 1 - September 30)"),
              tags$li(strong("Version:"), " 1.8 (with endogenous r* and fiscal feedback)"),
              tags$li(strong("Structure:"), " 9 simultaneous equations + pre-simulation block + fiscal block"),
              tags$li(strong("Parameters:"), " 39 calibrated parameters")
            ),

            h5("Model Components"),
            tags$ul(
              tags$li(strong("Macro Block:"), " Output gap with 8-period distributed lags, unemployment (Okun's law), inflation (Phillips curve), inflation expectations"),
              tags$li(strong("Monetary Block:"), " Taylor rule, term structure of interest rates, endogenous real neutral rate (r*)"),
              tags$li(strong("Fiscal Block:"), " Debt dynamics, net interest payments, primary balance, fiscal feedback to outlays"),
              tags$li(strong("Neutral Rate Block:"), " r* responds to potential growth and debt/GDP")
            ),

            h5("Key Features"),
            tags$ul(
              tags$li("Endogenous neutral rate that responds to growth and debt"),
              tags$li("Automatic fiscal feedback (spending adjusts to growth)"),
              tags$li("Rich dynamics through distributed lags"),
              tags$li("Year-by-year control over all inputs (FY2026-FY2035)"),
              tags$li("Real-time convergence diagnostics")
            )
          ),

          hr(),

          p(em("For questions or support, contact The Budget Lab at Yale.")),

          p(strong("Last Updated:"), " April 2026")
        )
      )
    )
  )
)

# ==============================================================================
# SERVER LOGIC
# ==============================================================================

