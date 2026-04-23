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
    # iframe-resizer child script: lets a parent page auto-size this iframe
    # to its content height so there are no nested scrollbars. Safe to load
    # when not embedded - it's a no-op unless a parent calls iFrameResize().
    tags$script(src = "https://cdn.jsdelivr.net/npm/iframe-resizer@4.4.5/js/iframeResizer.contentWindow.min.js"),
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

      /* Input table styling */
      .handsontable td {
        text-align: right;
      }

      .handsontable .htDimmed {
        color: #999;
      }

/* Fiscal year note */
      .fy-note {
        font-size: 0.875em;
        color: #666;
        font-style: italic;
        margin-top: -8px;
        margin-bottom: 8px;
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
        text-align: center;
        line-height: 1.35;
      }
      .run-ready { background: #e9ecef; color: #343a40; border-color: #ced4da; }
      .run-dirty { background: #fff3cd; color: #856404; border-color: #ffe69c; }
      .run-running { background: #cfe2ff; color: #084298; border-color: #9ec5fe; }
      .run-solved { background: #d1e7dd; color: #0f5132; border-color: #a3cfbb; }
      .run-error { background: #f8d7da; color: #842029; border-color: #f1aeb5; }
/* Muted text color class */
      .text-muted-custom {
        color: #666;
      }
/* Link color class */
      .text-link {
        color: #0066cc;
      }
/* Warning text color */
      .text-warning-custom {
        color: #cc0000;
      }
/* Info box backgrounds */
      .bg-info-light {
        background-color: #f8f9fa;
      }
.bg-blue-light {
        background-color: #e7f3ff;
        border-left: 4px solid #0066cc;
      }
.bg-yellow-light {
        background-color: #fff9e6;
      }
.bg-blue-pale {
        background-color: #f0f8ff;
      }
.bg-red-light {
        background-color: #fff0f0;
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
/* Sidebar section styling for visual separation */
      .sidebar-section {
        padding: 16px;
        margin-bottom: 16px;
        border-radius: 8px;
        background-color: #f8f9fa;
        border: 1px solid #e9ecef;
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
")),
    tags$script(HTML("
      // Only one Bootstrap popover open at a time. When a popover is
      // about to be shown, hide every other currently-open popover.
      document.addEventListener('show.bs.popover', function(e) {
        var opening = e.target;
        document.querySelectorAll('.popover.show').forEach(function(popEl) {
          var describedTrigger = document.querySelector(
            '[aria-describedby=\"' + popEl.id + '\"]'
          );
          if (describedTrigger && describedTrigger !== opening &&
              window.bootstrap && bootstrap.Popover) {
            var inst = bootstrap.Popover.getInstance(describedTrigger);
            if (inst) inst.hide();
          }
        });
      });

      // Click outside an open popover -> close it. A click INSIDE the
      // popover itself, or ON its trigger, is left alone (trigger click
      // is Bootstrap's own toggle behavior).
      document.addEventListener('click', function(e) {
        if (!window.bootstrap || !bootstrap.Popover) return;
        if (e.target.closest('.popover')) return;                   // inside popover body
        if (e.target.closest('[data-bs-toggle=\"popover\"]')) return; // trigger element
        if (e.target.closest('.blsmm-info-trigger')) return;          // our info trigger class
        document.querySelectorAll('.popover.show').forEach(function(popEl) {
          var describedTrigger = document.querySelector(
            '[aria-describedby=\"' + popEl.id + '\"]'
          );
          if (describedTrigger) {
            var inst = bootstrap.Popover.getInstance(describedTrigger);
            if (inst) inst.hide();
          }
        });
      });

      // Safety-net handler for offcanvas dismiss (X close button).
      // Bootstrap's auto-wiring sometimes misses clicks on .btn-close
      // inside responsive offcanvases (.offcanvas-md). This delegates
      // a click listener to the document so the X button always works.
      document.addEventListener('click', function(e) {
        var btn = e.target.closest('[data-bs-dismiss=\"offcanvas\"]');
        if (!btn) return;
        var container = btn.closest(
          '.offcanvas, .offcanvas-md, .offcanvas-sm, .offcanvas-lg, .offcanvas-xl'
        );
        if (container && window.bootstrap && bootstrap.Offcanvas) {
          bootstrap.Offcanvas.getOrCreateInstance(container).hide();
        }
      });

      // Clicking the dark .offcanvas-backdrop dismisses every visible
      // offcanvas. Bootstrap normally wires this itself but misses when
      // multiple offcanvases share a stack (e.g., the Controls drawer
      // open at the same time as the Custom Scenario Builder).
      document.addEventListener('click', function(e) {
        if (!e.target.classList ||
            !e.target.classList.contains('offcanvas-backdrop')) return;
        if (!window.bootstrap || !bootstrap.Offcanvas) return;
        document.querySelectorAll(
          '.offcanvas.show, .offcanvas-md.show, .offcanvas-sm.show, .offcanvas-lg.show, .offcanvas-xl.show'
        ).forEach(function(el) {
          bootstrap.Offcanvas.getOrCreateInstance(el).hide();
        });
      });

      // On narrow widths, opening the Custom Scenario Builder while the
      // Controls drawer is also open leaves Controls behind with no tint
      // (Bootstrap reuses a single backdrop for both). Close Controls
      // first, then let Bootstrap's toggle handler open CSB. On wide
      // widths Controls is inline (no .show class) so this is a no-op.
      //
      // Track whether Controls was open so we can restore it when CSB
      // closes — the user's next action is almost always Run Simulation,
      // which lives in Controls.
      var __blsmmControlsWasOpen = false;
      document.addEventListener('click', function(e) {
        var customBtn = e.target.closest('#open_assumptions');
        if (!customBtn) return;
        var controlsDrawer = document.getElementById('controls_drawer');
        if (!controlsDrawer || !controlsDrawer.classList.contains('show')) return;
        if (!window.bootstrap || !bootstrap.Offcanvas) return;
        var inst = bootstrap.Offcanvas.getInstance(controlsDrawer);
        if (inst) {
          __blsmmControlsWasOpen = true;
          inst.hide();
        }
      });
      // When CSB closes, reopen Controls if it was open before. Listen
      // on hide.bs.offcanvas (START of hide animation) rather than
      // hidden.bs.offcanvas (end), so Controls starts sliding IN while
      // CSB slides OUT — parallel animations that mirror the smooth
      // forward transition (Controls -> CSB). Bootstrap offcanvas events
      // bubble, so a document-level listener catches it.
      document.addEventListener('hide.bs.offcanvas', function(e) {
        if (!e.target || e.target.id !== 'assumptions_drawer') return;
        if (!__blsmmControlsWasOpen) return;
        __blsmmControlsWasOpen = false;
        var controlsDrawer = document.getElementById('controls_drawer');
        if (controlsDrawer && window.bootstrap && bootstrap.Offcanvas) {
          bootstrap.Offcanvas.getOrCreateInstance(controlsDrawer).show();
        }
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

  # No in-app header: the title, subtitle, and FY note are duplicative of
  # the Budget Lab website page that embeds this iframe. Fiscal year
  # context is carried in the Getting Started alert on the Results tab
  # and in the About tab for anyone who needs it.

  # App shell: responsive Bootstrap offcanvas for Controls + main content.
  # At >= md (768px): the Controls drawer renders inline as a 280px left
  # column (Bootstrap's .offcanvas-md reverts to normal flow at md+).
  # At < md: Controls is hidden behind an offcanvas drawer, opened by the
  # sticky toggle button at the top of the main area. Bootstrap handles the
  # dark backdrop, focus trap, Escape key, click-outside-to-close, and ARIA
  # state natively — same mechanism as the Custom Scenario Builder drawer.
  div(class = "d-flex flex-row blsmm-shell",

    # ------------------------------------------------------------------
    # CONTROLS — responsive offcanvas drawer
    # ------------------------------------------------------------------
    tags$div(
      class = "offcanvas-md offcanvas-start blsmm-controls-drawer",
      id = "controls_drawer",
      tabindex = "-1",
      `aria-labelledby` = "controls_drawer_label",

      # Drawer header: visible at every width so the sidebar is always
      # identifiable as "Controls". The close (X) button is hidden at md+
      # via CSS since the sidebar is always visible there.
      tags$div(class = "offcanvas-header blsmm-controls-header",
        h4(id = "controls_drawer_label", class = "offcanvas-title mb-0",
           "Controls"),
        tags$button(type = "button",
                    class = "btn-close blsmm-controls-close",
                    `data-bs-dismiss` = "offcanvas",
                    `data-bs-target` = "#controls_drawer",
                    `aria-label` = "Close")
      ),

      tags$div(class = "offcanvas-body blsmm-controls-body",

        # SCENARIO: Custom (opens Custom Scenario Builder drawer) or
        # one of three presets. Reset to Defaults also lives here since
        # it's a scenario-level control (wipes the current scenario
        # back to baseline).
        div(class = "sidebar-section",
          h4("Scenario"),

          # Custom Scenario — the primary option. Larger button.
          # Outline by default; fills navy via .preset-active when the
          # user has a custom scenario live (server toggles the class
          # via the custom_scenario_active reactive).
          tags$button(
            id = "open_assumptions",
            type = "button",
            class = "btn btn-outline-primary blsmm-action-btn blsmm-scenario-primary blsmm-preset-btn",
            style = "width: 100%; margin-bottom: 14px;",
            `data-bs-toggle` = "offcanvas",
            `data-bs-target` = "#assumptions_drawer",
            `aria-controls` = "assumptions_drawer",
            tags$i(class = "fa fa-sliders", `aria-hidden` = "true"),
            tags$span(" Custom Scenario")
          ),

          p("Or start from a preset:", class = "text-muted-custom",
            style = "font-size: 0.875em; margin-bottom: 8px;"),

          # Presets: all uniform (outline-primary). Description lives in a
          # popover triggered by the ? icon to the right of each button.
          preset_row("preset_rapid_ai", "Rapid AI Adoption",
                     "Productivity boost + labor-force participation decline + outlay rise (Karger et al.)."),
          preset_row("preset_persistent_infl", "Persistent Inflation",
                     "Inflation shock peaking at +0.3 pp in FY2028, returning to baseline by FY2030."),
          preset_row("preset_military_conflict", "Higher Defense Spending",
                     "Defense outlays rise per BR2027, including a +$350B mandatory bump in FY2027."),

          # Reset — scenario-level control. Softer visual weight than Custom.
          actionButton("reset_inputs",
                       "Reset to Defaults",
                       icon = icon("rotate-right"),
                       class = "btn btn-outline-secondary btn-sm",
                       style = "width: 100%; margin-top: 10px;")
        ),

        # SIMULATION: Run button + run-status pill.
        # (The raw SSE pill was removed as visual noise; run_status_bar
        # already surfaces Complete/Error/etc. in a user-friendly form.
        # The sse_display output is still rendered server-side but no
        # longer shown in the UI.)
        div(class = "sidebar-section",
          h4("Simulation"),
          actionButton("run_sim",
                       "Run Simulation",
                       icon = icon("play"),
                       class = "btn-primary blsmm-action-btn",
                       style = "width: 100%; margin-bottom: 12px;"),

          # Run status pill (READY / DIRTY / Complete / ERROR)
          div(class = "blsmm-sim-status-wrap",
              role = "status",
              `aria-live` = "polite",
              uiOutput("run_status_bar")
          )
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

        div(class = "text-muted-custom",
            style = "text-align: center; font-size: 0.875em; margin-top: 24px;",
            "Version 1.0")
      )
    ),

    # ------------------------------------------------------------------
    # MAIN CONTENT
    # ------------------------------------------------------------------
    tags$main(
      id = "main-content",
      class = "blsmm-main flex-grow-1",

      # Mobile-only top bar with a hamburger menu toggle. Hidden at >= md
      # via d-md-none. Sticky so it stays reachable as the user scrolls.
      # Hamburger icon (fa-bars) signals "drawer from the left" to users
      # familiar with mobile app top-bar patterns. Subtle styling — not a
      # navy primary button — so it doesn't compete with Run Simulation
      # as an action.
      tags$button(
        id = "toggle_controls",
        type = "button",
        class = "d-md-none blsmm-controls-toggle",
        `data-bs-toggle` = "offcanvas",
        `data-bs-target` = "#controls_drawer",
        `aria-controls` = "controls_drawer",
        `aria-label` = "Open controls menu",
        tags$i(class = "fa fa-bars", `aria-hidden` = "true"),
        tags$span(class = "blsmm-controls-toggle-label", "Controls")
      ),

      tabsetPanel(
        id = "main_tabs",
        selected = "results",

        # ======================================================================
        # INPUTS — removed. The 9 input categories live in an offcanvas
        # drawer opened by the Custom Scenario button in the sidebar; see
        # the drawer definition at the end of this UI. Each category's
        # "Edit year-by-year" disclosure renders a native numericInput
        # strip (see year_by_year_input_strip() in blsmm_helpers.R).
        # ======================================================================

        # ======================================================================
        # TAB: RESULTS (merged Dashboard + Deviations)
        # ======================================================================
        tabPanel(
          value = "results",
          tagList(icon("gauge-high"), " Results"),
          br(),

          # Getting started box removed — tutorial content lives in the
          # About tab and the Controls sidebar is visible / self-evident.

          # KPI Value Boxes — always visible above the level/deviation toggle.
          # 200px min so two fit side-by-side in a 900px iframe's main area;
          # labels wrap to multiple lines inside each card when tight.
          # showcase_left_center pins the icon to a left column that never
          # wraps above the text block.
          layout_column_wrap(
            width = "200px",
            gap = "12px",
            value_box(
              title = "Final Debt Impact",
              value = textOutput("kpi_final_debt"),
              showcase = icon("scale-balanced"),
              showcase_layout = showcase_left_center(),
              theme = value_box_theme(bg = "#ffffff", fg = bl_colors$navy),
              class = "blsmm-kpi-card",
              p("Change in debt/GDP ratio")
            ),
            value_box(
              title = "Max Unemployment Effect",
              value = textOutput("kpi_max_unemployment"),
              showcase = icon("users"),
              showcase_layout = showcase_left_center(),
              theme = value_box_theme(bg = "#ffffff", fg = bl_colors$navy),
              class = "blsmm-kpi-card",
              p("Peak change in unemployment")
            )
          ),

          # br() removed — navset_underline's own top margin gives
          # enough space; matches the gap above the KPI cards.

          # Tab toggle between Levels and Deviations-from-baseline views.
          navset_underline(
            id = "results_view",

            # Levels view: 13 plots showing absolute values (baseline +
            # scenario lines on each chart).
            nav_panel(
              title = "Levels",
              br(),
              layout_column_wrap(
                width = "400px",
                plotlyOutput("plot_budget_balance",     height = "360px"),
                plotlyOutput("plot_debt",               height = "360px"),
                plotlyOutput("plot_avg_interest_rate",  height = "360px"),
                plotlyOutput("plot_total_receipts",     height = "360px"),
                plotlyOutput("plot_total_outlays",      height = "360px"),
                plotlyOutput("plot_unemployment",       height = "360px"),
                plotlyOutput("plot_inflation",          height = "360px"),
                plotlyOutput("plot_10yr_yield",         height = "360px"),
                plotlyOutput("plot_federal_funds",      height = "360px"),
                plotlyOutput("plot_primary_outlays",    height = "360px"),
                plotlyOutput("plot_real_gdp_growth",    height = "360px"),
                plotlyOutput("plot_primary_balance",    height = "360px")
              )
            ),

            # Deviations view: key variable table, 8 deviation plots,
            # fiscal multiplier + deviation summary.
            nav_panel(
              title = "Deviations from baseline",
              br(),

              div(class = "d-flex align-items-center gap-2 mb-2",
                h4("Key Variable Deviations", class = "mb-0"),
                bslib::popover(
                  trigger = tags$button(
                    type  = "button",
                    class = "blsmm-info-trigger blsmm-info-trigger-inline",
                    `aria-label` = "How to read deviations",
                    tags$i(class = "fa fa-circle-question", `aria-hidden` = "true")
                  ),
                  "Deviations = Scenario - Baseline. Positive means the scenario is higher than baseline; negative means lower.",
                  placement = "right"
                )
              ),
              DTOutput("deviation_table"),

              br(),
              hr(),

              h4("Impact Analysis"),
              br(),
              layout_column_wrap(
                width = "400px",
                plotlyOutput("dev_plot_primary_balance", height = "360px"),
                plotlyOutput("dev_plot_debt",            height = "360px"),
                plotlyOutput("dev_plot_unemployment",    height = "360px"),
                plotlyOutput("dev_plot_inflation",       height = "360px"),
                plotlyOutput("dev_plot_10yr_yield",      height = "360px"),
                plotlyOutput("dev_plot_federal_funds",   height = "360px"),
                plotlyOutput("dev_plot_real_gdp_growth", height = "360px"),
                plotlyOutput("dev_plot_output_gap",      height = "360px")
              ),

              br(),
              hr(),

              layout_column_wrap(
                width = "280px",
                div(
                  h4("Fiscal Multiplier"),
                  verbatimTextOutput("multiplier_display")
                ),
                div(
                  h4("Deviation Summary Statistics"),
                  verbatimTextOutput("deviation_summary")
                )
              )
            )
          )
        ),

        # ======================================================================
        # TAB: SCENARIO SUMMARY (read-only table of all 9 user deltas;
        # mirrored inside the Custom Scenario Builder drawer accordion)
        # ======================================================================
        tabPanel(
          value = "scenario_summary",
          tagList(icon("list-check"), " Scenario Summary"),
          br(),
          helpText("All deltas in current scenario"),
          DTOutput("summary_all_deltas_results")
        ),

        # ======================================================================
        # TAB: ABOUT
        # ======================================================================
        tabPanel(
          tagList(icon("info-circle"), " About"),
          br(),

          div(class = "bg-info-light", style = "font-size: 1.05em; padding: 24px; border-radius: 8px; margin-bottom: 24px;",
              p(
                strong("The Budget Lab Small Macro Model (BLSMM)"),
                " is an interactive tool for exploring how fiscal and monetary policies affect the U.S. economy over a 10-year horizon (FY2026–FY2035). The model simulates interactions between government spending, taxation, Federal Reserve policy, potential growth, interest rates, and national debt.",
                style = "margin-bottom: 16px;"),

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

          h4("Getting started", style = "margin-top: 32px; margin-bottom: 16px;"),

          div(class = "bg-info-light", style = "padding: 24px; margin-bottom: 24px; border-radius: 8px;",
              tags$ol(style = "line-height: 2;",
                tags$li("Build a custom scenario in the Controls sidebar or start with a preset (Rapid AI Adoption, Persistent Inflation, Higher Defense Spending)."),
                tags$li("Click ", strong("Run Simulation"), " and wait for the status indicator to read ", strong("Simulation Complete"), "."),
                tags$li("Use the ", strong("Levels"), " / ", strong("Deviations from baseline"), " tabs on the Results page to compare baseline and scenario."),
                tags$li("Download the raw numbers via ", strong("Export Results"), " (CSV or Excel) in the sidebar.")
              ),
              p(style = "margin-top: 16px; font-style: italic; margin-bottom: 0;",
                icon("check-circle"), " Tip: most scenarios only need one or two assumption categories. The preset buttons populate realistic multi-category shocks if you want a starting point.")
          ),

          h4("Reading the results", style = "margin-top: 32px; margin-bottom: 16px;"),

          div(class = "bg-info-light", style = "padding: 24px; border-radius: 8px; margin-bottom: 16px;",
              p(strong("Chart conventions:"), style = "margin-bottom: 8px;"),
              tags$ul(style = "margin-bottom: 16px; line-height: 1.6;",
                tags$li("Baseline lines are ", strong("dashed"), "; scenario lines are ", strong("solid"), ". Both use the same color because they represent the same variable."),
                tags$li("Rates and inflation are in percentage points. Debt and budget balances are percent of GDP."),
                tags$li("For budget-balance charts, more negative = larger deficit.")
              ),
              p(strong("Key variables to watch:"), style = "margin-bottom: 8px;"),
              tags$ul(style = "margin-bottom: 0; line-height: 1.6;",
                tags$li(strong("Output Gap:"), " Positive = economy overheating. Negative = economic slack. The Fed tries to close this gap."),
                tags$li(strong("Unemployment:"), " Connected to the output gap through Okun's Law."),
                tags$li(strong("Inflation:"), " Above baseline means the scenario is inflationary."),
                tags$li(strong("Debt / GDP:"), " The key long-run fiscal indicator."),
                tags$li(strong("Interest Rates:"), " Fed response (Federal Funds) and market response (10-year yield, r*)."),
                tags$li(strong("Primary Balance:"), " Deficit before interest costs. Compare to debt/GDP for sustainability.")
              )
          ),

          div(class = "bg-red-light", style = "padding: 24px; border-radius: 8px; margin-bottom: 32px;",
              p(strong("Warning signs in your simulation:"), class = "text-warning-custom", style = "margin-bottom: 8px;"),
              tags$ul(style = "margin-bottom: 0; line-height: 1.6;",
                tags$li("Debt/GDP rising sharply without stabilizing"),
                tags$li("Inflation persistently far from the Fed's 2% target"),
                tags$li("Interest rates hitting zero (the model has limitations at the zero lower bound)"),
                tags$li("Unrealistic combinations (e.g., very large deficits with no interest-rate response)")
              )
          ),

          h4("Example use cases", style = "margin-bottom: 16px;"),

          div(class = "bg-info-light", style = "padding: 24px; border-radius: 8px; margin-bottom: 32px;",
              tags$ul(style = "line-height: 1.8; margin-bottom: 0;",
                tags$li(strong("Tax Reform Analysis:"), " Model a corporate tax cut and see effects on growth, deficits, and interest rates"),
                tags$li(strong("Fiscal Consolidation:"), " Test different paths to reduce debt-to-GDP (spending cuts vs. tax increases vs. growth)"),
                tags$li(strong("Fed Policy Changes:"), " Explore higher inflation targets or unconventional monetary policy"),
                tags$li(strong("Growth Scenarios:"), " Study effects of productivity slowdowns or labor force changes"),
                tags$li(strong("Policy Interactions:"), " See how fiscal and monetary policies work together or in opposition")
              )
          ),

          tags$details(
            tags$summary(strong("Advanced: technical details"), class = "text-muted-custom", style = "cursor: pointer; font-size: 1.1em;"),
            br(),

            h5("Model overview"),
            tags$ul(
              tags$li(strong("Type:"), " Structural macroeconomic model"),
              tags$li(strong("Frequency:"), " Annual (fiscal years, October 1 – September 30)"),
              tags$li(strong("Version:"), " 1.0"),
              tags$li(strong("Structure:"), " 9 simultaneous equations + pre-simulation block + fiscal block"),
              tags$li(strong("Parameters:"), " 39 calibrated parameters")
            ),

            h5("Model components"),
            tags$ul(
              tags$li(strong("Macro block:"), " Output gap with 8-period distributed lags, unemployment (Okun's law), inflation (Phillips curve), inflation expectations"),
              tags$li(strong("Monetary block:"), " Taylor rule, term structure of interest rates, endogenous real neutral rate (r*)"),
              tags$li(strong("Fiscal block:"), " Debt dynamics, net interest payments, primary balance, fiscal feedback to outlays"),
              tags$li(strong("Neutral rate block:"), " r* responds to potential growth and debt/GDP")
            ),

            h5("Simple vs. year-by-year inputs"),
            p("Each assumption in the drawer defaults to a simple shape + magnitude UI (permanent / one-time / linear ramp / three-year temporary). If you need the full 10-year path, expand the ", strong("Edit year-by-year"), " disclosure under any input to edit individual FY2026–FY2035 cells directly."),

            h5("Key features"),
            tags$ul(
              tags$li("Endogenous neutral rate that responds to growth and debt"),
              tags$li("Automatic fiscal feedback (spending adjusts to growth)"),
              tags$li("Rich dynamics through distributed lags"),
              tags$li("Year-by-year control over all inputs (FY2026–FY2035)"),
              tags$li("Real-time convergence diagnostics in the sidebar")
            )
          ),

          hr(),

          p(HTML('For questions or support, contact <a href="mailto:budgetlab@yale.edu">The Budget Lab</a>.'))
        )
      )
    )
  ),

  # ============================================================================
  # CUSTOM SCENARIO BUILDER (Bootstrap 5 offcanvas)
  # Opened by the "Custom Scenario" button in the sidebar. Holds the 9 input
  # shape+magnitude controls (with handsontable fallback under Edit year-by-
  # year), organized into three accordion sections plus a read-only
  # consolidated summary. Slides in from the right so it does not overlap
  # the left sidebar or obscure the Results view while editing.
  # ============================================================================
  tags$div(
    class = "offcanvas offcanvas-end blsmm-assumptions-drawer",
    id = "assumptions_drawer",
    tabindex = "-1",
    `aria-labelledby` = "assumptions_drawer_label",

    tags$div(
      class = "offcanvas-header blsmm-controls-header",
      h4(id = "assumptions_drawer_label", class = "offcanvas-title mb-0",
         "Custom Scenario Builder"),
      tags$button(
        type = "button",
        class = "btn-close",
        `data-bs-dismiss` = "offcanvas",
        `aria-label` = "Close"
      )
    ),

    tags$div(
      class = "offcanvas-body",

      p(style = "margin-bottom: 16px;",
        "Edit yellow cells to create your scenario. Zeros = no change from baseline. ",
        "Close this drawer and click ", strong("Run Simulation"), " when ready."
      ),
      p(class = "text-muted-custom", style = "font-size: 0.875em; margin-bottom: 12px;",
        icon("info-circle"), " ",
        strong("\"pp\""), " = percentage points (e.g., a change from 2.0% to 2.5% is +0.5 pp)."
      ),

      div(class = "blsmm-csb-toolbar",
        actionButton("csb_expand_all", "Expand all",
                     class = "btn btn-outline-secondary btn-sm"),
        actionButton("csb_collapse_all", "Collapse all",
                     class = "btn btn-outline-secondary btn-sm")
      ),

      accordion(
        id = "assumptions_accordion",
        multiple = TRUE,
        open = FALSE,

        # ---- Growth & Productivity -----------------------------------------
        accordion_panel(
          title = "Growth & Productivity",
          value = "growth",
          icon = icon("seedling"),
          p(class = "text-muted-custom", style = "font-size: 0.9em;",
            strong("What this does:"), " Adjust long-run growth via labor force and productivity. ",
            "Changes here automatically affect r* and government spending."),

          simple_input_card(
            table_key = "productivity",
            label     = "Potential Productivity Growth Delta (pp)",
            example   = "<strong>Example:</strong> +0.20 raises productivity growth by 0.2 pp/year."
          ),
          hr(),
          simple_input_card(
            table_key = "lf_growth",
            label     = "Potential Labor Force Growth Delta (pp)",
            example   = "<strong>Example:</strong> +0.10 raises labor force growth by 0.1 pp/year."
          )
        ),

        # ---- Fiscal Policy -------------------------------------------------
        accordion_panel(
          title = "Fiscal Policy",
          value = "fiscal",
          icon = icon("building-columns"),
          p(class = "text-muted-custom", style = "font-size: 0.9em;",
            strong("What this does:"), " Simulate tax and spending policies by changing federal receipts and primary outlays as a percent of GDP. ",
            "Positive values raise receipts or outlays; negative values cut."),

          simple_input_card(
            table_key = "receipts",
            label     = "Federal Receipts Delta (pp of GDP)",
            units     = "pp of GDP",
            example   = "<strong>Example:</strong> +1.00 = tax increase of 1% of GDP; -1.00 = tax cut."
          ),
          hr(),
          simple_input_card(
            table_key = "outlays",
            label     = "Federal Primary Outlays Delta (pp of GDP)",
            units     = "pp of GDP",
            example   = "<strong>Example:</strong> +1.00 = spending increase of 1% of GDP; -1.00 = spending cut.<br><em>Primary outlays exclude interest payments on the debt.</em>"
          ),
          br(),

          tags$details(
            class = "blsmm-details-muted",
            tags$summary("Advanced: calculated effects"),
            br(),
            h6("Additional Outlay Changes from Economic Growth"),
            p(class = "text-muted-custom", style = "font-size: 0.85em;",
              "The model automatically adjusts outlays when economic growth changes:"),
            verbatimTextOutput("outlays_indirect_display"),
            br(),
            h6("Implied Primary Budget Balance Delta"),
            p(class = "text-muted-custom", style = "font-size: 0.85em;",
              "Primary balance = Receipts - Outlays (excluding interest payments)."),
            verbatimTextOutput("primary_balance_derived")
          )
        ),

        # ---- Monetary & Shocks ---------------------------------------------
        accordion_panel(
          title = "Monetary & Shocks",
          value = "monetary",
          icon = icon("chart-line"),
          p(class = "text-muted-custom", style = "font-size: 0.9em;",
            strong("What this does:"), " Override the neutral rate, the Fed's inflation target or rate path, or apply demand and inflation shocks."),

          simple_input_card(
            table_key = "rfstar",
            label     = "Neutral Rate (r*) Delta (pp)",
            example   = "<strong>Example:</strong> +0.25 raises r* by 0.25 pp; -0.25 lowers it."
          ),
          tags$details(
            class = "blsmm-details-muted",
            tags$summary("Advanced: automatic r* adjustments"),
            br(),
            p(class = "text-muted-custom", style = "font-size: 0.85em;",
              "The neutral rate adjusts automatically based on growth and debt levels."),
            verbatimTextOutput("rfstar_indirect_display")
          ),
          hr(),

          simple_input_card(
            table_key = "inflation_target",
            label     = "Inflation Target Delta (pp)",
            example   = "<strong>Example:</strong> +0.50 = Fed raises target from 2.0% to 2.5%."
          ),
          checkboxInput("expectations_speed",
                        "Fast Expectations Adjustment",
                        value = FALSE),
          helpText("Check if the public immediately adjusts inflation expectations. Uncheck for gradual adjustment."),
          hr(),

          simple_input_card(
            table_key = "monetary_rule",
            label     = "Fed Interest Rate Adjustment (pp)",
            example   = "Sets Fed Funds higher or lower than the rule-based path. <strong>Example:</strong> +0.50 = 0.5 pp above normal; -0.50 = 0.5 pp below."
          ),
          hr(),

          simple_input_card(
            table_key = "output_gap",
            label     = "Output Gap Shock (pp)",
            example   = "Private demand shocks (confidence, wealth effects). <strong>Example:</strong> +2.00 = output 2 pp above potential."
          ),
          hr(),

          simple_input_card(
            table_key = "inflation_shock",
            label     = "Unexpected Inflation Shock (pp)",
            example   = "Temporary supply shocks (oil prices, pandemic disruptions). <strong>Example:</strong> +1.00 = inflation 1 pp above baseline that year.",
            shape_choices = BLSMM_SHAPE_CHOICES_SHOCK
          )
        )
      ),

      # ---- All Deltas Summary (always visible, outside the accordion) ------
      div(class = "blsmm-csb-summary",
        hr(),
        h5(icon("list-check"), " All Deltas Summary"),
        helpText("All deltas in current scenario"),
        DTOutput("summary_all_deltas")
      )
    )
  )
)

# ==============================================================================
# SERVER LOGIC
# ==============================================================================

