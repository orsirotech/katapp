const HEIAN = [
  ['Yoi', 'Pronti', 'hachiji-dachi'], ['1', 'Hidari gedan-barai', 'zenkutsu'], ['2', 'Migi chūdan oi-zuki', 'zenkutsu'], ['3', 'Migi gedan-barai', 'zenkutsu'],
  ['4', 'Migi tettsui-uchi', 'da verificare'], ['5', 'Hidari chūdan oi-zuki', 'zenkutsu'], ['6', 'Hidari gedan-barai', 'zenkutsu'], ['7', 'Migi jōdan age-uke', 'zenkutsu'],
  ['8', 'Hidari jōdan age-uke', 'zenkutsu'], ['9', 'Migi jōdan age-uke', 'zenkutsu', 1], ['10', 'Hidari gedan-barai', 'zenkutsu'], ['11', 'Migi chūdan oi-zuki', 'zenkutsu'],
  ['12', 'Migi gedan-barai', 'zenkutsu'], ['13', 'Hidari chūdan oi-zuki', 'zenkutsu'], ['14', 'Hidari gedan-barai', 'zenkutsu'], ['15', 'Migi chūdan oi-zuki', 'zenkutsu'],
  ['16', 'Hidari chūdan oi-zuki', 'zenkutsu'], ['17', 'Migi chūdan oi-zuki', 'zenkutsu', 1], ['18', 'Hidari chūdan shutō-uke', 'kokutsu'], ['19', 'Migi chūdan shutō-uke', 'kokutsu'],
  ['20', 'Migi chūdan shutō-uke', 'kokutsu'], ['21', 'Hidari chūdan shutō-uke', 'kokutsu'], ['Yame', 'Fine', 'hachiji-dachi']
];

/* ---------- Vettori ---------- */
const V = (x, y, z) => [x, y, z];
const add = (a, b) => [a[0] + b[0], a[1] + b[1], a[2] + b[2]], sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const mul = (a, k) => [a[0] * k, a[1] * k, a[2] * k], dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const len = a => Math.hypot(a[0], a[1], a[2]), norm = a => { const l = len(a) || 1; return mul(a, 1 / l); };
const rad = d => d * Math.PI / 180;
const ry = (v, deg) => { const c = Math.cos(rad(deg)), s = Math.sin(rad(deg)); return [v[0] * c + v[2] * s, v[1], -v[0] * s + v[2] * c]; };
function ik(A, T, l1, l2, pole) {
  const d = sub(T, A), dist = Math.min(Math.max(len(d), 1), l1 + l2 - .01), n = norm(d);
  const ca = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist), a = Math.acos(Math.max(-1, Math.min(1, ca)));
  const pp = norm(sub(pole, mul(n, dot(pole, n))));
  return { mid: add(add(A, mul(n, l1 * Math.cos(a))), mul(pp, l1 * Math.sin(a))), end: add(A, mul(n, dist)) };
}

