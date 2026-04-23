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

  output$run_status_bar <- renderUI({
    state <- run_state()
    state_class <- switch(
      state,
      ready = "run-ready",
      dirty = "run-dirty",
      running = "run-running",
      solved = "run-solved",
      error = "run-error",
      "run-ready"
    )

    state_label <- switch(
      state,
      ready = "READY",
      dirty = "DIRTY",
      running = "RUNNING",
      solved = "Complete",
      error = "ERROR",
      "READY"
    )

    div(
      class = paste("run-status", state_class),
      paste0(state_label, " | ", run_state_note())
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
      pos_fg  = "#28a745"
    )
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

  for (table_id in table_ids) {
    local({
      id <- table_id
      output[[id]] <- renderRHandsontable({
        req(table_state[[id]])
        tbl <- rhandsontable(
          table_state[[id]],
          rowHeaders = NULL,
          height = 180,
          readOnly = TRUE
        ) %>%
          hot_col("Row", readOnly = TRUE)

        # Keep only User Delta row editable (yellow row); baseline/level stay locked.
        for (col_idx in seq(TABLE_FIRST_DATA_COL, ncol(table_state[[id]]))) {
          tbl <- tbl %>% hot_cell(row = TABLE_ROW_DELTA, col = col_idx, readOnly = FALSE)
        }

        tbl
      })
    })
  }

  get_current_table_data <- function(table_id) {
    hot_data <- hot_to_r(input[[table_id]])
    if (is.null(hot_data)) table_state[[table_id]] else hot_data
  }

  # Force Handsontable widgets to compute size/render when tabs change.
  refresh_hot_tables <- function() {
    shinyjs::runjs(
      "setTimeout(function() {
         window.dispatchEvent(new Event('resize'));
         if (window.HTMLWidgets && HTMLWidgets.staticRender) {
           HTMLWidgets.staticRender();
         }
       }, 50);"
    )
  }

  session$onFlushed(function() {
    refresh_hot_tables()
  }, once = TRUE)

  observeEvent(input$main_tabs, {
    refresh_hot_tables()
  }, ignoreInit = TRUE)

  observeEvent(input$input_subtabs, {
    refresh_hot_tables()
  }, ignoreInit = TRUE)

  # ============================================================================
  # REACTIVE OBSERVERS - UPDATE LEVEL ROWS
  # ============================================================================
  update_table_level_row <- function(hot_data) {
    if (is.null(hot_data)) return(hot_data)
    fy_cols <- seq(TABLE_FIRST_DATA_COL, ncol(hot_data))
    baseline <- suppressWarnings(as.numeric(hot_data[TABLE_ROW_BASELINE, fy_cols]))
    parsed <- parse_table_deltas(hot_data, length(fy_cols))
    hot_data[TABLE_ROW_LEVEL, fy_cols] <- round(baseline + parsed$values, 2)
    hot_data
  }

  for (table_id in table_ids) {
    local({
      id <- table_id
      debounced_table_input <- debounce(reactive(input[[id]]), millis = 150)
      observeEvent(debounced_table_input(), {
        hot_data <- hot_to_r(debounced_table_input())
        req(hot_data)
        prev_data <- isolate(table_state[[id]])

        # Enforce numeric-only inputs in User Delta row:
        # revert non-numeric (non-blank) entries to the previous value.
        fy_cols <- seq(TABLE_FIRST_DATA_COL, TABLE_FIRST_DATA_COL + N_PERIODS - 1)
        raw_vals <- as.character(unlist(hot_data[TABLE_ROW_DELTA, fy_cols], use.names = FALSE))
        raw_vals[is.na(raw_vals)] <- ""
        trimmed <- trimws(raw_vals)
        parsed_vals <- suppressWarnings(as.numeric(trimmed))
        blank_mask <- trimmed == ""
        invalid_idx <- which(!blank_mask & is.na(parsed_vals))

        if (length(invalid_idx) > 0 && !is.null(prev_data)) {
          hot_data[TABLE_ROW_DELTA, fy_cols[invalid_idx]] <- prev_data[TABLE_ROW_DELTA, fy_cols[invalid_idx]]
          showNotification(
            paste0(
              "Only numeric values are allowed in User Delta cells. ",
              "Invalid entries were reverted in ",
              paste(fy_labels[invalid_idx], collapse = ", "),
              "."
            ),
            type = "warning",
            duration = 4
          )
        }

        table_state[[id]] <- update_table_level_row(hot_data)

        # Ignore startup no-op table events so initial status remains Complete.
        parsed <- parse_table_deltas(hot_data, N_PERIODS)
        has_nonzero_delta <- any(abs(parsed$values) > 1e-9, na.rm = TRUE)
        has_invalid_delta <- length(parsed$invalid_idx) > 0
        is_initial_baseline_state <- identical(run_state(), "solved") &&
          identical(run_state_note(), "Baseline loaded")

        if (!(is_initial_baseline_state && !has_nonzero_delta && !has_invalid_delta)) {
          set_run_state("dirty", "Inputs changed. Press Run to update results")
        }
      }, ignoreInit = TRUE)
    })
  }

  observeEvent(input$expectations_speed, {
    is_initial_baseline_state <- identical(run_state(), "solved") &&
      identical(run_state_note(), "Baseline loaded")
    if (!(is_initial_baseline_state && !isTRUE(input$expectations_speed))) {
      set_run_state("dirty", "Options changed. Press Run to update results")
    }
  }, ignoreInit = TRUE)

  collect_table_deltas <- function(require_valid = TRUE) {
    deltas <- list()
    invalid_messages <- character(0)

    for (table_id in table_ids) {
      current_data <- get_current_table_data(table_id)
      parsed <- parse_table_deltas(current_data, N_PERIODS)
      deltas[[table_id]] <- parsed$values

      if (require_valid && length(parsed$invalid_idx) > 0) {
        bad_years <- fy_labels[parsed$invalid_idx]
        invalid_messages <- c(
          invalid_messages,
          sprintf("%s: %s", table_specs[[table_id]]$label, paste(bad_years, collapse = ", "))
        )
      }
    }

    if (require_valid && length(invalid_messages) > 0) {
      showNotification(
        paste0(
          "Invalid numeric entries in User Delta rows:\n",
          paste(invalid_messages, collapse = "\n")
        ),
        type = "error",
        duration = 8
      )
      set_run_state("error", "Invalid numeric input in tables")
      return(NULL)
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

  # Initialize with baseline simulation on app launch
  simulation_results <- reactiveVal({
    baseline_old_format <- convert_to_old_structure(baseline_v1_8, baseline_v1_8)
    # Preserve solver_summary attribute from baseline
    attr(baseline_old_format$scenario, "solver_summary") <- attr(baseline_v1_8, "solver_summary")
    # Baseline has no shocks applied
    baseline_old_format$shock_spec <- NULL
    baseline_old_format
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
        set_run_state("solved", "Loaded cached results")
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
            set_run_state("solved", "Simulation complete")
          } else {
            set_run_state("error", sprintf("Not converged (SSE: %.2e)", max_sse))
          }
        } else {
          if (solver_summary$overall_converged) {
            set_run_state("solved", "Simulation complete")
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
    refresh_hot_tables()

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
    set_run_state("dirty", "Inputs reset. Press Run to update results")
  })

  # ============================================================================
  # PRESET SCENARIOS
  # ============================================================================

  # Helper function to reset all tables to baseline
  reset_all_tables_to_baseline <- function() {
    initialize_tables(force = TRUE)
    refresh_hot_tables()
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
    refresh_hot_tables()
  }

  apply_single_preset <- function(table_name, shock_values) {
    reset_all_tables_to_baseline()
    update_table_with_shocks(table_name, shock_values)
    set_run_state("dirty", "Preset applied. Press Run to update results")
  }

  apply_multi_preset <- function(presets_list) {
    reset_all_tables_to_baseline()
    for (i in seq_along(presets_list)) {
      table_name <- names(presets_list)[i]
      shock_values <- presets_list[[i]]
      update_table_with_shocks(table_name, shock_values)
    }
    set_run_state("dirty", "Preset applied. Press Run to update results")
  }

  # Preset 1: Rapid AI Adoption
  # Source: BLSMM_1_8_20260326_links_rapidAI.xlsm
  # Three simultaneous shocks: productivity boost, LFPR decline, outlay rise
  observeEvent(input$preset_rapid_ai, {
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
      prev_id   <- paste0("preview_",   k)
      tbl_name  <- paste0("table_",     k)

      # Preview: always reflects the current Delta row of the table, so it
      # stays accurate whether the change came from simple mode, a preset,
      # or a direct handsontable edit.
      output[[prev_id]] <- renderText({
        tbl <- table_state[[tbl_name]]
        if (is.null(tbl)) return("")
        fy_cols <- seq(TABLE_FIRST_DATA_COL,
                       TABLE_FIRST_DATA_COL + N_PERIODS - 1)
        delta <- suppressWarnings(as.numeric(unlist(
          tbl[TABLE_ROW_DELTA, fy_cols], use.names = FALSE
        )))
        delta[is.na(delta)] <- 0
        if (all(abs(delta) < 1e-12)) {
          "No change from baseline."
        } else {
          paste0("Applied delta: ", format_shape_preview(delta))
        }
      })

      # Observer: write simple-mode delta into the table when user edits
      # shape or magnitude. Overwrites any previous values (by design —
      # simple mode is an override layer).
      observeEvent(
        list(input[[shape_id]], input[[mag_id]]),
        ignoreInit = TRUE,
        {
          shape <- input[[shape_id]] %||% "onetime"
          mag   <- input[[mag_id]]
          delta <- build_shape_delta(shape, mag, N_PERIODS)
          update_table_with_shocks(tbl_name, delta)
          set_run_state("dirty",
                        "Inputs changed. Press Run to update results")
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
  # All 13 charts:
  outputOptions(output, "plot_unemployment", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_inflation", suspendWhenHidden = FALSE)
  outputOptions(output, "plot_real_gdp_indexed", suspendWhenHidden = FALSE)
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

  # Ensure input tables are always rendered (even when Inputs tab not visible)
  # This is critical for reset and preset scenarios to work from Dashboard tab
  # All 9 input tables
  outputOptions(output, "table_lf_growth", suspendWhenHidden = FALSE)
  outputOptions(output, "table_productivity", suspendWhenHidden = FALSE)
  outputOptions(output, "table_receipts", suspendWhenHidden = FALSE)
  outputOptions(output, "table_outlays", suspendWhenHidden = FALSE)
  outputOptions(output, "table_rfstar", suspendWhenHidden = FALSE)
  outputOptions(output, "table_output_gap", suspendWhenHidden = FALSE)
  outputOptions(output, "table_inflation_shock", suspendWhenHidden = FALSE)
  outputOptions(output, "table_monetary_rule", suspendWhenHidden = FALSE)
  outputOptions(output, "table_inflation_target", suspendWhenHidden = FALSE)

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

    # Add shaded area for cumulative effect
    plot_ly() %>%
      add_lines(
        x = data$fy_label,
        y = data$d_D_pct_GDP,
        name = "Debt/GDP Deviation",
        line = list(color = th$line_scenario, width = 3),
        fill = 'tozeroy',
        fillcolor = th$debt_fill,
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
        compact = TRUE
      ),
      rownames = FALSE,
      class = 'compact stripe'
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

  # Consolidated summary: All 9 input types in one table
  output$summary_all_deltas <- renderDT({
    table_deltas <- collect_table_deltas(require_valid = FALSE)

    # Create data frame with all shock types
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

    # Add year columns
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

    datatable(df,
              options = list(
                dom = 't',
                pageLength = 15,
                scrollX = TRUE,
                compact = TRUE
              ),
              rownames = FALSE,
              class = 'compact stripe') %>%
      formatRound(columns = 2:(N_PERIODS+1), digits = 2)
  })

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


