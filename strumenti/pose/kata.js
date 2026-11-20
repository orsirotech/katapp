// Costruttore generico di kata (stesso motore del prototipo) + Heian 3-5 e Tekki 1-3.
const m = require('./proto.js'); const T = require('./tech.js');
const { ARMS, POSES, legs, placed, stepMid, P, mArms, rArms, lerp, eIO, eOut, eIn, V, add, ry, HIK_L, HIK_R } = m;
const A = ARMS, M = mArms, o = a => ({ ...a, h: 'o' });
const W3 = (S, face, v) => add(V(S[0], 0, S[2]), ry(v, face));
const half = (L, R) => ({ L: L.L || L, R: R.R || R });
// braccia per kiba-dachi e kata superiori (lato destro = +z, sinistro = -z nel riferimento del viso)
Object.assign(A, {
  hips: { L: { w: [2, 92, -18], p: [0, 1, 0], pole: [-1, -.2, -.6] }, R: { w: [2, 92, 18], p: [0, 1, 0], pole: [-1, -.2, .6] } },
  koshiR: { L: { w: [6, 96, 8], p: [0, -1, 0], pole: [-.4, -.4, -1] }, R: HIK_R },
  sideGedanR: { L: HIK_L, R: { w: [8, 74, 50], p: [0, -.3, 1], pole: [.2, -.2, 1] } },
  sideUchiR: { L: HIK_L, R: { w: [10, 124, 40], p: [0, 0, -1], pole: [0, -1, .3] } },
  sideHaishuR: { L: HIK_L, R: o({ w: [8, 124, 50], p: [0, 0, -1], pole: [0, -1, .4] }) },
  sideUraR: { L: HIK_L, R: { w: [6, 138, 52], p: [-1, 0, 0], pole: [0, -1, .2] } },
  sideZukiR: { L: HIK_L, R: { w: [6, 116, 56], p: [0, -1, 0], pole: [0, -1, .3] } },
  sideEmpiR: { L: o({ w: [10, 118, 34], p: [0, 0, -1], pole: [0, -1, .2] }), R: { w: [12, 118, 4], p: [0, -1, 0], pole: [0, -.1, 1] } },
  furiEmpiR: { L: HIK_L, R: { w: [10, 130, 14], p: [-1, 0, 0], pole: [0, -.2, 1] } },
  kagiR: { L: { w: [18, 112, -48], p: [0, -1, 0], pole: [0, -1, -.3] }, R: { w: [24, 112, -22], p: [0, -1, 0], pole: [.1, -.1, 1] } },
  gedanSideL_kagi: { L: { w: [8, 74, -50], p: [0, -.3, -1], pole: [.2, -.2, -1] }, R: HIK_R },
  nagashiUra: { L: { w: [20, 104, 6], p: [0, -1, 0], pole: [0, -.3, -1] }, R: { w: [24, 136, 30], p: [-1, 0, .2], pole: [0, -1, .3] } },
  tekkiNami: { L: { w: [20, 110, -4], p: [0, -1, 0], pole: [0, -.2, -1] }, R: { w: [10, 122, 40], p: [0, 0, -1], pole: [0, -1, .3] } },
  morZSideL: { L: { w: [8, 116, -56], p: [0, -1, 0], pole: [0, -1, -.3] }, R: { w: [26, 112, -24], p: [0, -1, 0], pole: [.1, -.1, 1] } },
  heisokuDbl: { L: A.gedan.L, R: A.uchiR.R },
  mizu: { L: { w: [28, 112, 8], p: [0, -1, 0], pole: [0, -.3, -1] }, R: HIK_R },
  ryoOsae: { L: o({ w: [34, 110, 3], p: [0, -1, 0], pole: [0, -1, -.6] }), R: o({ w: [34, 112, -3], p: [0, -1, 0], pole: [0, -1, .6] }) },
  hikiJuji: { L: { w: [6, 96, 12], p: [0, -1, 0], pole: [-1, -.4, -.3] }, R: HIK_R },
  kohoR: { L: { w: [8, 100, -20], p: [0, 1, 0], pole: [-1, 0, -.2] }, R: { w: [-12, 152, 20], p: [0, 0, -1], pole: [1, .3, .3] } },
  tettsuiSideL: { L: { w: [10, 112, -52], p: [0, -1, 0], pole: [0, -1, -.2] }, R: HIK_R },
  tateShutoSideR: { L: HIK_L, R: o({ w: [10, 124, 44], p: [-1, 0, 0], pole: [0, -1, .2] }) },
  palmEmpiR: { L: o({ w: [38, 118, -4], p: [0, 0, 1], pole: [0, -1, -.6] }), R: { w: [14, 118, -10], p: [0, -1, 0], pole: [1, 0, .3] } },
  ageShutoUchi: { L: o({ ...A.uke.L }), R: o({ w: [48, 138, 6], p: [0, 1, 0], pole: [0, -1, .6] }) },
  uraFront: { L: HIK_L, R: { w: [42, 142, 2], p: [-1, 0, 0], pole: [0, -.4, .6] } },
  reach: { L: o({ w: [46, 150, -10], p: [0, -1, 0], pole: [0, -1, -.4] }), R: o({ w: [46, 150, 10], p: [0, -1, 0], pole: [0, -1, .4] }) },
  kneePull: { L: { w: [30, 104, -6], p: [0, 1, 0], pole: [-1, -.4, -.3] }, R: { w: [30, 104, 6], p: [0, 1, 0], pole: [-1, -.4, .3] } },
  uraL_kick: { L: { w: [4, 140, -52], p: [-1, 0, 0], pole: [0, -1, -.2] }, R: HIK_R },
  sideKakeL: { L: o({ w: [10, 128, -48], p: [0, 0, 1], pole: [0, -1, -.3] }), R: HIK_R },
  mikaPalmL: { L: o({ w: [20, 120, -30], p: [0, 0, 1], pole: [0, -1, -.4] }), R: HIK_R },
  empiPalmSideL: { L: o({ w: [10, 118, -34], p: [0, 0, 1], pole: [0, -1, -.2] }), R: { w: [12, 118, -4], p: [0, -1, 0], pole: [0, -.1, -1] } },
  manjiShuto: { L: o({ w: [36, 128, -6], p: [0, 0, 1], pole: [0, -1, -.5] }), R: o({ w: [44, 72, 6], p: [0, 1, 0], pole: [0, -1, .5] }) },
  nukiteGedanR: { L: o({ w: [20, 132, -10], p: [0, 0, 1], pole: [0, -1, -.5] }), R: o({ w: [46, 76, 4], p: [0, 0, -1], pole: [0, -1, .4] }) },
  rising: { L: { w: [2, 96, -18], p: [0, 1, 0], pole: [-1, -.4, -.3] }, R: { w: [-6, 150, 24], p: [0, 0, -1], pole: [.6, .4, .4] } },
  tsukami: { L: HIK_L, R: o({ w: [10, 122, 46], p: [-1, 0, 0], pole: [0, -1, .3] }) },
  soeteUchiR: { L: o({ w: [10, 116, 18], p: [0, 0, 1], pole: [0, -1, -.4] }), R: { w: [16, 124, 38], p: [0, 0, -1], pole: [0, -1, .3] } },
  hineriR: { L: o({ w: [10, 112, 30], p: [0, -1, 0], pole: [0, -1, -.3] }), R: { w: [8, 114, 54], p: [0, 1, 0], pole: [0, -1, .2] } },
  furisuteR: { L: HIK_L, R: { w: [10, 82, 52], p: [0, 1, 0], pole: [0, -1, .3] } },
  osaeR: { L: { w: [12, 106, 18], p: [0, -1, 0], pole: [0, -.2, -1] }, R: { w: [10, 118, 38], p: [0, 0, -1], pole: [0, -1, .3] } },
  gedanFrontKiba: { L: HIK_L, R: { w: [30, 72, 10], p: [0, -.3, -1], pole: [0, -.2, 1] } },
  suiheiTwo: { L: { w: [22, 116, 14], p: [0, -1, 0], pole: [0, -.2, -1] }, R: { w: [24, 112, -14], p: [0, -1, 0], pole: [0, -.2, 1] } },
  sokumenR: { L: { w: [20, 114, 10], p: [0, -1, 0], pole: [0, -.2, -1] }, R: { w: [12, 126, 40], p: [0, 0, -1], pole: [0, -1, .3] } },
  oshiR: { L: HIK_L, R: { w: [12, 84, 46], p: [0, -1, 0], pole: [0, -.2, 1] } },
  soeteGedanR: { L: o({ w: [8, 100, 26], p: [0, 0, 1], pole: [0, -1, -.3] }), R: { w: [10, 80, 50], p: [0, -1, 0], pole: [0, -.2, 1] } }
});
// ---- costruttore
class Kata {
  constructor(start, row = ['Yoi', 'Pronti', 'hachiji-dachi']) { this.keys = [[0, start]]; this.marks = [0]; this.hit = [0]; this.kiai = []; this.rows = [row]; this.t = 1.4; this.keys.push([this.t, start]); this.cur = start; }
  _fin(nx, row, o2, tHit) { this.rows.push([row[0], row[1], row[2], o2.kiai ? 1 : 0]); if (o2.kiai) this.kiai.push([tHit, tHit + .9]); this.cur = nx; }
  // passo: la posizione si sposta, un piede resta fermo (sup)
  mv(row, type, lead, face, arms, prep, yaw, o2 = {}) {
    const sup = o2.sup || (type === 'hachi' || type === 'heisoku' ? 'R' : lead === 'L' ? 'R' : 'L');
    const nx = { ...P(yaw, arms, { lean: o2.lean || 0 }), ...T.L2(type, lead, face, [0, 0]) };
    const pl = placed(type, lead, face, sup, this.cur['a' + sup]); Object.assign(nx, { ...pl, pL: nx.pL, pR: nx.pR });
    const sl = o2.slow ? 1.8 : 1, t = this.t;
    this.marks.push(t); this.hit.push(t + 1 * sl);
    this.keys.push([t + .6 * sl, stepMid(this.cur, nx, prep || arms, yaw * .4), eIO]); this.keys.push([t + 1 * sl, nx, o2.slow ? eIO : eOut]);
    this.t += (o2.kiai ? 2.1 : 1.6) * sl; this.keys.push([this.t, nx]); this._fin(nx, row, o2, t + sl);
    return this;
  }
  // sul posto: cambiano solo braccia, anche e busto
  here(row, arms, prep, yaw, o2 = {}) {
    const c = this.cur, nx = { ...c, ...arms, yaw, lean: o2.lean || 0 };
    const sl = o2.slow ? 2 : 1, t = this.t;
    this.marks.push(t); this.hit.push(t + .7 * sl);
    if (prep) this.keys.push([t + .4 * sl, { ...nx, ...prep, yaw: (c.yaw + yaw) / 2 }, eIO]); this.keys.push([t + .7 * sl, nx, o2.slow ? eIO : eOut]);
    this.t += (o2.kiai ? 2 : 1.3) * sl; this.keys.push([this.t, nx]); this._fin(nx, row, o2, t + .7 * sl);
    return this;
  }
  // calcio della gamba g (L/R) dal piede d'appoggio, poi atterra nella posa "land" (o torna)
  kick(row, g, face, ank, land, o2 = {}) {
    const c = this.cur, s = g === 'L' ? 'R' : 'L', S = c['a' + s], sg = g === 'R' ? 1 : -1;
    const C = W3(S, face, [-4, 0, 12 * sg]); C[1] = o2.Cy || 80;
    const base = { ...c, C, face, wt: s === 'L' ? 100 : 0, stance: o2.stance || 'mae-geri', ...(o2.arms || {}), yaw: o2.yaw ?? c.yaw };
    const ch = { ...base, ['a' + g]: add(W3(C, face, [20, 0, 8 * sg]), V(0, 52, 0)), ['f' + g]: face, ['p' + g]: -55, ['kp' + g]: [1, .8, .1 * sg], lean: -4 };
    const kk = { ...base, ['a' + g]: add(W3(C, face, ank[0]), V(0, ank[1], 0)), ['f' + g]: face + (o2.footYaw || 0), ['p' + g]: o2.pitch ?? 12, ['kp' + g]: ry(o2.kp || [0, 1, .1 * sg], 0), lean: o2.lean ?? -8, ...(o2.armsHit || {}) };
    const t = this.t; this.marks.push(t); this.hit.push(t + .7);
    this.keys.push([t + .45, ch, eIO]); this.keys.push([t + .7, kk, eOut]); this.keys.push([t + 1, kk]); this.keys.push([t + 1.25, ch, eIO]);
    const nx = land ? land(S) : { ...c };
    this.keys.push([t + 1.7, nx, eOut]); this.t += o2.kiai ? 2.6 : 2.3; this.keys.push([this.t, nx]); this._fin(nx, row, o2, t + .7);
    return this;
  }
  // posa libera (tutta la figura), per passaggi particolari
  pose(row, nx, prep, o2 = {}) {
    const sl = o2.slow ? 1.8 : 1, t = this.t; this.marks.push(t); this.hit.push(t + 1 * sl);
    if (prep) this.keys.push([t + .55 * sl, prep, eIO]); this.keys.push([t + 1 * sl, nx, o2.ease || eOut]);
    this.t += (o2.kiai ? 2.1 : 1.6) * sl; this.keys.push([this.t, nx]); this._fin(nx, row, o2, t + sl);
    return this;
  }
  // legs già piazzate: utile per kiba e heisoku che si formano sul posto
  legsAt(type, lead, face, sup, at) { return placed(type, lead, face, sup, at); }
  end(rowEnd = ['Yame', 'Fine', 'hachiji-dachi'], back = true) {
    if (back) { const c = this.cur, nx = { ...P(0, A.yoi), ...placed('hachi', 'L', 0, 'R', c.aR) }; nx.face = 0; this.marks.push(this.t); this.hit.push(this.t + 1); this.keys.push([this.t + .6, stepMid(c, nx, A.hikite, 0), eIO]); this.keys.push([this.t + 1, nx, eOut]); this.t += 2.4; this.keys.push([this.t, nx]); this.rows.push(rowEnd); this.cur = nx; }
    this.t += .8; this.keys.push([this.t, this.cur]);
    return { D: this.t, keys: this.keys, marks: this.marks, hit: this.hit, kiai: this.kiai, rows: this.rows, follow: 1, thumb: this.hit[Math.min(5, this.hit.length - 1)] + .2 };
  }
}
const YOI = { ...P(0, A.yoi), ...legs('hachi', 'L', 0, [0, 0]) };
const hz = (k, face, sup) => { const c = k.cur; return { ...T.L2('heisoku', 'L', face, [0, 0]), ...placed('heisoku', 'L', face, sup, c['a' + sup]) }; };
const kbAt = (k, face, sup, at) => placed('kiba', 'L', face, sup, at || k.cur['a' + sup]);
const KATA = {};

