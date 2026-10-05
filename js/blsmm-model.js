// =============================================================================
// BLSMM v1.8 — JavaScript port of the forward simulation in model/v1_8/
// =============================================================================
// The R code in model/v1_8/ is the reference implementation. This file is a
// line-for-line port of simulate_blsmm_v1_8() without the experimental forcing
// module (forcing.R), which no shipped code path uses. js/test/parity.test.mjs
// holds every output column to the R results; change the two together.
//
// Pure module: no DOM, no I/O. Inputs come from model-data.json, which
// js/export-data.R generates from data/, model/v1_8/parameters.R and the
// preset files in scenarios/inputs/.
// =============================================================================

export const N_PERIODS = 10;

// The nine user-delta paths of create_user_deltas() in user_deltas.R.
export const DELTA_KEYS = [
  'user_delta_prod',
  'user_delta_lf',
  'user_delta_rgfr',
  'user_delta_rgfop',
  'user_delta_rfstar_direct',
  'user_delta_pistar',
  'user_delta_ADshock',
  'user_delta_inflshock',
  'user_delta_MPshock',
];

// Column order of the data frame simulate_blsmm_v1_8() returns.
export const OUTPUT_COLUMNS = [
  'period', 'year',
  'glqstar', 'glfstar', 'rgfr_star', 'rgfop_star', 'rbudp_star', 'UN_path', 'PISTAR', 'tp_0',
  'LF_fb', 'PROD_fb',
  'epsxgap', 'epsu', 'epspi', 'epspie', 'epsrf', 'epsmpe', 'epstp', 'epsrg',
  'gstar', 'LFstar', 'LQstar', 'CEstar', 'GDPstar', 'GDP$star2',
  'rfstar', 'rbar10', 'gradual_growth', 'debt_contrib',
  'debt_proxy_user', 'debt_proxy_base',
  'xgap', 'U', 'PI', 'PIE', 'RF', 'MPE10', 'TP', 'R10', 'RG', 'ugap', 'real_r10',
  'GDP', 'PGDP', 'GDP$star', 'GDP$', 'BUDP', 'NI', 'BUD', 'D', 'D_pct_GDP',
  'solver_sse', 'solver_converged', 'solver_termcd',
];

const RESID_COLUMNS = ['epsxgap', 'epsu', 'epspi', 'epspie', 'epsrf', 'epsmpe', 'epstp', 'epsrg'];

// nleqslv's default function-value tolerance: converged when max |f| <= ftol.
const FTOL = 1e-8;
const MAX_ITER = 100;

/** All-zero user deltas (the baseline scenario). */
export function zeroDeltas(n = N_PERIODS) {
  const out = {};
  for (const k of DELTA_KEYS) out[k] = new Array(n).fill(0);
  return out;
}

function normalizeDeltas(deltas, n) {
  const out = zeroDeltas(n);
  if (!deltas) return out;
  for (const [k, v] of Object.entries(deltas)) {
    if (!DELTA_KEYS.includes(k)) throw new Error(`Unknown user delta: ${k}`);
    if (!Array.isArray(v) || v.length !== n) throw new Error(`${k} must be an array of length ${n}`);
    for (let i = 0; i < n; i++) {
      const x = Number(v[i]);
      if (!Number.isFinite(x)) throw new Error(`${k}[${i}] is not a finite number`);
      out[k][i] = x;
    }
  }
  return out;
}

function head(cols, n) {
  const out = {};
  for (const [k, v] of Object.entries(cols)) {
    if (v.length < n) throw new Error(`Column ${k} has fewer than ${n} rows`);
    out[k] = v.slice(0, n);
  }
  return out;
}

// R's all.equal() for numeric vectors (countEQ = FALSE): elements that are
// exactly equal are dropped, then the mean absolute difference is compared
// with the tolerance, relative to the mean absolute target when that exceeds it.
function rAllEqual(target, current, tolerance) {
  const t = [];
  const c = [];
  for (let i = 0; i < target.length; i++) {
    if (target[i] !== current[i]) { t.push(target[i]); c.push(current[i]); }
  }
  if (t.length === 0) return true;
  const n = t.length;
  let xy = 0;
  let xn = 0;
  for (let i = 0; i < n; i++) { xy += Math.abs(t[i] - c[i]); xn += Math.abs(t[i]); }
  xy /= n;
  xn /= n;
  if (Number.isFinite(xn) && xn > tolerance) xy /= xn;
  return !(Number.isNaN(xy) || xy > tolerance);
}

