import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:katapp/engine/camera.dart';
import 'package:katapp/engine/pose.dart';
import 'package:katapp/engine/rig.dart';
import 'package:katapp/engine/vec.dart';

Anim load(String id) => Anim.fromJson(jsonDecode(File('assets/contenuti/anim/$id.json').readAsStringSync()) as Map<String, dynamic>);

void expectV(V3 v, List<dynamic> ref, String what) {
  for (final (i, c) in [v.x, v.y, v.z].indexed) {
    expect(c, closeTo((ref[i] as num).toDouble(), 1e-6), reason: '$what[$i]');
  }
}

void main() {
  test('ik: le due ossa mantengono la lunghezza', () {
    final r = ik(const V3(0, 100, 0), const V3(30, 40, 10), 44, 44, const V3(1, 0, 0));
    expect((r.mid - const V3(0, 100, 0)).length, closeTo(44, 1e-9));
    expect((r.end - r.mid).length, closeTo(44, 1e-9));
  });

  test('lerp: le stringhe scattano a metà, i numeri si interpolano', () {
    final m = lerpValue({'a': 0, 'h': 'x', 'v': [0, 10]}, {'a': 10, 'h': 'o', 'v': [10, 20]}, .4) as Map;
    expect(m['a'], closeTo(4, 1e-9));
    expect(m['h'], 'x');
    expect(m['v'], [4.0, 14.0]);
  });

  // valori calcolati dal prototipo HTML (test/riferimento_prototipo.json)
  final refs = jsonDecode(File('test/riferimento_prototipo.json').readAsStringSync()) as List;
  for (final r in refs) {
    test('stesso manichino del prototipo: ${r['id']} a ${r['t']} s', () {
      final a = load(r['id'] as String), b = solveBody(a.poseAt((r['t'] as num).toDouble()));
      expectV(b.kneeL, r['kneeL'] as List, 'kneeL');
      expectV(b.r.wr, r['wrR'] as List, 'wrR');
      expectV(b.head, r['head'] as List, 'head');
      expectV(b.footR, r['footR'] as List, 'footR');
      final cam = Camera(views['34']!, a.follow ? b.c.x : 0, a.follow ? b.c.z : 0), p = cam.proj(b.r.wr), pr = r['pr'] as List;
      expect(p.x, closeTo((pr[0] as num).toDouble(), 1e-6));
      expect(p.y, closeTo((pr[1] as num).toDouble(), 1e-6));
      expect(p.d, closeTo((pr[2] as num).toDouble(), 1e-6));
    });
  }

  test('tutte le animazioni si caricano e producono pose valide', () {
    for (final f in Directory('assets/contenuti/anim').listSync().whereType<File>()) {
      final a = Anim.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      for (var t = 0.0; t < a.duration; t += a.duration / 37) {
        final b = solveBody(a.poseAt(t));
        expect(b.head.y.isFinite && b.kneeL.x.isFinite && b.l.wr.z.isFinite, isTrue, reason: '${a.id} a $t');
      }
    }
  });
}
