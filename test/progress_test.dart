import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katapp/data/catalog.dart';
import 'package:katapp/data/learn.dart';
import 'package:katapp/data/progress.dart';
import 'package:katapp/main.dart';
import 'package:katapp/ui/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog c;
  late Learn l;

  setUpAll(() async {
    c = await Catalog.load(rootBundle);
    l = await Learn.load(rootBundle);
  });

  Future<Progress> fresh(DateTime Function() now) async {
    SharedPreferences.setMockInitialValues({});
    return Progress(await SharedPreferences.getInstance(), c, now: now, rnd: Random(7));
  }

  test('glossario: parole collegate ai nomi delle tecniche', () {
    expect(l.glossary.length, 73);
    expect(l.wordsIn('Gyaku-zuki chūdan').map((g) => g.id), containsAll(['gyaku', 'chudan']));
    expect(l.word('do'), isNull);
    expect(l.search('saluto', 'tutte').map((g) => g.id), contains('rei'));
    expect(plain('Kōkutsu-dachi'), 'kokutsu-dachi');
  });

  test('serie di giorni e punti', () async {
    var day = DateTime(2026, 10, 28, 10);
    final p = await fresh(() => day);
    expect(p.streak, 0);
    p.addLog('lezione', 10, 5, 'a');
    day = DateTime(2026, 10, 29, 9);
    p.addLog('allenamento', 15, 10, 'b');
    p.addLog('quiz', 5, 2, 'c');
    expect(p.xpOn('2026-10-29'), 20);
    expect(p.streak, 2);
    day = DateTime(2026, 10, 30, 8); // oggi non ancora allenato: la serie resta
    expect(p.streak, 2);
    day = DateTime(2026, 11, 1, 8);
    expect(p.streak, 0);
  });

  test('ripasso a intervalli', () async {
    final day = DateTime(2026, 10, 30);
    final p = await fresh(() => day);
    expect(p.dueList({'gedan'}).map((t) => t.id), ['gedan']);
    p.rate('gedan', true);
    expect(p.reviewDue('gedan'), '2026-10-31');
    p.rate('gedan', true);
    expect(p.reviewDue('gedan'), '2026-11-01');
    p.rate('gedan', false);
    expect(p.reviewDue('gedan'), '2026-10-31');
    expect(p.dueList({'gedan'}), isEmpty);
  });

  test('percorso: lezioni, sblocco ed esame', () async {
    final p = await fresh(DateTime.now);
    expect(p.levels.map((x) => x.kyu), [9, 8, 7, 6]);
    expect(p.levels.first.lessons.first, ['musubi', 'heiko']);
    for (final L in p.levels) {
      for (final ls in L.lessons) {
        if (ls.any((id) => c.byId(id)!.isKata)) expect(ls.length, 1);
      }
    }
    expect(p.nextLesson, (0, 0));
    expect(p.canStart(0, 1), isFalse);
    expect(p.levelOpen(1), isFalse);
    for (var j = 0; j < p.levels[0].lessons.length; j++) {
      p.completeLesson(0, j);
    }
    expect(p.levelOpen(1), isTrue);
    expect(p.nextLesson, (1, 0));
    expect(p.grade, 10);
    p.recordExam(9, 7);
    expect(p.grade, 9);
  });

  test('quiz: ogni domanda ha 4 risposte e quella giusta', () async {
    final q = QuizMaker(c, l, Random(3));
    for (var n = 0; n < 20; n++) {
      for (final k in [9, 8, 7, 6]) {
        final qs = q.forKyu(k);
        expect(qs.length, 8);
        for (final x in qs) {
          expect(x.opts, contains(x.a), reason: x.q);
          expect(x.opts.length, 4, reason: x.q);
        }
      }
      for (final L in buildLevels(c)) {
        for (final ls in L.lessons) {
          final qs = q.lesson(ls);
          expect(qs, isNotEmpty);
          for (final x in qs) {
            expect(x.opts, contains(x.a));
          }
        }
      }
    }
  });

  test('allenamento su misura: dura circa il tempo scelto', () async {
    final p = await fresh(DateTime.now);
    for (final m in [5, 10, 20, 30]) {
      for (final (f, _) in focuses) {
        final plan = p.makePlan(m, f, {'gedan'}), tot = plan.fold(0.0, (a, s) => a + s.dur);
        expect(tot, lessThanOrEqualTo(m * 60 * 1.06 + 1), reason: '$m $f');
        expect(tot, greaterThan(m * 60 * (m >= 10 ? .7 : .5)), reason: '$m $f');
        expect(plan.first.title, 'Mokusō');
        expect(plan.last.title, 'Saluto finale');
      }
    }
    final ex = p.examPlan(8);
    expect(ex.where((s) => s.techId == 'heian1'), hasLength(1));
  });

  test('codici dei compiti compatibili con il prototipo', () async {
    // creato dal prototipo con b64e({n:'Dojo Kōhai', t:'Ripasso', i:['gedan','heian1'], r:8, d:'2026-11-10', no:'Piano'})
    const proto = 'KAT-eyJuIjoiRG9qbyBLxY1oYWkiLCJ0IjoiUmlwYXNzbyIsImkiOlsiZ2VkYW4iLCJoZWlhbjEiXSwiciI6OCwiZCI6IjIwMjYtMTEtMTAiLCJubyI6IlBpYW5vIn0';
    expect(encodeTask(dojo: 'Dojo Kōhai', title: 'Ripasso', ids: ['gedan', 'heian1'], reps: 8, due: '2026-11-10', note: 'Piano'), proto);
    final p = await fresh(DateTime.now);
    expect(p.addTask(proto), isNull);
    expect(p.addTask(proto), 'Questo compito c\'è già.');
    expect(p.addTask('KAT-boh'), startsWith('Codice non valido'));
    final t = p.tasks.single;
    expect((t.dojo, t.reps), ('Dojo Kōhai', 8));
    expect(t.ids, ['gedan', 'heian1']);
    p.toggleTaskDone(t.id, 'gedan');
    expect(p.tasks.single.done, ['gedan']);
  });

  testWidgets('le cinque schede si aprono', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(KatApp(app: AppState(c, l, prefs)));
    for (final tab in ['Percorso', 'Catalogo', 'Impara', 'Profilo', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text('Impara').last);
    await tester.pump();
    await tester.tap(find.text('Glossario parlante'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(find.text('Glossario'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
