// Nuove tecniche: posizioni, braccia e animazioni (stesso motore del prototipo).
const m = require('./proto.js');
const { ANIM, POSES, ARMS, STANCE, legs, placed, stepMid, P, mArms, mArm, rArms, eIO, eOut, eIn, V, add, ry, HIK_L, HIK_R, DEF } = m;
const o = a => ({ ...a, h: 'o' });
const GUARD = POSES.gedan, GG = POSES.guardG;
const HACHI = { ...P(0, ARMS.hikite), ...legs('hachi', 'L', 0, [0, 0]) };
const YOI = { ...P(0, ARMS.yoi), ...legs('hachi', 'L', 0, [0, 0]) };

Object.assign(STANCE, {
  heisoku: { aL: [0, 8, -6], aR: [0, 8, 6], fL: 0, fR: 0, Cy: 95, wt: 50, kpL: [1, 0, 0], kpR: [1, 0, 0], stance: 'heisoku-dachi' },
  uchihachi: { aL: [0, 8, -19], aR: [0, 8, 19], fL: -14, fR: 14, Cy: 94, wt: 50, kpL: [1, 0, .1], kpR: [1, 0, -.1], stance: 'uchi-hachiji-dachi' },
  fudo: { aL: [48, 8, -13], aR: [-50, 8, 15], fL: -12, fR: -45, Cy: 72, wt: 50, kpL: [1, 0, -.35], kpR: [.5, 0, .8], stance: 'fudo-dachi' },
  neko: { aL: [28, 13, -7], aR: [-6, 8, 8], fL: 0, fR: -35, Cy: 76, wt: 10, kpL: [1, 0, -.1], kpR: [.7, 0, .6], stance: 'neko-ashi-dachi', pL: -40 },
  sanchin: { aL: [22, 8, -15], aR: [-12, 8, 15], fL: -28, fR: 0, Cy: 88, wt: 50, kpL: [1, 0, .35], kpR: [1, 0, -.3], stance: 'sanchin-dachi' },
  hangetsu: { aL: [36, 8, -19], aR: [-30, 8, 19], fL: -30, fR: 12, Cy: 77, wt: 50, kpL: [1, 0, .4], kpR: [1, 0, -.4], stance: 'hangetsu-dachi' },
  kosa: { aL: [2, 8, 2], aR: [-12, 12, -12], fL: 25, fR: 0, Cy: 70, wt: 90, kpL: [1, 0, .1], kpR: [1, 0, -.2], stance: 'kosa-dachi', pR: -40 },
  renoji: { aL: [28, 8, -3], aR: [0, 8, 10], fL: 0, fR: -80, Cy: 93, wt: 50, kpL: [1, 0, 0], kpR: [.3, 0, 1], stance: 'renoji-dachi' },
  teiji: { aL: [30, 8, 9], aR: [0, 8, 10], fL: 0, fR: -90, Cy: 93, wt: 50, kpL: [1, 0, 0], kpR: [.3, 0, 1], stance: 'teiji-dachi' },
  tsuru: { aL: [4, 52, 2], aR: [0, 8, 7], fL: -20, fR: 0, Cy: 91, wt: 0, kpL: [1, .3, -.3], kpR: [1, 0, 0], stance: 'tsuruashi-dachi', pL: -50 },
  shiko: { aL: [-2, 8, -44], aR: [-2, 8, 44], fL: 42, fR: -42, Cy: 66, wt: 50, kpL: [.25, 0, -1], kpR: [.25, 0, 1], stance: 'shiko-dachi' }
});
// legs() non copia pL/pR dalla posizione: li aggiungiamo qui
const L2 = (type, lead, face, O) => { const s = STANCE[type], l = legs(type, lead, face, O); const pl = s.pL || 0, pr = s.pR || 0; return { ...l, pL: lead === 'R' ? pr : pl, pR: lead === 'R' ? pl : pr }; };
const ST = (type, arms, yaw = 0, ex = {}) => ({ ...P(yaw, arms || ARMS.hikite), ...L2(type, 'L', 0, [0, 0]), ...ex });