// compute_user_inclusive_exog() — user_deltas.R
function userInclusiveExog(bx, ud, params) {
  const n = bx.year.length;
  const glqstar = bx.glqstar.map((v, i) => v + ud.user_delta_prod[i]);
  const glfstar = bx.glfstar.map((v, i) => v + ud.user_delta_lf[i]);
  const rgfr_star = bx.rgfr_star.map((v, i) => v + ud.user_delta_rgfr[i]);

  const LF_fb = new Array(n).fill(0);
  const PROD_fb = new Array(n).fill(0);
  for (let t = 1; t < n; t++) {
    LF_fb[t] = LF_fb[t - 1] + params.psi_1 * (glfstar[t] - bx.glfstar[t]);
    PROD_fb[t] = PROD_fb[t - 1] + params.psi_2 * (glqstar[t] - bx.glqstar[t]);
  }

  const rgfop_star = bx.rgfop_star.map((v, i) => v + LF_fb[i] + PROD_fb[i] + ud.user_delta_rgfop[i]);

  // A baseline rbudp_star that does not equal rgfr_star - rgfop_star is an
  // override and is kept as is.
  const formula = bx.rgfr_star.map((v, i) => v - bx.rgfop_star[i]);
  const overridden = !rAllEqual(bx.rbudp_star, formula, 1e-10);
  const rbudp_star = overridden
    ? bx.rbudp_star.slice()
    : rgfr_star.map((v, i) => v - rgfop_star[i]);

  return {
    glqstar, glfstar, rgfr_star, rgfop_star, rbudp_star, LF_fb, PROD_fb,
    UN_path: bx.UN.slice(),
    PISTAR: bx.pistar.map((v, i) => v + ud.user_delta_pistar[i]),
    tp_0: bx.tp_0.slice(),
    glqstar_base: bx.glqstar,
    glfstar_base: bx.glfstar,
    rbudp_star_base: bx.rbudp_star,
    PISTAR_base: bx.pistar,
    tp_0_base: bx.tp_0_base ?? bx.tp_0,
  };
}

// compute_user_inclusive_resid() — user_deltas.R
function userInclusiveResid(br, ud) {
  const out = {};
  for (const k of RESID_COLUMNS) out[k] = br[k].slice();
  out.epsxgap = br.epsxgap.map((v, i) => v + ud.user_delta_ADshock[i]);
  out.epspi = br.epspi.map((v, i) => v + ud.user_delta_inflshock[i]);
  out.epsrf = br.epsrf.map((v, i) => v + ud.user_delta_MPshock[i]);
  return out;
}

function histRow(hist, year) {
  const i = hist.year.indexOf(year);
  if (i < 0) throw new Error(`Historical data for year ${year} not found`);
  const row = {};
  for (const [k, v] of Object.entries(hist)) row[k] = v[i];
  return row;
}

// build_lag_vector_8() — solver.R. Slot 0 is the current value; slots 1..7
// come from earlier simulated periods or, before period 1, from history.
function lagVector8(t, current, results, hist, name) {
  const vec = new Array(8);
  vec[0] = current;
  for (let i = 1; i <= 7; i++) {
    const lagPeriod = t - i; // 1-based period
    if (lagPeriod >= 1) {
      vec[i] = results[name][lagPeriod - 1];
    } else {
      vec[i] = histRow(hist, 2025 + lagPeriod)[name];
    }
  }
  return vec;
}

