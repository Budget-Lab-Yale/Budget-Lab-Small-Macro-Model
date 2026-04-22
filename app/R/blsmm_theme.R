# ==============================================================================
# BLSMM Design Tokens
# ------------------------------------------------------------------------------
# Single source of truth for colors, fonts, spacing, and plotly chart styling.
# Matches the Budget Lab website visual identity:
#   - Navy #101f5b headings / buttons
#   - Blue #286dc0 links / primary series
#   - Mallory (body) + YaleNew (headings) with Source Sans 3 fallback
# All color/font references in the app should read from here.
# ==============================================================================

# Light-mode palette
bl_colors <- list(
  # Brand
  navy          = "#101f5b",  # headings, buttons
  blue          = "#286dc0",  # links, primary/baseline series
  orange        = "#f28e2b",  # scenario series, accents

  # Text
  body          = "#4a4a4a",
  muted         = "#888888",
  heading       = "#1a1a2e",

  # Surfaces
  bg            = "#ffffff",
  bg_subtle     = "#f6f7f9",
  bg_highlight  = "#d9eaff",  # read-only rows, subtle callouts
  border        = "#e5e5e5",
  gridline      = "#f0f0f0",

  # Input table row tints
  row_baseline  = "#f9fafb",
  row_delta     = "#fff9e6",  # editable yellow
  row_level     = "#f9fafb",

  # Status pills (kept from current app for now)
  status_ready   = "#e9ecef",
  status_dirty   = "#fff3cd",
  status_running = "#cfe2ff",
  status_solved  = "#d1e7dd",
  status_error   = "#f8d7da",

  # Categorical palette (from Code Tests/shared/theme-v1.js)
  cat1 = "#286dc0",  # blue
  cat2 = "#5e9e00",  # lime
  cat3 = "#7040c8",  # violet
  cat4 = "#c86020",  # orange
  cat5 = "#00A846",  # forest
  cat6 = "#c04880",  # rose
  cat7 = "#1890a0"   # teal
)

# Dark-mode palette
bl_colors_dark <- list(
  navy          = "#4a6bd9",  # lighter navy for dark bg
  blue          = "#6fa3e6",
  orange        = "#f5a623",

  body          = "#d5d8dd",
  muted         = "#8a8f96",
  heading       = "#f0f0f5",

  bg            = "#1a1d23",
  bg_subtle     = "#23272e",
  bg_highlight  = "#2a3b5c",
  border        = "#3a3f47",
  gridline      = "#2a2e35",

  row_baseline  = "#1f2937",
  row_delta     = "#6b5d2f",
  row_level     = "#1f2937",

  status_ready   = "#3a3f47",
  status_dirty   = "#6b5d2f",
  status_running = "#1e3a5f",
  status_solved  = "#1f4c3d",
  status_error   = "#5a1f1f",

  cat1 = "#6fa3e6",
  cat2 = "#9ed142",
  cat3 = "#a78bf0",
  cat4 = "#e89c5c",
  cat5 = "#48c97a",
  cat6 = "#e084a8",
  cat7 = "#5abccb"
)

# Font stacks. Sans throughout: Budget Lab's website pairs sans body with
# serif headings (YaleNew), but in this app both use the same sans stack
# for a tighter, more data-dashboard feel.
bl_fonts <- list(
  body     = '"Mallory", system-ui, -apple-system, "Segoe UI", "Source Sans 3", Arial, sans-serif',
  heading  = '"Mallory", system-ui, -apple-system, "Segoe UI", "Source Sans 3", Arial, sans-serif',
  mono     = 'ui-monospace, SFMono-Regular, "SF Mono", Consolas, "Liberation Mono", monospace'
)

# Spacing and shape
bl_spacing <- list(
  container_pad = "24px",
  section_gap   = "20px",
  radius        = "8px",
  radius_sm     = "6px",
  shadow        = "0 1px 3px rgba(0, 0, 0, 0.08)",
  shadow_lg     = "0 4px 12px rgba(0, 0, 0, 0.10)"
)

