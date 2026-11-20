// Kata superiori descritti con una riga per movimento e interpretati sul motore del prototipo.
// Riga: [passo, testo, posizione, 'Lato+direzione', braccia, opzioni]
//  posizione: zen kok kiba kosa neko fudo hangetsu sanchin renoji teiji tsuru shiko heisoku hachi | here (sul posto) | kick:mae|yoko|mika|hiza|nidan|kekomi
//  direzione in gradi: 0 avanti, 90 sinistra, 180 indietro, 270 destra
//  braccia: 'R.zuki' (tecnica con la destra), 'L.uchiR' (con la sinistra), 'juji' (due mani), 'R.uchiR+L.osae' (somma)
//  opzioni: k kiai, s lento, b passo indietro (resta fermo il piede avanti), j salto, y=gradi rotazione anche
const m = require('./proto.js'), T = require('./tech.js'), { Kata, A, YOI } = require('./kata.js');
const { P, placed, legs, add, ry, V, mArms: M, HIK_L, HIK_R, eIO } = m;
const LEFT = new Set(['gedan', 'uke', 'soto', 'shuto', 'haiwan', 'haishu', 'osae', 'otoshi', 'sukui', 'teishoU', 'kake', 'tateShuto', 'gshuto', 'mizu', 'mikaPalmL', 'sideKakeL', 'tettsuiSideL', 'uraL_kick', 'guardG', 'tetL', 'ageShuto', 'chokuL']);
const SYM = new Set(['juji', 'jujiJ', 'kakiwake', 'hasami', 'morZ', 'yama', 'reach', 'kneePull', 'hips', 'ryoOsae', 'hikite', 'yoi', 'open', 'suiheiTwo', 'jujiPrep', 'kakiPrep', 'morotePrep']);
const PUNCH = new Set(['zuki', 'choku', 'chokuL', 'tate', 'age', 'mawZ', 'kagi', 'ippon', 'teishoZ', 'morZ', 'yama', 'hasami', 'uraFront', 'nukite', 'sideZukiR', 'kagiR', 'morZSideL']);
const one = (side, key) => { const a = A[key]; if (!a) throw new Error('braccia sconosciute: ' + key); if (!side || SYM.has(key)) return a; const nat = LEFT.has(key) ? 'L' : 'R'; return side === nat ? a : M(a); };
function arms(spec) {
  if (!spec) return null;
  const parts = spec.split('+').map(s => s.includes('.') ? s.split('.') : [null, s]);
  if (parts.length === 1) { const [s, k] = parts[0]; const prep = A[k + 'Prep'] ? one(s, k + 'Prep') : null; return { a: one(s, k), prep, side: s, key: k }; }
  const r = { L: HIK_L, R: HIK_R };
  for (const [s, k] of parts) { const a = one(s, k); if (s) r[s] = a[s]; else Object.assign(r, a); }
  return { a: r, prep: null, side: parts[0][0], key: parts[0][1] };
}
function yawOf(st, lead, ar) {
  const sg = lead === 'L' ? -1 : 1, hand = ar && ar.side, punch = ar && PUNCH.has(ar.key);
  if (['kiba', 'heisoku', 'hachi', 'sanchin', 'shiko'].includes(st)) return 0;
  if (st === 'kok') return 50 * sg;
  if (st === 'zen') { if (!hand) return 0; if (punch) return hand === 'R' ? 10 : -10; return hand === lead ? 30 * sg : (hand === 'R' ? 15 : -15); }
  return 20 * sg;
}
const KICK = { mae: s => [[78, 0, 6 * s], 118], yoko: s => [[4, 0, 74 * s], 112], kekomi: s => [[6, 0, 76 * s], 100], mika: s => [[46, 0, -10 * s], 120], hiza: s => [[24, 0, 8 * s], 60], nidan: s => [[72, 0, 6 * s], 132] };
function build(rows, start = YOI, yoiRow) {
  const k = new Kata(start, yoiRow);
  let lead = 'L', face = 0, st = 'hachi';
  for (const [lbl, txt, stance, lf, ar0, fl = ''] of rows) {
    const row = [lbl, txt, stance.startsWith('kick:') ? 'ashi-dachi' : stance === 'here' ? st : stance], ar = arms(ar0);
    if (lf) { lead = lf[0]; face = +lf.slice(1); }
    const kiai = fl.includes('k'), slow = fl.includes('s'), ym = fl.match(/y=(-?\d+)/), o2 = { kiai, slow };
    if (stance === 'here') { k.here(row, ar ? ar.a : k.cur, ar && ar.prep, ym ? +ym[1] : yawOf(st, lead, ar), o2); continue; }
    if (stance.startsWith('kick:')) {
      const kind = stance.slice(5), sg = lead === 'R' ? 1 : -1;
      const opt = { ...o2, arms: ar ? ar.a : undefined, ...(kind === 'hiza' ? { pitch: -60, kp: [1, 1.2, .1], lean: -2 } : {}), ...(kind === 'yoko' || kind === 'kekomi' ? { kp: [0, .6, sg], footYaw: 90 * sg, lean: -14, pitch: -10 } : {}), ...(kind === 'nidan' ? { Cy: 100 } : {}) };
      k.kick(row, lead, face, KICK[kind](sg), null, opt); continue;
    }
    st = stance;
    const sup = fl.includes('b') ? lead : undefined, yaw = ym ? +ym[1] : yawOf(st, lead, ar);
    k.mv(row, st, lead, face, ar ? ar.a : { L: k.cur.L, R: k.cur.R }, ar && ar.prep, yaw, { sup, kiai, slow, lean: st === 'zen' && ar && PUNCH.has(ar.key) ? 3 : 0 });
    if (fl.includes('j')) { const ks = k.keys, i = ks.length - 3, mid = ks[i][1]; ks[i][1] = { ...mid, C: add(mid.C, [0, 34, 0]), aL: add(mid.aL, [0, 40, 0]), aR: add(mid.aR, [0, 40, 0]) }; }
  }
  return k;
}
const HANDS = { ...P(0, { L: { ...A.yoi.L, w: [18, 96, -2], h: 'o' }, R: { ...A.yoi.R, w: [16, 94, 2] } }), ...T.L2('heisoku', 'L', 0, [0, 0]) };
const KD = {};
// ---------------- Bassai Dai (42)
KD.bassaidai = build([
  ['1', 'Salto in avanti: migi uchi-uke rinforzato dalla sinistra', 'kosa', 'R0', 'R.uchiR+L.osae', 'j'],
  ['2', 'Giro indietro: hidari uchi-uke', 'zen', 'L180', 'L.uchiR'],
  ['3', 'Migi uchi-uke ruotando le anche', 'here', '', 'R.uchiR'],
  ['4', 'Giro in avanti: migi soto-uke', 'zen', 'R0', 'R.soto'],
  ['5', 'Hidari uchi-uke ruotando le anche', 'here', '', 'L.uchiR'],
  ['6', 'Migi sukui-uke e migi soto-uke', 'zen', 'R0', 'R.soto', 'b'],
  ['7', 'Hidari uchi-uke', 'here', '', 'L.uchiR'],
  ['8', 'Pugni al fianco destro, piedi uniti', 'heisoku', 'L0', 'koshiR'],
  ['9', 'Hidari tate shutō-uke (lento)', 'hachi', 'L0', 'L.tateShuto', 's'],
  ['10', 'Migi choku-zuki', 'here', '', 'R.choku'],
  ['11', 'Migi uchi-uke', 'here', '', 'R.uchiR', 'y=30'],
  ['12', 'Hidari choku-zuki', 'here', '', 'L.choku'],
  ['13', 'Hidari uchi-uke', 'here', '', 'L.uchiR', 'y=-30'],
  ['14', 'Migi shutō-uke', 'kok', 'R0', 'R.shuto'],
  ['15', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto'],
  ['16', 'Migi shutō-uke', 'kok', 'R0', 'R.shuto'],
  ['17', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto', 'b'],
  ['18', 'Le due mani afferrano (lento)', 'zen', 'R0', 'reach', 's'],
  ['19', 'Migi yoko-geri kekomi verso il basso, mani che tirano', 'kick:kekomi', 'R0', 'kneePull', 'k'],
  ['20', 'Hidari shutō-uke', 'kok', 'L180', 'L.shuto'],
  ['21', 'Migi shutō-uke', 'kok', 'R180', 'R.shuto'],
  ['22', 'Giro: braccia in alto, piedi uniti (lento)', 'heisoku', 'L90', 'jujiJ', 's'],
  ['23', 'Hasami-uchi: pugni chiusi a forbice', 'zen', 'L90', 'hasami'],
  ['24', 'Migi oi-zuki', 'zen', 'R90', 'R.zuki'],
  ['25', 'Nagashi-uke e shutō-uchikomi, poi manji-uke', 'zen', 'R270', 'R.nukite', 'b'],
  ['25b', 'Manji-uke in heisoku-dachi', 'heisoku', 'L270', 'manji'],
  ['26', 'Fumikomi e migi gedan-barai', 'kiba', 'R0', 'sideGedanR'],
  ['27', 'Hidari kake-uke (lento)', 'here', '', 'sideKakeL', 's'],
  ['28', 'Migi mikazuki-geri e mae-empi', 'kick:mika', 'R90', 'mikaPalmL'],
  ['28b', 'Atterraggio in kiba-dachi, migi mae-empi', 'kiba', 'R0', 'empiPalmSideL'],
  ['29', 'Gedan-barai a destra, braccio sinistro davanti al petto', 'here', '', 'R.sideGedanR+L.osae'],
  ['30', 'Gedan-barai a sinistra, braccio destro davanti al petto', 'here', '', 'L.sideGedanR+R.osae'],
  ['31', 'Gedan-barai a destra, braccio sinistro davanti al petto', 'here', '', 'R.sideGedanR+L.osae'],
  ['32', 'Pugni al fianco destro', 'zen', 'L45', 'koshiR', 's'],
  ['33', 'Yama-zuki', 'here', '', 'yama'],
  ['34', 'Piedi uniti, pugni al fianco', 'heisoku', 'R45', 'R.koshiR'],
  ['35', 'Yama-zuki', 'zen', 'R-45', 'R.yama'],
  ['36', 'Piedi uniti, pugni al fianco', 'heisoku', 'L-45', 'koshiR'],
  ['37', 'Yama-zuki', 'zen', 'L45', 'yama'],
  ['38', 'Migi sukui-uke', 'zen', 'R0', 'R.sukui'],
  ['39', 'Hidari sukui-uke', 'zen', 'L0', 'L.sukui'],
  ['40', 'Migi shutō-uke', 'kok', 'R-45', 'R.shuto'],
  ['41', 'Posizione mantenuta, sguardo indietro', 'here', '', null],
  ['42', 'Hidari shutō-uke', 'kok', 'L45', 'L.shuto', 'k'],
], HANDS, ['Yoi', 'Piedi uniti, la mano sinistra copre il pugno destro', 'heisoku']);
// ---------------- Kankū Dai (65)
const kuDaiYoko = (n, side, face) => [
  [String(n), 'Pugni al fianco, in piedi su una gamba', 'tsuru', (side === 'R' ? 'L' : 'R') + face, (side === 'R' ? 'L' : 'R') + '.koshiR'],
  [String(n + 1), (side === 'R' ? 'Migi' : 'Hidari') + ' yoko-geri keage e uraken', 'kick:yoko', side + face, side + '.sideUraR'],
];
KD.kankudai = build([
  ['1', 'Mani aperte unite sopra la fronte, sguardo al cielo (lento)', 'here', '', 'jujiJ', 's'],
  ['2', 'Le mani scendono davanti al ventre (lento)', 'here', '', 'open', 's'],
  ['3', 'Hidari haiwan-uke', 'kok', 'L90', 'L.haiwan'],
  ['4', 'Migi haiwan-uke', 'kok', 'R270', 'R.haiwan'],
  ['5', 'Hidari tate shutō-uke (lento)', 'hachi', 'L0', 'L.tateShuto', 's'],
  ['6', 'Migi choku-zuki', 'here', '', 'R.choku'],
  ['7', 'Migi uchi-uke', 'here', '', 'R.uchiR', 'y=30'],
  ['8', 'Hidari choku-zuki', 'here', '', 'L.choku'],
  ['9', 'Hidari uchi-uke', 'here', '', 'L.uchiR', 'y=-30'],
  ...kuDaiYoko(10, 'R', 270),
  ['12', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto'],
  ['13', 'Migi shutō-uke', 'kok', 'R0', 'R.shuto'],
  ['14', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto'],
  ['15', 'Migi shihon nukite, la sinistra preme', 'zen', 'R0', 'R.nukite', 'k'],
  ['16', 'Giro: hidari gedan shutō-barai, poi jōdan shutō-uchi', 'zen', 'L180', 'ageShutoUchi'],
  ['17', 'Migi jōdan mae-geri', 'kick:mae', 'R180', null],
  ['18', 'Manji-uke', 'kok', 'R180', 'manji', 'b'],
  ['19', 'Nagashi-uke e shutō-uchikomi', 'zen', 'R0', 'R.nukite'],
  ['20', 'Hidari gedan-barai', 'renoji', 'L0', 'L.gedan'],
  ['21', 'Hidari gedan shutō-barai, poi jōdan shutō-uchi', 'zen', 'R0', 'ageShutoUchi'],
  ['22', 'Hidari jōdan mae-geri', 'kick:mae', 'L0', null],
  ['23', 'Manji-uke', 'kok', 'L0', 'L.manji', 'b'],
  ['24', 'Nagashi-uke e shutō-uchikomi', 'zen', 'L180', 'L.nukite'],
  ['25', 'Migi gedan-barai', 'renoji', 'R180', 'R.gedan'],
  ...kuDaiYoko(26, 'L', 90),
  ['28', 'Migi mae-empi nel palmo', 'zen', 'L90', 'palmEmpiR'],
  ...kuDaiYoko(29, 'R', 270),
  ['31', 'Hidari mae-empi nel palmo', 'zen', 'R270', 'L.palmEmpiR'],
  ['32', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto'],
  ['33', 'Migi shutō-uke', 'kok', 'R0', 'R.shuto'],
  ['34', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto'],
  ['35', 'Migi shutō-uke', 'kok', 'R0', 'R.shuto'],
  ['36', 'Gedan shutō-barai e jōdan shutō-uchi', 'zen', 'L0', 'ageShutoUchi'],
  ['37', 'Migi jōdan mae-geri', 'kick:mae', 'R0', null],
  ['38', 'Migi tate uraken-uchi', 'kosa', 'R0', 'R.uraFront', 'j'],
  ['39', 'Hidari uchi-uke', 'zen', 'L180', 'L.uchiR'],
  ['40', 'Migi gyaku-zuki', 'here', '', 'R.zuki'],
  ['41', 'Hidari chūdan zuki', 'here', '', 'L.zuki'],
  ['42', 'Migi ura-zuki e ginocchio che sale', 'kick:hiza', 'R180', 'R.tate'],
  ['43', 'Giù a terra, appoggiati sulle mani', 'zen', 'L180', 'open', 'b'],
  ['44', 'Migi shutō-uke (in basso)', 'kok', 'R0', 'R.shuto'],
  ['45', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto'],
  ['46', 'Migi uchi-uke', 'zen', 'R0', 'R.uchiR'],
  ['47', 'Hidari gyaku-zuki', 'here', '', 'L.zuki'],
  ['48', 'Hidari uchi-uke', 'zen', 'L0', 'L.uchiR'],
  ['49', 'Migi gyaku-zuki', 'here', '', 'R.zuki'],
  ['50', 'Hidari chūdan zuki', 'here', '', 'L.zuki'],
  ...kuDaiYoko(51, 'R', 270),
  ['53', 'Hidari shutō-uke', 'kok', 'L180', 'L.shuto'],
  ['54', 'Migi shihon nukite, la sinistra preme', 'zen', 'R180', 'R.nukite'],
  ['55', 'Giro: migi tate uraken-uchi', 'kiba', 'R0', 'sideUraR'],
  ['56', 'Migi tettsui yoko-uchi', 'here', '', 'R.tettsui'],
  ['57', 'Migi mae-empi nel palmo', 'kiba', 'R0', 'empiPalmSideL'],
  ['58', 'Pugni al fianco', 'here', '', 'koshiR'],
  ['59', 'Hidari gedan-barai', 'here', '', 'L.sideGedanR'],
  ['60', 'Migi gedan-barai', 'here', '', 'R.sideGedanR'],
  ['61', 'Hidari otoshi-zuki', 'here', '', 'L.otoshi'],
  ['62', 'Mani aperte incrociate in alto', 'hachi', 'L0', 'jujiJ'],
  ['63', 'Giro sul piede sinistro', 'zen', 'L180', 'jujiJ'],
  ['64', 'Pugni incrociati davanti al petto', 'here', '', 'hikiJuji'],
  ['65', 'Salto: nidan-geri e migi uraken', 'kick:nidan', 'R180', 'R.uraFront', 'k'],
], { ...YOI, ...P(0, A.jujiPrep) });
// ---------------- Jion (47)
KD.jion = build([
  ['1', 'Hidari uchi-uke e migi gedan-barai insieme', 'zen', 'L0', 'L.uchiR+R.gedan', 'b'],
  ['2', 'Kakiwake-uke (lento)', 'zen', 'R45', 'kakiwake', 's'],
  ['3', 'Migi mae-geri', 'kick:mae', 'R45', null],
  ['4', 'Migi oi-zuki', 'zen', 'R45', 'R.zuki'],
  ['5', 'Hidari gyaku-zuki', 'here', '', 'L.zuki'],
  ['6', 'Migi chūdan zuki', 'here', '', 'R.zuki'],
  ['7', 'Kakiwake-uke (lento)', 'zen', 'L-45', 'kakiwake', 's'],
  ['8', 'Hidari mae-geri', 'kick:mae', 'L-45', null],
  ['9', 'Hidari oi-zuki', 'zen', 'L-45', 'L.zuki'],
  ['10', 'Migi gyaku-zuki', 'here', '', 'R.zuki'],
  ['11', 'Hidari chūdan zuki', 'here', '', 'L.zuki'],
  ['12', 'Hidari age-uke', 'zen', 'L0', 'L.uke'],
  ['13', 'Migi gyaku-zuki', 'here', '', 'R.zuki'],
  ['14', 'Migi age-uke', 'zen', 'R0', 'R.uke'],
  ['15', 'Hidari gyaku-zuki', 'here', '', 'L.zuki'],
  ['16', 'Hidari age-uke', 'zen', 'L0', 'L.uke'],
  ['17', 'Migi oi-zuki', 'zen', 'R0', 'R.zuki', 'k'],
  ['18', 'Manji-uke', 'kok', 'L90', 'L.manji'],
  ['19', 'Migi kagi-zuki', 'kiba', 'L90', 'kagi'],
  ['20', 'Manji-uke', 'kok', 'R270', 'manji'],
  ['21', 'Hidari kagi-zuki', 'kiba', 'R270', 'L.kagi'],
  ['22', 'Hidari gedan-barai', 'zen', 'L180', 'L.gedan'],
  ['23', 'Migi teishō yoko-uke', 'kiba', 'R180', 'R.teishoU'],
  ['24', 'Hidari teishō yoko-uke', 'kiba', 'L180', 'L.teishoU'],
  ['25', 'Migi teishō yoko-uke', 'kiba', 'R180', 'R.teishoU'],
  ['26', 'Manji-uke', 'kok', 'L270', 'L.manji'],
  ['27', 'Morote-uke a piedi uniti', 'heisoku', 'L270', 'morote'],
  ['28', 'Manji-uke', 'kok', 'R90', 'manji'],
  ['29', 'Morote-uke a piedi uniti', 'heisoku', 'R90', 'L.morote'],
  ['30', 'Kakiwake-uke (lento)', 'hachi', 'L180', 'kakiwake', 's'],
  ['31', 'Salto: jūji-uke in kōsa-dachi', 'kosa', 'R180', 'juji', 'j'],
  ['32', 'Kakiwake-uke', 'zen', 'L180', 'kakiwake', 'b'],
  ['33', 'Kakiwake-uke', 'zen', 'R180', 'kakiwake', 'b'],
  ['34', 'Jūji-uke', 'zen', 'L180', 'juji'],
  ['35', 'Migi tate uraken-uchi', 'here', '', 'R.uraFront'],
  ['36', 'Hidari nagashi-uke con il dorso del braccio', 'zen', 'L0', 'L.nagashi'],
  ['37', 'Hidari uraken, braccio destro orizzontale', 'here', '', 'L.uraFront+R.osae'],
  ['38', 'Migi uchi-uke', 'zen', 'R0', 'R.uchiR'],
  ['39', 'Hidari oi-zuki', 'zen', 'L0', 'L.zuki'],
  ['40', 'Hidari uchi-uke', 'zen', 'L0', 'L.uchiR', 'b'],
  ['41', 'Migi oi-zuki', 'zen', 'R0', 'R.zuki'],
  ['42', 'Hidari gedan-barai', 'zen', 'L90', 'L.gedan'],
  ['43', 'Fumikomi: migi uchi-otoshi', 'kiba', 'R90', 'R.otoshi'],
  ['44', 'Fumikomi: hidari uchi-otoshi', 'kiba', 'L90', 'L.otoshi'],
  ['45', 'Fumikomi: migi uchi-otoshi', 'kiba', 'R90', 'R.otoshi'],
  ['46', 'Hidari yumi-zuki (pugno laterale)', 'kiba', 'R90', 'morZSideL'],
  ['47', 'Migi yumi-zuki (pugno laterale)', 'kiba', 'L270', 'L.morZSideL', 'k'],
], HANDS, ['Yoi', 'Piedi uniti, la mano sinistra copre il pugno destro', 'heisoku']);
// ---------------- Enpi (37)
const enGroup = (n, side, face) => { const S = side === 'L' ? 'Hidari' : 'Migi', O = side === 'L' ? 'R' : 'L';
  return [[String(n), S + ' gedan-barai', 'zen', side + face, side + '.gedan'], [String(n + 1), O === 'R' ? 'Migi age-zuki' : 'Hidari age-zuki', 'here', '', O + '.age'],
    [String(n + 2), 'Pugno sopra la spalla e gedan-zuki, in kōsa-dachi', 'kosa', side + face, side + '.gedan+' + O + '.ageMid', 'j'], [String(n + 3), S + ' gedan-barai', 'zen', O + face, side + '.gedan', 'b']]; };
KD.enpi = build([
  ['1', 'In ginocchio: migi gedan-barai, pugno sinistro sopra', 'zen', 'L90', 'R.gedan+L.ageMid', 'y=0'],
  ['2', 'In piedi, pugni al fianco destro', 'hachi', 'L0', 'koshiR'],
  ['3', 'Hidari gedan-barai', 'zen', 'L90', 'L.gedan'],
  ['4', 'Mizu-nagare no kamae', 'kiba', 'L0', 'mizu'],
  ['5', 'Migi gedan-barai', 'zen', 'R270', 'R.gedan'],
  ['6', 'Hidari age-zuki', 'here', '', 'L.age'],
  ['7', 'Pugno destro sopra la spalla e gedan-zuki, in kōsa-dachi', 'kosa', 'R270', 'R.gedan+L.ageMid', 'j'],
  ['8', 'Hidari gedan-barai', 'zen', 'L270', 'L.gedan', 'b'],
  ...enGroup(9, 'L', 90).map((r, i) => i === 0 ? r : r).slice(0, 4),
  ['13', 'Hidari gedan-barai', 'zen', 'L0', 'L.gedan'],
  ['14', 'Mani aperte in alto davanti, lente', 'kiba', 'R270', 'jujiJ', 's'],
  ['15', 'Tekubi-uchi, in piedi su una gamba', 'tsuru', 'L270', 'L.uraFront', 'k'],
  ['16', 'Hidari tate shutō-uke (lento)', 'kiba', 'L270', 'L.tateShutoSideR', 's'],
  ['17', 'Migi choku-zuki laterale', 'here', '', 'R.sideZukiR'],
  ['18', 'Hidari choku-zuki laterale', 'here', '', 'L.sideZukiR'],
  ['19', 'Hidari gedan-barai', 'zen', 'L0', 'L.gedan'],
  ['20', 'Migi age-zuki', 'here', '', 'R.age'],
  ['21', 'Migi shutō-uke', 'kok', 'R270', 'R.shuto'],
  ['22', 'Hidari shutō-uke', 'kok', 'L270', 'L.shuto'],
  ['23', 'Migi gyaku-zuki', 'here', '', 'R.zuki'],
  ['24', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto'],
  ['25', 'Hidari gedan-barai', 'zen', 'L90', 'L.gedan'],
  ['26', 'Migi age-zuki', 'here', '', 'R.age'],
  ['27', 'Pugno sopra la spalla e gedan-zuki, in kōsa-dachi', 'kosa', 'L90', 'L.gedan+R.ageMid', 'j'],
  ['28', 'Migi gedan-barai', 'zen', 'R90', 'R.gedan', 'b'],
  ['29', 'Hidari gedan-barai', 'zen', 'L180', 'L.gedan'],
  ['30', 'Migi teishō oshiage-uke (lento)', 'zen', 'L180', 'R.teishoU', 's'],
  ['31', 'Hidari teishō (lento)', 'zen', 'R180', 'L.teishoU', 's'],
  ['32', 'Migi teishō (lento)', 'zen', 'L180', 'R.teishoU', 's'],
  ['33', 'Hidari teishō (lento)', 'zen', 'R180', 'L.teishoU', 's'],
  ['34', 'Gedan-kamae', 'kok', 'L0', 'L.gedan'],
  ['35', 'Le mani afferrano', 'fudo', 'L0', 'reach'],
  ['36', 'Salto con giro completo: migi shutō-uke', 'kok', 'R0', 'R.shuto', 'jk'],
  ['37', 'Hidari shutō-uke', 'kok', 'L0', 'L.shuto', 'b'],
]);
module.exports = { build, KD, arms };
if (require.main === module) {
  const fs = require('fs'), meta = JSON.parse(fs.readFileSync(__dirname + '/out/meta_kata.json'));
  fs.mkdirSync(__dirname + '/out/anim', { recursive: true });
  for (const [id, k] of Object.entries(KD)) { const a = k.end ? (k.anim = k.end()) : k; fs.writeFileSync(__dirname + '/out/anim/' + id + '.json', JSON.stringify(m.exportAnim(id, a))); meta[id] = { marks: a.hit, rows: a.rows }; console.log(id, a.rows.length - 2, 'passi', Math.round(a.D) + 's'); }
  fs.writeFileSync(__dirname + '/out/meta_kata.json', JSON.stringify(meta));
}