// Solve A x = b by Gaussian elimination with partial pivoting. Returns null
// when A is singular.
function solveLinear(A, b) {
  const n = b.length;
  const M = A.map((row, i) => [...row, b[i]]);
  for (let col = 0; col < n; col++) {
    let piv = col;
    for (let r = col + 1; r < n; r++) {
      if (Math.abs(M[r][col]) > Math.abs(M[piv][col])) piv = r;
    }
    if (M[piv][col] === 0 || !Number.isFinite(M[piv][col])) return null;
    if (piv !== col) [M[piv], M[col]] = [M[col], M[piv]];
    for (let r = col + 1; r < n; r++) {
      const f = M[r][col] / M[col][col];
      if (f === 0) continue;
      for (let c = col; c <= n; c++) M[r][c] -= f * M[col][c];
    }
  }
  const x = new Array(n).fill(0);
  for (let r = n - 1; r >= 0; r--) {
    let s = M[r][n];
    for (let c = r + 1; c < n; c++) s -= M[r][c] * x[c];
    x[r] = s / M[r][r];
  }
  return x;
}

const maxAbs = (v) => v.reduce((m, x) => Math.max(m, Math.abs(x)), 0);

// Newton's method with a forward-difference Jacobian. The v1.8 system is
// linear in its nine unknowns, so this converges in one or two steps; it is
// written for the general case so the convergence flag stays meaningful if a
// future equation is nonlinear.
function newton(f, x0) {
  const n = x0.length;
  let x = x0.slice();
  let fx = f(x);
  let termcd = 4; // nleqslv: iteration limit reached
  for (let iter = 0; iter < MAX_ITER; iter++) {
    if (maxAbs(fx) <= FTOL * 1e-4) { termcd = 1; break; }
    const J = Array.from({ length: n }, () => new Array(n));
    for (let j = 0; j < n; j++) {
      const h = 1e-6 * Math.max(1, Math.abs(x[j]));
      const xh = x.slice();
      xh[j] += h;
      const fh = f(xh);
      for (let i = 0; i < n; i++) J[i][j] = (fh[i] - fx[i]) / h;
    }
    const step = solveLinear(J, fx.map((v) => -v));
    if (!step) { termcd = 6; break; } // singular Jacobian
    const xNew = x.map((v, i) => v + step[i]);
    const fNew = f(xNew);
    // Stop when a step no longer improves the residual.
    if (maxAbs(fNew) >= maxAbs(fx)) {
      termcd = maxAbs(fx) <= FTOL ? 1 : 3;
      break;
    }
    x = xNew;
    fx = fNew;
  }
  if (termcd === 4 && maxAbs(fx) <= FTOL) termcd = 1;
  return { x, fvec: fx, termcd };
}