// ---------- Heian Sandan
{
  const k = new Kata(YOI), U = mArms(A.uchiR), Ud = A.heisokuDbl, Um = M(A.heisokuDbl);
  k.mv(['1', 'Hidari chūdan uchi-uke', 'kokutsu'], 'kok', 'L', 90, U, A.uchiRPrep, -50);
  k.pose(['2', 'Migi uchi-uke e hidari gedan-barai insieme', 'heisoku'], { ...k.cur, ...hz(k, 90, 'L'), ...Ud, yaw: 0 }, { ...k.cur, ...Um, yaw: 0 });
  k.here(['3', 'Hidari uchi-uke e migi gedan-barai insieme', 'heisoku'], Um, Ud, 0);
  k.mv(['4', 'Migi chūdan uchi-uke (giro di 180°)', 'kokutsu'], 'kok', 'R', -90, A.uchiR, M(A.uchiRPrep), 50, { sup: 'L' });
  k.pose(['5', 'Hidari uchi-uke e migi gedan-barai insieme', 'heisoku'], { ...k.cur, ...hz(k, -90, 'R'), ...Um, yaw: 0 }, { ...k.cur, ...Ud, yaw: 0 });
  k.here(['6', 'Migi uchi-uke e hidari gedan-barai insieme', 'heisoku'], Ud, Um, 0);
  k.mv(['7', 'Hidari morote-uke', 'kokutsu'], 'kok', 'L', 0, M(A.morote), M(A.morotePrep), -40, { sup: 'R' });
  k.mv(['8', 'Migi shihon nukite, la sinistra preme sotto il gomito', 'zenkutsu'], 'zen', 'R', 0, A.nukite, A.nukitePrep, 20);
  k.pose(['9', 'Giro su se stessi: hidari tettsui yoko-uchi', 'kiba'], { ...k.cur, ...P(0, A.tettsuiSideL), ...kbAt(k, 270, 'R'), yaw: 0 }, { ...k.cur, yaw: 120, ...A.hikite });
  k.mv(['10', 'Migi chūdan oi-zuki', 'zenkutsu'], 'zen', 'R', 0, A.zuki, A.zukiPrep, 10, { sup: 'L', kiai: 1, lean: 3 });
  k.pose(['11', 'Giro lento in heisoku-dachi, pugni sui fianchi', 'heisoku'], { ...k.cur, ...P(0, A.hips), ...hz(k, 180, 'R') }, null, { slow: 1 });
  const fumi = (lbl, side, face) => { const sup = side === 'R' ? 'L' : 'R', c = k.cur, at = c['a' + sup];
    const nx = { ...P(0, side === 'R' ? A.furiEmpiR : M(A.furiEmpiR)), ...kbAt(k, face, sup, at) };
    const up = { ...c, ['a' + side]: add(c['a' + sup], ry(V(10, 46, side === 'R' ? 14 : -14), face)), ['kp' + side]: ry([1, .7, 0], face), wt: side === 'R' ? 0 : 100, C: [c.C[0], 88, c.C[2]], face };
    k.pose([lbl, (side === 'R' ? 'Migi' : 'Hidari') + ' fumikomi e furi-empi', 'kiba'], nx, up); };
  const ura = (lbl, side) => k.here([lbl, (side === 'R' ? 'Migi' : 'Hidari') + ' tate uraken-uchi', 'kiba'], side === 'R' ? A.sideUraR : M(A.sideUraR), side === 'R' ? A.furiEmpiR : M(A.furiEmpiR), 0);
  fumi('12', 'R', 270); ura('13', 'R'); fumi('14', 'L', 90); ura('15', 'L'); fumi('16', 'R', 270); ura('17', 'R');
  k.here(['18a', 'Migi tate shutō-uke (afferra)', 'kiba'], A.tateShutoSideR, null, 0);
  k.mv(['18b', 'Hidari oi-zuki', 'zenkutsu'], 'zen', 'L', 180, M(A.zuki), M(A.zukiPrep), -10, { sup: 'R', lean: 3 });
  k.pose(['19', 'Giro in kiba-dachi: migi tsukiage indietro e hidari ushiro-empi', 'kiba'], { ...k.cur, ...P(0, A.kohoR), ...kbAt(k, 0, 'L') });
  const c = k.cur, sh = W3([0, 0, 0], 0, [0, 0, 26]);
  k.pose(['20', 'Scivolando (yori-ashi): hidari tsukiage indietro e migi ushiro-empi', 'kiba'], { ...c, ...M(A.kohoR), aL: add(c.aL, sh), aR: add(c.aR, sh), C: add(c.C, sh) }, null, { kiai: 1 });
  KATA.heian3 = k.end();
}
// ---------- Heian Yondan
{
  const k = new Kata(YOI);
  k.mv(['1', 'Hidari haiwan-uke, destro davanti alla fronte (lento)', 'kokutsu'], 'kok', 'L', 90, A.haiwan, A.haiwanPrep, -65, { slow: 1 });
  k.mv(['2', 'Migi haiwan-uke, sinistro davanti alla fronte (lento)', 'kokutsu'], 'kok', 'R', -90, M(A.haiwan), M(A.haiwanPrep), 65, { sup: 'L', slow: 1 });
  k.mv(['3', 'Gedan jūji-uke', 'zenkutsu'], 'zen', 'L', 0, A.juji, A.jujiPrep, 0, { lean: 6 });
  k.mv(['4', 'Migi morote-uke', 'kokutsu'], 'kok', 'R', 0, A.morote, A.morotePrep, 40);
  const ashi = (lbl, g, face, armsLow, armsHit, land) => {
    const s = g === 'L' ? 'R' : 'L', S = k.cur['a' + s], sg = g === 'L' ? -1 : 1;
    const base = { ...k.cur, ...P(0, armsLow), ...placed('heisoku', 'L', face, s, S) };
    const raise = { ...base, ['a' + g]: add(S, ry(V(4, 46, -6 * sg), face)), ['kp' + g]: ry([1, .4, 0], face), wt: s === 'L' ? 100 : 0, C: [base.C[0], 92, base.C[2]], stance: 'ashi-dachi' };
    k.pose([lbl, 'In piedi su una gamba, pugni al fianco', 'ashi-dachi'], raise, null);
    const kk = { ...raise, ...armsHit, ['a' + g]: add(S, ry(V(4, 108, 74 * sg), face)), ['kp' + g]: ry([0, 1, 0], face), ['p' + g]: -10, lean: -14 * 1, stance: 'yoko-geri' };
    return kk;
  };
  let kk = ashi('5', 'L', 0, A.koshiR, A.uraL_kick);
  k.pose(['6', 'Hidari yoko-geri keage e hidari uraken', 'ashi-dachi'], kk, null, { ease: eOut });
  k.mv(['7', 'Migi mae-empi nel palmo sinistro', 'zenkutsu'], 'zen', 'L', 90, A.palmEmpiR, A.palmEmpiR, 20, { sup: 'R' });
  kk = ashi('8', 'R', 0, M(A.koshiR), M(A.uraL_kick));
  k.pose(['9', 'Migi yoko-geri keage e migi uraken', 'ashi-dachi'], kk, null, { ease: eOut });
  k.mv(['10', 'Hidari mae-empi nel palmo destro', 'zenkutsu'], 'zen', 'R', -90, M(A.palmEmpiR), M(A.palmEmpiR), -20, { sup: 'L' });
  k.mv(['11', 'Hidari gedan shutō-barai poi age-uke, migi shutō-uchi', 'zenkutsu'], 'zen', 'L', 0, A.ageShutoUchi, A.gshutoPrep, 10, { sup: 'R' });
  k.kick(['12', 'Migi jōdan mae-geri', 'ashi-dachi'], 'R', 0, [[78, 0, 6], 118], (S) => ({ ...P(10, A.uraFront), ...placed('kosa', 'R', 0, 'L', add(S, [70, 0, 0])), ...T.L2('kosa', 'R', 0, [0, 0]), ...placed('kosa', 'R', 0, 'R', add(S, [78, 0, 10])) }), { arms: A.ageShutoUchi });
  k.rows[k.rows.length - 1][1] = 'Migi jōdan mae-geri, atterra in kōsa-dachi'; 
  k.here(['13', 'Migi tate uraken-uchi', 'kosa'], A.uraFront, A.urPrep && { L: HIK_L, R: { w: [10, 120, 8], p: [0, -1, 0], pole: [0, -1, .6] } }, 10, { kiai: 1 });
  k.mv(['14', 'Kakiwake-uke (lento), giro di 135°', 'kokutsu'], 'kok', 'L', 135, A.kakiwake, A.kakiPrep, -30, { sup: 'R', slow: 1 });
  const landZ = (lead, face, arms, yaw) => (S) => ({ ...P(yaw, arms, { lean: 3 }), ...placed('zen', lead, face, lead === 'L' ? 'R' : 'L', S) });
  k.kick(['15', 'Migi jōdan mae-geri', 'ashi-dachi'], 'R', 135, [[78, 0, 6], 118], landZ('R', 135, A.zuki, 10), { arms: A.kakiwake });
  k.rows[k.rows.length - 1][1] = 'Migi jōdan mae-geri'; k.rows[k.rows.length - 1][2] = 'ashi-dachi';
  k.mv(['16', 'Migi oi-zuki', 'zenkutsu'], 'zen', 'R', 135, A.zuki, A.zukiPrep, 10, { sup: 'L', lean: 3 });
  k.here(['17', 'Hidari gyaku-zuki', 'zenkutsu'], M(A.zuki), M(A.zukiMid), -10, { lean: 3 });
  k.mv(['18', 'Kakiwake-uke (lento), giro di 90°', 'kokutsu'], 'kok', 'R', 225, A.kakiwake, A.kakiPrep, 30, { sup: 'L', slow: 1 });
  k.kick(['19', 'Hidari jōdan mae-geri', 'ashi-dachi'], 'L', 225, [[78, 0, -6], 118], landZ('L', 225, M(A.zuki), -10), { arms: A.kakiwake });
  k.mv(['20', 'Hidari oi-zuki', 'zenkutsu'], 'zen', 'L', 225, M(A.zuki), M(A.zukiPrep), -10, { sup: 'R', lean: 3 });
  k.here(['21', 'Migi gyaku-zuki', 'zenkutsu'], A.zuki, A.zukiMid, 10, { lean: 3 });
  k.mv(['22', 'Hidari morote-uke', 'kokutsu'], 'kok', 'L', 180, M(A.morote), M(A.morotePrep), -40, { sup: 'R' });
  k.mv(['23', 'Migi morote-uke', 'kokutsu'], 'kok', 'R', 180, A.morote, A.morotePrep, 40);
  k.mv(['24', 'Hidari morote-uke', 'kokutsu'], 'kok', 'L', 180, M(A.morote), M(A.morotePrep), -40);
  k.mv(['25a', 'Mani aperte in alto: afferra', 'zenkutsu'], 'zen', 'L', 180, A.reach, A.reach, 0, { sup: 'R' });
  k.kick(['25b', 'Migi hiza-geri tirando giù le mani', 'ashi-dachi'], 'R', 180, [[24, 0, 8], 60], null, { arms: A.reach, armsHit: A.kneePull, pitch: -60, kp: [1, 1.2, .1], lean: -2, kiai: 1 });
  k.mv(['26', 'Hidari shutō-uke (giro di 180°)', 'kokutsu'], 'kok', 'L', 360, A.shuto, A.shutoPrep, -65, { sup: 'R' });
  k.mv(['27', 'Migi shutō-uke', 'kokutsu'], 'kok', 'R', 360, M(A.shuto), M(A.shutoPrep), 65);
  KATA.heian4 = k.end();
}
// ---------- Heian Godan
{
  const k = new Kata(YOI), U = mArms(A.uchiR);
  k.mv(['1', 'Hidari chūdan uchi-uke', 'kokutsu'], 'kok', 'L', 90, U, A.uchiRPrep, -50);
  k.here(['2', 'Migi gyaku-zuki', 'kokutsu'], A.zuki, A.zukiMid, 0, { lean: 2 });
  k.pose(['3', 'Mizu-nagare no kamae (lento)', 'heisoku'], { ...k.cur, ...P(0, A.mizu), ...hz(k, 90, 'L') }, null, { slow: 1 });
  k.mv(['4', 'Migi chūdan uchi-uke', 'kokutsu'], 'kok', 'R', -90, A.uchiR, M(A.uchiRPrep), 50, { sup: 'L' });
  k.here(['5', 'Hidari gyaku-zuki', 'kokutsu'], M(A.zuki), M(A.zukiMid), 0, { lean: 2 });
  k.pose(['6', 'Mizu-nagare no kamae (lento)', 'heisoku'], { ...k.cur, ...P(0, M(A.mizu)), ...hz(k, -90, 'R') }, null, { slow: 1 });
  k.mv(['7', 'Migi morote-uke', 'kokutsu'], 'kok', 'R', 0, A.morote, A.morotePrep, 40, { sup: 'L' });
  k.mv(['8', 'Gedan jūji-uke', 'zenkutsu'], 'zen', 'L', 0, A.juji, A.jujiPrep, 0, { lean: 6 });
  k.here(['9', 'Jōdan jūji-uke a mani aperte', 'zenkutsu'], A.jujiJ, null, 0);
  k.here(['10', 'Mani incrociate premono in basso, al fianco destro', 'zenkutsu'], A.ryoOsae, null, 0);
  k.here(['11', 'Hidari chūdan tsuki', 'zenkutsu'], M(A.zuki), A.hikiJuji, -10, { lean: 3 });
  k.mv(['12', 'Migi oi-zuki', 'zenkutsu'], 'zen', 'R', 0, A.zuki, A.zukiPrep, 10, { kiai: 1, lean: 3 });
  k.pose(['13', 'Migi gedan-barai (giro di 180°)', 'kiba'], { ...k.cur, ...P(0, A.sideGedanR), ...kbAt(k, 90, 'R') }, null);
  k.here(['14', 'Hidari kake-uke (lento)', 'kiba'], A.sideKakeL, null, 0, { slow: 1 });
  const c = k.cur, S = c.aL;
  const mk = { ...c, ...A.mikaPalmL, aR: add(S, ry(V(14, 100, -18), 90)), kpR: ry([.3, 1, -.4], 90), wt: 100, C: [c.C[0], 86, c.C[2]], stance: 'mikazuki-geri', pR: 0, fR: 90 - 60 };
  k.pose(['15', 'Migi mikazuki-geri nel palmo sinistro', 'ashi-dachi'], mk, { ...c, ...A.mikaPalmL, aR: add(S, ry(V(-4, 60, 30), 90)), kpR: ry([.7, .6, .6], 90), wt: 100 }, { ease: eOut });
  k.pose(['16', 'Migi mae-empi nel palmo sinistro', 'kiba'], { ...k.cur, ...P(0, A.empiPalmSideL), ...placed('kiba', 'L', 90, 'L', S), ...{ aL: add(S, ry(V(0, 0, -50), 90)), aR: S }, C: (() => { const q = add(S, ry(V(0, 70, -25), 90)); return q; })(), wt: 50, stance: 'kiba-dachi' });
  k.pose(['17', 'Migi morote-uke (sguardo a destra)', 'kosa'], { ...k.cur, ...P(30, A.morote), ...placed('kosa', 'L', 0, 'L', k.cur.aL) });
  k.pose(['18', 'Migi tsukiage verso dietro', 'renoji'], { ...k.cur, ...P(0, A.rising), ...placed('renoji', 'L', 180, 'L', k.cur.aL) });
  const j = k.cur, fw = ry(V(1, 0, 0), 180), dst = add(j.aL, [fw[0] * 120, 0, fw[2] * 120]);
  const air = { ...j, ...P(0, A.jujiPrep), face: 180, C: add(lerp(j.C, add(j.C, mul3(fw, 60)), 1), [0, 30, 0]), aL: add(j.aL, [fw[0] * 60, 46, fw[2] * 60]), aR: add(j.aR, [fw[0] * 60, 46, fw[2] * 60]), kpL: ry([1, .6, 0], 180), kpR: ry([1, .6, 0], 180), stance: 'tobi' };
  k.pose(['19', 'Salto in avanti: gedan jūji-uke in kōsa-dachi', 'kosa'], { ...P(0, A.juji, { lean: 10 }), ...placed('kosa', 'L', 180, 'L', dst) }, air, { kiai: 1 });
  k.mv(['20', 'Migi morote-uke', 'zenkutsu'], 'zen', 'R', 180, A.morote, A.morotePrep, 40, { sup: 'L' });
  k.mv(['21', 'Migi gedan nukite, poi manji-uke', 'kokutsu'], 'zen', 'L', 0, A.nukiteGedanR, null, 10, { sup: 'R' });
  k.here(['21b', 'Manji-uke', 'kokutsu'], { L: M(A.manji).L, R: M(A.manji).R }, null, 60);
  k.pose(['22', 'Lento in heisoku-dachi, braccia ferme', 'heisoku'], { ...k.cur, ...hz(k, 0, 'R') }, null, { slow: 1 });
  k.mv(['23', 'Hidari gedan nukite, poi manji-uke', 'kokutsu'], 'zen', 'R', 180, M(A.nukiteGedanR), null, -10, { sup: 'L' });
  k.here(['23b', 'Manji-uke', 'kokutsu'], A.manji, null, -60);
  KATA.heian5 = k.end();
}
function mul3(a, s) { return [a[0] * s, a[1] * s, a[2] * s]; }
// ---------- Tekki (kiba-dachi verso la parte frontale; i piedi si spostano a destra e a sinistra)
const HEI = { ...P(0, { L: o({ w: [10, 84, 2], p: [-1, 0, 0], pole: [-1, -.5, -.3] }), R: o({ w: [10, 82, -2], p: [-1, 0, 0], pole: [-1, -.5, .3] }) }), ...T.L2('heisoku', 'L', 0, [0, 0]) };
const side = (k, dir, slow) => { // passo incrociato: un piede passa davanti all'altro
  const c = k.cur, g = dir > 0 ? 'L' : 'R', s = dir > 0 ? 'R' : 'L';
  const nx = { ...c, ['a' + g]: add(c['a' + s], [10, 0, dir * 4]), ['f' + g]: 0, C: add(c.C, [0, 0, dir * 22]), stance: 'kosa', wt: s === 'L' ? 30 : 70 };
  return nx;
};
const kibaOut = (k, dir) => { const c = k.cur, g = dir > 0 ? 'R' : 'L', s = dir > 0 ? 'L' : 'R'; return placed('kiba', 'L', 0, s, c['a' + s]); };
function tekkiHalf(k, d, n0, kiai) { // d = +1 verso destra, -1 verso sinistra
  const Mx = a => d > 0 ? a : M(a), hand = d > 0 ? 'Migi' : 'Hidari', other = d > 0 ? 'Hidari' : 'Migi', n = i => String(n0 + i);
  k.pose([n(0), 'Sguardo e passo incrociato verso ' + (d > 0 ? 'destra' : 'sinistra'), 'kosa'], side(k, d), null);
  k.pose([n(1), hand + ' haishu-uke (fumikomi in kiba-dachi)', 'kiba'], { ...k.cur, ...P(0, Mx(A.sideHaishuR)), ...kibaOut(k, d) });
  k.here([n(2), other + ' mae-empi nel palmo', 'kiba'], Mx(A.sideEmpiR), null, 0);
  k.here([n(3), 'Sguardo dall\'altra parte, pugni al fianco', 'kiba'], Mx(A.koshiR), null, 0);
  k.here([n(4), other + ' gedan-barai', 'kiba'], Mx(M(A.sideGedanR)), null, 0);
  k.here([n(5), hand + ' kagi-zuki', 'kiba'], Mx(A.kagiR), null, 0);
  k.pose([n(6), 'Passo incrociato lento', 'kosa'], side(k, -d), null, { slow: 1 });
  k.pose([n(7), 'Fumikomi e ' + hand.toLowerCase() + ' uchi-uke', 'kiba'], { ...k.cur, ...P(0, Mx({ L: HIK_L, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } })), ...kibaOut(k, -d) });
  k.here([n(8), hand + ' nagashi-uke e uraken, l\'altro braccio davanti al petto', 'kiba'], Mx(A.nagashiUra), null, 0);
  k.here([n(9), 'Sguardo a ' + (d > 0 ? 'sinistra' : 'destra'), 'kiba'], k.cur, null, 0);
  const nami = (lbl, g) => { const c = k.cur, up = { ...c, ['a' + g]: add(c['a' + g], [10, 30, g === 'L' ? 22 : -22]), ['p' + g]: -20, wt: g === 'L' ? 0 : 100 };
    k.pose([lbl, (g === 'L' ? 'Hidari' : 'Migi') + ' nami-gaeshi e sokumen-uke', 'kiba'], { ...c, ...(g === 'L' ? M(A.tekkiNami) : A.tekkiNami) }, up); };
  nami(n(10), d > 0 ? 'L' : 'R'); k.here([n(11), 'Sguardo dall\'altra parte', 'kiba'], k.cur, null, 0); nami(n(12), d > 0 ? 'R' : 'L');
  k.here([n(13), 'Sguardo e pugni al fianco', 'kiba'], Mx(M(A.koshiR)), null, 0);
  k.here([n(14), 'Morote-zuki laterale', 'kiba'], d > 0 ? A.morZSideL : M(A.morZSideL), null, 0, { kiai });
}
{
  const k = new Kata(HEI, ['Yoi', 'Mani sovrapposte davanti al corpo', 'heisoku']);
  tekkiHalf(k, 1, 1, 1);
  k.here(['16', 'Migi kake-uke (lento) verso destra', 'kiba'], A.sideHaishuR, null, 0, { slow: 1 });
  // seconda metà: speculare
  k.here(['17', 'Hidari mae-empi nel palmo', 'kiba'], A.sideEmpiR, null, 0);
  k.here(['18', 'Sguardo a sinistra, pugni al fianco destro', 'kiba'], A.koshiR, null, 0);
  k.here(['19', 'Hidari gedan-barai', 'kiba'], M(A.sideGedanR), null, 0);
  k.here(['20', 'Migi kagi-zuki', 'kiba'], A.kagiR, null, 0);
  const rest = new Kata(k.cur); // riusa la metà iniziale per i passi 21-29
  KATA.tekki1 = (() => { const kk = k; tekkiTail(kk); return kk.end(['Yame', 'Torna in heisoku-dachi', 'heisoku'], false); })();
}
function tekkiTail(k) {
  k.pose(['21', 'Passo incrociato lento verso sinistra', 'kosa'], side(k, -1), null, { slow: 1 });
  k.pose(['22', 'Fumikomi e hidari uchi-uke', 'kiba'], { ...k.cur, ...P(0, M({ L: HIK_L, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } })), ...kibaOut(k, -1) });
  k.here(['23', 'Hidari nagashi-uke e uraken', 'kiba'], M(A.nagashiUra), null, 0);
  k.here(['24', 'Sguardo a destra', 'kiba'], k.cur, null, 0);
  const nami = (lbl, g) => { const c = k.cur, up = { ...c, ['a' + g]: add(c['a' + g], [10, 30, g === 'L' ? 22 : -22]), wt: g === 'L' ? 0 : 100 };
    k.pose([lbl, (g === 'L' ? 'Hidari' : 'Migi') + ' nami-gaeshi e sokumen-uke', 'kiba'], { ...c, ...(g === 'L' ? M(A.tekkiNami) : A.tekkiNami) }, up); };
  nami('25', 'R'); k.here(['26', 'Sguardo a sinistra', 'kiba'], k.cur, null, 0); nami('27', 'L');
  k.here(['28', 'Sguardo a destra, pugni al fianco sinistro', 'kiba'], M(A.koshiR), null, 0);
  k.here(['29', 'Morote-zuki laterale verso destra', 'kiba'], M(A.morZSideL), null, 0, { kiai: 1 });
}
// Tekki Nidan
{
  const k = new Kata(HEI, ['Yoi', 'Heisoku-dachi, mani aperte ai fianchi', 'heisoku']);
  const half2 = (d, n0, kiai) => { const Mx = a => d > 0 ? a : M(a), n = i => String(n0 + i);
    k.pose([n(0), 'Avambracci orizzontali davanti al petto, passo incrociato (lento)', 'kosa'], { ...side(k, d), ...A.suiheiTwo }, null, { slow: 1 });
    k.pose([n(1), 'Fumikomi: sokumen-uke ' + (d > 0 ? 'destro' : 'sinistro'), 'kiba'], { ...k.cur, ...P(0, Mx(A.sokumenR)), ...kibaOut(k, d) });
    k.pose([n(2), 'Passo incrociato, avambracci verso il basso', 'kosa'], { ...side(k, d), ...Mx(A.gedanFrontKiba) });
    k.pose([n(3), 'Oshi-uke in basso di lato', 'kiba'], { ...k.cur, ...P(0, Mx(A.soeteGedanR)), ...kibaOut(k, d) }); };
  half2(1, 1); 
  k.pose(['5', 'Heisoku-dachi, avambracci orizzontali (lento)', 'heisoku'], { ...k.cur, ...A.suiheiTwo, ...placed('heisoku', 'L', 0, 'R', k.cur.aR) }, null, { slow: 1 });
  k.pose(['6', 'Fumikomi: sokumen-uke sinistro', 'kiba'], { ...k.cur, ...P(0, M(A.sokumenR)), ...kibaOut(k, -1) });
  k.pose(['7', 'Passo incrociato, avambracci verso il basso', 'kosa'], { ...side(k, -1), ...M(A.gedanFrontKiba) });
  k.pose(['8', 'Oshi-uke in basso di lato', 'kiba'], { ...k.cur, ...P(0, M(A.soeteGedanR)), ...kibaOut(k, -1) });
  const part = (d, n0, kiai) => { const Mx = a => d > 0 ? a : M(a), hand = d > 0 ? 'Migi' : 'Hidari', n = i => String(n0 + i);
    k.here([n(0), 'Sguardo, pugni al fianco', 'kiba'], Mx(M(A.koshiR)), null, 0);
    k.here([n(1), hand + ' soete uchi-uke', 'kiba'], Mx(A.soeteUchiR), null, 0);
    k.here([n(2), 'Fumikomi e mae-empi', 'kiba'], Mx(A.sideEmpiR), null, 0);
    k.here([n(3), 'Tsukami-uke, afferra (lento)', 'kiba'], Mx(A.tsukami), null, 0, { slow: 1 });
    k.here([n(4), 'Kagi-zuki', 'kiba'], d > 0 ? M(A.kagiR) : A.kagiR, null, 0);
    k.pose([n(5), 'Passo incrociato lento', 'kosa'], side(k, -d), null, { slow: 1 });
    k.pose([n(6), 'Fumikomi e uchi-uke', 'kiba'], { ...k.cur, ...P(0, Mx({ L: HIK_L, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } })), ...kibaOut(k, -d) });
    k.here([n(7), 'Nagashi-uke e uraken', 'kiba'], Mx(A.nagashiUra), null, 0, { kiai: 1 }); };
  part(1, 9); part(-1, 17);
  KATA.tekki2 = k.end(['Yame', 'Torna in heisoku-dachi', 'heisoku'], false);
}
// Tekki Sandan
{
  const k = new Kata(HEI, ['Yoi', 'Heisoku-dachi, mani sovrapposte', 'heisoku']);
  k.pose(['1', 'Kiba-dachi: hidari uchi-uke', 'kiba'], { ...k.cur, ...P(0, M({ L: HIK_L, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } })), ...legs('kiba', 'L', 0, [0, 0]) });
  k.here(['2', 'Migi uchi-uke e hidari gedan-barai', 'kiba'], { L: { w: [30, 72, -10], p: [0, -.3, 1], pole: [0, -.2, -1] }, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } }, null, 0);
  k.here(['3', 'Uchi-otoshi destro, sinistro preme', 'kiba'], A.osaeR, null, 0);
  k.here(['4', 'Migi haiwan nagashi-uke', 'kiba'], A.nagashiUra, null, 0);
  k.here(['5', 'Migi tate uraken-uchi', 'kiba'], A.uraFront, null, 0);
  k.here(['6', 'Pugni al fianco', 'kiba'], A.koshiR, null, 0);
  k.here(['7', 'Migi choku-zuki', 'kiba'], A.choku, null, 0);
  k.here(['8', 'Zenwan hineri: avambraccio destro ruota', 'kiba'], A.hineriR, null, 0);
  k.pose(['9', 'Passo incrociato lento verso destra', 'kosa'], side(k, 1), null, { slow: 1 });
  k.pose(['10', 'Oshi-uke in basso', 'kiba'], { ...k.cur, ...P(0, A.soeteGedanR), ...kibaOut(k, 1) });
  k.here(['11', 'Gedan furisute: l\'avambraccio frusta in basso', 'kiba'], A.furisuteR, null, 0);
  k.here(['12', 'Pugni al fianco', 'kiba'], A.koshiR, null, 0);
  k.here(['13', 'Migi choku-zuki', 'kiba'], A.choku, null, 0);
  k.here(['14', 'Hidari uchi-uke e migi gedan-barai', 'kiba'], M({ L: { w: [30, 72, -10], p: [0, -.3, 1], pole: [0, -.2, -1] }, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } }), null, 0);
  k.here(['15', 'Migi uchi-uke e hidari gedan-barai', 'kiba'], { L: { w: [30, 72, -10], p: [0, -.3, 1], pole: [0, -.2, -1] }, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } }, null, 0);
  k.here(['16', 'Migi nagashi-uke e uraken', 'kiba'], A.nagashiUra, null, 0, { kiai: 1 });
  k.here(['17', 'Sguardo a destra', 'kiba'], k.cur, null, 0);
  k.pose(['18', 'Passo incrociato lento', 'kosa'], side(k, 1), null, { slow: 1 });
  k.pose(['19', 'Fumikomi in kiba-dachi', 'kiba'], { ...k.cur, ...kibaOut(k, 1) });
  k.here(['20', 'Uchi-otoshi destro', 'kiba'], A.osaeR, null, 0);
  k.here(['21', 'Migi haiwan nagashi-uke', 'kiba'], A.nagashiUra, null, 0);
  k.here(['22', 'Migi tate uraken-uchi', 'kiba'], A.uraFront, null, 0);
  k.here(['23', 'Pugni al fianco', 'kiba'], A.koshiR, null, 0);
  k.here(['24', 'Migi choku-zuki', 'kiba'], A.choku, null, 0);
  k.here(['25', 'Zenwan hineri', 'kiba'], A.hineriR, null, 0);
  k.pose(['26', 'Passo incrociato lento', 'kosa'], side(k, 1), null, { slow: 1 });
  k.pose(['27', 'Oshi-uke in basso', 'kiba'], { ...k.cur, ...P(0, A.soeteGedanR), ...kibaOut(k, 1) });
  k.here(['28', 'Gedan furisute', 'kiba'], A.furisuteR, null, 0);
  k.here(['29', 'Pugni al fianco', 'kiba'], A.koshiR, null, 0);
  k.here(['30', 'Migi choku-zuki', 'kiba'], A.choku, null, 0);
  k.here(['31', 'Tsukami-uke, afferra (lento)', 'kiba'], A.tsukami, null, 0, { slow: 1 });
  k.here(['32', 'Hidari kagi-zuki', 'kiba'], M(A.kagiR), null, 0);
  k.pose(['33', 'Passo incrociato lento verso sinistra', 'kosa'], side(k, -1), null, { slow: 1 });
  k.pose(['34', 'Fumikomi e hidari uchi-uke', 'kiba'], { ...k.cur, ...P(0, M({ L: HIK_L, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } })), ...kibaOut(k, -1) });
  k.here(['35', 'Migi uchi-uke e hidari gedan-barai', 'kiba'], { L: { w: [30, 72, -10], p: [0, -.3, 1], pole: [0, -.2, -1] }, R: { w: [20, 124, 24], p: [0, 0, -1], pole: [0, -1, .3] } }, null, 0);
  k.here(['36', 'Hidari nagashi-uke e uraken', 'kiba'], M(A.nagashiUra), null, 0, { kiai: 1 });
  KATA.tekki3 = k.end(['Yame', 'Torna in heisoku-dachi', 'heisoku'], false);
}
module.exports = { Kata, KATA, A, YOI, HEI, side, kibaOut, hz, kbAt, W3 };
if (require.main === module) {
  const fs = require('fs'); const meta = fs.existsSync(__dirname + '/out/meta_kata.json') ? JSON.parse(fs.readFileSync(__dirname + '/out/meta_kata.json')) : {};
  fs.mkdirSync(__dirname + '/out/anim', { recursive: true });
  for (const [id, a] of Object.entries(KATA)) { if (id.startsWith("tekki")) a.view = "fronte"; fs.writeFileSync(__dirname + '/out/anim/' + id + '.json', JSON.stringify(m.exportAnim(id, a))); meta[id] = { marks: a.hit, rows: a.rows }; }
  fs.writeFileSync(__dirname + '/out/meta_kata.json', JSON.stringify(meta)); console.log(Object.keys(KATA).join(' '));
}
