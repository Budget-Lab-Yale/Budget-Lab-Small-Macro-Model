#!/usr/bin/env Rscript

# Historical recipe for the frozen fixtures. Do not run this script as part of
# the calibration workflow. The source workbooks live outside this repository.
# openxlsx reads the cached values stored in those workbooks.

suppressPackageStartupMessages({
  library(digest)
  library(openxlsx)
})

find_project_root <- function(start = getwd()) {
  path <- normalizePath(start, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(path, "calibration", "source_manifest.csv"))) return(path)
    parent <- dirname(path)
    if (identical(parent, path)) stop("Could not locate BLSMM project root")
    path <- parent
  }
}

root <- find_project_root()
manifest <- read.csv(file.path(root, "calibration", "source_manifest.csv"),
                     stringsAsFactors = FALSE)

resolve_source <- function(source_id) {
  entry <- manifest[manifest$source_id == source_id, , drop = FALSE]
  if (nrow(entry) != 1L) stop("Manifest must contain exactly one entry for ", source_id)
  path <- normalizePath(file.path(root, entry$path), mustWork = TRUE)
  actual <- digest(path, algo = "sha256", file = TRUE)
  if (!identical(actual, entry$sha256)) {
    stop("SHA-256 mismatch for ", source_id, ": expected ", entry$sha256,
         ", got ", actual)
  }
  path
}

read_cached_sheet <- function(path, sheet) {
  read.xlsx(path, sheet = sheet, colNames = FALSE,
            skipEmptyRows = FALSE, skipEmptyCols = FALSE)
}

extract_model_sections <- function(path, source_id) {
  model <- read_cached_sheet(path, "Model")
  columns <- 16:25
  years <- as.integer(unlist(model[3, columns], use.names = FALSE))
  section_rows <- list(
    force_flag = setNames(60:67, c("xgap", "U", "PI", "PIE", "RF", "MPE10", "TP", "RG")),
    forced_value = setNames(70:77, c("xgap", "U", "PI", "PIE", "RF", "MPE10", "TP", "RG")),
    baseline_residual = setNames(81:88, c("epsxgap", "epsu", "epspi", "epspie",
                                         "epsrf", "epsmpe", "epstp", "epsrg")),
    structural_value = c(xgap = 153, U = 157, PI = 158, PIE = 159, RF = 160,
                         MPE10 = 161, TP = 162, RG = 163),
    solution = c(GDP = 166, xgap = 167, R10 = 168, PIE = 169, PGDP = 170,
                 `GDP$star` = 171, `GDP$` = 172, BUDP = 173, U = 174,
                 PI = 175, RF = 176, MPE10 = 177, TP = 178, RG = 179,
                 NI = 180, D = 181, BUD = 182),
    implied_residual = setNames(207:214, c("epsxgap", "epsu", "epspi", "epspie",
                                          "epsrf", "epsmpe", "epstp", "epsrg"))
  )

  pieces <- lapply(names(section_rows), function(section) {
    rows <- section_rows[[section]]
    do.call(rbind, lapply(seq_along(rows), function(i) {
      data.frame(
        source_id = source_id,
        section = section,
        variable = names(rows)[i],
        year = years,
        value = as.numeric(unlist(model[rows[i], columns], use.names = FALSE)),
        stringsAsFactors = FALSE
      )
    }))
  })
  historical_rows <- c(xgap = 167, R10 = 168, PIE = 169, U = 174, PI = 175,
                       RF = 176, MPE10 = 177, TP = 178, RG = 179)
  historical <- do.call(rbind, lapply(seq_along(historical_rows), function(i) {
    data.frame(
      source_id = source_id,
      section = "historical_solution",
      variable = names(historical_rows)[i],
      year = 2025L,
      value = as.numeric(model[historical_rows[i], 15]),
      stringsAsFactors = FALSE
    )
  }))
  rbind(do.call(rbind, pieces), historical)
}

extract_spf_user_deltas <- function(path) {
  user <- read_cached_sheet(path, "User")
  columns <- 10:19
  # The User sheet year labels are merged/format-heavy. The calibration workbook
  # has a fixed 2026-2035 horizon, verified against Model row 3.
  rows <- c(
    user_delta_lf = 12,
    user_delta_prod = 17,
    user_delta_rgfr = 32,
    user_delta_rgfop = 40,
    user_delta_rfstar_direct = 60,
    user_delta_ADshock = 70,
    user_delta_inflshock = 79,
    user_delta_MPshock = 88,
    user_delta_pistar = 97
  )
  do.call(rbind, lapply(seq_along(rows), function(i) {
    data.frame(
      source_id = "spf_calibration",
      variable = names(rows)[i],
      year = 2026:2035,
      value = as.numeric(unlist(user[rows[i], columns], use.names = FALSE)),
      stringsAsFactors = FALSE
    )
  }))
}

extract_baseline_effective_rate <- function(path) {
  user <- read_cached_sheet(path, "User")
  data.frame(
    source_id = "original_v1_8",
    variable = "RG_base",
    year = 2026:2035,
    value = as.numeric(unlist(user[232, 10:19], use.names = FALSE)),
    stringsAsFactors = FALSE
  )
}

original_path <- resolve_source("original_v1_8")
spf_path <- resolve_source("spf_calibration")
output_dir <- file.path(root, "calibration", "golden")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(extract_model_sections(original_path, "original_v1_8"),
          file.path(output_dir, "original_v1_8_model.csv"), row.names = FALSE, na = "")
write.csv(extract_model_sections(spf_path, "spf_calibration"),
          file.path(output_dir, "spf_model.csv"), row.names = FALSE, na = "")
write.csv(extract_spf_user_deltas(spf_path),
          file.path(output_dir, "spf_user_deltas.csv"), row.names = FALSE, na = "")
write.csv(extract_baseline_effective_rate(original_path),
          file.path(output_dir, "baseline_effective_rate.csv"), row.names = FALSE, na = "")

cat("Wrote Excel golden fixtures to", output_dir, "\n")
