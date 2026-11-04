# BLSMM calibration workflow

The calibration layer supports forced solves, implied-residual backout, and
unforced re-solves for annual fiscal-year baselines. The canonical FY2026–2035
baseline remains in `data/`. A separate LTBO builder extends it through FY2056
without replacing those inputs.

## Model and calibration

`model/v1_8/solver.R` evaluates structural equations through
`compute_structural_values_v1_8()`. With `diagnostics = TRUE`,
`simulate_blsmm_v1_8()` and `run_baseline_v1_8()` also return eight
structural-value columns (`*_struct`), eight implied-residual columns
(`eps*_final`), and `growth_contrib`, the growth contribution to the neutral
rate. The default output keeps the published columns, which the app's cached
baseline, the scenario results, and the JavaScript port's parity test use.
The κ contribution uses `min(year_index/10, 1)`, with `growth_contrib` equal to
`gradual_growth`. The timing of this growth pass-through is under review and may
change in a later version.

`model/v1_8/calibration.R` exposes `calibrate_residuals_v1_8()`. It solves a forced
path, backs out residuals, removes any user residual shocks from those inputs,
and solves again without forcing. Its round-trip diagnostics cover all nine
endogenous variables. This round trip tests the residual accounting; frozen
Excel fixtures provide a separate comparison.

`simulate_blsmm_v1_8()` defaults to the row count of `baseline_exog` and takes
its initial conditions from the `hist_data` row for the year before the first
baseline year. It stops if that row is missing or the baseline years are not
consecutive. `run_scenario()` accepts optional `baseline_exog`, `baseline_resid`,
`hist_data`, and `n_periods`. A scenario that passes `baseline_exog` must also
pass `baseline_resid` and `hist_data`, and a requested horizon longer than either
input frame stops. The app runs the canonical FY2026–2035 baseline.

## Public CBO sources

`source_manifest.csv` pins the public workbooks in `sources/` by SHA-256.
The adapter verifies each workbook before reading its saved values.

| Source | Vintage and use |
|---|---|
| `51135-2026-02-Economic-Projections.xlsx` | February 11, 2026 detailed economic projections. Calendar-year federal funds rate in `2. Calendar Year`, row 105, through 2036. |
| `57054-2026-02-LTBO-econ.xlsx` | February 25, 2026 long-term economic projections. Annual economic rates and levels through 2056. |
| `51119-2026-02-11-LTBO-Budget.xlsx` | February 11, 2026 extended-baseline budget workbook, reposted February 26 with the Supplemental Table 1 M20 correction. Fiscal-year budget ratios and GDP. |

`R/build_calibration_inputs.R` reads `config/cbo_ltbo_2026.yaml` and splices the
canonical FY2026–2035 paths with the LTBO extension. It carries the configured
inflation target and term premium, holds the baseline's terminal neutral-rate
anchors, and decays the output gap toward zero under the configured rule.
The config's `forcing_mask.forced` lists `xgap`, `U`, `PI`, `RF`, `MPE10`, and
`TP`; `build_ltbo_forcing_spec()` forces those, and the rest, here `PIE` and `RG`,
remain structural.

The calendar-year FFR follows the detailed CBO forecast through 2036. From 2037,
`ffr(t) = ffr(t-1) + nominal_r10_ltbo(t) - nominal_r10_ltbo(t-1)`.
The builder applies this rule before converting to fiscal years with
`FY(t) = 0.75*CY(t) + 0.25*CY(t-1)`. Other economic rates and levels use the same
conversion. Budget series remain fiscal-year values. The fiscal-ratio adapter
uses the same-year calendar output gap to approximate the conversion from
actual to potential GDP. `RG_base`, the baseline effective rate on debt that the structural `RG`
equation uses, is net interest divided by average current and prior debt, a
different denominator from CBO's published debt rate.

No Macro-Projections output is a calibration input. Rebuilt from the public
workbooks, the calendar-year FFR is within 0.001 percentage point of
Macro-Projections v3/2026031112 in every year 2026–2056. Macro-Projections reads
CBO's annual calendar-year data file rather than the published workbook, which
reports three decimals.

## Frozen fixtures and tests

`golden/` contains the frozen original v1.8, SPF, and public LTBO comparisons.
The historical `R/extract_excel_goldens.R` recipe documents their construction.
Its Excel inputs, the original v1.8 workbook and two SPF calibration workbooks,
are not distributed with this repository; their rows in `source_manifest.csv`
record the SHA-256 hashes of the files the goldens were extracted from. Do not
run the recipe or regenerate the goldens as part of this workflow.

From the repository root, run every test file:

```sh
export TMPDIR=/tmp UV_CACHE_DIR=/tmp/uv-cache
timeout 1800 Rscript --vanilla tests/run_all.R
```

To run only the calibration tests, each in a separate R process:

```sh
export TMPDIR=/tmp UV_CACHE_DIR=/tmp/uv-cache
for test_file in tests/calibration/test_*.R; do
  timeout 300 Rscript --vanilla -e 'source(commandArgs(TRUE)[1])' "$test_file" || exit
done
```

The tests compare the R solution with the frozen original v1.8 and SPF Excel
fixtures, check the forced, backed-out, and unforced round trip, and check the
LTBO-centered baseline's overlap with the canonical baseline, its terminal
stability, and its debt/GDP path against CBO's extended baseline. The SPF
fixture was solved in Excel with immediate κ, so its test asserts the exact
difference the capped ramp makes to the implied `epsrf`, `epsmpe`, and
`epsxgap` residuals; the other residuals match within `1e-5`.