/* ---------- Pose (cm, x = avanti, y = su, z = lato destro; braccia relative al bacino) ---------- */
const HIK_L = { w: [4, 90, -17], p: [0, 1, 0], pole: [-1, -.4, -.3] }, HIK_R = { w: [4, 90, 17], p: [0, 1, 0], pole: [-1, -.4, .3] };
const mz = v => [v[0], v[1], -v[2]], mArm = a => ({ ...a, w: mz(a.w), p: mz(a.p), pole: mz(a.pole) }), mArms = s => ({ L: mArm(s.R), R: mArm(s.L) });
const ARMS = {
  hikite: { L: HIK_L, R: HIK_R },
  yoi: { L: { w: [16, 84, -15], p: [-1, 0, .2], pole: [-.3, -.5, -1] }, R: { w: [16, 84, 15], p: [-1, 0, -.2], pole: [-.3, -.5, 1] } },
  gedan: { L: { w: [40, 60, -16], p: [0, -.6, .8], pole: [.3, -.2, -1] }, R: HIK_R },
  gbPrep: { L: { w: [8, 140, 12], p: [0, 0, -1], pole: [.3, -.3, -1] }, R: { w: [44, 72, 2], p: [0, -1, 0], pole: [0, -1, .5] } },
  ukePrep: { L: { w: [28, 116, 4], p: [-.3, 0, 1], pole: [0, -1, -.3] }, R: { w: [38, 104, 2], p: [0, -1, 0], pole: [-.2, -1, .4] } },
  uke: { L: { w: [24, 152, 2], p: [1, .3, -.2], pole: [.2, -.4, -1] }, R: HIK_R },
  zukiMid: { L: { w: [12, 102, -15], p: [.5, .7, 0], pole: [-1, -.5, -.3] }, R: { w: [32, 104, 7], p: [0, .7, -.7], pole: [-.5, -1, .5] } },
  zuki: { L: HIK_L, R: { w: [60, 112, 0], p: [0, -1, 0], pole: [0, -1, .6] } },
  zukiPrep: { L: { w: [46, 104, -3], p: [0, -1, 0], pole: [0, -1, -.5] }, R: HIK_R },
  guardG: { L: { w: [42, 108, -6], p: [0, -.6, .8], pole: [0, -1, -.4] }, R: HIK_R },
  sotoPrep: { L: { w: [-4, 140, -32], p: [1, 0, 0], pole: [-.2, -1, -.8] }, R: { w: [44, 104, 4], p: [0, -1, 0], pole: [0, -1, .5] } },
  soto: { L: { w: [36, 122, -2], p: [-.85, 0, .3], pole: [0, -1, -.2] }, R: HIK_R },
  tetPrep: { L: { w: [40, 100, -4], p: [0, -1, 0], pole: [0, -1, -.5] }, R: { w: [-4, 166, 12], p: [0, 0, -1], pole: [-1, .3, .5] } },
  tettsui: { L: HIK_L, R: { w: [50, 108, 4], p: [0, 0, -1], pole: [0, -1, .6] } },
  shutoPrep: { L: { w: [8, 138, 16], p: [0, 0, -1], pole: [.2, -1, -.4], h: 'o' }, R: { w: [46, 108, 2], p: [0, -1, 0], pole: [0, -1, .5], h: 'o' } },
  shuto: { L: { w: [42, 124, -8], p: [.5, -.2, -.85], pole: [0, -1, -.6], h: 'o' }, R: { w: [16, 102, 2], p: [0, 1, 0], pole: [-1, -.4, .4], h: 'o' } }
};
// posizioni con il piede sinistro avanti; a = caviglia, f = direzione del piede (gradi), kp = verso del ginocchio
const STANCE = {
  zen: { aL: [45, 8, -13], aR: [-62, 8, 15], fL: -4.6, fR: -30.5, Cy: 78, wt: 60, kpL: [1, 0, -.1], kpR: [1, 0, .2], stance: 'zenkutsu-dachi' },
  kok: { aL: [60, 8, -6], aR: [-22, 8, 8], fL: 0, fR: -90, Cy: 72, wt: 30, kpL: [1, 0, -.1], kpR: [.3, 0, 1], stance: 'kokutsu-dachi' },
  kiba: { aL: [-2, 8, -40], aR: [-2, 8, 40], fL: -6, fR: 6, Cy: 70, wt: 50, kpL: [.5, 0, -1], kpR: [.5, 0, 1], stance: 'kiba-dachi' },
  hachi: { aL: [0, 8, -20], aR: [0, 8, 20], fL: 15, fR: -15, Cy: 94, wt: 50, kpL: [1, 0, -.2], kpR: [1, 0, .2], stance: 'hachiji-dachi' }
};
function legs(type, lead, face, O) {
  let s = STANCE[type];
  if (lead === 'R') s = { ...s, aL: mz(s.aR), aR: mz(s.aL), fL: -s.fR, fR: -s.fL, kpL: mz(s.kpR), kpR: mz(s.kpL), wt: 100 - s.wt };
  const W3 = a => add(V(O[0], 0, O[1]), ry(a, face));
  return { face, C: [O[0], s.Cy, O[1]], aL: W3(s.aL), aR: W3(s.aR), fL: face + s.fL, fR: face + s.fR, kpL: s.kpL, kpR: s.kpR, wt: s.wt, stance: s.stance, pL: 0, pR: 0 };
}
function placed(type, lead, face, side, at) { // il piede "side" resta dov'è
  const l = legs(type, lead, face, [0, 0]), a = l['a' + side];
  return legs(type, lead, face, [at[0] - a[0], at[2] - a[2]]);
}
const DEF = { yaw: 0, lean: 0, ...legs('zen', 'L', 0, [0, 0]), ...ARMS.hikite };
const P = (yaw, arms, extra) => ({ ...DEF, yaw, ...arms, ...extra });
const POSES = {
  gedan: P(-45, ARMS.gedan), ukePrep: P(-40, ARMS.ukePrep), uke: P(-45, ARMS.uke, { lean: -2 }),
  zukiMid: P(-22, ARMS.zukiMid, { lean: 2 }), zuki: P(0, ARMS.zuki, { lean: 6 }),
  hipsA: P(0, ARMS.hikite), hipsB: P(-45, ARMS.hikite), gbPrep: P(-15, ARMS.gbPrep), guardG: P(-45, ARMS.guardG),
  sotoPrep: P(-55, ARMS.sotoPrep), soto: P(-35, ARMS.soto),
  mgChamber: P(-10, ARMS.gedan, { C: [12, 80, 0], lean: -4, aR: [30, 52, 10], fR: 0, pR: -55, kpR: [1, .8, .1], wt: 100 }),
  mgKick: P(-5, ARMS.gedan, { C: [14, 80, 0], lean: -8, aR: [86, 95, 8], fR: 0, pR: 12, kpR: [0, 1, .1], wt: 100 })
};
const eIO = x => x < .5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2, eOut = x => 1 - Math.pow(1 - x, 3), eIn = x => x * x;
const lerp = (a, b, k) => {
  if (a === undefined || b === undefined) { const d = a ?? b; return typeof d === 'string' ? (k < .5 ? a ?? '' : b ?? '') : d; }
  if (typeof a === 'number') return a + (b - a) * k; if (typeof a === 'string') return k < .5 ? a : b;
  if (Array.isArray(a)) return a.map((v, i) => lerp(v, b[i], k));
  const o = {}; for (const key of new Set([...Object.keys(a), ...Object.keys(b)])) o[key] = lerp(a[key], b[key], k); return o;
};
// passo: il piede che si muove passa vicino a quello d'appoggio, un po' sollevato
function stepMid(A, B, arms, yaw) {
  const m = len(sub(A.aL, B.aL)) > len(sub(A.aR, B.aR)) ? 'L' : 'R', s = m === 'L' ? 'R' : 'L', sp = B['a' + s];
  let mid = lerp(lerp(A['a' + m], B['a' + m], .5), sp, .55);
  mid = add(mid, mul(ry(V(0, 0, m === 'R' ? 1 : -1), (A.face + B.face) / 2), 7)); mid[1] = 9.5;
  const c = lerp(A.C, B.C, .5);
  return { ...lerp(A, B, .5), C: [lerp(c[0], sp[0], .3), c[1] + 1, lerp(c[2], sp[2], .3)], ['a' + m]: mid, ['p' + m]: -3, yaw, L: arms.L, R: arms.R, wt: s === 'L' ? 100 : 0 };
}
const HACHI = { ...P(0, ARMS.hikite), ...legs('hachi', 'L', 0, [0, 0]) }, KIBA = { ...P(0, ARMS.hikite), ...legs('kiba', 'L', 0, [0, 0]) };
const KOK = { ...P(-65, ARMS.hikite), ...placed('kok', 'L', 0, 'R', HACHI.aR) }, KOKMID = stepMid(HACHI, KOK, ARMS.hikite, -30);
const OZ_A = { ...P(-45, ARMS.gedan), ...legs('zen', 'L', 0, [-45, 0]) };
const OZ_B = { ...P(10, ARMS.zuki, { lean: 4 }), ...placed('zen', 'R', 0, 'L', OZ_A.aL) };
const OZ_M1 = stepMid(OZ_A, OZ_B, ARMS.zukiPrep, 0), OZ_M2 = stepMid(OZ_B, OZ_A, ARMS.gbPrep, -15);

