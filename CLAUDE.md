# Budget Lab Small Macro Model (BLSMM)

R implementation of the BLSMM v1.8 macro model (`model/v1_8/`), its Shiny app (`app/`, `app.R`),
article-figure scripts (`scenarios/`), and a JavaScript port (`js/`) that powers the interactive at
interactives.budgetlab.yale.edu/tools/blsmm/.

## Hard invariants

- **R is the reference model.** `js/blsmm-model.js` is a port of `simulate_blsmm_v1_8()` and must
  match it on every output column. Gated by `.github/workflows/js-model.yml`, which regenerates R
  reference runs (`js/make-fixtures.R`) and runs `node --test js/test/*.test.mjs`. An equation or
  simulation-loop change in `model/v1_8/` is incomplete until the same change is in the JS.
- **`js/model-data.json` is generated** by `Rscript js/export-data.R` from `data/*.csv`,
  `create_parameters_v1_8()` and the preset files listed in `PRESET_FILES`. Never hand-edit it.
  CI fails if the committed copy differs from a fresh export.
- **`js/blsmm-model.js` and `js/model-data.json` are vendored** into `budget-lab-interactives` at
  `tools/blsmm/vendor/blsmm-model/`, pinned to a tag or commit of this repo. That repo's CI
  re-downloads both files at the pinned ref and fails on any difference, so the ref must be pushed.
  Their public shape (`simulate`, `zeroDeltas`, `DELTA_KEYS`, `OUTPUT_COLUMNS`, the JSON keys) is
  an interface the interactive depends on.
- **Changing a preset value changes published output.** `scenarios/inputs/ai_s2_prod_lf.R`,
  `alt_persistent_inflation.R` and `alt_military_conflict.R` feed the article figures, the Shiny
  app, and (through `model-data.json`) the interactive's preset buttons.
- **The JS port has no forcing.** `model/v1_8/forcing.R` is experimental and unused by any shipped
  path; the JS omits it. Porting it is new work, not a fix.
- **Fixtures are never committed.** R's solver output differs across platforms in the last bits,
  so `js/test/fixtures/` is gitignored and regenerated on every CI run.
- **Model data must round-trip exactly.** `js/write-json.R` writes non-integer doubles with 17
  significant digits. Do not swap in `jsonlite::toJSON(digits = NA)` (15 digits), and do not
  shorten numbers by checking `as.numeric(s) == x`: R's parser is not correctly rounded, so a
  string can pass that check and still parse to a different double in JavaScript.

## Working here

- Run R scripts from the repo root; the model sources files by relative path.
- `node --test` needs the glob: `node --test js/test/*.test.mjs`.
