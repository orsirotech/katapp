import 'dart:math' as math;

import 'vec.dart';

/// Tavola di riferimento: 480 × 540, la figura nei primi 360, i riquadri sotto.
const double kW = 480, kH = 540, kMainH = 360;
const double kScale = 1.75, kOx = 236;

class ViewSpec {
  final String id, label;
  final double phi, eps, oy;
  const ViewSpec(this.id, this.label, this.phi, this.eps, this.oy);
}

const views = <String, ViewSpec>{
  '34': ViewSpec('34', '3/4', 35, 10, 338),
  'lato': ViewSpec('lato', 'lato', 0, 4, 338),
  'fronte': ViewSpec('fronte', 'fronte', 90, 6, 338),
  'alto': ViewSpec('alto', "dall'alto", 0, 68, 232),
};

class P2 {
  final double x, y, d; // d = profondità verso la camera
  const P2(this.x, this.y, [this.d = 0]);
}

class Camera {
  final ViewSpec v;
  final double ctX, ctZ;
  const Camera(this.v, [this.ctX = 0, this.ctZ = 0]);

  P2 proj(V3 p) {
    final c = math.cos(rad(v.phi)), s = math.sin(rad(v.phi)), px = p.x - ctX, pz = p.z - ctZ;
    final x = px * c - pz * s, z = px * s + pz * c, ce = math.cos(rad(v.eps)), se = math.sin(rad(v.eps));
    return P2(kOx + x * kScale, v.oy - p.y * ce * kScale + z * se * kScale, z * ce + p.y * se);
  }

  /// Direzione verso la camera.
  V3 get viewDir {
    final c = math.cos(rad(v.phi)), s = math.sin(rad(v.phi));
    return V3(s * math.cos(rad(v.eps)), math.sin(rad(v.eps)), c * math.cos(rad(v.eps))).unit;
  }
}
