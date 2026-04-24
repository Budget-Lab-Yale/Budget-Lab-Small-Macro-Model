# ==============================================================================
# The Budget Lab's Small Macro Model (BLSMM) - Interactive Shiny Application
# ==============================================================================

# Pin dev port so docs/embed_preview.html has a stable URL across sessions.
# Change this (and the URL in embed_preview.html) if 8100 conflicts.
options(shiny.port = 8100)

# Load required libraries
library(shiny)
library(bslib)
library(plotly)
library(DT)
library(dplyr)
library(openxlsx)
library(shinyjs)

# Source model modules
source('model/v1_8/parameters.R')
source('model/v1_8/user_deltas.R')
source('model/v1_8/presim_block.R')
source('model/v1_8/neutral_rate.R')
source('model/v1_8/debt_proxy.R')
source('model/v1_8/equations.R')
source('model/v1_8/solver.R')
source('model/v1_8/forcing.R')
source('model/v1_8/simulation.R')

# Load data files (global for app)
baseline_exog_v1_8 <<- read.csv('data/blsmm_v1_8_forecast_exog.csv', check.names = FALSE)
baseline_resid_v1_8 <<- read.csv('data/blsmm_v1_8_forecast_resid.csv', check.names = FALSE)
hist_data_v1_8 <<- read.csv('data/blsmm_v1_8_historical.csv', check.names = FALSE)

# Source modular app components
source('app/R/blsmm_theme.R')
source('app/R/blsmm_helpers.R')
source('app/R/blsmm_ui.R')
source('app/R/blsmm_server.R')

# Run application
shinyApp(ui = ui, server = server)