function buildKata() {
  const keys = [], marks = [], kiai = []; let t = 0;
  let cur = { ...P(0, ARMS.yoi), ...legs('hachi', 'L', 0, [0, 0]) };
  keys.push([0, cur]); marks.push(0); t = 1.4; keys.push([t, cur]);
  const g = ARMS.gedan, gp = ARMS.gbPrep, z = ARMS.zuki, zp = ARMS.zukiPrep, u = ARMS.uke, up = ARMS.ukePrep, sh = ARMS.shuto, shp = ARMS.shutoPrep;
  const M = [ // posizione, piede avanti, direzione, braccia, preparazione, rotazione anche
    ['zen', 'L', 90, g, gp, -45], ['zen', 'R', 90, z, zp, 10], ['zen', 'R', -90, mArms(g), mArms(gp), 45], ['zen', 'R', -90, ARMS.tettsui, ARMS.tetPrep, 45],
    ['zen', 'L', -90, mArms(z), mArms(zp), -10], ['zen', 'L', 0, g, gp, -45], ['zen', 'R', 0, mArms(u), mArms(up), 45], ['zen', 'L', 0, u, up, -45],
    ['zen', 'R', 0, mArms(u), mArms(up), 45, 1], ['zen', 'L', 270, g, gp, -45], ['zen', 'R', 270, z, zp, 10], ['zen', 'R', 90, mArms(g), mArms(gp), 45],
    ['zen', 'L', 90, mArms(z), mArms(zp), -10], ['zen', 'L', 180, g, gp, -45], ['zen', 'R', 180, z, zp, 10], ['zen', 'L', 180, mArms(z), mArms(zp), -10],
    ['zen', 'R', 180, z, zp, 10, 1], ['kok', 'L', 450, sh, shp, -65], ['kok', 'R', 405, mArms(sh), mArms(shp), 65], ['kok', 'R', 270, mArms(sh), mArms(shp), 65],
    ['kok', 'L', 315, sh, shp, -65], ['hachi', 'L', 360, ARMS.yoi, ARMS.hikite, 0]
  ];
  for (const [type, lead, face, arms, prep, yaw, k] of M) {
    const sup = type === 'hachi' ? 'R' : lead === 'L' ? 'R' : 'L';
    const nx = { ...P(yaw, arms, { lean: Math.abs(yaw) === 10 ? 3 : 0 }), ...placed(type, lead, face, sup, cur['a' + sup]) };
    marks.push(t);
    keys.push([t + .6, stepMid(cur, nx, prep, yaw * .4), eIO]); keys.push([t + 1, nx, eOut]);
    if (k) kiai.push([t + 1, t + 1.9]);
    t += k ? 2.1 : 1.6; keys.push([t, nx]); cur = nx;
  }
  t += 1.2; keys.push([t, cur]);
  return { D: t, keys, marks, hit: marks.map((m, i) => i ? m + 1 : 0), kiai, rows: HEIAN, follow: 1, thumb: marks[9] + 1.2 };
}