# ------------------------------------------------------------------------------
# Plotly chart theme
# ------------------------------------------------------------------------------
# Returns a list suitable for splatting into plotly::layout(..., !!!bl_plotly_theme()).
# Pass dark = TRUE to get the dark-mode variant.
# ------------------------------------------------------------------------------
bl_plotly_theme <- function(dark = FALSE) {
  pal <- if (dark) bl_colors_dark else bl_colors

  list(
    font = list(
      family = bl_fonts$body,
      size   = 13,
      color  = pal$body
    ),
    paper_bgcolor = pal$bg,
    plot_bgcolor  = pal$bg,
    colorway      = c(pal$blue, pal$orange, pal$cat2, pal$cat3, pal$cat5, pal$cat6, pal$cat7),
    xaxis = list(
      gridcolor    = pal$gridline,
      zerolinecolor = pal$border,
      linecolor    = pal$border,
      tickfont     = list(color = pal$muted, size = 11)
    ),
    yaxis = list(
      gridcolor    = pal$gridline,
      zerolinecolor = pal$border,
      linecolor    = pal$border,
      tickfont     = list(color = pal$muted, size = 11)
    ),
    legend = list(
      font = list(color = pal$body, size = 12),
      bgcolor = "rgba(0,0,0,0)",
      bordercolor = "rgba(0,0,0,0)"
    ),
    hoverlabel = list(
      font = list(family = bl_fonts$body, color = "white", size = 12),
      bgcolor = pal$navy,
      bordercolor = pal$navy
    ),
    margin = list(l = 60, r = 30, t = 20, b = 50)
  )
}

# ------------------------------------------------------------------------------
# Emit :root CSS custom properties so inline CSS and component CSS can share
# the same token values. Usage: place `bl_css_vars_block()` inside tags$head.
# ------------------------------------------------------------------------------
bl_css_vars_block <- function() {
  to_vars <- function(pal, prefix) {
    paste0(
      "  --", prefix, names(pal), ": ", unlist(pal), ";",
      collapse = "\n"
    )
  }
  css <- paste0(
    ":root {\n", to_vars(bl_colors, "bl-"), "\n",
    "  --bl-font-body: ", bl_fonts$body, ";\n",
    "  --bl-font-heading: ", bl_fonts$heading, ";\n",
    "  --bl-font-mono: ", bl_fonts$mono, ";\n",
    "  --bl-radius: ", bl_spacing$radius, ";\n",
    "  --bl-radius-sm: ", bl_spacing$radius_sm, ";\n",
    "  --bl-container-pad: ", bl_spacing$container_pad, ";\n",
    "  --bl-shadow: ", bl_spacing$shadow, ";\n",
    "  --bl-shadow-lg: ", bl_spacing$shadow_lg, ";\n",
    "}\n",
    "[data-bs-theme='dark'] {\n", to_vars(bl_colors_dark, "bl-"), "\n}"
  )
  shiny::tags$style(shiny::HTML(css))
}

# ------------------------------------------------------------------------------
# Webfont loader: Mallory/YaleNew primary, Source Sans 3 as free fallback.
# When Yale confirms a font CDN URL, add it here alongside the Google Fonts call.
# Returns a tagList so it can be placed inside an existing tags$head().
# ------------------------------------------------------------------------------
bl_webfonts_block <- function() {
  shiny::tagList(
    # Preconnect for faster Google Fonts load
    shiny::tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    shiny::tags$link(rel = "preconnect", href = "https://fonts.gstatic.com", crossorigin = NA),
    # Source Sans 3 (free fallback for Mallory)
    shiny::tags$link(
      rel  = "stylesheet",
      href = "https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700&display=swap"
    )
    # TODO: once Yale confirms Mallory/YaleNew CDN URL or ships woff2 files,
    # add the corresponding <link> or @font-face block here.
  )
}