// solve_period_v1_8() — solver.R, no-forcing branch; structural equations
// from equations.R.
function solvePeriod(t, results, hist, ex, rs, lag, p, fast) {
  const rbar10Vec = lagVector8(t, ex.rbar10, results, hist, 'rbar10');
  const rbudpVec = lagVector8(t, ex.rbudp_star, results, hist, 'rbudp_star');
  const sigma = [p.sigma_0, p.sigma_1, p.sigma_2, p.sigma_3, p.sigma_4, p.sigma_5, p.sigma_6, p.sigma_7];
  const theta = [p.theta_0, p.theta_1, p.theta_2, p.theta_3, p.theta_4, p.theta_5, p.theta_6, p.theta_7];
  const [l1, l2, l3] = fast ? [0.40, 0.50, 0.10] : [p.lambda_1, p.lambda_2, p.lambda_3];

  // Slot 0 of these two holds the solver's current guess; lags are fixed.
  const R10Vec = lagVector8(t, NaN, results, hist, 'R10');
  const PIEVec = lagVector8(t, NaN, results, hist, 'PIE');

  const system = (x) => {
    const [xgap, u, pi, pie, rf, mpe10, tp, r10, rg] = x;
    R10Vec[0] = r10;
    PIEVec[0] = pie;

    let realRateEffect = 0;
    let fiscalEffect = 0;
    for (let i = 0; i < 8; i++) {
      realRateEffect += sigma[i] * (R10Vec[i] - PIEVec[i] - rbar10Vec[i]);
      fiscalEffect += theta[i] * rbudpVec[i];
    }
    const xgapStruct = p.eta * lag.xgap_lag - realRateEffect - fiscalEffect;
    const UStruct = ex.UN_path - p.alpha_1 * xgap - p.alpha_2 * lag.xgap_lag;
    const PIStruct = p.gamma_1 * lag.pi_lag + (1 - p.gamma_1) * lag.pie_lag + p.gamma_2 * (ex.UN_path - u);
    const PIEStruct = l1 * lag.pie_lag + l2 * pi + l3 * ex.PISTAR;
    const RFStruct = ex.rfstar + pi
      + p.mu_1 * (pi - ex.PISTAR)
      + p.mu_2 * (pie - ex.PISTAR)
      + p.mu_3 * (ex.UN_path - u);
    const anchor = ex.rfstar + pie + p.phi_2 * (pie - ex.PISTAR);
    const MPE10Struct = p.phi_1 * rf + (1 - p.phi_1) * anchor;
    const TPStruct = ex.tp_0;
    const RGStruct = p.delta_1 * lag.rg_lag + (1 - p.delta_1) * (p.delta_2 * rf + (1 - p.delta_2) * r10);

    const xgapA = xgapStruct + rs.epsxgap;
    const uA = UStruct + rs.epsu;
    const piA = PIStruct + rs.epspi;
    const pieA = PIEStruct + rs.epspie;
    const rfA = RFStruct + rs.epsrf;
    const mpe10A = MPE10Struct + rs.epsmpe;
    const tpA = TPStruct + rs.epstp;
    const rgA = RGStruct + rs.epsrg;
    const r10A = mpe10A + tpA;

    return [
      xgap - xgapA, u - uA, pi - piA, pie - pieA, rf - rfA,
      mpe10 - mpe10A, tp - tpA, r10 - r10A, rg - rgA,
    ];
  };

  const x0 = [
    lag.xgap_lag, lag.u_lag, lag.pi_lag, lag.pie_lag, lag.rf_lag,
    lag.mpe10_lag, lag.tp_lag, lag.r10_lag, lag.rg_lag,
  ];
  const sol = newton(system, x0);
  const fvec = system(sol.x);
  const sse = fvec.reduce((s, v) => s + v * v, 0);
  const [xgap, u, pi, pie, rf, mpe10, tp, r10, rg] = sol.x;
  return {
    xgap, u, pi, pie, rf, mpe10, tp, r10, rg,
    ugap: ex.UN_path - u,
    real_r10: r10 - pie,
    solver_sse: sse,
    solver_converged: sol.termcd === 1 || sol.termcd === 2,
    solver_termcd: sol.termcd,
  };
}

/**
 * Run the BLSMM v1.8 forward simulation.
 *
 * @param {object} data   Parsed model-data.json.
 * @param {object} [options]
 * @param {object} [options.deltas]  user_delta_* arrays of length nPeriods;
 *   missing keys are zero (baseline).
 * @param {boolean} [options.fastExpectations=false]
 * @param {object} [options.params]  Override data.params.
 * @param {number} [options.nPeriods=10]
 * @returns {{columns: Object<string, Array>, summary: object}} columns keyed
 *   as in OUTPUT_COLUMNS, one entry per period.
 */