const HEIAN2 = [
  ['Yoi', 'Pronti', 'hachiji-dachi'], ['1', 'Hidari jōdan haiwan-uke, migi age-uke', 'kokutsu'], ['2', 'Hidari soto-uke e migi ura-zuki', 'kokutsu'], ['3', 'Hidari tettsui-uchi', 'kokutsu'],
  ['4', 'Migi jōdan haiwan-uke, hidari age-uke', 'kokutsu'], ['5', 'Migi soto-uke e hidari ura-zuki', 'kokutsu'], ['6', 'Migi tettsui-uchi', 'kokutsu'],
  ['7a', 'Migi yoko-geri kekomi e uraken', 'su una gamba'], ['7b', 'Hidari shutō-uke', 'kokutsu'], ['8', 'Migi shutō-uke', 'kokutsu'], ['9', 'Hidari shutō-uke', 'kokutsu'],
  ['10', 'Migi nukite', 'zenkutsu', 1], ['11', 'Hidari shutō-uke', 'kokutsu'], ['12', 'Migi shutō-uke', 'kokutsu'], ['13', 'Migi shutō-uke', 'kokutsu'], ['14', 'Hidari shutō-uke', 'kokutsu'],
  ['15', 'Migi uchi-uke (gyaku hanmi)', 'zenkutsu'], ['16', 'Migi mae-geri', 'zenkutsu'], ['17', 'Hidari gyaku-zuki', 'zenkutsu'], ['18', 'Hidari uchi-uke (gyaku hanmi)', 'zenkutsu'],
  ['19', 'Hidari mae-geri', 'zenkutsu'], ['20', 'Migi gyaku-zuki', 'zenkutsu'], ['21', 'Migi morote-uke', 'zenkutsu'], ['22', 'Hidari gedan-barai', 'zenkutsu'],
  ['23a', 'Hidari age-shutō-uke', 'zenkutsu'], ['23b', 'Migi age-uke', 'zenkutsu'], ['24', 'Migi gedan-barai', 'zenkutsu'], ['25a', 'Migi age-shutō-uke', 'zenkutsu'], ['25b', 'Hidari age-uke', 'zenkutsu', 1],
  ['Yame', 'Fine', 'hachiji-dachi']
];
Object.assign(ARMS, {
  haiwanPrep: { L: { w: [6, 96, 26], p: [0, -1, 0], pole: [0, -1, -.5] }, R: { w: [-12, 100, 30], p: [0, -1, 0], pole: [-.5, -1, .5] } },
  haiwan: { L: { w: [34, 146, -22], p: [-.7, 0, .5], pole: [0, -1, -.6] }, R: { w: [14, 162, 0], p: [.8, .4, 0], pole: [-.2, -.4, 1] } },
  ura: { L: { w: [36, 122, -2], p: [-.85, 0, .3], pole: [0, -1, -.2] }, R: { w: [42, 104, 2], p: [0, 1, 0], pole: [0, -1, .6] } },
  tetL: { L: { w: [52, 116, -16], p: [0, 0, 1], pole: [0, -1, -.6] }, R: HIK_R },
  tetLPrep: { L: { w: [12, 128, 14], p: [0, -1, 0], pole: [0, -1, -.6] }, R: HIK_R },
  nukite: { L: { w: [32, 102, 2], p: [0, -1, 0], pole: [-.2, -1, -.6], h: 'o' }, R: { w: [64, 118, 0], p: [0, 0, -1], pole: [0, -1, .5], h: 'o' } },
  nukitePrep: { L: { w: [46, 110, -2], p: [0, -1, 0], pole: [0, -1, -.5], h: 'o' }, R: { ...HIK_R, h: 'o' } },
  uchiR: { L: HIK_L, R: { w: [36, 122, 2], p: [-.85, 0, -.3], pole: [0, -1, .2] } },
  uchiRPrep: { L: { w: [44, 104, -4], p: [0, -1, 0], pole: [0, -1, -.5] }, R: { w: [18, 86, -12], p: [0, -1, 0], pole: [0, -1, .6] } },
  morote: { L: { w: [22, 104, 2], p: [0, 1, 0], pole: [-1, -.4, -.3] }, R: { w: [36, 124, 2], p: [-.85, 0, -.3], pole: [0, -1, .2] } },
  morotePrep: { L: { w: [-2, 88, -16], p: [0, -1, 0], pole: [-1, -.4, -.3] }, R: { w: [6, 88, -14], p: [0, -1, 0], pole: [-1, -.4, .3] } },
  ageShuto: { L: { ...ARMS.uke.L, h: 'o' }, R: HIK_R }
});
function buildNidan() {
  const keys = [], marks = [], hit = [], kiai = []; let t = 0;
  let cur = { ...P(0, ARMS.yoi), ...legs('hachi', 'L', 0, [0, 0]) };
  keys.push([0, cur]); marks.push(0); hit.push(0); t = 1.4; keys.push([t, cur]);
  const A = ARMS, M = mArms, W3 = (C, face, v) => add(V(C[0], 0, C[2]), ry(v, face));
  const step = (type, lead, face, arms, prep, yaw, o = {}) => {
    const sup = o.sup || (lead === 'L' ? 'R' : 'L');
    const nx = { ...P(yaw, arms, { lean: o.lean || 0 }), ...placed(type, lead, face, sup, cur['a' + sup]) };
    marks.push(t); hit.push(t + 1);
    keys.push([t + .6, stepMid(cur, nx, prep, yaw * .4), eIO]); keys.push([t + 1, nx, eOut]);
    if (o.kiai) kiai.push([t + 1, t + 1.9]);
    t += o.kiai ? 2.1 : 1.6; keys.push([t, nx]); cur = nx;
  };
  const inPlace = (arms, prep, yaw, o = {}) => { // tecnica sul posto
    const nx = { ...cur, ...P(yaw, arms, { lean: o.lean || 0 }), aL: cur.aL, aR: cur.aR, C: cur.C, face: cur.face, fL: cur.fL, fR: cur.fR, kpL: cur.kpL, kpR: cur.kpR, wt: cur.wt, stance: cur.stance };
    marks.push(t); hit.push(t + .7);
    keys.push([t + .4, { ...nx, ...prep, yaw: (cur.yaw + yaw) / 2 }, eIO]); keys.push([t + .7, nx, eOut]);
    t += 1.3; keys.push([t, nx]); cur = nx;
  };
  const mae = (lead, face, arms, yaw) => { // il piede dietro calcia e atterra avanti
    const m = lead, s = m === 'L' ? 'R' : 'L', S = cur['a' + s], g = m === 'R' ? 1 : -1;
    const C = W3(S, face, [-6, 0, 12 * g]); C[1] = 80;
    const base = { ...cur, C, face, yaw: -10 * g, wt: s === 'L' ? 100 : 0, stance: 'mae-geri' };
    const ch = { ...base, ['a' + m]: add(W3(C, face, [20, 0, 8 * g]), V(0, 52, 0)), ['f' + m]: face, ['p' + m]: -55, ['kp' + m]: [1, .8, .1 * g], lean: -4 };
    const kk = { ...base, ['a' + m]: add(W3(C, face, [76, 0, 6 * g]), V(0, 95, 0)), ['f' + m]: face, ['p' + m]: 12, ['kp' + m]: [0, 1, .1 * g], lean: -8 };
    const nx = { ...P(yaw, arms), ...placed('zen', lead, face, s, S) };
    marks.push(t); hit.push(t + .7);
    keys.push([t + .45, ch, eIO]); keys.push([t + .7, kk, eOut]); keys.push([t + 1, kk]); keys.push([t + 1.25, ch, eIO]); keys.push([t + 1.7, nx, eOut]);
    t += 2.3; keys.push([t, nx]); cur = nx;
  };
  const yoko = () => { // 7a: piede dietro a metà, yoko-geri destro verso est con uraken
    const fk = cur.face, S = [lerp(cur.aL[0], cur.aR[0], .45), 8, lerp(cur.aL[2], cur.aR[2], .45)];
    const C = W3(S, fk, [6, 0, 0]); C[1] = 80;
    const arms = { L: { w: [-12, 90, -4], p: [0, 1, 0], pole: [-.3, -.4, 1] }, R: { w: [58, 138, -4], p: [-1, 0, 0], pole: [0, -1, 0] } };
    const base = { ...cur, aL: S, C, yaw: 80, wt: 100, stance: 'yoko-geri' };
    const draw = { ...base, C: [lerp(cur.C[0], C[0], .5), 82, lerp(cur.C[2], C[2], .5)], ...ARMS.tetLPrep, R: { w: [8, 130, -12], p: [0, -1, 0], pole: [0, -1, .6] } };
    const ch = { ...base, ...arms, R: { w: [14, 132, -8], p: [0, -1, 0], pole: [0, -1, .6] }, aR: add(W3(C, fk, [16, 0, 4]), V(0, 50, 0)), fR: fk + 80, pR: -30, kpR: [1, .6, 0], lean: -6 };
    const kk = { ...base, ...arms, aR: add(W3(C, fk, [80, 0, 4]), V(0, 94, 0)), fR: fk + 80, pR: -10, kpR: [0, 1, 0], lean: -14 };
    marks.push(t); hit.push(t + 1);
    keys.push([t + .4, draw, eIO]); keys.push([t + .75, ch, eIO]); keys.push([t + 1, kk, eOut]); keys.push([t + 1.4, kk]); keys.push([t + 1.65, { ...ch, lean: -4 }, eIO]);
    const land = { ...ch, aR: W3(S, fk, [30, 8, 0]), pR: 0, fR: fk, wt: 50 }; land.aR[1] = 8;
    t += 2; keys.push([t, land, eIO]); cur = land;
  };
  const sh = A.shuto, shp = A.shutoPrep;
  step('kok', 'L', 90, A.haiwan, A.haiwanPrep, -65);       // 1
  inPlace(A.ura, A.ura, -30);                               // 2
  inPlace(A.tetL, A.tetLPrep, -60);                         // 3
  step('kok', 'R', -90, M(A.haiwan), M(A.haiwanPrep), 65, { sup: 'L' }); // 4 (rotazione sul posto)
  inPlace(M(A.ura), M(A.ura), 30);                          // 5
  inPlace(M(A.tetL), M(A.tetLPrep), 60);                    // 6
  yoko();                                                   // 7a
  step('kok', 'L', 0, sh, shp, -65);                        // 7b
  step('kok', 'R', 0, M(sh), M(shp), 65);                   // 8
  step('kok', 'L', 0, sh, shp, -65);                        // 9
  step('zen', 'R', 0, A.nukite, A.nukitePrep, 20, { kiai: 1 }); // 10
  step('kok', 'L', 270, sh, shp, -65);                      // 11
  step('kok', 'R', 225, M(sh), M(shp), 65);                 // 12
  step('kok', 'R', 90, M(sh), M(shp), 65);                  // 13
  step('kok', 'L', 135, sh, shp, -65);                      // 14
  step('zen', 'L', 180, A.uchiR, A.uchiRPrep, 30);          // 15
  mae('R', 180, A.uchiR, 30);                               // 16
  inPlace(M(A.zuki), M(A.zukiMid), 0, { lean: 3 });         // 17
  inPlace(M(A.uchiR), M(A.uchiRPrep), -30);                 // 18
  mae('L', 180, M(A.uchiR), -30);                           // 19
  inPlace(A.zuki, A.zukiMid, 0, { lean: 3 });               // 20
  step('zen', 'R', 180, A.morote, A.morotePrep, 40);        // 21
  step('zen', 'L', 450, A.gedan, A.gbPrep, -45);            // 22
  step('zen', 'L', 405, A.ageShuto, A.ukePrep, -45);        // 23a
  step('zen', 'R', 405, M(A.uke), M(A.ukePrep), 45);        // 23b
  step('zen', 'R', 270, M(A.gedan), M(A.gbPrep), 45);       // 24
  step('zen', 'R', 315, M(A.ageShuto), M(A.ukePrep), 45, { sup: 'L' }); // 25a
  step('zen', 'L', 315, A.uke, A.ukePrep, -45, { kiai: 1 }); // 25b
  step('hachi', 'L', 360, A.yoi, A.hikite, 0, { sup: 'L' }); // yame
  t += 1.2; keys.push([t, cur]);
  return { D: t, keys, marks, hit, kiai, rows: HEIAN2, follow: 1, thumb: hit[11] + .3 };
}