# ------------------------------------------------------------------------------
# Minimal CSS overrides that apply Budget Lab fonts and core brand colors
# on top of the existing Bootswatch theme. Keep this narrow so it composes
# with the heavier inline CSS until that gets refactored into the theme.
# ------------------------------------------------------------------------------
bl_brand_overrides_block <- function() {
  shiny::tags$style(shiny::HTML("
    /* Border radius: softer, rounder corners across buttons, cards, inputs,
       alerts, nav pills. Matches the rounded feel of the Deficits
       Affordability calculator and the Budget Lab infographic set. */
    :root {
      --bs-border-radius: 0.5rem;
      --bs-border-radius-sm: 0.4rem;
      --bs-border-radius-lg: 0.75rem;
      --bs-border-radius-pill: 50rem;
    }
    .btn, .card, .form-control, .form-select, .input-group-text,
    .alert, .modal-content, .offcanvas, .dropdown-menu, .nav-pills .nav-link,
    .value-box, .bslib-value-box {
      border-radius: 0.5rem;
    }
    .btn-sm { border-radius: 0.4rem; }
    .btn-lg { border-radius: 0.6rem; }

    /* Font stack everywhere, but DO NOT override button text color
       (buttons carry their own white/colored text per variant). */
    body, .form-control, .btn, .nav-link, .navbar, .card,
    .dropdown-menu, .modal-content, .offcanvas, .alert, .badge {
      font-family: var(--bl-font-body);
    }
    body, .form-control, .card, .offcanvas, .dropdown-menu {
      color: var(--bl-body);
    }
    h1, h2, h3, h4, h5, h6,
    .h1, .h2, .h3, .h4, .h5, .h6 {
      font-family: var(--bl-font-heading);
      color: var(--bl-heading);
      font-weight: 700;
      letter-spacing: -0.01em;
    }
    [data-bs-theme='dark'] h1, [data-bs-theme='dark'] h2,
    [data-bs-theme='dark'] h3, [data-bs-theme='dark'] h4,
    [data-bs-theme='dark'] h5, [data-bs-theme='dark'] h6 {
      color: var(--bl-heading);
    }
    a { color: var(--bl-blue); }
    a:hover, a:focus { color: var(--bl-navy); }
    [data-bs-theme='dark'] a:hover,
    [data-bs-theme='dark'] a:focus { color: var(--bl-blue); }

    /* Primary button: navy with white text */
    .btn-primary,
    .btn-primary:disabled {
      background-color: var(--bl-navy);
      border-color: var(--bl-navy);
      color: #ffffff;
    }
    .btn-primary:hover, .btn-primary:focus, .btn-primary:active,
    .btn-primary:not(:disabled):not(.disabled):active,
    .btn-primary:not(:disabled):not(.disabled).active {
      background-color: var(--bl-blue) !important;
      border-color: var(--bl-blue) !important;
      color: #ffffff !important;
    }

    /* Outline primary: navy outline + text, navy fill on hover */
    .btn-outline-primary {
      color: var(--bl-navy);
      border-color: var(--bl-navy);
      background-color: transparent;
    }
    .btn-outline-primary:hover, .btn-outline-primary:focus,
    .btn-outline-primary:active {
      background-color: var(--bl-navy);
      border-color: var(--bl-navy);
      color: #ffffff;
    }

    /* Secondary button: soft neutral, not the Flatly gray-green */
    .btn-secondary {
      background-color: #6c757d;
      border-color: #6c757d;
      color: #ffffff;
    }
    .btn-secondary:hover, .btn-secondary:focus, .btn-secondary:active {
      background-color: #5a6268 !important;
      border-color: #5a6268 !important;
      color: #ffffff !important;
    }

    /* Success/info/warning/danger: keep Bootstrap-ish but aligned with
       the Budget Lab accent set, and avoid Flatly's teal-green. */
    .btn-success, .bg-success {
      background-color: #2a7a2a;
      border-color: #2a7a2a;
    }
    .btn-info, .bg-info {
      background-color: var(--bl-blue);
      border-color: var(--bl-blue);
      color: #ffffff;
    }
    .alert-success {
      background-color: #e8f3e8;
      border-color: #c4e0c4;
      color: #155724;
    }
    .alert-info {
      background-color: #e7f0f9;
      border-color: #b5d1ea;
      color: #084298;
    }

    /* Focus ring: use navy, not Flatly's teal */
    .form-control:focus, .form-select:focus, .btn:focus {
      border-color: var(--bl-blue);
      box-shadow: 0 0 0 0.2rem rgba(40, 109, 192, 0.25);
    }

    /* Nav tabs underline uses navy */
    .nav-tabs .nav-link.active {
      color: var(--bl-navy);
      border-bottom-color: var(--bl-navy);
    }

    /* ---------- Sidebar-specific layout fixes ---------- */

    /* Enable container queries so sidebar content scales to its width */
    .bslib-sidebar-layout > .sidebar,
    .bslib-sidebar-layout .sidebar-content {
      container-type: inline-size;
    }

    /* Center the Solver Status / run-status pill inside the sidebar */
    .blsmm-solver-status,
    .blsmm-run-status-wrap {
      text-align: center;
    }
    .blsmm-solver-status h4 {
      text-align: center;
      margin-bottom: 6px;
    }
    .blsmm-solver-status .sse-box {
      display: inline-block;
    }

    /* Run Simulation / Reset buttons:
       stack icon above text, wrap text cleanly, font size scales to
       sidebar width via container queries with safe min/max. */
    .blsmm-action-btn {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 4px;
      white-space: normal;
      line-height: 1.2;
      padding: 10px 12px;
      font-weight: 600;
      min-height: 56px;
    }
    #run_sim.blsmm-action-btn {
      font-size: clamp(0.9rem, 5cqi, 1.05rem);
    }
    #reset_inputs.blsmm-action-btn {
      font-size: clamp(0.82rem, 4.2cqi, 0.95rem);
    }
    .blsmm-action-btn > i,
    .blsmm-action-btn > .fa,
    .blsmm-action-btn > svg {
      font-size: 1.25em;
      flex: 0 0 auto;
      margin: 0;
    }

    /* ---------- KPI value boxes ----------
       Light card look: white background, navy left-edge accent, muted
       uppercase title, big navy value. Clearly non-interactive; navy fill
       is reserved for action buttons. */
    .blsmm-kpi-card {
      background-color: #ffffff !important;
      border-left: 4px solid var(--bl-navy) !important;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
    }
    .blsmm-kpi-card .value-box-title {
      color: var(--bl-muted) !important;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      font-size: 0.75rem;
      font-weight: 600;
      margin-bottom: 4px;
    }
    .blsmm-kpi-card .value-box-value {
      color: var(--bl-navy) !important;
      font-size: 1.8rem;
      font-weight: 700;
      line-height: 1.1;
    }
    .blsmm-kpi-card .value-box-showcase,
    .blsmm-kpi-card .value-box-showcase svg,
    .blsmm-kpi-card .value-box-showcase .fa {
      color: var(--bl-navy) !important;
      opacity: 0.35;
    }
    .blsmm-kpi-card p {
      color: var(--bl-body) !important;
      margin-top: 6px;
    }
    [data-bs-theme='dark'] .blsmm-kpi-card {
      background-color: var(--bl-bg-subtle) !important;
      border-left-color: var(--bl-blue) !important;
    }
    [data-bs-theme='dark'] .blsmm-kpi-card .value-box-value {
      color: var(--bl-blue) !important;
    }
    [data-bs-theme='dark'] .blsmm-kpi-card .value-box-showcase {
      color: var(--bl-blue) !important;
    }

    /* Preset buttons: active state (sticky highlight until another preset
       is clicked or inputs are reset). Fills the outline variant with its
       own color so the selected scenario reads at a glance. */
    .btn-outline-primary.preset-active,
    .btn-outline-primary.preset-active:focus,
    .btn-outline-primary.preset-active:hover {
      background-color: var(--bl-navy) !important;
      border-color: var(--bl-navy) !important;
      color: #ffffff !important;
    }
    .btn-outline-warning.preset-active,
    .btn-outline-warning.preset-active:focus,
    .btn-outline-warning.preset-active:hover {
      background-color: #b45309 !important;
      border-color: #b45309 !important;
      color: #ffffff !important;
    }
    .btn-outline-danger.preset-active,
    .btn-outline-danger.preset-active:focus,
    .btn-outline-danger.preset-active:hover {
      background-color: #9b2226 !important;
      border-color: #9b2226 !important;
      color: #ffffff !important;
    }
  "))
}
