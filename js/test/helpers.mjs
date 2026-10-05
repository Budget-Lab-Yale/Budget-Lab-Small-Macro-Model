import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

export const JS_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const REPO_DIR = path.resolve(JS_DIR, '..');

export function loadModelData() {
  return JSON.parse(readFileSync(path.join(JS_DIR, 'model-data.json'), 'utf8'));
}

// Mixed tolerance: absolute near zero, relative for large levels (debt and
// GDP run into the tens of thousands).
export const TOL = 1e-6;
export function close(a, b, tol = TOL) {
  return Math.abs(a - b) <= tol * Math.max(1, Math.abs(b));
}

// Columns whose values depend on the solver's internals rather than the model.
export const SOLVER_INTERNAL = new Set(['solver_sse', 'solver_termcd']);

// Parse a CSV written by R's write.csv (quoted header, numeric/logical cells).
export function readRCsv(file) {
  const lines = readFileSync(file, 'utf8').trim().split(/\r?\n/);
  const header = lines[0].split(',').map((h) => h.replace(/^"|"$/g, ''));
  const cols = Object.fromEntries(header.map((h) => [h, []]));
  for (const line of lines.slice(1)) {
    const cells = line.split(',');
    header.forEach((h, i) => {
      const c = cells[i].replace(/^"|"$/g, '');
      cols[h].push(c === 'TRUE' ? true : c === 'FALSE' ? false : c === 'NA' ? null : Number(c));
    });
  }
  return cols;
}

// Compare every column of a JS result with an R result; returns a list of
// mismatch descriptions (empty when they agree).
export function diffColumns(jsCols, rCols, columns) {
  const problems = [];
  for (const c of columns) {
    if (SOLVER_INTERNAL.has(c)) continue;
    const a = jsCols[c];
    const b = rCols[c];
    if (!b) { problems.push(`${c}: missing from R output`); continue; }
    if (a.length !== b.length) { problems.push(`${c}: length ${a.length} vs ${b.length}`); continue; }
    for (let i = 0; i < a.length; i++) {
      const ok = typeof b[i] === 'boolean' ? a[i] === b[i] : close(a[i], b[i]);
      if (!ok) {
        problems.push(`${c}[${i}]: JS ${a[i]} vs R ${b[i]}`);
        break;
      }
    }
  }
  return problems;
}