// braccia nuove (sinistra = mano che para, posizione con il piede sinistro avanti)
Object.assign(ARMS, {
  juji: { L: { w: [40, 70, 3], p: [0, -.4, -.9], pole: [0, -1, -1] }, R: { w: [40, 72, -3], p: [0, -.4, .9], pole: [0, -1, 1] } },
  jujiPrep: { L: { w: [14, 96, -14], p: [0, 1, 0], pole: [-1, -.4, -.3] }, R: { w: [14, 96, 14], p: [0, 1, 0], pole: [-1, -.4, .3] } },
  jujiJ: { L: o({ w: [26, 152, 3], p: [1, 0, -.3], pole: [0, -1, -1] }), R: o({ w: [26, 150, -3], p: [1, 0, .3], pole: [0, -1, 1] }) },
  kakiwake: { L: { w: [30, 124, -24], p: [-.85, 0, .3], pole: [0, -1, -.1] }, R: { w: [30, 124, 24], p: [-.85, 0, -.3], pole: [0, -1, .1] } },
  kakiPrep: { L: { w: [20, 100, 6], p: [-1, 0, 0], pole: [0, -1, -.3] }, R: { w: [22, 104, -6], p: [-1, 0, 0], pole: [0, -1, .3] } },
  haishu: { L: o({ w: [30, 130, -36], p: [-.3, 0, 1], pole: [0, -1, -.4] }), R: HIK_R },
  haishuPrep: { L: o({ w: [16, 100, 14], p: [0, 1, 0], pole: [0, -1, -.5] }), R: HIK_R },
  nagashi: { L: HIK_L, R: o({ w: [26, 138, -10], p: [0, 0, -1], pole: [0, -1, .6] }) },
  nagashiPrep: { L: HIK_L, R: o({ w: [30, 128, 22], p: [0, 0, -1], pole: [0, -1, .6] }) },
  osae: { L: o({ w: [32, 98, 4], p: [0, -1, 0], pole: [0, -.3, -1] }), R: HIK_R },
  osaePrep: { L: o({ w: [26, 118, -6], p: [0, -1, 0], pole: [0, -.3, -1] }), R: HIK_R },
  otoshi: { L: { w: [40, 98, 0], p: [0, -.5, .85], pole: [0, -.4, -1] }, R: HIK_R },
  otoshiPrep: { L: { w: [20, 140, -10], p: [0, 0, 1], pole: [0, -1, -.6] }, R: HIK_R },
  sukui: { L: o({ w: [38, 96, 8], p: [0, 1, .2], pole: [0, -1, -.5] }), R: HIK_R },
  sukuiPrep: { L: o({ w: [30, 66, -24], p: [0, 0, 1], pole: [0, -.5, -1] }), R: HIK_R },
  teishoU: { L: o({ w: [40, 108, 2], p: [1, -.2, .2], pole: [0, -1, -.5] }), R: HIK_R },
  teishoUPrep: { L: o({ w: [10, 112, -16], p: [0, 0, 1], pole: [-.4, -1, -.4] }), R: HIK_R },
  kake: { L: o({ w: [40, 128, -14], p: [.3, 0, -1], pole: [0, -1, -.6] }), R: HIK_R },
  kakePrep: { L: o({ w: [18, 108, 14], p: [0, 0, 1], pole: [0, -1, -.4] }), R: HIK_R },
  manji: { L: { w: [40, 62, -18], p: [0, -.6, .8], pole: [.3, -.2, -1] }, R: { w: [-4, 152, 30], p: [-.6, 0, -.8], pole: [-.4, -.6, 1] } },
  manjiPrep: { L: { w: [10, 132, 16], p: [0, 0, -1], pole: [0, -1, -.4] }, R: { w: [30, 80, -6], p: [0, -1, 0], pole: [0, -1, .5] } },
  gshuto: { L: o({ w: [44, 62, -14], p: [0, -.3, 1], pole: [.3, -.3, -1] }), R: o({ w: [16, 102, 2], p: [0, 1, 0], pole: [-1, -.4, .4] }) },
  gshutoPrep: { L: o({ w: [6, 132, 14], p: [0, 0, -1], pole: [.2, -1, -.4] }), R: o({ w: [44, 84, 2], p: [0, -1, 0], pole: [0, -1, .5] }) },
  tateShuto: { L: o({ w: [44, 120, -2], p: [0, .4, 1], pole: [0, -1, -.3] }), R: HIK_R },
  tateShutoPrep: { L: o({ w: [14, 116, 14], p: [0, 0, 1], pole: [0, -1, -.4] }), R: HIK_R },
  mawashiU: { L: o({ w: [42, 124, -6], p: [1, 0, 0], pole: [0, -1, -.5] }), R: o({ w: [42, 92, 6], p: [1, 0, 0], pole: [0, -1, .5] }) },
  mawashiUPrep: { L: o({ w: [30, 96, -10], p: [0, 1, 0], pole: [0, -1, -.4] }), R: o({ w: [30, 128, 10], p: [0, -1, 0], pole: [0, -1, .4] }) },
  // pugni (mano destra che colpisce)
  choku: { L: HIK_L, R: { w: [62, 120, 0], p: [0, -1, 0], pole: [0, -1, .6] } },
  chokuL: { L: { w: [62, 120, 0], p: [0, -1, 0], pole: [0, -1, -.6] }, R: HIK_R },
  tate: { L: HIK_L, R: { w: [58, 114, 0], p: [0, 0, -1], pole: [0, -1, .3] } },
  age: { L: HIK_L, R: { w: [40, 140, 0], p: [-1, 0, -.4], pole: [.2, -1, .2] } },
  ageMid: { L: HIK_L, R: { w: [16, 102, 12], p: [0, 1, 0], pole: [-.6, -1, .4] } },
  mawZ: { L: HIK_L, R: { w: [42, 128, -14], p: [0, -1, 0], pole: [0, -.2, 1] } },
  mawZPrep: { L: HIK_L, R: { w: [18, 110, 26], p: [0, 0, -1], pole: [-.5, -.6, 1] } },
  kagi: { L: HIK_L, R: { w: [24, 112, -24], p: [0, -1, 0], pole: [.1, -.1, 1] } },
  morZ: { L: { w: [58, 114, -9], p: [0, -1, 0], pole: [0, -1, -.6] }, R: { w: [58, 114, 9], p: [0, -1, 0], pole: [0, -1, .6] } },
  morZPrep: { L: HIK_L, R: HIK_R },
  yama: { L: { w: [40, 88, 4], p: [0, 1, 0], pole: [-1, -.6, -.2] }, R: { w: [58, 142, 0], p: [0, -1, 0], pole: [0, -1, .6] } },
  yamaPrep: { L: { w: [4, 90, 20], p: [0, 1, 0], pole: [-1, -.4, .3] }, R: { w: [2, 112, 22], p: [0, -1, 0], pole: [-1, -.4, .3] } },
  hasami: { L: { w: [42, 130, -12], p: [0, 0, 1], pole: [0, -.4, -1] }, R: { w: [42, 130, 12], p: [0, 0, -1], pole: [0, -.4, 1] } },
  hasamiPrep: { L: { w: [20, 112, -30], p: [0, 0, 1], pole: [-.4, -.4, -1] }, R: { w: [20, 112, 30], p: [0, 0, -1], pole: [-.4, -.4, 1] } },
  ippon: { L: HIK_L, R: { w: [60, 134, 0], p: [0, -1, 0], pole: [0, -1, .6] } },
  // percosse
  haito: { L: HIK_L, R: o({ w: [48, 142, -8], p: [0, -1, 0], pole: [0, -.3, 1] }) },
  haitoPrep: { L: { w: [40, 104, -6], p: [0, -1, 0], pole: [0, -1, -.5] }, R: o({ w: [-6, 128, 34], p: [0, 1, 0], pole: [-.5, -.5, 1] }) },
  haishuU: { L: HIK_L, R: o({ w: [40, 138, 36], p: [-.3, 0, -1], pole: [0, -1, .4] }) },
  haishuUPrep: { L: { w: [40, 104, -6], p: [0, -1, 0], pole: [0, -1, -.5] }, R: o({ w: [16, 112, -18], p: [0, 1, 0], pole: [0, -1, .5] }) },
  teishoZ: { L: HIK_L, R: o({ w: [60, 118, 0], p: [1, 0, 0], pole: [0, -1, .5] }) },
  uchiShuto: { L: HIK_L, R: o({ w: [48, 140, -4], p: [0, 1, 0], pole: [0, -1, .6] }) },
  uchiShutoPrep: { L: { w: [40, 104, -6], p: [0, -1, 0], pole: [0, -1, -.5] }, R: o({ w: [12, 110, -18], p: [0, -1, 0], pole: [0, -1, .7] }) },
  ageEmpi: { L: HIK_L, R: { w: [14, 150, 2], p: [-1, 0, 0], pole: [1, .6, .2] } },
  yokoEmpi: { L: { w: [14, 118, 8], p: [0, -1, 0], pole: [0, -.2, -1] }, R: { w: [8, 116, 10], p: [0, -1, 0], pole: [.1, -.1, 1] } },
  yokoEmpiPrep: { L: { w: [30, 116, 26], p: [0, 0, -1], pole: [0, -1, -.4] }, R: HIK_R },
  ushiroEmpi: { L: { w: [36, 110, -4], p: [0, -1, 0], pole: [0, -1, -.6] }, R: { w: [6, 100, 20], p: [0, 1, 0], pole: [-1, -.1, .3] } },
  ushiroEmpiPrep: { L: HIK_L, R: { w: [56, 112, 4], p: [0, 1, 0], pole: [0, -1, .6] } }
});
const A = ARMS;
// tecnica sul posto: guardia → preparazione → tecnica → tieni → guardia
function onSpot(start, prep, fin, o2 = {}) {
  const D = o2.D || 3.4;
  return { D, keys: [[0, start], [.6, start], [1.1, prep, eIO], [1.45, fin, eOut], [2.7, fin], [D, start, eIO]], marks: [0, .6, 1.1, 1.45], view: o2.view };
}
function stanceAnim(from, to, o2 = {}) {
  return { D: 3.6, keys: [[0, from], [.8, from], [1.6, to, eIO], [2.8, to], [3.4, from, eIO], [3.6, from]], marks: [0, .8, 1.2, 1.6], view: o2.view };
}
const Z = (yaw, arms, ex) => P(yaw, arms, ex);          // zenkutsu, piede sinistro avanti
const K = (type, yaw, arms, ex) => ST(type, arms, yaw, ex);
const NEW = {};
// ---- posizioni
NEW.hachiji = stanceAnim(K('heisoku', 0, A.open), YOI);
NEW.heisoku = stanceAnim(HACHI, K('heisoku', 0, A.hikite));
NEW.uchihachi = stanceAnim(HACHI, K('uchihachi', 0, A.yoi));
NEW.fudo = stanceAnim(HACHI, K('fudo', -30, A.gedan));
NEW.neko = stanceAnim(HACHI, K('neko', -45, A.guardG));
NEW.sanchin = stanceAnim(HACHI, K('sanchin', -10, mArms(A.uchiR)));
NEW.hangetsu = stanceAnim(HACHI, K('hangetsu', -20, mArms(A.uchiR)));
NEW.kosa = stanceAnim(HACHI, K('kosa', -20, A.hikite));
NEW.renoji = stanceAnim(HACHI, K('renoji', -30, A.yoi));
NEW.teiji = stanceAnim(HACHI, K('teiji', -30, A.yoi));
NEW.tsuru = stanceAnim(HACHI, K('tsuru', 0, A.hikite));
NEW.shiko = stanceAnim(HACHI, K('shiko', 0, A.hikite));
// ---- parate
const KK = (yaw, arms) => ({ ...P(yaw, arms), ...placed('kok', 'L', 0, 'R', [0, 8, 20]) });
NEW.morote = onSpot(KK(-65, A.hikite), KK(-40, mArms(A.morotePrep)), KK(-30, mArms(A.morote)));
NEW.juji = onSpot(GUARD, Z(-10, A.jujiPrep), Z(0, A.juji, { lean: 6 }));
NEW.jujij = onSpot(GUARD, Z(-10, A.jujiPrep), Z(0, A.jujiJ));
NEW.kakiwake = onSpot(KK(-65, A.hikite), KK(-40, A.kakiPrep), KK(-30, A.kakiwake));
NEW.haiwan = onSpot(KK(-65, A.hikite), KK(-40, A.haiwanPrep), KK(-65, A.haiwan));
NEW.haishu = onSpot(KK(-65, A.hikite), KK(-40, A.haishuPrep), KK(-65, A.haishu));
NEW.nagashi = onSpot(GUARD, Z(-30, A.nagashiPrep), Z(-10, A.nagashi));
NEW.osae = onSpot(GUARD, Z(-30, A.osaePrep), Z(-40, A.osae));
NEW.otoshi = onSpot(GUARD, Z(-30, A.otoshiPrep), Z(-45, A.otoshi));
NEW.sukui = onSpot(GUARD, Z(-30, A.sukuiPrep), Z(-45, A.sukui));
NEW.teishou = onSpot(GUARD, Z(-30, A.teishoUPrep), Z(-45, A.teishoU));
NEW.kake = onSpot(GG, Z(-30, A.kakePrep), Z(-55, A.kake));
NEW.manji = onSpot(KK(-65, A.hikite), KK(-40, A.manjiPrep), KK(-70, A.manji));
NEW.gshuto = onSpot(KK(-65, A.hikite), KK(-40, A.gshutoPrep), KK(-65, A.gshuto));
NEW.tateshuto = onSpot(GUARD, Z(-30, A.tateShutoPrep), Z(-50, A.tateShuto));
NEW.mawashiu = onSpot(GUARD, Z(-20, A.mawashiUPrep), Z(-10, A.mawashiU));
// ---- pugni
const HZ = arms => ({ ...P(0, arms), ...legs('hachi', 'L', 0, [0, 0]) });
NEW.choku = { D: 3.6, keys: [[0, HZ(A.hikite)], [.6, HZ(A.hikite)], [.85, HZ(A.choku), eOut], [1.6, HZ(A.choku)], [1.85, HZ(A.chokuL), eOut], [2.6, HZ(A.chokuL)], [3.2, HZ(A.hikite), eIO], [3.6, HZ(A.hikite)]], marks: [0, .6, .85, 1.85] };
NEW.tate = onSpot(GG, Z(-20, A.zukiMid), Z(-5, A.tate, { lean: 3 }), { D: 3 });
NEW.agez = onSpot(GG, Z(-25, A.ageMid), Z(5, A.age, { lean: 2 }), { D: 3 });
NEW.mawz = onSpot(GG, Z(-30, A.mawZPrep), Z(15, A.mawZ, { lean: 3 }), { D: 3 });
NEW.kagi = onSpot({ ...P(0, A.hikite), ...legs('kiba', 'L', 0, [0, 0]) }, { ...P(0, A.hikite), ...legs('kiba', 'L', 0, [0, 0]) }, { ...P(-10, A.kagi), ...legs('kiba', 'L', 0, [0, 0]) });
NEW.morz = onSpot(GUARD, Z(-10, A.morZPrep), Z(0, A.morZ, { lean: 4 }));
NEW.yama = onSpot(GUARD, Z(40, A.yamaPrep), Z(-10, A.yama, { lean: 10 }));
NEW.hasami = onSpot(GUARD, Z(0, A.hasamiPrep), Z(0, A.hasami, { lean: 3 }));
NEW.ippon = onSpot(GG, Z(-20, A.zukiMid), Z(5, A.ippon, { lean: 4 }), { D: 3 });
// ---- percosse
NEW.tettsui = onSpot(GUARD, Z(-30, A.tetPrep), Z(10, A.tettsui, { lean: 2 }));
NEW.haito = onSpot(GUARD, Z(-50, A.haitoPrep), Z(20, A.haito, { lean: 3 }));
NEW.haishuu = onSpot(GUARD, Z(-20, A.haishuUPrep), Z(-10, A.haishuU));
NEW.teishoz = onSpot(GG, Z(-20, A.zukiMid), Z(5, A.teishoZ, { lean: 5 }), { D: 3 });
NEW.uchishuto = onSpot(GUARD, Z(-30, A.uchiShutoPrep), Z(20, A.uchiShuto, { lean: 3 }));
NEW.ageempi = onSpot(GG, Z(-25, A.ageMid), Z(15, A.ageEmpi, { lean: 2 }), { D: 3 });
const KB = (yaw, arms) => ({ ...P(yaw, arms), ...legs('kiba', 'L', 0, [0, 0]) });
NEW.yokoempi = onSpot(KB(0, A.hikite), KB(-25, A.yokoEmpiPrep), KB(20, A.yokoEmpi));
NEW.ushiroempi = onSpot(Z(-10, A.zuki), Z(-5, A.ushiroEmpiPrep), Z(-40, A.ushiroEmpi));