export function simulate(data, options = {}) {
  const n = options.nPeriods ?? N_PERIODS;
  const params = options.params ?? data.params;
  const fast = Boolean(options.fastExpectations);
  const ud = normalizeDeltas(options.deltas, n);
  const bx = head(data.forecast_exog, n);
  const br = head(data.forecast_resid, n);
  const hist = data.historical;

  const exog = userInclusiveExog(bx, ud, params);
  const resid = userInclusiveResid(br, ud);

  const R = {};
  for (const c of OUTPUT_COLUMNS) R[c] = new Array(n).fill(0);
  for (let i = 0; i < n; i++) { R.period[i] = i + 1; R.year[i] = bx.year[i]; }
  for (const c of ['glqstar', 'glfstar', 'rgfr_star', 'rgfop_star', 'rbudp_star', 'UN_path', 'PISTAR', 'tp_0', 'LF_fb', 'PROD_fb']) {
    R[c] = exog[c].slice();
  }
  for (const c of RESID_COLUMNS) R[c] = resid[c].slice();

  // initialize_all_lags_from_history() — solver.R
  const h0 = histRow(hist, 2025);
  let lag = {
    xgap_lag: h0.xgap, u_lag: h0.U, pi_lag: h0.PI, pie_lag: h0.PIE, rf_lag: h0.RF,
    mpe10_lag: h0.MPE10, tp_lag: h0.TP, r10_lag: h0.R10, rg_lag: h0.RG,
    D_lag: h0.D, PGDP_lag: h0.PGDP,
    UN_lag: h0.UN, LFstar_lag: h0.LFstar, LQstar_lag: h0.LQstar,
    GDPstar_lag: h0.GDPstar, GDPstar2_lag: h0['GDP$star2'],
  };
  // initialize_debt_proxy_lags_from_history() — debt_proxy.R: absent columns
  // fall back to the workbook's 2025 value; present-but-missing values are an error.
  let dpUserLag = 99.37172136945937;
  let dpBaseLag = 99.37172136945937;
  if ('debt_proxy_user' in hist && 'debt_proxy_base' in hist) {
    if (h0.debt_proxy_user == null || h0.debt_proxy_base == null) {
      throw new Error('Debt proxy values for 2025 are NA. Debt proxy is only initialized at 2025.');
    }
    dpUserLag = h0.debt_proxy_user;
    dpBaseLag = h0.debt_proxy_base;
  }

  for (let t = 1; t <= n; t++) {
    const i = t - 1;
    const ex = {
      glqstar: exog.glqstar[i], glfstar: exog.glfstar[i],
      rbudp_star: exog.rbudp_star[i], UN_path: exog.UN_path[i],
      PISTAR: exog.PISTAR[i], tp_0: exog.tp_0[i],
      glqstar_base: exog.glqstar_base[i], glfstar_base: exog.glfstar_base[i],
      rbudp_star_base: exog.rbudp_star_base[i], PISTAR_base: exog.PISTAR_base[i],
      tp_0_base: exog.tp_0_base[i],
    };
    const rs = {};
    for (const c of RESID_COLUMNS) rs[c] = resid[c][i];

    // compute_presim_deterministic_v1_8() — presim_block.R
    const gstar = 100 * ((1 + ex.glqstar / 100) *
                         (1 + ex.glfstar / 100) *
                         (1 - ex.UN_path / 100) / (1 - lag.UN_lag / 100) - 1);
    const LFstar = lag.LFstar_lag * (1 + 0.01 * ex.glfstar);
    const LQstar = lag.LQstar_lag * (1 + 0.01 * ex.glqstar);
    const CEstar = LFstar * (1 - ex.UN_path / 100);
    const GDPstar = lag.GDPstar_lag * (1 + 0.01 * gstar);
    const GDPstar2 = lag.GDPstar2_lag * (1 + gstar / 100) * (1 + ex.PISTAR / 100);
    R.gstar[i] = gstar;
    R.LFstar[i] = LFstar;
    R.LQstar[i] = LQstar;
    R.CEstar[i] = CEstar;
    R.GDPstar[i] = GDPstar;
    R['GDP$star2'][i] = GDPstar2;

    // Debt proxies — simulation.R + debt_proxy.R
    const LF_rf_LR = params.kappa_1 * (ex.glfstar - ex.glfstar_base);
    const PROD_rf_LR = params.kappa_2 * (ex.glqstar - ex.glqstar_base);
    const GR_LR = LF_rf_LR + PROD_rf_LR;
    const RG_base = params.RG_base;

    const yearFactor = Math.min(1 / (1 - params.delta_1), t);
    const rComp = RG_base / 100 + (1 - params.delta_1) * yearFactor * GR_LR / 100;
    const chiUser = rComp / (1 - 0.5 * rComp);
    const dpUser = ((1 + chiUser) / ((1 + gstar / 100) * (1 + ex.PISTAR / 100))) * dpUserLag
                   - (1 + chiUser / 2) * ex.rbudp_star;
    const rCompBase = RG_base / 100;
    const chiBase = rCompBase / (1 - 0.5 * rCompBase);
    const dpBase = ((1 + chiBase) / ((1 + bx.gstar[i] / 100) * (1 + ex.PISTAR_base / 100))) * dpBaseLag
                   - (1 + chiBase / 2) * ex.rbudp_star_base;
    R.debt_proxy_user[i] = dpUser;
    R.debt_proxy_base[i] = dpBase;

    // compute_neutral_rates_v1_8() — neutral_rate.R
    const gradualGrowth = (t / 10) * LF_rf_LR + (t / 10) * PROD_rf_LR;
    const debtContrib = params.kappa_3 * (dpUser - dpBase);
    const rfstar = bx.rfstar[i] + debtContrib + gradualGrowth + ud.user_delta_rfstar_direct[i];
    const rbar10 = bx.rbar10[i]
      + ((rfstar - bx.rfstar[i]) + (ex.tp_0 - ex.tp_0_base)
         + params.theta_sigma_ratio * (ex.rbudp_star - ex.rbudp_star_base));
    R.rfstar[i] = rfstar;
    R.rbar10[i] = rbar10;
    R.gradual_growth[i] = gradualGrowth;
    R.debt_contrib[i] = debtContrib;
    ex.rfstar = rfstar;
    ex.rbar10 = rbar10;

    const s = solvePeriod(t, R, hist, ex, rs, lag, params, fast);
    R.xgap[i] = s.xgap;
    R.U[i] = s.u;
    R.PI[i] = s.pi;
    R.PIE[i] = s.pie;
    R.RF[i] = s.rf;
    R.MPE10[i] = s.mpe10;
    R.TP[i] = s.tp;
    R.R10[i] = s.r10;
    R.RG[i] = s.rg;
    R.ugap[i] = s.ugap;
    R.real_r10[i] = s.real_r10;
    R.solver_sse[i] = s.solver_sse;
    R.solver_converged[i] = s.solver_converged;
    R.solver_termcd[i] = s.solver_termcd;

    // solve_fiscal_block_v1_8() — solver.R
    const GDP = GDPstar * (1 + s.xgap / 100);
    const PGDP = lag.PGDP_lag * (1 + s.pi / 100);
    const GDPdollarStar = GDPstar * PGDP / 100;
    const GDPdollar = GDP * PGDP / 100;
    const BUDP = GDPdollarStar * ex.rbudp_star / 100;
    const r = s.rg / 100;
    const NI = r * (lag.D_lag - 0.5 * BUDP) / (1 - 0.5 * r);
    const BUD = BUDP - NI;
    const D = lag.D_lag - BUD;
    R.GDP[i] = GDP;
    R.PGDP[i] = PGDP;
    R['GDP$star'][i] = GDPdollarStar;
    R['GDP$'][i] = GDPdollar;
    R.BUDP[i] = BUDP;
    R.NI[i] = NI;
    R.BUD[i] = BUD;
    R.D[i] = D;
    R.D_pct_GDP[i] = (D / GDPdollar) * 100;

    lag = {
      xgap_lag: s.xgap, u_lag: s.u, pi_lag: s.pi, pie_lag: s.pie, rf_lag: s.rf,
      mpe10_lag: s.mpe10, tp_lag: s.tp, r10_lag: s.r10, rg_lag: s.rg,
      D_lag: D, PGDP_lag: PGDP,
      UN_lag: ex.UN_path, LFstar_lag: LFstar, LQstar_lag: LQstar,
      GDPstar_lag: GDPstar, GDPstar2_lag: GDPstar2,
    };
    dpUserLag = dpUser;
    dpBaseLag = dpBase;
  }

  const summary = {
    expectations_speed: fast,
    overall_converged: R.solver_converged.every(Boolean),
    max_sse: Math.max(...R.solver_sse),
    final_sse: R.solver_sse[n - 1],
    user_deltas_active: DELTA_KEYS.some((k) => ud[k].some((v) => v !== 0)),
  };
  return { columns: R, summary };
}