const rA = (a, d) => ({ ...a, w: ry(a.w, d), p: ry(a.p, d), pole: ry(a.pole, d) }), rArms = (s, d) => ({ L: rA(s.L, d), R: rA(s.R, d) });
Object.assign(STANCE, {
  musubi: { aL: [0, 8, -5], aR: [0, 8, 5], fL: 22, fR: -22, Cy: 95, wt: 50, kpL: [1, 0, -.2], kpR: [1, 0, .2], stance: 'musubi-dachi' },
  heiko: { aL: [0, 8, -18], aR: [0, 8, 18], fL: 0, fR: 0, Cy: 94, wt: 50, kpL: [1, 0, 0], kpR: [1, 0, 0], stance: 'heiko-dachi' }
});
ARMS.open = { L: { w: [4, 66, -20], p: [0, 0, 1], pole: [-1, 0, -.3], h: 'o' }, R: { w: [4, 66, 20], p: [0, 0, -1], pole: [-1, 0, .3], h: 'o' } };
const MUSU = { ...P(0, ARMS.open), ...legs('musubi', 'L', 0, [0, 0]) }, REI = { ...MUSU, lean: 28 }, HEIKO = { ...P(0, ARMS.yoi), ...legs('heiko', 'L', 0, [0, 0]) };
const GL = ARMS.guardG.L;
Object.assign(POSES, {
  uchiPrep: P(-15, mArms(ARMS.uchiRPrep)), uchi: P(-45, mArms(ARMS.uchiR)),
  kizami: P(-62, { L: { w: [64, 114, -2], p: [0, -1, 0], pole: [0, -1, -.6] }, R: HIK_R }, { lean: 8, C: [6, 78, 0], aL: [55, 8, -13] }),
  uraZ: P(-5, { L: HIK_L, R: { w: [42, 102, 2], p: [0, 1, 0], pole: [0, -1, .6] } }, { lean: 3 }),
  uraMid: P(-25, { L: GL, R: { w: [20, 94, 10], p: [0, 1, 0], pole: [-.4, -1, .5] } }),
  suPrep: P(-55, { L: { ...GL, h: 'o' }, R: { w: [-4, 146, 24], p: [0, 0, -1], pole: [-.4, -.2, 1], h: 'o' } }),
  su: P(5, { L: HIK_L, R: { w: [52, 134, -6], p: [0, 1, 0], pole: [0, -1, .6], h: 'o' } }, { lean: 3 }),
  urPrep: P(-30, { L: { w: [14, 128, 10], p: [0, -1, 0], pole: [.6, -.4, -.4] }, R: HIK_R }),
  ur: P(-65, { L: { w: [56, 140, -10], p: [-1, 0, 0], pole: [0, -.3, -1] }, R: HIK_R }),
  em: P(20, { L: HIK_L, R: { w: [16, 118, -14], p: [0, -1, 0], pole: [1, 0, .3] } }, { lean: 4 }),
  nkPrep: P(-30, ARMS.nukitePrep), nk: P(0, ARMS.nukite, { lean: 5 }),
  mwCh: P(30, ARMS.guardG, { C: [8, 80, 0], lean: -6, aR: [-10, 84, 60], fR: 30, pR: -30, kpR: [.7, .1, .7], fL: 40, wt: 100 }),
  mwKick: P(70, ARMS.guardG, { C: [10, 80, 0], lean: -10, aR: [88, 110, -10], fR: 90, pR: 0, kpR: [0, 1, -.3], fL: 70, wt: 100 }),
  usPivot: P(90, rArms(ARMS.hikite, 90), { fL: 60, C: [4, 78, 0] }),
  usCh: P(160, rArms(ARMS.hikite, 160), { C: [8, 82, -6], aR: [-6, 52, 4], fR: 180, pR: -50, kpR: [-1, .8, 0], fL: 150, wt: 100, lean: -10 }),
  usKick: P(160, rArms(ARMS.hikite, 160), { C: [12, 82, -6], aR: [86, 96, -4], fR: 180, pR: -20, kpR: [0, -1, 0], fL: 150, wt: 100, lean: -18 })
});
const KIBAY = { ...P(90, rArms(ARMS.hikite, 90)), ...legs('kiba', 'L', 0, [0, 0]), face: -90, yaw: 90, stance: 'kiba-dachi' };
const YK_CH = { ...KIBAY, C: [0, 82, -12], lean: -6, aR: [4, 48, 4], fR: 0, pR: -20, kpR: [1, .6, 0], wt: 100, stance: 'yoko-geri' };
const YK_UP = { ...YK_CH, aR: [6, 112, 70], pR: 0, kpR: [0, 1, 0], lean: -14 };
const YK_CH2 = { ...YK_CH, aR: [4, 78, 14], kpR: [1, .9, 0] }, YK_KE = { ...YK_CH2, aR: [2, 96, 84], kpR: [0, 1, 0], lean: -16 };
const SHK = { ...KOK, ...ARMS.shuto }, SHKMID = { ...KOKMID, ...ARMS.shutoPrep };
const TAIKYOKU = [['Yoi', 'Pronti', 'hachiji-dachi']];
function buildTaikyoku() {
  const keys = [], marks = [], hit = [], kiai = []; let t = 0;
  let cur = { ...P(0, ARMS.yoi), ...legs('hachi', 'L', 0, [0, 0]) };
  keys.push([0, cur]); marks.push(0); hit.push(0); t = 1.4; keys.push([t, cur]);
  const g = ARMS.gedan, gp = ARMS.gbPrep, z = ARMS.zuki, zp = ARMS.zukiPrep;
  const M = [[90, 'L', 'g'], [90, 'R', 'z'], [-90, 'R', 'g'], [-90, 'L', 'z'], [0, 'L', 'g'], [0, 'R', 'z'], [0, 'L', 'z'], [0, 'R', 'z', 1],
    [270, 'L', 'g'], [270, 'R', 'z'], [90, 'R', 'g'], [90, 'L', 'z'], [180, 'L', 'g'], [180, 'R', 'z'], [180, 'L', 'z'], [180, 'R', 'z', 1],
    [450, 'L', 'g'], [450, 'R', 'z'], [270, 'R', 'g'], [270, 'L', 'z']];
  const hand = { L: 'Hidari', R: 'Migi' };
  M.forEach(([face, lead, k, ki], i) => {
    const gd = k === 'g', arms = gd ? (lead === 'L' ? g : mArms(g)) : (lead === 'R' ? z : mArms(z)), prep = gd ? (lead === 'L' ? gp : mArms(gp)) : (lead === 'R' ? zp : mArms(zp));
    const yaw = gd ? (lead === 'L' ? -45 : 45) : (lead === 'R' ? 10 : -10), sup = lead === 'L' ? 'R' : 'L';
    TAIKYOKU.push([String(i + 1), hand[lead] + (gd ? ' gedan-barai' : ' chūdan oi-zuki'), 'zenkutsu', ki]);
    const nx = { ...P(yaw, arms, { lean: gd ? 0 : 3 }), ...placed('zen', lead, face, sup, cur['a' + sup]) };
    marks.push(t); hit.push(t + 1);
    keys.push([t + .6, stepMid(cur, nx, prep, yaw * .4), eIO]); keys.push([t + 1, nx, eOut]);
    if (ki) kiai.push([t + 1, t + 1.9]);
    t += ki ? 2.1 : 1.6; keys.push([t, nx]); cur = nx;
  });
  TAIKYOKU.push(['Yame', 'Fine', 'hachiji-dachi']);
  const nx = { ...P(0, ARMS.yoi), ...placed('hachi', 'L', 360, 'R', cur.aR) };
  marks.push(t); hit.push(t + 1); keys.push([t + .6, stepMid(cur, nx, ARMS.hikite, 0), eIO]); keys.push([t + 1, nx, eOut]); t += 2.8; keys.push([t, nx]);
  return { D: t, keys, marks, hit, kiai, rows: TAIKYOKU, follow: 1, thumb: hit[8] + .3 };
}

