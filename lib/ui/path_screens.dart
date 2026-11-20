import 'package:flutter/material.dart';

import '../data/progress.dart';
import 'app_state.dart';
import 'tech_view.dart';
import 'theme.dart';
import 'train_screen.dart';
import 'widgets.dart';

/// Percorso a tappe: per ogni kyu lezioni da 5 minuti e un esame simulato.
class PathScreen extends StatelessWidget {
  final AppState app;
  const PathScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final p = app.progress, nl = p.nextLesson;
    return Paper(title: 'Percorso', badge: 'lezioni da 5 minuti', children: [
      GoalCard(app),
      for (var li = 0; li < p.levels.length; li++) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Sec('Verso il ${p.levels[li].kyu}° kyu'), Tag('${p.levels[li].belt}${p.levelOpen(li) ? '' : ' · 🔒'}')]),
        for (var j = 0; j < p.levels[li].lessons.length; j++)
          _Node(
            label: p.lessonName(p.levels[li].lessons[j]),
            mark: p.lessonDone(li, j) ? '✓' : p.canStart(li, j) ? '${j + 1}' : '🔒',
            done: p.lessonDone(li, j),
            current: nl == (li, j),
            right: j.isOdd,
            onTap: p.canStart(li, j) ? () => openLesson(context, app, li, j) : null,
          ),
        _Node(
          label: 'Esame simulato${p.examScore(p.levels[li].kyu) != null ? ' · ${p.examScore(p.levels[li].kyu)}/8' : ''}',
          mark: (p.examScore(p.levels[li].kyu) ?? 0) >= 6 ? '★' : '🥋',
          done: (p.examScore(p.levels[li].kyu) ?? 0) >= 6,
          onTap: p.levelDone(li) ? () => openExam(context, app, p.levels[li].kyu) : null,
        ),
      ],
      const Note('L\'esame simulato non sostituisce quello del dojo: serve a capire se sei pronto.'),
    ]);
  }
}

class _Node extends StatelessWidget {
  final String label, mark;
  final bool done, current, right;
  final VoidCallback? onTap;
  const _Node({required this.label, required this.mark, this.done = false, this.current = false, this.right = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? K.leadSoft.withValues(alpha: .6) : current ? K.red : K.lead;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$label${done ? ', fatta' : onTap == null ? ', bloccata' : ''}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(left: right ? 48 : 0, top: 4, bottom: 4),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: done ? K.lead : K.paper2, border: Border.all(color: color, width: current ? 3 : 1.6)),
              child: Text(mark, style: K.hand.copyWith(fontSize: 22, color: done ? K.paper : color)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: K.hand.copyWith(fontSize: 21, color: color))),
          ]),
        ),
      ),
    );
  }
}

void openLesson(BuildContext context, AppState app, int li, int j, {bool replace = false}) {
  final ids = app.progress.levels[li].lessons[j];
  ids.forEach(app.markSeen);
  final route = MaterialPageRoute<void>(builder: (_) => LessonScreen(app: app, li: li, j: j));
  replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}

/// Lezione: una tecnica alla volta, poi tre domande di verifica.
class LessonScreen extends StatefulWidget {
  final AppState app;
  final int li, j;
  const LessonScreen({super.key, required this.app, required this.li, required this.j});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final app = widget.app, p = app.progress, ids = p.levels[widget.li].lessons[widget.j], x = app.catalog.byId(ids[i])!;
    final cat = app.catalog.categories.firstWhere((c) => c.id == x.categoryId).nameIt;
    return Paper(back: 'percorso', badge: '${i + 1} di ${ids.length}', children: [
      Bar(i / (ids.length + 1)),
      Eyebrow('Lezione · $cat'),
      Text(x.nameJp, style: K.hand.copyWith(fontSize: 36)),
      Muted(x.nameIt),
      const SizedBox(height: 8),
      TechAnimation(key: ValueKey(x.id), tech: x, controller: TechController(view: x.anim!.view), insets: false),
      const SizedBox(height: 8),
      LinkText(app, x.description, style: const TextStyle(color: K.leadSoft)),
      const Sec('Prova tu'),
      Muted(x.isKata ? 'Segui il kata una volta guardando il disegno, poi una seconda volta da solo.' : 'Guarda il disegno due volte, poi esegui la tecnica 5 volte per lato, lentamente.'),
      const SizedBox(height: 6),
      for (final pt in x.keyPoints) LinkText(app, '•  $pt'),
      const SizedBox(height: 12),
      Wrap(children: [
        HandButton(i + 1 < ids.length ? 'fatto, avanti →' : 'fatto, alla verifica →', outlined: true, onTap: () {
          if (i + 1 < ids.length) return setState(() => i++);
          _quiz(context, ids);
        }),
        HandButton('scheda completa', onTap: () => app.openTech(context, x)),
      ]),
    ]);
  }

  void _quiz(BuildContext context, List<String> ids) {
    final app = widget.app, p = app.progress, qs = QuizMaker(app.catalog, app.learn, p.rnd).lesson(ids);
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => QuizScreen(
        app: app,
        back: 'percorso',
        title: 'Verifica',
        questions: qs,
        onDone: (ok) {
          p.completeLesson(widget.li, widget.j);
          for (final id in ids) {
            p.rate(id, ok == qs.length);
          }
        },
        result: (context, ok) {
          final nl = p.nextLesson;
          return [
            Card2(eyebrow: 'Lezione completata · +10 punti', title: '$ok su ${qs.length} giuste', text: ok == qs.length ? 'Perfetto.' : 'Le tecniche sbagliate torneranno nel ripasso.'),
            GoalCard(app),
            Wrap(children: [
              if (nl != null) HandButton('prossima lezione →', outlined: true, onTap: () => openLesson(context, app, nl.$1, nl.$2, replace: true)),
              HandButton('percorso', onTap: () => Navigator.of(context).pop()),
            ]),
          ];
        },
      ),
    ));
  }
}

