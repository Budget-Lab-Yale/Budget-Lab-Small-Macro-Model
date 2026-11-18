# Run every test file in the repository. From the repository root:
#   Rscript --vanilla tests/run_all.R
#
# Each file runs in its own Rscript process, because the files source the
# model into the global environment. A failing test stops its file, so tests
# later in a failing file are not run. Exits nonzero if any file fails.

files <- c(
  sort(list.files("tests", pattern = "^test_.*\\.R$", full.names = TRUE)),
  sort(list.files("tests/v1_8", pattern = "^test_.*\\.R$", full.names = TRUE)),
  sort(list.files("tests/calibration", pattern = "^test_.*\\.R$", full.names = TRUE))
)
if (!length(files)) stop("No test files found; run from the repository root.")

rscript <- file.path(R.home("bin"), "Rscript")
failed <- character()
for (f in files) {
  cat("==>", f, "\n")
  status <- system2(rscript, c("--vanilla", "-e", shQuote(sprintf("source('%s')", f))))
  if (!identical(status, 0L)) failed <- c(failed, f)
}

cat("\n", length(files) - length(failed), "of", length(files), "test files passed\n")
if (length(failed)) {
  cat("Failed:", failed, sep = "\n  ")
  quit(status = 1)
}