// ---- calci (gamba destra, dalla guardia con il sinistro avanti)
const KG = (ex) => ({ ...GG, ...ex });
const ch = KG({ C: [12, 80, 0], yaw: -10, lean: -4, aR: [30, 52, 10], fR: 0, pR: -55, kpR: [1, .8, .1], wt: 100, stance: 'mae-geri' });
NEW.maekekomi = { D: 3.8, keys: [[0, GG], [.7, GG], [1.05, ch, eIO], [1.35, KG({ C: [18, 80, 0], yaw: 0, lean: -12, aR: [92, 98, 8], fR: 0, pR: 35, kpR: [0, 1, .1], wt: 100, stance: 'mae-geri' }), eOut], [1.8, KG({ C: [18, 80, 0], yaw: 0, lean: -12, aR: [92, 98, 8], fR: 0, pR: 35, kpR: [0, 1, .1], wt: 100, stance: 'mae-geri' })], [2.1, ch, eIO], [2.6, GG, eIO], [3.8, GG]], marks: [0, .7, 1.05, 1.35, 2.1] };
const mkCh = KG({ C: [8, 80, 0], yaw: -20, lean: -4, aR: [0, 70, 46], fR: 0, pR: -20, kpR: [.6, .5, .6], wt: 100, stance: 'mikazuki-geri' });
const mkHit = KG({ C: [10, 80, 0], yaw: 10, lean: -8, aR: [66, 118, -6], fR: -60, pR: 0, kpR: [0, 1, -.2], wt: 100, stance: 'mikazuki-geri', L: o({ w: [46, 122, -2], p: [0, 0, 1], pole: [0, -1, -.5] }) });
NEW.mikazuki = { D: 3.6, keys: [[0, GG], [.7, GG], [1.05, mkCh, eIO], [1.35, mkHit, eOut], [1.7, mkHit], [2.1, KG({ ...ch, yaw: 0 }), eIO], [2.6, GG, eIO], [3.6, GG]], marks: [0, .7, 1.05, 1.35, 2.1] };
const umCh = KG({ C: [6, 80, 0], yaw: -60, lean: -6, aR: [14, 66, -26], fR: -80, pR: -20, kpR: [.6, .6, -.6], fL: -40, wt: 100, stance: 'ura-mawashi-geri' });
const umHit = KG({ C: [6, 80, 0], yaw: -70, lean: -14, aR: [70, 124, 30], fR: -90, pR: 10, kpR: [0, 1, .3], fL: -50, wt: 100, stance: 'ura-mawashi-geri' });
NEW.uramawashi = { D: 3.6, keys: [[0, GG], [.7, GG], [1.05, umCh, eIO], [1.35, umHit, eOut], [1.65, umHit], [1.95, umCh, eIO], [2.5, GG, eIO], [3.6, GG]], marks: [0, .7, 1.05, 1.35, 1.95] };
const KBF = { ...P(0, ARMS.hikite), ...legs('kiba', 'L', 0, [0, 0]) };
const fmCh = { ...KBF, C: [0, 84, -8], lean: -4, aR: [6, 60, 22], fR: -40, pR: 0, kpR: [1, .7, .5], wt: 100, stance: 'fumikomi' };
const fmHit = { ...KBF, C: [0, 72, -4], aR: [16, 8, 38], fR: -70, pR: 0, wt: 70, stance: 'fumikomi' };
NEW.fumikomi = { D: 3.4, keys: [[0, KBF], [.7, KBF], [1.1, fmCh, eIO], [1.35, fmHit, eIn], [1.9, fmHit], [2.6, KBF, eIO], [3.4, KBF]], marks: [0, .7, 1.1, 1.35] };
const hzHit = KG({ C: [14, 82, 0], yaw: -5, lean: -2, aR: [24, 58, 8], fR: 0, pR: -60, kpR: [1, 1, .1], wt: 100, stance: 'hiza-geri', L: { w: [40, 150, -6], p: [0, -1, 0], pole: [0, -1, -.4] }, R: { w: [40, 150, 6], p: [0, -1, 0], pole: [0, -1, .4] } });
const hzPull = KG({ ...hzHit, aR: [36, 66, 8], kpR: [1, 1.6, .1], L: { w: [36, 106, -6], p: [0, 1, 0], pole: [-1, -.4, -.3] }, R: { w: [36, 106, 6], p: [0, 1, 0], pole: [-1, -.4, .3] } });
NEW.hiza = { D: 3.2, keys: [[0, GG], [.6, GG], [.95, hzHit, eIO], [1.2, hzPull, eOut], [1.8, hzPull], [2.4, GG, eIO], [3.2, GG]], marks: [0, .6, .95, 1.2] };
// nidan-geri: salto, calcia prima il destro poi il sinistro in aria
const air = (ex) => KG({ C: [14, 104, 0], wt: 50, stance: 'nidan-geri', ...ex });
const n1 = air({ aR: [30, 74, 10], pR: -55, kpR: [1, .8, .1], aL: [-6, 30, -12], kpL: [1, .3, -.1], lean: -4 });
const n2 = air({ aR: [24, 38, 10], kpR: [1, .2, .1], aL: [92, 128, -8], pL: 15, fL: 0, kpL: [0, 1, -.1], lean: -12, yaw: 10 });
const n1b = air({ aR: [24, 38, 10], kpR: [1, .2, .1], aL: [30, 70, -10], pL: -55, fL: 0, kpL: [1, .8, -.1], lean: -6 });
const land = { ...P(-45, ARMS.guardG), ...legs('zen', 'L', 0, [30, 0]) };
NEW.nidan = { D: 4, keys: [[0, GG], [.7, GG], [1, KG({ C: [0, 70, 0], lean: 6 }), eIO], [1.3, n1, eOut], [1.5, air({ aR: [90, 116, 8], pR: 15, fR: 0, kpR: [0, 1, .1], aL: [-6, 34, -12], kpL: [1, .3, -.1], lean: -10 }), eOut], [1.7, n1b, eIO], [1.9, n2, eOut], [2.2, n1b, eIO], [2.6, land, eIn], [4, land]], marks: [0, .7, 1.3, 1.5, 1.9, 2.6] };
const ushPivot = rArms(ARMS.guardG, 0);
const umwA = KG({ yaw: 90, C: [4, 78, 0], fL: 120, ...rArms(ARMS.guardG, 120) });
const umwCh = KG({ yaw: 170, C: [6, 82, -4], fL: 160, aR: [-4, 74, -36], fR: 180, pR: -10, kpR: [-.4, .6, -.6], wt: 100, lean: -12, stance: 'ushiro-mawashi-geri', ...rArms(ARMS.guardG, 170) });
const umwHit = KG({ yaw: 200, C: [6, 82, -4], fL: 180, aR: [64, 126, -36], fR: 270, pR: 0, kpR: [.2, 1, -.4], wt: 100, lean: -18, stance: 'ushiro-mawashi-geri', ...rArms(ARMS.guardG, 200) });
NEW.ushiromawashi = { D: 4, keys: [[0, GG], [.7, GG], [1, umwA, eIO], [1.3, umwCh, eIO], [1.6, umwHit, eOut], [1.85, umwHit], [2.2, KG({ ...umwCh, yaw: 240 }), eIO], [2.8, KG({ ...GG, face: 0 }), eIO], [4, GG]], marks: [0, .7, 1, 1.6, 2.2] };
const KIBAY2 = { ...P(90, rArms(ARMS.hikite, 90)), ...legs('kiba', 'L', 0, [0, 0]), face: -90, yaw: 90, stance: 'kiba-dachi' };
const ytUp = { ...KIBAY2, C: [0, 100, -8], aL: [-2, 40, -26], kpL: [1, .6, 0], aR: [4, 62, 6], fR: 0, pR: -20, kpR: [1, .6, 0], wt: 50, lean: -8, stance: 'yoko-tobi-geri' };
const ytHit = { ...ytUp, aR: [2, 112, 86], pR: -10, kpR: [0, 1, 0], lean: -18, R: { w: [58, 138, -4], p: [-1, 0, 0], pole: [0, -1, 0] } };
const ytLand = { ...KIBAY2, C: [0, 70, 30] , aL: [-2, 8, -10], aR: [-2, 8, 70] };
NEW.yokotobi = { D: 4, keys: [[0, KIBAY2], [.7, KIBAY2], [1, { ...KIBAY2, C: [0, 66, 0] }, eIO], [1.3, ytUp, eOut], [1.55, ytHit, eOut], [1.85, ytHit], [2.1, ytUp, eIO], [2.5, ytLand, eIn], [4, ytLand]], marks: [0, .7, 1.3, 1.55, 2.1], view: 'fronte' };
const ngA = { ...KIBAY2 };
const ngUp = { ...KIBAY2, C: [0, 72, 4], aL: [12, 40, 2], fL: -60, pL: -30, kpL: [1, .5, .4], wt: 0, stance: 'nami-gaeshi' };
NEW.namigaeshi = { D: 3.4, keys: [[0, ngA], [.7, ngA], [1.1, ngUp, eOut], [1.4, ngUp], [1.9, ngA, eIO], [3.4, ngA]], marks: [0, .7, 1.1, 1.9], view: 'fronte' };
// ---- kumite di base (parte di chi difende, o sequenza tipo)
const BC = m.buildCombo;
NEW.gohon = BC([['b', 'age'], ['b', 'age'], ['b', 'age'], ['b', 'age'], ['b', 'age'], ['s', 'gyaku', 1]]);
NEW.sanbon = BC([['b', 'age'], ['b', 'soto'], ['b', 'gedan'], ['s', 'gyaku', 1]]);
NEW.kihonippon = BC([['b', 'age'], ['s', 'gyaku', 1], ['b', 'soto'], ['s', 'gyaku', 1], ['b', 'gedan'], ['s', 'gyaku', 1]]);
NEW.jiyuippon = BC([['b', 'soto'], ['s', 'gyaku', 1], ['b', 'gedan'], ['s', 'gyaku', 1]]);
NEW.jiyu = BC([['s', 'kizami'], ['s', 'gyaku', 1], ['f', 'oi'], ['b', 'gedan'], ['s', 'gyaku', 1]]);
NEW.mikazuki.view = 'lato'; NEW.uramawashi.view = 'fronte';
module.exports = { NEW, ARMS, STANCE, L2, ST, onSpot, stanceAnim, Z, K, KK, KB, HZ, HACHI, YOI, GUARD, GG };
if (require.main === module) {
  const fs = require('fs');
  fs.mkdirSync(__dirname + '/out/anim', { recursive: true });
  for (const [id, a] of Object.entries(NEW)) fs.writeFileSync(__dirname + '/out/anim/' + id + '.json', JSON.stringify(m.exportAnim(id, a)));
  const meta = {}; for (const [id, a] of Object.entries(NEW)) meta[id] = { marks: a.hit || a.marks, rows: a.rows || null };
  fs.writeFileSync(__dirname + '/out/meta.json', JSON.stringify(meta));
  console.log(Object.keys(NEW).length, 'animazioni');
}
