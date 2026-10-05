// Checks that need no R: the committed baseline reference, input handling,
// and solver diagnostics.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { simulate, zeroDeltas, OUTPUT_COLUMNS, DELTA_KEYS } from '../blsmm-model.js';
import { loadModelData, readRCsv, diffColumns, REPO_DIR } from './helpers.mjs';

const data = loadModelData();

test('baseline matches data/blsmm_v1_8_baseline_solution.csv', () => {
  const ref = readRCsv(path.join(REPO_DIR, 'data', 'blsmm_v1_8_baseline_solution.csv'));
  const { columns } = simulate(data);
  assert.deepEqual(Object.keys(ref), OUTPUT_COLUMNS);
  assert.deepEqual(diffColumns(columns, ref, OUTPUT_COLUMNS), []);
});

test('output has every R column, one value per period', () => {
  const { columns } = simulate(data);
  assert.deepEqual(Object.keys(columns), OUTPUT_COLUMNS);
  for (const c of OUTPUT_COLUMNS) assert.equal(columns[c].length, 10, c);
});

test('baseline converges with negligible residual', () => {
  const { columns, summary } = simulate(data);
  assert.equal(summary.overall_converged, true);
  assert.ok(summary.max_sse < 1e-20, `max_sse ${summary.max_sse}`);
  assert.ok(columns.solver_termcd.every((v) => v === 1));
});

test('explicit zero deltas equal the default baseline exactly', () => {
  const a = simulate(data).columns;
  const b = simulate(data, { deltas: zeroDeltas() }).columns;
  for (const c of OUTPUT_COLUMNS) {
    if (c === 'solver_sse') continue;
    assert.deepEqual(a[c], b[c], c);
  }
});

test('history without debt-proxy columns falls back to the 2025 workbook value', () => {
  const hist = { ...data.historical };
  assert.equal(hist.debt_proxy_user[hist.year.indexOf(2025)], 99.37172136945937);
  delete hist.debt_proxy_user;
  delete hist.debt_proxy_base;
  const a = simulate(data).columns;
  const b = simulate({ ...data, historical: hist }).columns;
  assert.deepEqual(b.D_pct_GDP, a.D_pct_GDP);
  assert.deepEqual(b.rfstar, a.rfstar);
});

test('rejects unknown delta keys and malformed paths', () => {
  assert.throws(() => simulate(data, { deltas: { user_delta_typo: new Array(10).fill(0) } }), /Unknown user delta/);
  assert.throws(() => simulate(data, { deltas: { user_delta_prod: [1, 2] } }), /length 10/);
  assert.throws(() => simulate(data, { deltas: { user_delta_prod: new Array(10).fill(NaN) } }), /finite/);
});

test('does not mutate its inputs', () => {
  const before = JSON.stringify(data);
  const deltas = zeroDeltas();
  deltas.user_delta_rgfop = new Array(10).fill(1);
  const deltasBefore = JSON.stringify(deltas);
  simulate(data, { deltas, fastExpectations: true });
  assert.equal(JSON.stringify(data), before);
  assert.equal(JSON.stringify(deltas), deltasBefore);
});

test('every delta key moves the solution', () => {
  const base = simulate(data).columns;
  for (const k of DELTA_KEYS) {
    const d = zeroDeltas();
    d[k] = new Array(10).fill(0.5);
    const s = simulate(data, { deltas: d }).columns;
    const moved = OUTPUT_COLUMNS.some((c) =>
      typeof base[c][0] === 'number' && !['solver_sse', 'period', 'year'].includes(c) &&
      s[c].some((v, i) => Math.abs(v - base[c][i]) > 1e-9));
    assert.ok(moved, k);
  }
});
