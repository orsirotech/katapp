import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katapp/data/catalog.dart';
import 'package:katapp/posture/stance.dart';
import 'package:katapp/services/reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('il disegno della scheda passa il controllo, l\'esempio sbagliato no', () async {
    final c = await Catalog.load(rootBundle);
    for (final id in postureInfo.keys) {
      final t = c.byId(id)!, good = checkStance(id, rigPoints(t).$2), bad = checkStance(id, rigPoints(t, wrong: true).$2);
      expect(good.score, 100, reason: '$id: ${good.tips.where((x) => !x.ok).map((x) => x.text)}');
      expect(bad.score, lessThan(100), reason: id);
      expect(bad.firstWrong, isNotNull);
    }
  });

  test('promemoria: oggi se non ancora allenato, altrimenti domani', () {
    final now = DateTime(2026, 10, 30, 17, 0);
    expect(Reminder.nextAt(now, '18:30', false), DateTime(2026, 10, 30, 18, 30));
    expect(Reminder.nextAt(now, '18:30', true), DateTime(2026, 10, 31, 18, 30));
    expect(Reminder.nextAt(now, '07:15', false), DateTime(2026, 10, 31, 7, 15));
  });
}