// combinazioni con spostamenti: f = passo avanti, b = passo indietro, s = sul posto, k = mae-geri che atterra avanti
function buildCombo(list) {
  const A = ARMS, T = {
    oi: { a: mArms(A.zuki), p: mArms(A.zukiPrep), y: -10, l: 3, n: 'oi-zuki' }, gyaku: { a: A.zuki, p: A.zukiMid, y: 0, l: 4, n: 'gyaku-zuki' },
    age: { a: A.uke, p: A.ukePrep, y: -45, n: 'age-uke' }, gedan: { a: A.gedan, p: A.gbPrep, y: -45, n: 'gedan-barai' },
    soto: { a: A.soto, p: A.sotoPrep, y: -40, n: 'soto-uke' }, shuto: { a: A.shuto, p: A.shutoPrep, y: -65, n: 'shutō-uke' },
    nukite: { a: mArms(A.nukite), p: mArms(A.nukitePrep), y: -10, l: 5, n: 'nukite' },
    kizami: { a: { L: POSES.kizami.L, R: POSES.kizami.R }, p: A.guardG, y: -62, l: 8, n: 'kizami-zuki' }, mae: { a: A.guardG, p: A.guardG, y: -45, n: 'mae-geri' }
  };
  const get = (name, lead) => { const x = T[name]; return lead === 'L' ? x : { ...x, a: mArms(x.a), p: mArms(x.p), y: -x.y }; };
  const side = { L: 'Hidari', R: 'Migi' }, keys = [], marks = [], hit = [], kiai = [], rows = [['Kamae', 'Guardia', 'zenkutsu']];
  let t = 0, lead = 'L', cur = { ...P(-45, A.gedan), ...legs('zen', 'L', 0, [0, 0]) };
  keys.push([0, cur]); marks.push(0); hit.push(0); t = 1; keys.push([t, cur]);
  for (const [k, name, ki, type = 'zen'] of list) {
    let nx;
    if (k === 'f' || k === 'b') {
      const nl = lead === 'L' ? 'R' : 'L', sup = k === 'f' ? lead : nl, x = get(name, nl);
      nx = { ...P(x.y, x.a, { lean: x.l || 0 }), ...placed(type, nl, 0, sup, cur['a' + sup]) };
      marks.push(t); hit.push(t + 1);
      keys.push([t + .6, stepMid(cur, nx, x.p, x.y * .4), eIO]); keys.push([t + 1, nx, eOut]);
      rows.push([String(rows.length), side[name === 'gyaku' ? lead : nl] + ' ' + x.n + (k === 'f' ? ', avanti' : ', indietro'), type === 'kok' ? 'kokutsu' : 'zenkutsu', ki]);
      lead = nl;
    } else if (k === 's') {
      const x = get(name, lead);
      nx = { ...cur, ...P(x.y, x.a, { lean: x.l || 0 }), aL: cur.aL, aR: cur.aR, C: cur.C, face: 0, fL: cur.fL, fR: cur.fR, kpL: cur.kpL, kpR: cur.kpR, wt: cur.wt, stance: cur.stance };
      marks.push(t); hit.push(t + .7);
      keys.push([t + .4, { ...nx, ...x.p, yaw: (cur.yaw + x.y) / 2 }, eIO]); keys.push([t + .7, nx, eOut]);
      const hand = name === 'gyaku' ? (lead === 'L' ? 'R' : 'L') : lead;
      rows.push([String(rows.length), side[hand] + ' ' + x.n + ', sul posto', cur.stance.split('-')[0], ki]);
      t -= .3;
    } else { // mae-geri con la gamba dietro, atterra avanti
      const m = lead === 'L' ? 'R' : 'L', s = lead, S = cur['a' + s], g = m === 'R' ? 1 : -1, W3 = (C, v) => add(V(C[0], 0, C[2]), v);
      const C = W3(S, [-6, 0, 12 * g]); C[1] = 80;
      const base = { ...cur, ...A.guardG, ...(m === 'L' ? mArms(A.guardG) : {}), C, yaw: -10 * g, wt: s === 'L' ? 100 : 0, stance: 'mae-geri' };
      const ch = { ...base, ['a' + m]: add(W3(C, [20, 0, 8 * g]), V(0, 52, 0)), ['f' + m]: 0, ['p' + m]: -55, ['kp' + m]: [1, .8, .1 * g], lean: -4 };
      const kk = { ...base, ['a' + m]: add(W3(C, [76, 0, 6 * g]), V(0, 95, 0)), ['f' + m]: 0, ['p' + m]: 12, ['kp' + m]: [0, 1, .1 * g], lean: -8 };
      const x = get('mae', m);
      nx = { ...P(x.y, x.a), ...placed('zen', m, 0, s, S) };
      marks.push(t); hit.push(t + .7);
      keys.push([t + .45, ch, eIO]); keys.push([t + .7, kk, eOut]); keys.push([t + 1, kk]); keys.push([t + 1.25, ch, eIO]); keys.push([t + 1.7, nx, eOut]);
      rows.push([String(rows.length), side[m] + ' mae-geri, atterra avanti', 'zenkutsu', ki]);
      lead = m; t += .7;
    }
    if (ki) kiai.push([hit.at(-1), hit.at(-1) + .9]);
    t += ki ? 2.1 : 1.6; keys.push([t, nx]); cur = nx;
  }
  t += 1; keys.push([t, cur]);
  return { D: t, keys, marks, hit, kiai, rows, follow: 1, thumb: hit[1] + .2 };
}

