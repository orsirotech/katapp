import 'dart:math' as math;

/// Vettore 3D in centimetri: x avanti, y su, z a destra del karateka.
class V3 {
  final double x, y, z;
  const V3(this.x, this.y, this.z);

  factory V3.of(List<dynamic> l) => V3((l[0] as num).toDouble(), (l[1] as num).toDouble(), (l[2] as num).toDouble());

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double k) => V3(x * k, y * k, z * k);

  double dot(V3 o) => x * o.x + y * o.y + z * o.z;
  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  V3 get unit {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }

  @override
  String toString() => 'V3(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

double rad(double d) => d * math.pi / 180;

/// Rotazione attorno all'asse verticale, in gradi (come `ry` del prototipo).
V3 ry(V3 v, double deg) {
  final c = math.cos(rad(deg)), s = math.sin(rad(deg));
  return V3(v.x * c + v.z * s, v.y, -v.x * s + v.z * c);
}

class IkResult {
  final V3 mid, end;
  const IkResult(this.mid, this.end);
}

/// Cinematica inversa a due segmenti: da A verso T, il gomito/ginocchio piega verso `pole`.
IkResult ik(V3 a, V3 t, double l1, double l2, V3 pole) {
  final d = t - a, dist = math.min(math.max(d.length, 1), l1 + l2 - .01).toDouble(), n = d.unit;
  final ca = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist), ang = math.acos(ca.clamp(-1.0, 1.0));
  final pp = (pole - n * pole.dot(n)).unit;
  return IkResult(a + n * (l1 * math.cos(ang)) + pp * (l1 * math.sin(ang)), a + n * dist);
}
