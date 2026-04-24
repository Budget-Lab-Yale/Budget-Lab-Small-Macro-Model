server <- function(input, output, session) {
  fy_labels <- create_fy_labels(n_years = N_PERIODS)
  run_state <- reactiveVal("solved")
  run_state_note <- reactiveVal("Baseline loaded")

  set_run_state <- function(state, note = NULL) {
    run_state(state)
    if (!is.null(note)) run_state_note(note)
  }

  # Active preset tracking. NULL when no preset is loaded (or inputs have
  # been reset). Set by each preset observer; cleared by the reset
  # observer. An observe() below toggles a CSS class on the three preset
  # buttons so the active one stays visually selected until another
  # preset is clicked or the user resets. Running a simulation does NOT
  # clear the active preset.
  active_preset <- reactiveVal(NULL)
  # Timestamp of the most recent preset application. Used by the
  # handsontable observer to decide whether a table-change event is
  # user-driven (so it should clear active_preset) or was caused by
  # the preset itself writing to table_state (so it should NOT clear
  # active_preset).
  preset_apply_time <- reactiveVal(0)
  preset_button_ids <- c(
    rapid_ai          = "preset_rapid_ai",
    persistent_infl   = "preset_persistent_infl",
    military_conflict = "preset_military_conflict"
  )
  observe({
    ap <- active_preset()
    for (key in names(preset_button_ids)) {
      btn_id <- preset_button_ids[[key]]
      if (!is.null(ap) && identical(ap, key)) {
        shinyjs::addCssClass(btn_id, "preset-active")
      } else {
        shinyjs::removeCssClass(btn_id, "preset-active")
      }
    }
  })

  # Custom Scenario highlight: TRUE iff no preset is active AND at least
  # one delta in table_state is non-zero. Derived so the state self-
  # corrects if the user manually zeroes everything out.
  custom_scenario_active <- reactive({
    if (!is.null(active_preset())) return(FALSE)
    fy_cols <- seq(TABLE_FIRST_DATA_COL,
                   TABLE_FIRST_DATA_COL + N_PERIODS - 1)
    keys <- names(table_state)
    if (length(keys) == 0) return(FALSE)
    any(vapply(keys, function(k) {
      tbl <- table_state[[k]]
      if (is.null(tbl)) return(FALSE)
      delta <- suppressWarnings(
        as.numeric(unlist(tbl[TABLE_ROW_DELTA, fy_cols], use.names = FALSE))
      )
      any(abs(delta) > 1e-9, na.rm = TRUE)
    }, logical(1)))
  })
  observe({
    if (isTRUE(custom_scenario_active())) {
      shinyjs::addCssClass("open_assumptions", "preset-active")
    } else {
      shinyjs::removeCssClass("open_assumptions", "preset-active")
    }
  })

  output$run_status_bar <- renderUI({
    state <- run_state()
    note  <- run_state_note()

    # Initial baseline: grey "Ready | Baseline Loaded" pill.
    # Any other solved state: green pill, note only (no label prefix).
    is_initial <- identical(state, "solved") &&
      identical(note, "Baseline loaded")

    state_class <- if (is_initial) {
      "run-ready"
    } else {
      switch(
        state,
        ready = "run-ready",
        dirty = "run-dirty",
        running = "run-running",
        solved = "run-solved",
        error = "run-error",
        "run-ready"
      )
    }

    pill_content <- if (is_initial) {
      "Ready | Baseline Loaded"
    } else if (identical(state, "running")) {
      paste0("RUNNING | ", note)
    } else if (identical(state, "error")) {
      paste0("ERROR | ", note)
    } else if (identical(state, "dirty")) {
      tagList("Inputs Changed", br(), "Run simulation to update results")
    } else {
      note
    }

    div(
      class = paste("run-status", state_class),
      pill_content
    )
  })

  # Plot theme pulls from Budget Lab design tokens (app/R/blsmm_theme.R).
  #
  # Line-color rule: baseline and scenario of the SAME variable use the
  # same color; dash style (baseline = dashed, scenario = solid)
  # distinguishes them. Single-variable plots use blue for both. Two-
  # variable plots (10Y nominal vs real; r* vs Fed Funds) use blue for
  # the primary pair and brand amber for the secondary pair.
  plot_theme <- reactive({
    pal <- bl_colors
    list(
      paper_bg       = pal$bg,
      plot_bg        = pal$bg,
      font           = pal$body,
      font_family    = bl_fonts$body,
      grid           = pal$gridline,
      grid_secondary = pal$bg_subtle,
      zero           = pal$border,
      legend_bg      = "rgba(255, 255, 255, 0.9)",
      zero_line      = pal$muted,
      # Primary variable pair: both baseline and scenario in brand blue.
      line_baseline  = pal$blue,
      line_scenario  = pal$blue,
      # Secondary variable pair (2-pair charts only): brand amber.
      line_secondary = pal$orange,
      debt_fill      = "rgba(40, 109, 192, 0.18)",
      hover_bg       = pal$navy
    )
  })

  dt_deviation_palette <- reactive({
    list(
      neg_bg  = "rgba(220, 53, 69, 0.15)",
      zero_bg = "rgba(248, 249, 250, 0)",
      pos_bg  = "rgba(40, 167, 69, 0.15)",
      neg_fg  = "#dc3545",
      zero_fg = "#6c757d",
      pos_fg  = "#1a7a2e"
    )
  })

  # ============================================================================
  # SCREEN-READER CHART DESCRIPTIONS
  # sr_level_desc: summarises a two-line (baseline + scenario) levels chart.
  # sr_dev_desc:   summarises a single-line deviation chart.
  # Both return a plain string used inside a sr-only aria-live paragraph in
  # the corresponding output$<id>_sr renderUI block below.
  # ============================================================================

  sr_level_desc <- function(b, s, fy, fmt, unit, label) {
    valid <- !is.na(b) & !is.na(s)
    if (!any(valid)) return(label)
    b <- b[valid]; s <- s[valid]; fy <- fy[valid]; n <- length(b)
    dev <- s[n] - b[n]
    dir <- if (abs(dev) < 0.005) "no significant change" else sprintf("%+.2f%s", dev, unit)
    sprintf(
      "%s. Baseline: %s%s in %s, ending %s%s in %s. Scenario ends at %s%s (%s from baseline).",
      label,
      sprintf(fmt, b[1]), unit, fy[1],
      sprintf(fmt, b[n]), unit, fy[n],
      sprintf(fmt, s[n]), unit,
      dir
    )
  }

  sr_dev_desc <- function(dev, fy, fmt, unit, label) {
    valid <- !is.na(dev)
    if (!any(valid)) return(label)
    dev <- dev[valid]; fy <- fy[valid]; n <- length(dev)
    peak_i <- which.max(abs(dev))
    dir <- if (abs(dev[n]) < 0.005) "returns near zero" else sprintf("%+.2f%s", dev[n], unit)
    sprintf(
      "%s. Peak deviation %+.2f%s in %s. Final: %s in %s.",
      label,
      dev[peak_i], unit, fy[peak_i],
      dir, fy[n]
    )
  }

  # -- Levels tab SR outputs (12 charts) --

  output$plot_unemployment_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(d$baseline$U, d$scenario$U, d$baseline$fy_label,
                    "%.2f", " percent", "Unemployment rate"))
  })

  output$plot_inflation_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(d$baseline$PI, d$scenario$PI, d$baseline$fy_label,
                    "%.2f", " percent", "Inflation rate"))
  })

  output$plot_10yr_yield_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(d$baseline$R10, d$scenario$R10, d$baseline$fy_label,
                    "%.2f", " percent", "Nominal 10-year Treasury yield"))
  })

  output$plot_federal_funds_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(d$baseline$RF, d$scenario$RF, d$baseline$fy_label,
                    "%.2f", " percent", "Federal Funds rate"))
  })

  output$plot_budget_balance_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    b <- (d$baseline$BUD / d$baseline[["GDP$"]]) * 100
    s <- (d$scenario$BUD  / d$scenario[["GDP$"]])  * 100
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(b, s, d$baseline$fy_label,
                    "%.2f", "% of GDP", "Total budget balance"))
  })

  output$plot_debt_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(d$baseline$D_pct_GDP, d$scenario$D_pct_GDP, d$baseline$fy_label,
                    "%.1f", "% of GDP", "Federal debt held by the public"))
  })

  output$plot_avg_interest_rate_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(d$baseline$RG, d$scenario$RG, d$baseline$fy_label,
                    "%.2f", " percent", "Average interest rate on federal debt"))
  })

  output$plot_total_receipts_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    b <- d$baseline$rgfr_star * (d$baseline$GDPstar / d$baseline$GDP)
    s <- d$scenario$rgfr_star  * (d$scenario$GDPstar  / d$scenario$GDP)
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(b, s, d$baseline$fy_label,
                    "%.2f", "% of GDP", "Total federal receipts"))
  })

  output$plot_total_outlays_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    b <- (d$baseline$rgfop_star * (d$baseline$GDPstar / d$baseline$GDP)) +
         ((d$baseline$NI / d$baseline[["GDP$"]]) * 100)
    s <- (d$scenario$rgfop_star  * (d$scenario$GDPstar  / d$scenario$GDP))  +
         ((d$scenario$NI  / d$scenario[["GDP$"]])  * 100)
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(b, s, d$baseline$fy_label,
                    "%.2f", "% of GDP", "Total federal outlays (including net interest)"))
  })

  output$plot_primary_outlays_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    b <- d$baseline$rgfop_star * (d$baseline$GDPstar / d$baseline$GDP)
    s <- d$scenario$rgfop_star  * (d$scenario$GDPstar  / d$scenario$GDP)
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(b, s, d$baseline$fy_label,
                    "%.2f", "% of GDP", "Primary federal outlays (excluding interest)"))
  })

  output$plot_real_gdp_growth_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(d$baseline$real_gdp_growth, d$scenario$real_gdp_growth,
                    d$baseline$fy_label,
                    "%.2f", " percent", "Real GDP growth rate"))
  })

  output$plot_primary_balance_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()
    b <- d$baseline$rbudp_star * (d$baseline$GDPstar / d$baseline$GDP)
    s <- d$scenario$rbudp_star  * (d$scenario$GDPstar  / d$scenario$GDP)
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_level_desc(b, s, d$baseline$fy_label,
                    "%.2f", "% of GDP", "Primary budget balance"))
  })

  # -- Deviations tab SR outputs (8 charts) --

  output$dev_plot_primary_balance_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()$deviations
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_dev_desc(d$d_rbudp_star, d$fy_label,
                  "%.2f", " pp of GDP", "Primary balance deviation from baseline"))
  })

  output$dev_plot_debt_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()$deviations
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_dev_desc(d$d_D_pct_GDP, d$fy_label,
                  "%.2f", " pp of GDP", "Debt-to-GDP deviation from baseline"))
  })

  output$dev_plot_unemployment_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()$deviations
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_dev_desc(d$d_U, d$fy_label,
                  "%.3f", " pp", "Unemployment rate deviation from baseline"))
  })

  output$dev_plot_inflation_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()$deviations
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_dev_desc(d$d_PI, d$fy_label,
                  "%.3f", " pp", "Inflation rate deviation from baseline"))
  })

  output$dev_plot_10yr_yield_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()$deviations
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_dev_desc(d$d_R10, d$fy_label,
                  "%.2f", " pp", "10-year Treasury yield deviation from baseline"))
  })

  output$dev_plot_federal_funds_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()$deviations
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_dev_desc(d$d_RF, d$fy_label,
                  "%.2f", " pp", "Federal Funds rate deviation from baseline"))
  })

  output$dev_plot_real_gdp_growth_sr <- renderUI({
    req(simulation_results()); d <- simulation_results()$deviations
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_dev_desc(d$d_real_gdp_growth, d$fy_label,
                  "%.3f", " pp", "Real GDP growth deviation from baseline"))
  })

  output$dev_plot_output_gap_sr <- renderUI({
    req(simulation_results()); full <- simulation_results()
    b_pct <- (full$baseline$BUD / full$baseline[["GDP$"]]) * 100
    s_pct <- (full$scenario$BUD  / full$scenario[["GDP$"]])  * 100
    dev <- s_pct - b_pct
    tags$p(class = "sr-only", `aria-live` = "polite",
      sr_dev_desc(dev, full$baseline$fy_label,
                  "%.2f", " pp of GDP", "Budget balance deviation from baseline"))
  })

  # ============================================================================
  # REACTIVE DATA - BASELINE VALUES
  # ============================================================================

  # Get baseline exogenous data for fixed horizon starting from 2026
  # Data already loaded as baseline_exog_v1_8 global variable
  baseline_exog_static <- baseline_exog_v1_8
  baseline_exog_data <- reactiveVal(baseline_exog_static)

  # Get baseline residuals for fixed horizon
  # Data already loaded as baseline_resid_v1_8 global variable
  baseline_resid_static <- baseline_resid_v1_8
  baseline_resid_data <- reactiveVal(baseline_resid_static)

  # ============================================================================
  # INPUT TABLES - RENDER HANDSONTABLES
  # ============================================================================
  table_specs <- list(
    # Growth input tables (baseline from exog)
    table_lf_growth = list(source = "exog", column = "glfstar", label = "Potential LF Growth"),
    table_productivity = list(source = "exog", column = "glqstar", label = "Potential Productivity Growth"),

    # Fiscal input tables (baseline from exog)
    table_receipts = list(source = "exog", column = "rgfr_star", label = "Federal Receipts Delta"),
    table_outlays = list(source = "exog", column = "rgfop_star", label = "Federal Primary Outlays Delta"),

    # Neutral rate input table (baseline from exog)
    table_rfstar = list(source = "exog", column = "rfstar", label = "Real Neutral FF Rate Direct"),

    # Shock input tables (baseline from residuals)
    table_output_gap = list(source = "resid", column = "epsxgap", label = "Output Gap Shock"),
    table_inflation_shock = list(source = "resid", column = "epspi", label = "Inflation Shock"),
    table_monetary_rule = list(source = "resid", column = "epsmpe", label = "Monetary Rule Shock"),
    table_inflation_target = list(source = "exog", column = "pistar", label = "Inflation Target")
  )
  table_ids <- names(table_specs)

  get_baseline_values <- function(table_id, exog, resid) {
    spec <- table_specs[[table_id]]
    if (is.null(spec)) stop(sprintf("Unknown table id: %s", table_id))
    if (identical(spec$source, "zero")) {
      # User input tables have zero baseline (no historical reference)
      rep(0, N_PERIODS)
    } else if (identical(spec$source, "exog")) {
      exog[[spec$column]]
    } else {
      resid[[spec$column]]
    }
  }

  get_default_table_data <- function(table_id, exog, resid) {
    baseline_vals <- get_baseline_values(table_id, exog, resid)
    var_name <- if (!is.null(table_specs[[table_id]]$column)) {
      table_specs[[table_id]]$column
    } else {
      table_id  # Use table_id as variable name for zero-baseline tables
    }
    create_input_table(baseline_vals, var_name)
  }

  table_state <- reactiveValues()
  tables_initialized <- reactiveVal(FALSE)

  initialize_tables <- function(force = FALSE) {
    exog <- baseline_exog_data()
    resid <- baseline_resid_data()
    for (table_id in table_ids) {
      if (force || is.null(isolate(table_state[[table_id]]))) {
        table_state[[table_id]] <- get_default_table_data(table_id, exog, resid)
      }
    }
    tables_initialized(TRUE)
  }

  observe({
    baseline_exog_data()
    baseline_resid_data()
    if (!tables_initialized()) initialize_tables(force = TRUE)
  })

  # ============================================================================
  # YEAR-BY-YEAR INPUT STRIPS
  # ----------------------------------------------------------------------------
  # Each category's "Edit year-by-year" disclosure contains a strip of 10
  # native numericInputs named `delta_<table_id>_fy<yyyy>` plus matching
  # baseline and level textOutputs. table_state[[table_id]] remains the
  # single source of truth:
  #   - user edits to the inputs flow UP to table_state (Direction A)
  #   - programmatic writes to table_state (presets / reset / simple mode)
  #     flow DOWN to the inputs via refresh_delta_inputs() (Direction B)
  # ============================================================================

  # Helper to recompute the Level row from Baseline + Delta after any
  # change to the delta values. Kept out of the observers for reuse.
  update_table_level_row <- function(hot_data) {
    if (is.null(hot_data)) return(hot_data)
    fy_cols <- seq(TABLE_FIRST_DATA_COL, ncol(hot_data))
    baseline <- suppressWarnings(as.numeric(hot_data[TABLE_ROW_BASELINE, fy_cols]))
    parsed <- parse_table_deltas(hot_data, length(fy_cols))
    hot_data[TABLE_ROW_LEVEL, fy_cols] <- round(baseline + parsed$values, 2)
    hot_data
  }

  # Direction B: push table_state values into each numericInput. Called
  # after any programmatic write to table_state (presets, reset, simple
  # mode). Opens the 1.5s echo guard first so the resulting input-change
  # events do not clear active_preset.
  refresh_delta_inputs <- function() {
    preset_apply_time(as.numeric(Sys.time()))
    for (id in table_ids) {
      tbl <- isolate(table_state[[id]])
      if (is.null(tbl)) next
      for (yr in seq_len(N_PERIODS)) {
        val <- suppressWarnings(as.numeric(
          tbl[TABLE_ROW_DELTA, TABLE_FIRST_DATA_COL + yr - 1]
        ))
        updateTextInput(session,
                        paste0("delta_", id, "_fy", 2025 + yr),
                        value = format_signed_delta(val))
      }
    }
  }

  # Baseline + level textOutputs — 90 each. Baseline values don't change
  # after the baseline data loads, but we render from table_state anyway
  # so initialize_tables() picking up new baseline data propagates.
  for (table_id in table_ids) {
    for (yr in seq_len(N_PERIODS)) {
      local({
        id <- table_id
        yyr <- yr
        col <- TABLE_FIRST_DATA_COL + yyr - 1
        suffix <- paste0(id, "_fy", 2025 + yyr)
        output[[paste0("baseline_", suffix)]] <- renderText({
          tbl <- table_state[[id]]
          if (is.null(tbl)) return("")
          sprintf("%.2f", as.numeric(tbl[TABLE_ROW_BASELINE, col]))
        })
        output[[paste0("level_", suffix)]] <- renderText({
          tbl <- table_state[[id]]
          if (is.null(tbl)) return("")
          sprintf("%.2f", as.numeric(tbl[TABLE_ROW_LEVEL, col]))
        })
      })
    }
  }

  # Direction A: user edits to any delta_* input write that year's value
  # into table_state, recompute the level row, and (outside the echo
  # guard) mark the scenario dirty and clear active_preset.
  for (table_id in table_ids) {
    for (yr in seq_len(N_PERIODS)) {
      local({
        id <- table_id
        yyr <- yr
        col <- TABLE_FIRST_DATA_COL + yyr - 1
        input_id <- paste0("delta_", id, "_fy", 2025 + yyr)

        observeEvent(input[[input_id]], {
          raw <- input[[input_id]]
          new_val <- suppressWarnings(as.numeric(raw))
          if (is.null(new_val) || is.na(new_val)) new_val <- 0

          tbl <- isolate(table_state[[id]])
          if (is.null(tbl)) return(invisible())

          cur_val <- suppressWarnings(as.numeric(tbl[TABLE_ROW_DELTA, col]))
          if (isTRUE(all.equal(cur_val, new_val))) return(invisible())

          tbl[TABLE_ROW_DELTA, col] <- new_val
          table_state[[id]] <- update_table_level_row(tbl)

          is_initial_baseline_state <-
            identical(isolate(run_state()), "solved") &&
            identical(isolate(run_state_note()), "Baseline loaded")
          has_nonzero_delta <- any(abs(suppressWarnings(as.numeric(
            table_state[[id]][TABLE_ROW_DELTA,
                              seq(TABLE_FIRST_DATA_COL,
                                  TABLE_FIRST_DATA_COL + N_PERIODS - 1)]
          ))) > 1e-9, na.rm = TRUE)

          if (!(is_initial_baseline_state && !has_nonzero_delta)) {
            if (as.numeric(Sys.time()) - isolate(preset_apply_time()) > 1.5) {
              active_preset(NULL)
            }
            set_run_state("dirty",
                          "Inputs Changed. Run Simulation to Update Results")
          }
        }, ignoreInit = TRUE)
      })
    }
  }

  observeEvent(input$expectations_speed, {
    is_initial_baseline_state <- identical(run_state(), "solved") &&
      identical(run_state_note(), "Baseline loaded")
    if (!(is_initial_baseline_state && !isTRUE(input$expectations_speed))) {
      # Changing the expectations-speed option is a scenario edit too;
      # clear the preset highlight.
      active_preset(NULL)
      set_run_state("dirty", "Inputs Changed. Run Simulation to Update Results")
    }
  }, ignoreInit = TRUE)

  collect_table_deltas <- function(require_valid = TRUE) {
    deltas <- list()
    for (table_id in table_ids) {
      tbl <- table_state[[table_id]]
      parsed <- parse_table_deltas(tbl, N_PERIODS)
      deltas[[table_id]] <- parsed$values
    }
    deltas
  }

  # ============================================================================
  # SIMULATION RESULTS
  # ============================================================================
  simulation_cache <- new.env(parent = emptyenv())

  make_cache_key <- function(table_deltas, expectations_speed) {
    ordered <- unlist(table_deltas[table_ids], use.names = FALSE)
    paste(
      paste(format(round(ordered, 6), nsmall = 6, trim = TRUE), collapse = ","),
      if (isTRUE(expectations_speed)) "fast" else "normal",
      sep = "|"
    )
  }

  # Store baseline solution (load from cache if available, otherwise compute)
  cache_file <- "data/baseline_v1_8_cached.rds"

  if (file.exists(cache_file)) {
    # Load cached baseline (used in deployment and local runs)
    cached_baseline <- readRDS(cache_file)
    baseline_v1_8 <- cached_baseline$data
    cat("Loaded cached baseline from", cache_file,
        "(computed", format(cached_baseline$timestamp, "%Y-%m-%d %H:%M"), ")\n")
  } else {
    # Compute baseline if no cache exists
    cat("No baseline cache found. Computing baseline scenario...\n")
    start_time <- Sys.time()

    baseline_v1_8 <- run_baseline_v1_8(
      n_periods = N_PERIODS,
      params = NULL,
      expectations_speed = FALSE,
      verbose = FALSE
    )

    end_time <- Sys.time()
    computation_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
    cat("Baseline computed in", round(computation_time, 2), "seconds\n")

    # Try to save to cache (will fail on read-only file systems like shinyapps.io, but that's okay)
    tryCatch({
      cached_baseline <- list(
        data = baseline_v1_8,
        timestamp = Sys.time(),
        n_periods = N_PERIODS,
        computation_time = computation_time,
        cache_version = "1.0"
      )
      saveRDS(cached_baseline, cache_file)
      cat("Baseline cached to", cache_file, "\n")
    }, error = function(e) {
      cat("Note: Could not save baseline cache (read-only file system)\n")
      cat("This is normal on deployment platforms like shinyapps.io\n")
    })
  }

  baseline_v1_8$fy_label <- fy_labels[1:nrow(baseline_v1_8)]

  # Helper to convert results to app display structure
  convert_to_old_structure <- function(scenario_v1_8, baseline_v1_8) {
    # Make explicit copies to avoid modifying the original data
    scenario_copy <- as.data.frame(scenario_v1_8)
    baseline_copy <- as.data.frame(baseline_v1_8)

    # Add computed variables needed by app
    # Real GDP growth (year-over-year % change)
    if ("GDP" %in% names(scenario_copy)) {
      scenario_copy$real_gdp_growth <- c(NA, diff(scenario_copy$GDP) / head(scenario_copy$GDP, -1) * 100)
      baseline_copy$real_gdp_growth <- c(NA, diff(baseline_copy$GDP) / head(baseline_copy$GDP, -1) * 100)
    }

    # Compute deviations - create clean data frame with only deviation columns
    numeric_cols <- sapply(scenario_copy, is.numeric)
    deviations <- data.frame(fy_label = scenario_copy$fy_label)

    for (col in names(scenario_copy)[numeric_cols]) {
      if (col %in% names(baseline_copy) && col != "year" && col != "solver_sse") {
        deviations[[paste0("d_", col)]] <- scenario_copy[[col]] - baseline_copy[[col]]
      }
    }

    list(
      baseline = baseline_copy,
      scenario = scenario_copy,
      deviations = deviations
    )
  }

  # Helper to add FY2025 historical data to results for plotting
  add_fy2025_to_results <- function(results) {
    # Load historical data to get both FY2024 and FY2025
    historical <- read.csv(file.path("data", "blsmm_v1_8_historical.csv"))
    fy2024 <- historical[historical$year == 2024, ]
    fy2025 <- historical[historical$year == 2025, ]

    # Get columns from baseline to ensure compatibility
    baseline_cols <- names(results$baseline)

    # Create FY2025 data frame with matching structure
    fy2025_data <- results$baseline[1, , drop = FALSE]  # Copy structure from first row
    rownames(fy2025_data) <- NULL

    # Set FY2025 values for existing columns
    if ("fy_label" %in% baseline_cols) fy2025_data$fy_label <- "FY25"
    if ("year" %in% baseline_cols) fy2025_data$year <- 2025
    if ("U" %in% baseline_cols) fy2025_data$U <- fy2025$U
    if ("PI" %in% baseline_cols) fy2025_data$PI <- fy2025$PI
    if ("PIE" %in% baseline_cols) fy2025_data$PIE <- fy2025$PIE
    if ("GDP" %in% baseline_cols) fy2025_data$GDP <- fy2025$GDPstar
    if ("R10" %in% baseline_cols) fy2025_data$R10 <- fy2025$R10
    if ("RF" %in% baseline_cols) fy2025_data$RF <- fy2025$RF
    if ("D_pct_GDP" %in% baseline_cols) fy2025_data$D_pct_GDP <- fy2025$debt_proxy_user
    if ("BUD" %in% baseline_cols) fy2025_data$BUD <- fy2025$BUD
    if ("NI" %in% baseline_cols) fy2025_data$NI <- fy2025$NI
    if ("BUDP" %in% baseline_cols) fy2025_data$BUDP <- fy2025$BUDP
    if ("D" %in% baseline_cols) fy2025_data$D <- fy2025$D

    # Add additional fields needed for fiscal plots
    if ("GDPstar" %in% baseline_cols) fy2025_data$GDPstar <- fy2025$GDPstar
    if ("GDP$" %in% baseline_cols) fy2025_data[["GDP$"]] <- fy2025$GDP.
    if ("GDP$star" %in% baseline_cols) fy2025_data[["GDP$star"]] <- fy2025$GDP.star
    if ("GDP$star2" %in% baseline_cols) fy2025_data[["GDP$star2"]] <- fy2025$GDP.star2

    # Calculate fiscal metrics as % of potential GDP for FY2025
    # For historical year, use typical values and budget identity
    if ("rgfr_star" %in% baseline_cols) {
      # Use approximate receipts % GDP from nearby years (around 17.7%)
      # This is a reasonable estimate for FY2025
      fy2025_data$rgfr_star <- 17.7
    }
    if ("rgfop_star" %in% baseline_cols) {
      # Primary outlays = Receipts - Primary balance
      # Using rgfr_star estimate and actual BUDP
      receipts_nominal <- 17.7 * fy2025$GDPstar / 100
      prim_outlays_nominal <- receipts_nominal - fy2025$BUDP
      fy2025_data$rgfop_star <- (prim_outlays_nominal / fy2025$GDPstar) * 100
    }
    if ("rbudp_star" %in% baseline_cols) {
      # Primary balance as % of potential GDP
      fy2025_data$rbudp_star <- (fy2025$BUDP / fy2025$GDPstar) * 100
    }

    # Calculate FY2025 real GDP growth using FY2024 data
    if ("real_gdp_growth" %in% baseline_cols && nrow(fy2024) > 0) {
      fy2025_growth <- (fy2025$GDPstar - fy2024$GDPstar) / fy2024$GDPstar * 100
      fy2025_data$real_gdp_growth <- fy2025_growth
    } else if ("real_gdp_growth" %in% baseline_cols) {
      fy2025_data$real_gdp_growth <- NA
    }

    # Add FY2025 to baseline
    results$baseline_with_history <- rbind(fy2025_data, results$baseline)
    results$baseline_with_history$fy_label <- create_fy_labels_with_history()[1:nrow(results$baseline_with_history)]

    # Add FY2025 to scenario (same as baseline for historical year)
    results$scenario_with_history <- rbind(fy2025_data, results$scenario)
    results$scenario_with_history$fy_label <- create_fy_labels_with_history()[1:nrow(results$scenario_with_history)]

    # Recalculate real GDP growth for combined data (FY2026 onward)
    if ("GDP" %in% names(results$baseline_with_history)) {
      gdp_baseline <- results$baseline_with_history$GDP
      gdp_scenario <- results$scenario_with_history$GDP
      # Keep FY2025 growth as calculated above, recalculate FY2026+
      baseline_growth <- c(fy2025_data$real_gdp_growth, diff(gdp_baseline) / head(gdp_baseline, -1) * 100)
      scenario_growth <- c(fy2025_data$real_gdp_growth, diff(gdp_scenario) / head(gdp_scenario, -1) * 100)
      results$baseline_with_history$real_gdp_growth <- baseline_growth
      results$scenario_with_history$real_gdp_growth <- scenario_growth
    }

    return(results)
  }

  # Initialize with baseline simulation on app launch
  simulation_results <- reactiveVal({
    baseline_old_format <- convert_to_old_structure(baseline_v1_8, baseline_v1_8)
    # Preserve solver_summary attribute from baseline
    attr(baseline_old_format$scenario, "solver_summary") <- attr(baseline_v1_8, "solver_summary")
    # Baseline has no shocks applied
    baseline_old_format$shock_spec <- NULL
    baseline_old_format
  })

  # Reactive to provide plotting data with FY2025 included
  simulation_results_for_plots <- reactive({
    results <- simulation_results()
    if (is.null(results)) return(NULL)

    # Add FY2025 historical data to the results
    results_with_history <- add_fy2025_to_results(results)

    # Return structure with both versions of the data
    list(
      # Original data for compatibility
      baseline = results_with_history$baseline_with_history,
      scenario = results_with_history$scenario_with_history,
      deviations = results$deviations,
      # Keep original data available if needed
      baseline_original = results$baseline,
      scenario_original = results$scenario,
      # Preserve shock spec
      shock_spec = results$shock_spec
    )
  })

  # Update simulation when button is clicked
  observeEvent(input$run_sim, {
    set_run_state("running", "Solving model...")
    # Show progress
    withProgress(message = 'Running simulation...', value = 0, {

      incProgress(0.2, detail = "Extracting inputs...")

      # Extract deltas from all tables
      table_deltas <- collect_table_deltas(require_valid = TRUE)
      if (is.null(table_deltas)) return(invisible(NULL))
      expectations_fast <- isTRUE(input$expectations_speed)
      cache_key <- make_cache_key(table_deltas, expectations_fast)

      incProgress(0.3, detail = "Mapping inputs...")

      # Map app tables to user_deltas structure
      user_deltas <- map_tables_to_user_deltas(table_deltas, n_periods = N_PERIODS)

      incProgress(0.4, detail = "Running simulation...")

      if (exists(cache_key, envir = simulation_cache, inherits = FALSE)) {
        results <- get(cache_key, envir = simulation_cache, inherits = FALSE)
        set_run_state("solved", "Simulation Complete")
      } else {
        # Run simulation
        results <- tryCatch({
          simulate_blsmm_v1_8(
            n_periods = N_PERIODS,
            baseline_exog = baseline_exog_v1_8,
            baseline_resid = baseline_resid_v1_8,
            hist_data = hist_data_v1_8,
            user_deltas = user_deltas,
            forcing_spec = NULL,
            params = NULL,  # Uses defaults
            expectations_speed = expectations_fast,
            verbose = FALSE
          )
        }, error = function(e) {
          set_run_state("error", paste("Simulation error:", e$message))
          return(NULL)
        })

        if (is.null(results)) return(invisible(NULL))

        assign(cache_key, results, envir = simulation_cache)

        # Check convergence
        solver_summary <- attr(results, "solver_summary")
        if (is.null(solver_summary)) {
          max_sse <- max(results$solver_sse, na.rm = TRUE)
          if (max_sse < 1e-9) {
            set_run_state("solved", "Simulation Complete")
          } else {
            set_run_state("error", sprintf("Not converged (SSE: %.2e)", max_sse))
          }
        } else {
          if (solver_summary$overall_converged) {
            set_run_state("solved", "Simulation Complete")
          } else {
            set_run_state("error", sprintf("Not converged (SSE: %.2e)", solver_summary$final_sse))
          }
        }
      }

      incProgress(0.8, detail = "Formatting results...")

      # Add fiscal year labels for display
      results$fy_label <- fy_labels

      # Convert to app display structure for charts and tables
      results_old_format <- convert_to_old_structure(results, baseline_v1_8)

      # Preserve solver_summary attribute through conversion
      attr(results_old_format$scenario, "solver_summary") <- attr(results, "solver_summary")

      # Store table_deltas for displays (not user_deltas, which has different field names)
      results_old_format$shock_spec <- table_deltas

      incProgress(1.0, detail = "Done!")

      # Update reactive value
      simulation_results(results_old_format)
    })
  })

  # Reset button handler
  observeEvent(input$reset_inputs, {
    initialize_tables(force = TRUE)
    refresh_delta_inputs()

    # Reset simple-mode inputs too so the drawer UI matches the zeroed
    # tables. The resulting change-events fire the simple observers, which
    # write zero deltas into the already-zero tables — harmless.
    # Reset to the first option in the new shape-choice order
    # ("onetime"). Inflation_shock has a restricted choice list but
    # still has "onetime" as its first option, so the same value
    # works for every input.
    for (k in c("productivity", "lf_growth", "receipts", "outlays",
                "rfstar", "inflation_target", "monetary_rule",
                "output_gap", "inflation_shock")) {
      updateSelectInput(session, paste0("shape_", k), selected = "onetime")
      updateNumericInput(session, paste0("magnitude_", k), value = 0)
    }

    # Reset checkbox
    updateCheckboxInput(session, "expectations_speed", value = FALSE)
    # Clear active preset so none of the three preset buttons appears selected
    active_preset(NULL)
    set_run_state("dirty", "Inputs Changed. Run Simulation to Update Results")
  })

  # Custom Scenario Builder: Expand all / Collapse all accordion controls.
  # Purely UI — does not touch table_state, active_preset, or run_state.
  observeEvent(input$csb_expand_all, {
    bslib::accordion_panel_open("assumptions_accordion", values = TRUE)
  })
  observeEvent(input$csb_collapse_all, {
    bslib::accordion_panel_close("assumptions_accordion", values = TRUE)
  })

  # ============================================================================
  # PRESET SCENARIOS
  # ============================================================================

  # Helper function to reset all tables to baseline
  reset_all_tables_to_baseline <- function() {
    initialize_tables(force = TRUE)
    refresh_delta_inputs()
  }

  # Helper function to update a table with shocks
  update_table_with_shocks <- function(table_name, shock_values) {
    exog <- baseline_exog_data()
    resid <- baseline_resid_data()
    baseline_vals <- get_baseline_values(table_name, exog, resid)
    table_data <- create_input_table(baseline_vals, table_specs[[table_name]]$column)
    if (length(shock_values) < N_PERIODS) {
      shock_values <- c(shock_values, rep(0, N_PERIODS - length(shock_values)))
    }
    shock_values <- shock_values[1:N_PERIODS]

    fy_cols <- seq(TABLE_FIRST_DATA_COL, TABLE_FIRST_DATA_COL + N_PERIODS - 1)
    table_data[TABLE_ROW_DELTA, fy_cols] <- shock_values
    table_data[TABLE_ROW_LEVEL, fy_cols] <- baseline_vals + shock_values

    table_state[[table_name]] <- table_data
    refresh_delta_inputs()
  }

  apply_single_preset <- function(table_name, shock_values) {
    reset_all_tables_to_baseline()
    update_table_with_shocks(table_name, shock_values)
    set_run_state("dirty", "Inputs Changed. Run Simulation to Update Results")
  }

  apply_multi_preset <- function(presets_list) {
    reset_all_tables_to_baseline()
    for (i in seq_along(presets_list)) {
      table_name <- names(presets_list)[i]
      shock_values <- presets_list[[i]]
      update_table_with_shocks(table_name, shock_values)
    }
    set_run_state("dirty", "Inputs Changed. Run Simulation to Update Results")
  }

  # Preset 1: Rapid AI Adoption
  # Source: BLSMM_1_8_20260326_links_rapidAI.xlsm
  # Three simultaneous shocks: productivity boost, LFPR decline, outlay rise
  observeEvent(input$preset_rapid_ai, {
    preset_apply_time(as.numeric(Sys.time()))
    apply_multi_preset(list(
      table_productivity = c(1.60, 1.50, 1.50, 1.60, 1.60,
                             1.70, 1.70, 1.80, 1.80, 1.80),
      table_lf_growth    = c(-0.40, -0.40, -0.40, -0.40, -0.40,
                              0.00,  0.00,  0.00,  0.00,  0.00),
      table_outlays      = c(0.40, 0.40, 0.40, 0.40, 0.40, 0.40, 0.40, 0.40, 0.40, 0.40)
    ))
    active_preset("rapid_ai")
  })

  # Preset 2: Persistent Inflation
  # Source: BLSMM_1_8_20260326_links_persistentinflation.xlsm
  # Front-loaded inflation shock (3 nonzero years)
  observeEvent(input$preset_persistent_infl, {
    preset_apply_time(as.numeric(Sys.time()))
    apply_single_preset(
      "table_inflation_shock",
      c(0.0, 0.1, 0.3, 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    )
    active_preset("persistent_infl")
  })

  # Preset 3: Military Conflict
  # Source: defense_outlays_data.xlsx, "Primary Outlays Delta" col
  # Defense outlay path including +$350B FY2027 mandatory spending
  observeEvent(input$preset_military_conflict, {
    preset_apply_time(as.numeric(Sys.time()))
    apply_single_preset(
      "table_outlays",
      c(0.05926643923051801, 1.4648663376827828,
        0.6024768143143505,  0.7583951483560541,
        0.7938454047864912,  0.8164223748813694,
        0.785826175398481,   0.7236216101604063,
        0.6726591880611538,  0.6147969334429797)
    )
    active_preset("military_conflict")
  })

  # ============================================================================
  # SIMPLE-MODE INPUTS
  # ----------------------------------------------------------------------------
  # Each input in the Custom Scenario Builder has a shape picker + magnitude input
  # (see simple_input_card() in blsmm_helpers.R). When those change we compute
  # the 10-year delta via build_shape_delta() and write it into the underlying
  # handsontable via update_table_with_shocks(). The handsontable (under
  # "Edit year-by-year") remains the single source of truth consumed by the
  # solver; simple mode is a "quick-fill" overlay.
  #
  # Preview text for each input is derived from the table state (not from the
  # simple inputs), so presets and direct handsontable edits also appear in
  # the preview.
  # ============================================================================

  simple_input_keys <- c(
    "productivity", "lf_growth", "receipts", "outlays",
    "rfstar", "inflation_target", "monetary_rule",
    "output_gap", "inflation_shock"
  )

  for (key in simple_input_keys) {
    local({
      k         <- key
      shape_id  <- paste0("shape_",     k)
      mag_id    <- paste0("magnitude_", k)
      tbl_name  <- paste0("table_",     k)

      # Observer: write simple-mode delta into the table when user edits
      # shape or magnitude. update_table_with_shocks() already writes
      # the new delta into table_state and calls refresh_delta_inputs()
      # to sync the per-year numericInput strip.
      observeEvent(
        list(input[[shape_id]], input[[mag_id]]),
        ignoreInit = TRUE,
        {
          shape <- input[[shape_id]] %||% "onetime"
          mag   <- input[[mag_id]]
          delta <- build_shape_delta(shape, mag, N_PERIODS)
          update_table_with_shocks(tbl_name, delta)
          # Any simple-mode edit means the scenario diverges from any
          # preset — clear the preset highlight so only Custom Scenario
          # can light up.
          active_preset(NULL)
          set_run_state("dirty",
                        "Inputs Changed. Run Simulation to Update Results")
        }
      )
    })
  }

  # ============================================================================
  # SSE CONVERGENCE DISPLAY
  # ============================================================================

  output$sse_display <- renderText({
    req(simulation_results())

    solver <- attr(simulation_results()$scenario, "solver_summary")
    sse <- solver$final_sse
    status <- if (isTRUE(solver$overall_converged)) "CONVERGED" else "NOT CONVERGED"
    sprintf("SSE: %.6f | %s", sse, status)
  })

  # ============================================================================
  # KPI VALUE BOXES
  # ============================================================================

  # KPI 2: Final Debt Impact
  output$kpi_final_debt <- renderText({
    req(simulation_results())

    data <- simulation_results()
    final_debt_change <- tail(data$deviations$d_D_pct_GDP, 1)

    sprintf("%+.2f pp", final_debt_change)
  })

  # KPI 3: Max Unemployment Effect
  output$kpi_max_unemployment <- renderText({
    req(simulation_results())

    data <- simulation_results()
    max_u_change <- max(abs(data$deviations$d_U))

    # Get the actual value (not absolute)
    actual_max <- data$deviations$d_U[which.max(abs(data$deviations$d_U))]

    sprintf("%+.2f pp", actual_max)
  })

  # ============================================================================
  # INDIRECT EFFECTS DISPLAYS (BLSMM)
  # ============================================================================

  # Display indirect outlays effects from fiscal feedback
  output$outlays_indirect_display <- renderText({
    req(simulation_results())
    results <- simulation_results()$scenario

    # Extract fiscal feedback components
    if ("LF_fb" %in% names(results) && "PROD_fb" %in% names(results)) {
      lf_fb_avg <- mean(results$LF_fb, na.rm = TRUE)
      prod_fb_avg <- mean(results$PROD_fb, na.rm = TRUE)
      total_fb <- lf_fb_avg + prod_fb_avg

      sprintf(
        "From labor force growth: %+.3f pp (psi_1 effect)\nFrom productivity growth: %+.3f pp (psi_2 effect)\n────────────────────────────────\nTotal indirect effect: %+.3f pp",
        lf_fb_avg, prod_fb_avg, total_fb
      )
    } else {
      "Run simulation to see indirect effects"
    }
  })

  # Display primary balance derivation
  output$primary_balance_derived <- renderText({
    # Get user deltas from tables
    table_deltas <- collect_table_deltas(require_valid = FALSE)

    if (!is.null(table_deltas) && !is.null(simulation_results())) {
      receipts_delta <- table_deltas$table_receipts
      outlays_direct <- table_deltas$table_outlays

      # Get indirect from simulation
      results <- simulation_results()$scenario
      if ("LF_fb" %in% names(results) && "PROD_fb" %in% names(results)) {
        outlays_indirect <- results$LF_fb + results$PROD_fb
        outlays_total <- outlays_direct + outlays_indirect
        balance <- receipts_delta - outlays_total

        sprintf(
          "Receipts delta: %+.2f pp (avg)\nPrimary outlays direct: %+.2f pp (avg)\nPrimary outlays indirect: %+.2f pp (avg)\nPrimary outlays total: %+.2f pp (avg)\n────────────────────────────────\nImplied primary balance delta: %+.2f pp (avg)",
          mean(receipts_delta), mean(outlays_direct), mean(outlays_indirect),
          mean(outlays_total), mean(balance)
        )
      } else {
        "Run simulation to see derived values"
      }
    } else {
      "Run simulation to see derived values"
    }
  })

  # Display rfstar decomposition
  output$rfstar_indirect_display <- renderText({
    req(simulation_results())
    results <- simulation_results()$scenario

    # Extract r* components
    if ("gradual_growth" %in% names(results) && "debt_contrib" %in% names(results)) {
      growth_effect <- mean(results$gradual_growth, na.rm = TRUE)
      debt_effect <- mean(results$debt_contrib, na.rm = TRUE)
      total_indirect <- growth_effect + debt_effect

      sprintf(
        "From potential growth: %+.3f pp (kappa_1 + kappa_2 effect)\nFrom debt/GDP proxy: %+.3f pp (kappa_3 effect)\n────────────────────────────────\nTotal indirect effect: %+.3f pp",
        growth_effect, debt_effect, total_indirect
      )
    } else {
      "Run simulation to see indirect effects"
    }
  })

  # ============================================================================
  # DASHBOARD PLOTS
  # ============================================================================


  # ============================================================================
  # LOAD V1.8 PLOT DEFINITIONS
  # ============================================================================
  # Source all 13 dashboard chart definitions
  source("app/R/blsmm_plots_v1_8.R", local = TRUE)

  # ============================================================================
  # FORCE OUTPUTS TO UPDATE EVEN WHEN TAB IS HIDDEN
  # ============================================================================

  # Ensure dashboard plots update immediately when simulation runs,
  # even if Dashboard tab is not currently visible
  # All 12 charts:
  outputOptions(output, "plot_unemployment", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_inflation", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_10yr_yield", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_federal_funds", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_budget_balance", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_debt", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_avg_interest_rate", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_total_receipts", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_total_outlays", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_primary_outlays", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_real_gdp_growth", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_primary_balance", suspendWhenHidden = FALSE)
  outputOptions(output, "kpi_final_debt", suspendWhenHidden = FALSE)
  outputOptions(output, "kpi_max_unemployment", suspendWhenHidden = FALSE)

  # ============================================================================
  # DEVIATION PLOTS (Tab 3)
  # ============================================================================

  # Deviation Plot 1: Budget Balance
  output$dev_plot_output_gap <- renderPlotly({
    req(simulation_results())

    full_data <- simulation_results()
    th <- plot_theme()

    # Calculate budget balance as % of GDP for both scenarios
    baseline_budget_pct <- (full_data$baseline$BUD / full_data$baseline[["GDP$"]]) * 100
    scenario_budget_pct <- (full_data$scenario$BUD / full_data$scenario[["GDP$"]]) * 100
    budget_deviation <- scenario_budget_pct - baseline_budget_pct

    plot_ly() %>%
      add_lines(
        x = full_data$baseline$fy_label,
        y = budget_deviation,
        name = "Budget Balance Deviation",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f} pp<extra></extra>")
      ) %>%
      add_lines(
        x = full_data$baseline$fy_label,
        y = rep(0, length(full_data$baseline$fy_label)),
        name = "Zero",
        line = list(color = th$zero_line, dash = "dot", width = 1),
        showlegend = FALSE
      ) %>%
      layout(
        title = "<b>Budget Balance Deviation from Baseline (pp of GDP)</b>",
        xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
        yaxis = list(title = "Percentage Points of GDP", gridcolor = th$grid, zerolinecolor = th$zero),
        hovermode = "x unified",
        dragmode = FALSE,
        paper_bgcolor = th$paper_bg,
        plot_bgcolor = th$plot_bg,
        font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
  })

  # Deviation Plot 2: Unemployment
  output$dev_plot_unemployment <- renderPlotly({
    req(simulation_results())

    data <- simulation_results()$deviations
    th <- plot_theme()

    plot_ly() %>%
      add_lines(
        x = data$fy_label,
        y = data$d_U,
        name = "Unemployment Deviation",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.3f} pp<extra></extra>")
      ) %>%
      add_lines(
        x = data$fy_label,
        y = rep(0, length(data$fy_label)),
        name = "Zero",
        line = list(color = th$zero_line, dash = "dot", width = 1),
        showlegend = FALSE
      ) %>%
      layout(
        title = "<b>Unemployment Rate Deviation from Baseline (pp)</b>",
        xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
        yaxis = list(title = "Percentage Points", gridcolor = th$grid, zerolinecolor = th$zero),
        hovermode = "x unified",
        dragmode = FALSE,
        paper_bgcolor = th$paper_bg,
        plot_bgcolor = th$plot_bg,
        font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
  })

  # Deviation Plot 3: Real GDP Growth
  output$dev_plot_real_gdp_growth <- renderPlotly({
    req(simulation_results())

    data <- simulation_results()$deviations
    th <- plot_theme()

    # Remove NA values (first period has NA since growth is year-over-year)
    valid_idx <- !is.na(data$d_real_gdp_growth)

    plot_ly() %>%
      add_lines(
        x = data$fy_label[valid_idx],
        y = data$d_real_gdp_growth[valid_idx],
        name = "Real GDP Growth Deviation",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.3f} pp<extra></extra>")
      ) %>%
      add_lines(
        x = data$fy_label[valid_idx],
        y = rep(0, sum(valid_idx)),
        name = "Zero",
        line = list(color = th$zero_line, dash = "dot", width = 1),
        showlegend = FALSE
      ) %>%
      layout(
        title = "<b>Real GDP Growth Deviation from Baseline (pp)</b>",
        xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
        yaxis = list(title = "Percentage Points", gridcolor = th$grid, zerolinecolor = th$zero),
        hovermode = "x unified",
        dragmode = FALSE,
        paper_bgcolor = th$paper_bg,
        plot_bgcolor = th$plot_bg,
        font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
  })

  # Deviation Plot 4: Inflation
  output$dev_plot_inflation <- renderPlotly({
    req(simulation_results())

    data <- simulation_results()$deviations
    th <- plot_theme()

    plot_ly() %>%
      add_lines(
        x = data$fy_label,
        y = data$d_PI,
        name = "Inflation Deviation",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.3f} pp<extra></extra>")
      ) %>%
      add_lines(
        x = data$fy_label,
        y = rep(0, length(data$fy_label)),
        name = "Zero",
        line = list(color = th$zero_line, dash = "dot", width = 1),
        showlegend = FALSE
      ) %>%
      layout(
        title = "<b>Inflation Rate Deviation from Baseline (pp)</b>",
        xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
        yaxis = list(title = "Percentage Points", gridcolor = th$grid, zerolinecolor = th$zero),
        hovermode = "x unified",
        dragmode = FALSE,
        paper_bgcolor = th$paper_bg,
        plot_bgcolor = th$plot_bg,
        font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
  })

  # Deviation Plot 5: Debt/GDP
  output$dev_plot_debt <- renderPlotly({
    req(simulation_results())

    data <- simulation_results()$deviations
    th <- plot_theme()

    plot_ly() %>%
      add_lines(
        x = data$fy_label,
        y = data$d_D_pct_GDP,
        name = "Debt/GDP Deviation",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f} pp<extra></extra>")
      ) %>%
      add_lines(
        x = data$fy_label,
        y = rep(0, length(data$fy_label)),
        name = "Zero",
        line = list(color = th$zero_line, dash = "dot", width = 1),
        showlegend = FALSE
      ) %>%
      layout(
        title = "<b>Debt/GDP Deviation from Baseline (pp of GDP)</b>",
        xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
        yaxis = list(title = "Percentage Points", gridcolor = th$grid, zerolinecolor = th$zero),
        hovermode = "x unified",
        dragmode = FALSE,
        paper_bgcolor = th$paper_bg,
        plot_bgcolor = th$plot_bg,
        font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
  })

  # Deviation Plot 6: Federal Funds Rate
  output$dev_plot_federal_funds <- renderPlotly({
    req(simulation_results())

    data <- simulation_results()$deviations
    th <- plot_theme()

    plot_ly() %>%
      add_lines(
        x = data$fy_label,
        y = data$d_RF,
        name = "Federal Funds Rate Deviation",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f} pp<extra></extra>")
      ) %>%
      add_lines(
        x = data$fy_label,
        y = rep(0, length(data$fy_label)),
        name = "Zero",
        line = list(color = th$zero_line, dash = "dot", width = 1),
        showlegend = FALSE
      ) %>%
      layout(
        title = "<b>Federal Funds Rate Deviation from Baseline (pp)</b>",
        xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
        yaxis = list(title = "Percentage Points", gridcolor = th$grid, zerolinecolor = th$zero),
        hovermode = "x unified",
        dragmode = FALSE,
        paper_bgcolor = th$paper_bg,
        plot_bgcolor = th$plot_bg,
        font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
  })

  # Deviation Plot 7: 10-Year Treasury Yield
  output$dev_plot_10yr_yield <- renderPlotly({
    req(simulation_results())

    data <- simulation_results()$deviations
    th <- plot_theme()

    plot_ly() %>%
      add_lines(
        x = data$fy_label,
        y = data$d_R10,
        name = "10-Year Yield Deviation",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f} pp<extra></extra>")
      ) %>%
      add_lines(
        x = data$fy_label,
        y = rep(0, length(data$fy_label)),
        name = "Zero",
        line = list(color = th$zero_line, dash = "dot", width = 1),
        showlegend = FALSE
      ) %>%
      layout(
        title = "<b>10-Year Treasury Yield Deviation from Baseline (pp)</b>",
        xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
        yaxis = list(title = "Percentage Points", gridcolor = th$grid, zerolinecolor = th$zero),
        hovermode = "x unified",
        dragmode = FALSE,
        paper_bgcolor = th$paper_bg,
        plot_bgcolor = th$plot_bg,
        font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
  })

  # Deviation Plot 8: Primary Balance
  output$dev_plot_primary_balance <- renderPlotly({
    req(simulation_results())

    data <- simulation_results()$deviations
    th <- plot_theme()

    plot_ly() %>%
      add_lines(
        x = data$fy_label,
        y = data$d_rbudp_star,
        name = "Primary Balance Deviation",
        line = list(color = th$line_scenario, width = 3),
        hovertemplate = paste0("%{fullData.name}: %{y:.2f} pp<extra></extra>")
      ) %>%
      add_lines(
        x = data$fy_label,
        y = rep(0, length(data$fy_label)),
        name = "Zero",
        line = list(color = th$zero_line, dash = "dot", width = 1),
        showlegend = FALSE
      ) %>%
      layout(
        title = "<b>Primary Balance Deviation from Baseline (pp of GDP)</b>",
        xaxis = list(title = "", gridcolor = th$grid, zerolinecolor = th$zero),
        yaxis = list(title = "Percentage Points of GDP", gridcolor = th$grid, zerolinecolor = th$zero),
        hovermode = "x unified",
        dragmode = FALSE,
        paper_bgcolor = th$paper_bg,
        plot_bgcolor = th$plot_bg,
        font = list(color = th$font, family = th$font_family)
    ) %>%
    config(displayModeBar = FALSE, doubleClick = FALSE)
  })

  # Fiscal Multiplier Calculation
  output$multiplier_display <- renderText({
    req(simulation_results())

    data <- simulation_results()
    shock <- data$shock_spec

    # Check if this is baseline (no shocks)
    if (is.null(shock)) {
      return("No shock specified. Set shocks in input tables to see multiplier analysis.")
    }

    # Helper to safely get max of numeric vector
    safe_max <- function(x) {
      if (is.null(x)) return(0)
      x <- as.numeric(x)
      if (length(x) == 0 || all(is.na(x))) return(0)
      max(abs(x), na.rm = TRUE)
    }

    # Helper to check if vector has any non-zero values
    has_values <- function(x) {
      if (is.null(x)) return(FALSE)
      x <- as.numeric(x)
      if (length(x) == 0) return(FALSE)
      any(!is.na(x) & abs(x) > 1e-10)
    }

    # Extract all shock types
    fiscal_receipts <- as.numeric(shock$table_receipts)
    fiscal_outlays <- as.numeric(shock$table_outlays)
    lf_growth <- as.numeric(shock$table_lf_growth)
    productivity <- as.numeric(shock$table_productivity)
    rfstar_direct <- as.numeric(shock$table_rfstar)
    inflation_shock <- as.numeric(shock$table_inflation_shock)
    output_gap_shock <- as.numeric(shock$table_output_gap)
    mp_rule_shock <- as.numeric(shock$table_monetary_rule)
    inflation_target <- as.numeric(shock$table_inflation_target)

    # Calculate composite shocks
    net_fiscal_shock <- fiscal_receipts - fiscal_outlays
    total_growth_shock <- lf_growth + productivity

    # Get common output measures
    peak_xgap <- max(abs(data$deviations$d_xgap), na.rm = TRUE)
    peak_period <- which.max(abs(data$deviations$d_xgap))
    final_debt_change <- tail(data$deviations$d_D_pct_GDP, 1)

    # Check if ANY shocks were applied (check for actual deviations)
    has_any_deviation <- max(abs(data$deviations$d_xgap), na.rm = TRUE) > 0.001 ||
                         max(abs(data$deviations$d_PI), na.rm = TRUE) > 0.001

    # Calculate multiplier based on shock type (priority: fiscal > growth > other)
    if (has_values(fiscal_receipts) || has_values(fiscal_outlays)) {
      # Fiscal shock analysis
      first_fiscal <- net_fiscal_shock[1]
      first_period_multiplier <- if(abs(first_fiscal) > 0.001) {
        -data$deviations$d_xgap[1] / first_fiscal
      } else {
        NA
      }

      peak_fiscal <- safe_max(net_fiscal_shock)
      peak_multiplier <- -peak_xgap / peak_fiscal

      multiplier_text <- paste0(
        "Fiscal Shock  Receipts - Outlays (max: ", sprintf("%+.2f", peak_fiscal), " pp of GDP)\n",
        "  Receipts delta max: ", sprintf("%+.2f", safe_max(fiscal_receipts)), " pp\n",
        "  Outlays delta max: ", sprintf("%+.2f", safe_max(fiscal_outlays)), " pp\n\n",
        "Output Gap Multipliers:\n",
        "  Impact (FY2026): ", sprintf("%.2f", first_period_multiplier), "\n",
        "  Peak (", data$deviations$fy_label[peak_period], "): ", sprintf("%.2f", peak_multiplier), "\n\n",
        "Debt Impact:\n",
        "  Final Period Debt Change: ", sprintf("%+.2f", final_debt_change), " pp of GDP\n",
        "  Debt Multiplier: ", sprintf("%.2f", -final_debt_change / peak_fiscal), " (debt change per unit of fiscal shock)\n\n",
        "Note: Multipliers calculated using max shock value. With year-by-year shocks, interpretation varies."
      )
    } else if (has_values(lf_growth) || has_values(productivity)) {
      # Growth shock analysis
      max_growth <- safe_max(total_growth_shock)

      multiplier_text <- paste0(
        "Growth Shock  LF Growth + Productivity (max: ", sprintf("%+.2f", max_growth), " pp)\n",
        "  LF growth max: ", sprintf("%+.2f", safe_max(lf_growth)), " pp\n",
        "  Productivity max: ", sprintf("%+.2f", safe_max(productivity)), " pp\n\n",
        "Debt Impact:\n",
        "  Final Period Debt Change: ", sprintf("%+.2f", final_debt_change), " pp of GDP\n",
        "  Debt-to-Growth Sensitivity: ", sprintf("%.2f", final_debt_change / max_growth), " pp debt change per pp growth\n\n",
        "Note: Positive growth reduces debt/GDP ratio."
      )
    } else {
      # Check for other shock types
      has_shocks <- has_values(rfstar_direct) ||
                    has_values(inflation_shock) ||
                    has_values(output_gap_shock) ||
                    has_values(mp_rule_shock) ||
                    has_values(inflation_target)

      if (has_shocks) {
        # Other shock types - show impacts without traditional multipliers
        shock_list <- c()
        if (has_values(rfstar_direct)) shock_list <- c(shock_list, sprintf("r* Direct: %+.2f pp", safe_max(rfstar_direct)))
        if (has_values(inflation_target)) shock_list <- c(shock_list, sprintf("Inflation Target: %+.2f pp", safe_max(inflation_target)))
        if (has_values(inflation_shock)) shock_list <- c(shock_list, sprintf("Inflation Shock: %+.2f pp", safe_max(inflation_shock)))
        if (has_values(output_gap_shock)) shock_list <- c(shock_list, sprintf("Output Gap Shock: %+.2f pp", safe_max(output_gap_shock)))
        if (has_values(mp_rule_shock)) shock_list <- c(shock_list, sprintf("MP Rule Shock: %+.2f pp", safe_max(mp_rule_shock)))

        multiplier_text <- paste0(
          "Non-Fiscal/Non-Growth Shocks Applied:\n",
          paste("  ", shock_list, collapse = "\n"), "\n\n",
          "Impacts:\n",
          "  Peak Output Gap: ", sprintf("%+.3f", peak_xgap), " pp\n",
          "  Peak Inflation: ", sprintf("%+.3f", max(abs(data$deviations$d_PI), na.rm = TRUE)), " pp\n",
          "  Final Debt/GDP Change: ", sprintf("%+.2f", final_debt_change), " pp\n\n",
          "Note: Traditional fiscal multipliers not applicable for these shock types.\n",
          "These shocks affect the economy through monetary policy and expectations channels."
        )
      } else {
        # If we get here, check if simulation produced any results
        if (has_any_deviation) {
          # Show impact summary without trying to categorize shock type
          multiplier_text <- paste0(
            "Simulation Results:\n\n",
            "Observed Impacts:\n",
            "  Peak Output Gap: ", sprintf("%+.3f", peak_xgap), " pp\n",
            "  Peak Inflation: ", sprintf("%+.3f", max(abs(data$deviations$d_PI), na.rm = TRUE)), " pp\n",
            "  Peak Unemployment: ", sprintf("%+.3f", max(abs(data$deviations$d_U), na.rm = TRUE)), " pp\n",
            "  Final Debt/GDP Change: ", sprintf("%+.2f", final_debt_change), " pp"
          )
        } else {
          multiplier_text <- "No significant shock specified. Set shocks in input tables to see multiplier analysis."
        }
      }
    }

    multiplier_text
  })

  # ============================================================================
  # DEVIATION TABLES
  # ============================================================================

  # Deviation table (key variables)
  output$deviation_table <- renderDT({
    req(simulation_results())

    data <- simulation_results()$deviations
    pal <- dt_deviation_palette()

    # Select key variables
    key_vars <- data %>%
      select(fy_label, d_xgap, d_U, d_PI, d_RF, d_R10, d_D_pct_GDP, d_NI)

    # Rename for display
    names(key_vars) <- c("Fiscal Year", "Output Gap (pp)", "Unemployment (pp)", "Inflation (pp)",
                         "Fed Funds (pp)", "10yr Rate (pp)", "Debt/GDP (pp of GDP)", "Net Interest ($B 2017$)")

    datatable(
      key_vars,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 't',
        compact = TRUE,
        ordering = FALSE
      ),
      rownames = FALSE,
      selection = "none",  # no persistent row-click highlight
      class = 'compact stripe hover'  # hover class -> light highlight on hover only
    ) %>%
      formatRound(columns = 2:8, digits = 2) %>%
      formatStyle(
        columns = 2:8,
        backgroundColor = styleInterval(
          cuts = c(-0.001, 0.001),
          values = c(pal$neg_bg, pal$zero_bg, pal$pos_bg)
        ),
        color = styleInterval(
          cuts = c(-0.001, 0.001),
          values = c(pal$neg_fg, pal$zero_fg, pal$pos_fg)
        ),
        fontWeight = 'bold'
      )
  })

  # Deviation summary statistics
  output$deviation_summary <- renderText({
    req(simulation_results())

    data <- simulation_results()
    dev <- data$deviations
    shock <- data$shock_spec

    # Calculate summary statistics
    max_xgap_dev <- max(abs(dev$d_xgap))
    max_pi_dev <- max(abs(dev$d_PI))
    max_D_dev <- max(abs(dev$d_D_pct_GDP))
    final_D_dev <- tail(dev$d_D_pct_GDP, 1)

    # Helper to safely get max of numeric vector
    safe_max <- function(x) {
      x <- as.numeric(x)
      if (length(x) == 0 || all(is.na(x))) return(0)
      max(abs(x), na.rm = TRUE)
    }

    # Check if this is baseline (no shocks)
    if (is.null(shock)) {
      summary_text <- paste0(
        "Baseline scenario - no shocks applied\n\n",
        "Maximum Absolute Deviations:\n",
        "  Output Gap: ", sprintf("%+.3f", max_xgap_dev), " pp\n",
        "  Inflation: ", sprintf("%+.3f", max_pi_dev), " pp\n",
        "  Debt/GDP: ", sprintf("%+.2f", max_D_dev), " pp\n\n",
        "Final Period Debt/GDP Deviation: ", sprintf("%+.2f", final_D_dev), " pp"
      )
    } else {
      # Build summary text with field names
      summary_text <- paste0(
        "Shock Specification (Year-by-Year):\n",
        "  Receipts Delta: max ", sprintf("%+.2f", safe_max(shock$table_receipts)), " pp of GDP\n",
        "  Outlays Delta: max ", sprintf("%+.2f", safe_max(shock$table_outlays)), " pp of GDP\n",
        "  LF Growth: max ", sprintf("%+.2f", safe_max(shock$table_lf_growth)), " pp\n",
        "  Productivity Growth: max ", sprintf("%+.2f", safe_max(shock$table_productivity)), " pp\n",
        "  r* Direct: max ", sprintf("%+.2f", safe_max(shock$table_rfstar)), " pp\n",
        "  Inflation Target: max ", sprintf("%+.2f", safe_max(shock$table_inflation_target)), " pp\n",
        "  Inflation Shock: max ", sprintf("%+.2f", safe_max(shock$table_inflation_shock)), " pp\n",
        "  Output Gap Shock: max ", sprintf("%+.2f", safe_max(shock$table_output_gap)), " pp\n",
        "  Mon. Policy Rule: max ", sprintf("%+.2f", safe_max(shock$table_monetary_rule)), " pp\n\n",
        "Maximum Absolute Deviations:\n",
        "  Output Gap: ", sprintf("%+.3f", max_xgap_dev), " pp\n",
        "  Inflation: ", sprintf("%+.3f", max_pi_dev), " pp\n",
        "  Debt/GDP: ", sprintf("%+.2f", max_D_dev), " pp\n\n",
        "Final Period Debt/GDP Deviation: ", sprintf("%+.2f", final_D_dev), " pp"
      )
    }

    summary_text
  })

  # ============================================================================
  # USER DELTAS SUMMARY TABLE (BLSMM) - CONSOLIDATED
  # ============================================================================

  # Consolidated summary: All 9 input types in one table.
  # Data assembled into a shared reactive so we can render the same
  # table into two outputs — inside the Custom Scenario Builder drawer
  # AND on the Results tab's "Scenario Summary" nav panel.
  summary_all_deltas_df <- reactive({
    table_deltas <- collect_table_deltas(require_valid = FALSE)

    df <- data.frame(
      Shock = c(
        "Labor Force Growth (pp)",
        "Productivity Growth (pp)",
        "Receipts (pp of GDP)",
        "Primary Outlays (pp of GDP)",
        "Real r* (Direct) (pp)",
        "Inflation Target (pp)",
        "Output Gap Shock (pp)",
        "Inflation Shock (pp)",
        "Monetary Rule Shock (pp)"
      ),
      stringsAsFactors = FALSE
    )

    fy_labels <- create_fy_labels()
    for (i in 1:N_PERIODS) {
      df[[fy_labels[i]]] <- c(
        table_deltas$table_lf_growth[i],
        table_deltas$table_productivity[i],
        table_deltas$table_receipts[i],
        table_deltas$table_outlays[i],
        table_deltas$table_rfstar[i],
        table_deltas$table_inflation_target[i],
        table_deltas$table_output_gap[i],
        table_deltas$table_inflation_shock[i],
        table_deltas$table_monetary_rule[i]
      )
    }
    df
  })

  # Shared renderer: no row-selection highlight, hover-only row tint,
  # matches the Key Variable Deviations table treatment.
  render_summary_all_deltas <- function() {
    datatable(summary_all_deltas_df(),
              options = list(
                dom = 't',
                pageLength = 15,
                scrollX = TRUE,
                compact = TRUE,
                ordering = FALSE
              ),
              rownames = FALSE,
              selection = "none",
              class = 'compact stripe hover') %>%
      formatRound(columns = 2:(N_PERIODS + 1), digits = 2) %>%
      formatStyle(
        columns = 2:(N_PERIODS + 1),
        backgroundColor = styleInterval(c(-1e-9, 1e-9),
                                        c("#9ec5e8", "transparent", "#9ec5e8"))
      )
  }

  # Render #1: inside the Custom Scenario Builder drawer
  output$summary_all_deltas <- renderDT({ render_summary_all_deltas() })
  # Render #2: on the Results tab's "Scenario Summary" sub-tab
  output$summary_all_deltas_results <- renderDT({ render_summary_all_deltas() })

  # ============================================================================
  # EXPORT HANDLERS
  # ============================================================================

  # Download CSV (model variables)
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("BLSMM_simulation_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(simulation_results())

      # Combine baseline, scenario, and deviations (model variables)
      data <- simulation_results()

      export_data <- data$baseline %>%
        select(fy_label, xgap, U, PI, PIE, RF, R10, rfstar, rbar10, D_pct_GDP, NI, rbudp_star, GDP) %>%
        rename_with(~paste0("baseline_", .), -fy_label) %>%
        left_join(
          data$scenario %>%
            select(fy_label, xgap, U, PI, PIE, RF, R10, rfstar, rbar10, D_pct_GDP, NI, rbudp_star, GDP) %>%
            rename_with(~paste0("scenario_", .), -fy_label),
          by = "fy_label"
        ) %>%
        left_join(
          data$deviations %>%
            select(fy_label, d_xgap, d_U, d_PI, d_PIE, d_RF, d_R10, d_rfstar, d_rbar10, d_D_pct_GDP, d_NI, d_rbudp_star, d_GDP),
          by = "fy_label"
        )

      write.csv(export_data, file, row.names = FALSE)
    }
  )

  # Download Excel (model variables and user_deltas)
  output$download_excel <- downloadHandler(
    filename = function() {
      paste0("BLSMM_simulation_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      req(simulation_results())

      data <- simulation_results()

      # Create workbook
      wb <- createWorkbook()

      # Add sheets
      addWorksheet(wb, "Baseline")
      addWorksheet(wb, "Scenario")
      addWorksheet(wb, "Deviations")
      addWorksheet(wb, "Parameters")
      addWorksheet(wb, "User Deltas")

      # Write data (full data frames with all model variables)
      writeData(wb, "Baseline", data$baseline)
      writeData(wb, "Scenario", data$scenario)
      writeData(wb, "Deviations", data$deviations)

      # Add parameter info (model parameters)
      params <- create_parameters_v1_8()
      params_df <- data.frame(
        Parameter = names(params),
        Value = unlist(params)
      )
      writeData(wb, "Parameters", params_df)

      # Add the input deltas used for the exported simulation result.
      # Do not read the live editable tables here; they may have changed since
      # the last run, while simulation_results() still contains the prior solve.
      table_deltas <- data$shock_spec
      if (is.null(table_deltas)) {
        table_deltas <- list(
          table_lf_growth = rep(0, N_PERIODS),
          table_productivity = rep(0, N_PERIODS),
          table_receipts = rep(0, N_PERIODS),
          table_outlays = rep(0, N_PERIODS),
          table_rfstar = rep(0, N_PERIODS),
          table_output_gap = rep(0, N_PERIODS),
          table_inflation_shock = rep(0, N_PERIODS),
          table_monetary_rule = rep(0, N_PERIODS),
          table_inflation_target = rep(0, N_PERIODS)
        )
      }
      user_deltas_df <- data.frame(
        FY = create_fy_labels(n_years = N_PERIODS),
        LF_Growth = table_deltas$table_lf_growth,
        Productivity = table_deltas$table_productivity,
        Receipts = table_deltas$table_receipts,
        Outlays = table_deltas$table_outlays,
        RFstar_Direct = table_deltas$table_rfstar,
        Output_Gap_Shock = table_deltas$table_output_gap,
        Inflation_Shock = table_deltas$table_inflation_shock,
        MP_Rule_Shock = table_deltas$table_monetary_rule,
        Inflation_Target = table_deltas$table_inflation_target
      )
      writeData(wb, "User Deltas", user_deltas_df)

      # Save workbook
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )

  # ============================================================================
  # OUTPUT OPTIONS - Configure outputs to update even when tabs are hidden
  # ============================================================================
  # This ensures all outputs update immediately when simulations run,
  # regardless of which tab is currently visible

  # Deviation plots
  outputOptions(output, "dev_plot_output_gap", suspendWhenHidden = FALSE)
  outputOptions(output, "dev_plot_unemployment", suspendWhenHidden = FALSE)
  outputOptions(output, "dev_plot_real_gdp_growth", suspendWhenHidden = FALSE)
  outputOptions(output, "dev_plot_inflation", suspendWhenHidden = FALSE)
  outputOptions(output, "dev_plot_debt", suspendWhenHidden = FALSE)
  outputOptions(output, "dev_plot_federal_funds", suspendWhenHidden = FALSE)
  outputOptions(output, "dev_plot_10yr_yield", suspendWhenHidden = FALSE)
  outputOptions(output, "dev_plot_primary_balance", suspendWhenHidden = FALSE)

  # Multiplier display
  outputOptions(output, "multiplier_display", suspendWhenHidden = FALSE)
}

# ==============================================================================
# RUN APPLICATION
# ==============================================================================


