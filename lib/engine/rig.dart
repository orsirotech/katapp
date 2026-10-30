import 'dart:math' as math;

import 'pose.dart';
import 'vec.dart';

class ArmState {
  final V3 sh, el, wr, f, p;
  final int side;
  final bool open;
  const ArmState(this.sh, this.el, this.wr, this.f, this.p, this.side, this.open);
}

/// Il manichino risolto in 3D: articolazioni e orientamenti (come `body` del prototipo).
class Body {
  final V3 c, up, fw, sd, hipL, hipR, shL, shR, kneeL, kneeR, ankL, ankR, footL, footR, head, faceDir, sideDir;
  final ArmState l, r;
  final double face, wt, yw;
  final String stance;

  const Body({
    required this.c, required this.up, required this.fw, required this.sd, required this.hipL, required this.hipR, required this.shL, required this.shR,
    required this.kneeL, required this.kneeR, required this.ankL, required this.ankR, required this.footL, required this.footR, required this.head,
    required this.faceDir, required this.sideDir, required this.l, required this.r, required this.face, required this.wt, required this.yw, required this.stance,
  });

  V3 at(double h) => c + up * h;
}

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

Body solveBody(Pose p) {
  final face = _d(p['face']), yaw = _d(p['yaw']), lean = _d(p['lean']);
  V3 rot(V3 v) => ry(v, face);
  final yw = face + yaw, c = V3.of(p['C'] as List), dy = c.y - 78;
  final up = rot(V3(math.sin(rad(lean)), math.cos(rad(lean)), 0)).unit, fw = ry(const V3(1, 0, 0), yw), sd = ry(const V3(0, 0, 1), yw);
  V3 at(double h) => c + up * h;
  final hipL = c + sd * -12, hipR = c + sd * 12;
  final shL = at(46) + sd * -18, shR = at(46) + sd * 18;
  final legL = ik(hipL, V3.of(p['aL'] as List), 44, 44, rot(V3.of(p['kpL'] as List))), legR = ik(hipR, V3.of(p['aR'] as List), 44, 44, rot(V3.of(p['kpR'] as List)));
  V3 foot(double yawF, double pitch) {
    final d = ry(const V3(1, 0, 0), yawF);
    return (d * math.cos(rad(pitch)) + V3(0, math.sin(rad(pitch)), 0)).unit;
  }

  ArmState arm(V3 sh, Map a, int side) {
    final res = ik(sh, V3(c.x, dy, c.z) + rot(V3.of(a['w'] as List)), 30, 27, rot(V3.of(a['pole'] as List)));
    final f = (res.end - res.mid).unit;
    var pv = rot(V3.of(a['p'] as List));
    if (pv.length < .3) pv = pv + V3(0, 0, .5 * side);
    final pn = (pv - f * pv.dot(f)).unit;
    return ArmState(sh, res.mid, res.end, f, pn, side, a['h'] == 'o');
  }

  return Body(
    c: c, up: up, fw: fw, sd: sd, hipL: hipL, hipR: hipR, shL: shL, shR: shR,
    kneeL: legL.mid, kneeR: legR.mid, ankL: legL.end, ankR: legR.end,
    footL: foot(_d(p['fL']), _d(p['pL'])), footR: foot(_d(p['fR']), _d(p['pR'])),
    l: arm(shL, p['L'] as Map, -1), r: arm(shR, p['R'] as Map, 1),
    head: at(64), faceDir: rot(const V3(1, 0, 0)), sideDir: rot(const V3(0, 0, 1)),
    face: face, wt: _d(p['wt']), yw: yw, stance: (p['stance'] as String?) ?? '',
  );
}
