// Holds js/blsmm-model.js to the R reference implementation. Fixtures are R
// runs written by js/make-fixtures.R (not committed; regenerate first):
//
//   Rscript js/make-fixtures.R && node --test js/test/*.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { simulate, OUTPUT_COLUMNS } from '../blsmm-model.js';
import { loadModelData, diffColumns, JS_DIR } from './helpers.mjs';

const data = loadModelData();
const dir = path.join(JS_DIR, 'test', 'fixtures');
const files = existsSync(dir) ? readdirSync(dir).filter((f) => f.endsWith('.json')).sort() : [];

test('R fixtures are present', () => {
  assert.ok(files.length > 0, 'No fixtures in js/test/fixtures. Run: Rscript js/make-fixtures.R');
});

for (const f of files) {
  const fx = JSON.parse(readFileSync(path.join(dir, f), 'utf8'));
  test(`parity: ${fx.name}`, () => {
    // A column R adds must be ported, not silently skipped.
    assert.deepEqual(Object.keys(fx.columns), OUTPUT_COLUMNS);
    const { columns } = simulate(data, { deltas: fx.deltas, fastExpectations: fx.fast_expectations });
    assert.deepEqual(diffColumns(columns, fx.columns, OUTPUT_COLUMNS), []);
  });
}
