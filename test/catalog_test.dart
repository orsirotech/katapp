import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katapp/data/catalog.dart';
import 'package:katapp/engine/camera.dart';
import 'package:katapp/engine/pencil_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('il catalogo carica tutte le tecniche con la loro animazione', () async {
    final c = await Catalog.load(rootBundle);
    expect(c.categories.map((x) => x.id), containsAll(['dachi', 'uke', 'tsuki', 'uchi', 'geri', 'combo', 'kata']));
    expect(c.all.length, greaterThanOrEqualTo(33));
    for (final t in c.all) {
      expect(t.anim, isNotNull, reason: t.id);
      expect(t.steps, isNotEmpty, reason: t.id);
    }
    final h = c.byId('heian1')!;
    expect(h.isSequence, isTrue);
    expect(h.steps.where((s) => s.kiai).length, 2);
  });

  testWidgets('ogni tecnica si disegna senza errori in tutte le viste', (tester) async {
    final c = (await tester.runAsync(() => Catalog.load(rootBundle)))!;
    for (final t in c.all) {
      for (final v in views.keys) {
        await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: SizedBox(width: 240, height: 270, child: CustomPaint(painter: PencilPainter(anim: t.anim!, t: t.anim!.duration * .4, view: views[v]!))))));
      }
    }
    expect(tester.takeException(), isNull);
  });
}