const ANIM = {
  zenkutsu: { D: 3.4, keys: [[0, 'hipsA'], [.9, 'hipsA'], [1.5, 'hipsB', eIO], [2.5, 'hipsB'], [3.1, 'hipsA', eIO], [3.4, 'hipsA']], marks: [0, .6, 1.2, 1.5], thumb: 2, note: 'piede dietro ruotato ~30° in fuori' },
  gedan: { D: 3.6, keys: [[0, 'gedan'], [.6, 'gedan'], [1.2, 'gbPrep', eIO], [1.5, 'gbPrep'], [1.85, 'gedan', eOut], [3, 'gedan'], [3.6, 'gedan']], marks: [0, .6, 1.5, 1.85], thumb: 2.2 },
  ageuke: { D: 3.4, keys: [[0, 'gedan'], [.6, 'gedan'], [1.05, 'ukePrep', eIO], [1.45, 'uke', eOut], [2.7, 'uke'], [3.4, 'gedan', eIO]], marks: [0, .6, 1.2, 1.45], thumb: 2 },
  gyaku: { D: 3, keys: [[0, 'guardG'], [.8, 'guardG'], [.98, 'zukiMid', eIn], [1.12, 'zuki', eOut], [2.2, 'zuki'], [3, 'guardG', eIO]], marks: [0, .5, .9, 1.12], thumb: 1.6 },
  combo: { D: 4.4, keys: [[0, 'gedan'], [.8, 'gedan'], [1.15, 'ukePrep', eIO], [1.5, 'uke', eOut], [2.3, 'uke'], [2.48, 'zukiMid', eIn], [2.62, 'zuki', eOut], [3.6, 'zuki'], [4.4, 'gedan', eIO]], marks: [0, .8, 2.3, 3.6], thumb: 3 },
  oizuki: { D: 4.4, keys: [[0, OZ_A], [.6, OZ_A], [1.05, OZ_M1, eIO], [1.4, OZ_B, eOut], [2.4, OZ_B], [2.9, OZ_M2, eIO], [3.4, OZ_A, eOut], [4.4, OZ_A]], marks: [0, .6, 1.05, 1.4, 2.4], thumb: 1.7, thumbX: 45, note: 'il piede passa vicino all\'altro' },
  kokutsu: { D: 3.8, keys: [[0, HACHI], [.7, HACHI], [1.1, KOKMID, eIO], [1.5, KOK, eOut], [2.8, KOK], [3.2, KOKMID, eIO], [3.6, HACHI, eOut], [3.8, HACHI]], marks: [0, .7, 1.1, 1.5], thumb: 2.2, note: 'piedi a L, talloni sulla stessa linea' },
  kiba: { D: 3.6, keys: [[0, HACHI], [.8, HACHI], [1.6, KIBA, eIO], [2.8, KIBA], [3.4, HACHI, eIO], [3.6, HACHI]], marks: [0, .8, 1.2, 1.6], thumb: 2.2, note: 'piedi paralleli, ginocchia in fuori' },
  soto: { D: 3.4, keys: [[0, 'gedan'], [.6, 'gedan'], [1.1, 'sotoPrep', eIO], [1.45, 'soto', eOut], [2.7, 'soto'], [3.4, 'gedan', eIO]], marks: [0, .6, 1.1, 1.45], thumb: 2 },
  maegeri: { D: 3.6, keys: [[0, 'gedan'], [.7, 'gedan'], [1.05, 'mgChamber', eIO], [1.3, 'mgKick', eOut], [1.7, 'mgKick'], [1.95, 'mgChamber', eIO], [2.4, 'gedan', eIO], [3.6, 'gedan']], marks: [0, .7, 1.05, 1.7, 1.95], thumb: 1.45, note: 'si colpisce con l\'avampiede' },
  musubi: { D: 3.8, keys: [[0, MUSU], [1, MUSU], [1.6, REI, eIO], [2.4, REI], [3, MUSU, eIO], [3.8, MUSU]], marks: [0, .5, 1, 2.4], thumb: .5, note: 'talloni uniti, punte aperte a 45°' },
  heiko: { D: 4, keys: [[0, MUSU], [.8, MUSU], [1.5, HEIKO, eIO], [3, HEIKO], [3.6, MUSU, eIO], [4, MUSU]], marks: [0, .8, 1.2, 1.5], thumb: 2, note: 'piedi paralleli, larghi come le spalle' },
  uchi: { D: 3.4, keys: [[0, 'gedan'], [.6, 'gedan'], [1.1, 'uchiPrep', eIO], [1.45, 'uchi', eOut], [2.7, 'uchi'], [3.4, 'gedan', eIO]], marks: [0, .6, 1.1, 1.45], thumb: 2 },
  shutouke: { D: 3.8, keys: [[0, HACHI], [.7, HACHI], [1.1, SHKMID, eIO], [1.5, SHK, eOut], [2.8, SHK], [3.2, KOKMID, eIO], [3.6, HACHI, eOut], [3.8, HACHI]], marks: [0, .7, 1.1, 1.5], thumb: 2.2 },
  kizami: { D: 2.8, keys: [[0, 'guardG'], [.7, 'guardG'], [.95, 'kizami', eOut], [1.9, 'kizami'], [2.6, 'guardG', eIO], [2.8, 'guardG']], marks: [0, .5, .8, .95], thumb: 1.4 },
  ura: { D: 2.8, keys: [[0, 'guardG'], [.7, 'guardG'], [.85, 'uraMid', eIn], [1, 'uraZ', eOut], [2, 'uraZ'], [2.8, 'guardG', eIO]], marks: [0, .5, .85, 1], thumb: 1.5 },
  shutouchi: { D: 3.2, keys: [[0, 'guardG'], [.6, 'guardG'], [1, 'suPrep', eIO], [1.3, 'su', eOut], [2.4, 'su'], [3.2, 'guardG', eIO]], marks: [0, .6, 1, 1.3], thumb: 1.9 },
  uraken: { D: 3, keys: [[0, 'guardG'], [.6, 'guardG'], [.95, 'urPrep', eIO], [1.15, 'ur', eOut], [1.35, 'ur'], [1.7, 'urPrep', eIO], [2.3, 'guardG', eIO], [3, 'guardG']], marks: [0, .6, .95, 1.15, 1.35], thumb: 1.2 },
  empi: { D: 2.8, keys: [[0, 'guardG'], [.8, 'guardG'], [1.1, 'em', eOut], [2, 'em'], [2.8, 'guardG', eIO]], marks: [0, .5, .8, 1.1], thumb: 1.5 },
  nukite: { D: 3, keys: [[0, 'guardG'], [.6, 'guardG'], [.95, 'nkPrep', eIO], [1.2, 'nk', eOut], [2.2, 'nk'], [3, 'guardG', eIO]], marks: [0, .6, .95, 1.2], thumb: 1.6 },
  keage: { D: 3.4, keys: [[0, KIBAY], [.7, KIBAY], [1.05, YK_CH, eIO], [1.25, YK_UP, eOut], [1.45, YK_CH, eIO], [2, KIBAY, eIO], [3.4, KIBAY]], marks: [0, .7, 1.05, 1.25, 1.45], thumb: 1.25, view: 'fronte', note: 'si colpisce con il taglio del piede (sokuto)' },
  kekomi: { D: 3.6, keys: [[0, KIBAY], [.7, KIBAY], [1.1, YK_CH2, eIO], [1.35, YK_KE, eOut], [1.75, YK_KE], [2, YK_CH2, eIO], [2.5, KIBAY, eIO], [3.6, KIBAY]], marks: [0, .7, 1.1, 1.35, 2], thumb: 1.5, view: 'fronte', note: 'l\'anca spinge dietro il calcio' },
  mawashi: { D: 3.6, keys: [[0, 'guardG'], [.7, 'guardG'], [1.1, 'mwCh', eIO], [1.35, 'mwKick', eOut], [1.65, 'mwKick'], [1.95, 'mwCh', eIO], [2.5, 'guardG', eIO], [3.6, 'guardG']], marks: [0, .7, 1.1, 1.35, 1.95], thumb: 1.5, note: 'il piede d\'appoggio ruota con le anche' },
  ushiro: { D: 4, keys: [[0, 'guardG'], [.7, 'guardG'], [1.05, 'usPivot', eIO], [1.35, 'usCh', eIO], [1.6, 'usKick', eOut], [2, 'usKick'], [2.3, 'usCh', eIO], [2.7, 'usPivot', eIO], [3.1, 'guardG', eIO], [4, 'guardG']], marks: [0, .7, 1.05, 1.6, 2.3], thumb: 1.7, note: 'si colpisce con il tallone (kakato)' },
  taikyoku1: buildTaikyoku(),
  combo2: buildCombo([['f', 'oi'], ['f', 'oi'], ['f', 'oi', 1], ['b', 'gedan'], ['b', 'gedan'], ['b', 'gedan']]),
  combo3: buildCombo([['f', 'oi'], ['b', 'age'], ['s', 'gyaku', 1]]),
  combo4: buildCombo([['k', 'mae'], ['f', 'oi', 1], ['b', 'gedan'], ['b', 'gedan']]),
  combo5: buildCombo([['b', 'soto'], ['s', 'gyaku'], ['f', 'oi', 1]]),
  combo6: buildCombo([['b', 'shuto', 0, 'kok'], ['b', 'shuto', 0, 'kok'], ['f', 'nukite'], ['f', 'nukite', 1]]),
  combo7: buildCombo([['s', 'kizami'], ['s', 'gyaku'], ['k', 'mae'], ['s', 'gyaku', 1], ['b', 'gedan']]),
  heian1: buildKata(), heian2: buildNidan()
};
const EASE = new Map([[eIO,'inOut'],[eOut,'out'],[eIn,'in']]);
const r2 = x => typeof x==='number' ? Math.round(x*100)/100 : Array.isArray(x) ? x.map(r2) : (x && typeof x==='object') ? Object.fromEntries(Object.entries(x).map(([k,v])=>[k,r2(v)])) : x;
function exportAnim(id, a) {
  const get = x => typeof x === 'string' ? POSES[x] : x;
  return { versione: 1, id, durata: r2(a.D), segue_camera: !!a.follow, vista: a.view === 'fronte' ? 'fronte' : (a.view || '34'), unita: 'cm; x avanti, y su, z destra; angoli in gradi',
    chiavi: a.keys.map(([t,p,e]) => ({ t: r2(t), ease: (e && EASE.get(e)) || 'linear', pose: r2(get(p)) })), passi_t: r2(a.hit || a.marks), kiai: r2(a.kiai || []) };
}
module.exports = { buildCombo, ANIM, POSES, ARMS, STANCE, legs, placed, stepMid, P, mArms, mArm, rArms, lerp, eIO, eOut, eIn, V, add, sub, mul, ry, len, HIK_L, HIK_R, DEF, exportAnim, HEIAN, HEIAN2, TAIKYOKU };