/// Esame simulato: prima la parte pratica guidata dalla voce, poi 8 domande.
void openExam(BuildContext context, AppState app, int kyu) {
  final p = app.progress;
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => TrainScreen(
      app: app,
      plan: p.examPlan(kyu),
      onFinished: (context, minutes) {
        p.addLog('esame', 0, minutes, 'Esame $kyu° kyu, parte pratica');
        app.voice.say('Parte pratica finita. Ora le domande');
        final qs = QuizMaker(app.catalog, app.learn, p.rnd).forKyu(kyu);
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => QuizScreen(
            app: app,
            back: 'percorso',
            title: 'Esame $kyu° kyu',
            questions: qs,
            onDone: (ok) => p.recordExam(kyu, ok),
            result: (context, ok) => [
              Card2(
                eyebrow: 'Esame simulato · $kyu° kyu',
                title: '${ok >= 6 ? '★ Superato' : 'Non ancora'}: $ok/8',
                text: '${ok >= 6 ? 'Sei pronto per parlarne con il tuo istruttore.' : 'Ti servono almeno 6 risposte giuste. Ripassa le lezioni del livello e riprova.'} +${ok >= 6 ? 30 : 10} punti.',
              ),
              Wrap(children: [HandButton('percorso', outlined: true, onTap: () => Navigator.of(context).pop())]),
            ],
          ),
        ));
      },
    ),
  ));
}

/// Domande a scelta multipla, con la spiegazione dopo ogni risposta.
class QuizScreen extends StatefulWidget {
  final AppState app;
  final String back, title;
  final List<Question> questions;
  final void Function(int ok) onDone;
  final List<Widget> Function(BuildContext context, int ok) result;
  const QuizScreen({super.key, required this.app, required this.back, required this.title, required this.questions, required this.onDone, required this.result});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int i = 0, ok = 0;
  String? ans;

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions, app = widget.app;
    if (i >= qs.length) return Paper(back: widget.back, children: widget.result(context, ok));
    final q = qs[i];
    return Paper(back: widget.back, badge: widget.title, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Tag('Domanda ${i + 1} di ${qs.length}'), Tag('$ok giuste')]),
      Bar(i / qs.length),
      if (q.kind == 'pic') Center(child: SizedBox(width: 240, child: TechThumb(app.catalog.byId(q.techId!)!))),
      Row(children: [Expanded(child: Text(q.q, style: K.hand.copyWith(fontSize: 28))), if (q.say != null) SayButton(app, q.say!)]),
      const SizedBox(height: 8),
      for (final o in q.opts)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RoughBox(
            fill: ans == null ? null : o == q.a ? const Color(0x2E3C7A3C) : o == ans ? K.red.withValues(alpha: .15) : null,
            onTap: ans != null
                ? null
                : () => setState(() {
                      ans = o;
                      if (o == q.a) ok++;
                    }),
            child: SizedBox(width: double.infinity, child: Text(o, style: const TextStyle(fontSize: 16))),
          ),
        ),
      if (ans != null) ...[
        LinkText(app, '${ans == q.a ? '✓ Giusto.' : '✗ Non è così.'} ${q.why}', style: const TextStyle(color: K.leadSoft)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: HandButton(i + 1 < qs.length ? 'prossima →' : 'vedi il risultato', outlined: true, onTap: () {
            setState(() {
              ans = null;
              i++;
            });
            if (i >= qs.length) {
              widget.onDone(ok);
              app.changed();
            }
          }),
        ),
      ],
    ]);
  }
}
