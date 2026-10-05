# ==============================================================================
# Minimal JSON writer for the files js/blsmm-model.js reads.
# ==============================================================================
# jsonlite's digits = NA rounds to 15 significant digits, which does not
# round-trip doubles (1.600233824120423 becomes 1.60023382412042). Numbers here
# are written with 17 significant digits, which identify every double exactly,
# so JS sees exactly the values R used. Shorter forms cannot be chosen by
# parsing them back in R: R's parser is not correctly rounded, and accepts
# 1.668436614039707 for a double that JavaScript reads one ULP away.
#
# Mapping: named list -> object; unnamed list -> array; numeric/logical
# vector -> array, or a scalar when length 1 and not wrapped in I();
# character -> string(s); NA -> null.
# ==============================================================================

format_double <- function(x) {
  if (is.na(x)) return("null")
  if (!is.finite(x)) stop("JSON cannot represent non-finite number: ", x)
  if (x == round(x) && abs(x) < 1e15) return(sprintf("%.0f", x))
  # "%.17g" may emit "1.0000000000000001e-05"; JSON accepts that form.
  sprintf("%.17g", x)
}

to_json <- function(x, indent = 0) {
  pad <- strrep("  ", indent)
  pad1 <- strrep("  ", indent + 1)
  as_array <- inherits(x, "AsIs")
  if (is.list(x)) {
    if (length(x) == 0) return(if (is.null(names(x))) "[]" else "{}")
    if (!is.null(names(x))) {
      items <- vapply(names(x), function(k) {
        paste0(pad1, jsonlite::toJSON(k, auto_unbox = TRUE), ": ", to_json(x[[k]], indent + 1))
      }, character(1))
      return(paste0("{\n", paste(items, collapse = ",\n"), "\n", pad, "}"))
    }
    items <- vapply(x, function(v) paste0(pad1, to_json(v, indent + 1)), character(1))
    return(paste0("[\n", paste(items, collapse = ",\n"), "\n", pad, "]"))
  }
  vals <- if (is.character(x)) {
    vapply(x, function(v) if (is.na(v)) "null" else as.character(jsonlite::toJSON(v, auto_unbox = TRUE)), character(1))
  } else if (is.logical(x)) {
    ifelse(is.na(x), "null", ifelse(x, "true", "false"))
  } else if (is.numeric(x)) {
    vapply(as.numeric(x), format_double, character(1))
  } else {
    stop("Unsupported type for JSON: ", class(x)[1])
  }
  if (length(vals) == 1 && !as_array) return(unname(vals))
  paste0("[", paste(vals, collapse = ", "), "]")
}

# Data frame -> named list of column vectors (always arrays).
df_columns <- function(df) {
  out <- lapply(names(df), function(k) I(df[[k]]))
  names(out) <- names(df)
  out
}

write_json_file <- function(x, path) {
  con <- file(path, open = "wb")
  on.exit(close(con))
  writeLines(to_json(x), con, sep = "\n", useBytes = TRUE)
}
