import 'dart:math' as math;

/// Una posa è la mappa JSON esportata dal prototipo (`anim/<id>.json`):
/// face, yaw, lean, C, aL, aR, fL, fR, pL, pR, kpL, kpR, wt, stance, L, R.
typedef Pose = Map<String, dynamic>;

/// Interpolazione generica come `lerp` del prototipo: numeri, liste e mappe;
/// le stringhe (es. il nome della posizione, `h: 'o'`) scattano a metà.
dynamic lerpValue(dynamic a, dynamic b, double k) {
  if (a == null || b == null) {
    final d = a ?? b;
    return d is String ? (k < .5 ? (a ?? '') : (b ?? '')) : d;
  }
  if (a is num && b is num) return a + (b - a) * k;
  if (a is String) return k < .5 ? a : b;
  if (a is List && b is List) return [for (var i = 0; i < a.length; i++) lerpValue(a[i], b[i], k)];
  if (a is Map && b is Map) {
    return <String, dynamic>{for (final key in {...a.keys, ...b.keys}) key as String: lerpValue(a[key], b[key], k)};
  }
  return k < .5 ? a : b;
}

typedef Ease = double Function(double);

double _eIO(double x) => x < .5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2;
double _eOut(double x) => 1 - math.pow(1 - x, 3).toDouble();
double _eIn(double x) => x * x;
double _lin(double x) => x;

Ease easeByName(String? n) => switch (n) { 'inOut' => _eIO, 'out' => _eOut, 'in' => _eIn, _ => _lin };

class Key {
  final double t;
  final Pose pose;
  final Ease ease;
  const Key(this.t, this.pose, this.ease);
}

/// Animazione di una tecnica: chiavi nel tempo, inizio dei passi, finestre del kiai.
class Anim {
  final String id;
  final double duration;
  final bool follow;
  final String view;
  final List<Key> keys;
  final List<double> marks;
  final List<List<double>> kiai;

  const Anim({required this.id, required this.duration, required this.follow, required this.view, required this.keys, required this.marks, required this.kiai});

  factory Anim.fromJson(Map<String, dynamic> j) => Anim(
        id: j['id'] as String,
        duration: (j['durata'] as num).toDouble(),
        follow: j['segue_camera'] == true,
        view: (j['vista'] as String?) ?? '34',
        keys: [for (final k in j['chiavi'] as List) Key((k['t'] as num).toDouble(), Map<String, dynamic>.from(k['pose'] as Map), easeByName(k['ease'] as String?))],
        marks: [for (final m in (j['passi_t'] as List? ?? const [0])) (m as num).toDouble()],
        kiai: [for (final w in (j['kiai'] as List? ?? const [])) [for (final v in w as List) (v as num).toDouble()]],
      );

  double wrap(double t) => ((t % duration) + duration) % duration;

  Pose poseAt(double t) {
    t = wrap(t);
    for (var i = 0; i < keys.length - 1; i++) {
      final a = keys[i], b = keys[i + 1];
      if (t >= a.t && t <= b.t) {
        final span = b.t - a.t;
        return lerpValue(a.pose, b.pose, b.ease(span == 0 ? 0 : (t - a.t) / span)) as Pose;
      }
    }
    return keys.first.pose;
  }

  /// Indice del passo in corso al tempo t.
  int stepAt(double t) {
    final tt = wrap(t);
    var i = 0;
    for (var j = 0; j < marks.length; j++) {
      if (tt >= marks[j]) i = j;
    }
    return i;
  }

  bool kiaiAt(double t) {
    final tt = wrap(t);
    return kiai.any((w) => tt >= w[0] && tt <= w[1]);
  }
}
