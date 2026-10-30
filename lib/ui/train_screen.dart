import 'dart:async';

import 'package:flutter/material.dart';

import '../data/progress.dart';
import 'app_state.dart';
import 'tech_view.dart';
import 'theme.dart';
import 'widgets.dart';

void openTraining(BuildContext context, AppState app) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TrainSetupScreen(app: app)));

String segmentTitle(AppState app, Segment s) {
  if (s.kind != 'kihon') return s.title;
  final name = app.catalog.byId(s.techId!)!.nameJp;
  return s.noCount ? (s.reps > 1 ? '$name × ${s.reps}' : name) : '$name × ${s.reps}';
}

/// Allenamento su misura: tempo e obiettivo, poi il piano da avviare.
class TrainSetupScreen extends StatefulWidget {
  final AppState app;
  const TrainSetupScreen({super.key, required this.app});
  @override
  State<TrainSetupScreen> createState() => _TrainSetupScreenState();
}

class _TrainSetupScreenState extends State<TrainSetupScreen> {
  int minutes = 10;
  String focus = 'misto';
  late List<Segment> plan = _make();

  List<Segment> _make() => widget.app.progress.makePlan(minutes, focus, widget.app.seen);

  @override
  Widget build(BuildContext context) {
    final app = widget.app, tot = (plan.fold(0.0, (a, s) => a + s.dur) / 60).round();
    return Paper(back: 'indietro', title: 'Allenamento su misura', subtitle: 'Scegli quanto tempo hai e su cosa vuoi lavorare: ogni volta l\'allenamento cambia. La voce conta e annuncia ogni esercizio.', children: [
      const Eyebrow('Quanto tempo'),
      const SizedBox(height: 6),
      Wrap(children: [
        for (final m in [5, 10, 20, 30])
          Pill('$m min', on: minutes == m, onTap: () => setState(() {
                minutes = m;
                plan = _make();
              })),
      ]),
      const Eyebrow('Su cosa'),
      const SizedBox(height: 6),
      Wrap(children: [
        for (final (id, l) in focuses)
          Pill(l, on: focus == id, onTap: () => setState(() {
                focus = id;
                plan = _make();
              })),
      ]),
      const SizedBox(height: 6),
      Card2(title: 'Il tuo allenamento', badge: 'circa $tot min', children: [
        const SizedBox(height: 4),
        for (var i = 0; i < plan.length; i++) Text('${i + 1}.  ${segmentTitle(app, plan[i])}'),
        const SizedBox(height: 8),
        Wrap(children: [
          HandButton('inizia', outlined: true, onTap: () {
            final label = focuses.firstWhere((f) => f.$1 == focus).$2.toLowerCase();
            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => TrainScreen(app: app, plan: plan, logTitle: 'Allenamento $minutes min · $label')));
          }),
          HandButton('cambia esercizi', onTap: () => setState(() => plan = _make())),
        ]),
      ]),
      const Note('Le tecniche "da ripassare" entrano per prime. "Il mio esame" usa il programma del tuo prossimo kyu.'),
    ]);
  }
}

/// L'allenamento in corso: tempo, disegno, conteggio a voce.
class TrainScreen extends StatefulWidget {
  final AppState app;
  final List<Segment> plan;
  final String logTitle;

  /// Al posto della schermata finale (per l'esame simulato).
  final void Function(BuildContext context, double minutes)? onFinished;
  const TrainScreen({super.key, required this.app, required this.plan, this.logTitle = 'Allenamento', this.onFinished});
  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  int i = 0, rep = -1, item = 0;
  double el = 0;
  bool paused = false, done = false;
  String count = '';
  TechController? ctrl;
  Timer? timer;

  Segment get s => widget.plan[i];
  double get total => widget.plan.fold(0.0, (a, x) => a + x.dur);

  @override
  void initState() {
    super.initState();
    _start();
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick(.1));
  }

  @override
  void dispose() {
    timer?.cancel();
    ctrl?.dispose();
    widget.app.voice.stop();
    super.dispose();
  }

  void _start() {
    el = 0;
    rep = -1;
    item = 0;
    count = '';
    ctrl?.dispose();
    ctrl = null;
    final v = widget.app.voice;
    if (s.kind == 'kihon') {
      final t = widget.app.catalog.byId(s.techId!)!;
      ctrl = TechController(view: t.anim!.view)..speed = s.speed;
      ctrl!.playing = !paused;
    }
    if (s.say != null) {
      v.say(s.say!);
    } else if (s.kind == 'kihon') {
      v.say(widget.app.catalog.byId(s.techId!)!.nameJp + (s.noCount ? '' : ', ${s.reps} ripetizioni'));
    } else if (s.kind == 'list') {
      v.say('${s.title}. ${s.items.first}');
    }
  }

  void _tick(double dt) {
    if (done || paused || !mounted) return;
    final v = widget.app.voice;
    el += dt;
    if (s.kind == 'list') {
      final it = (el / s.each).floor();
      if (it != item && it < s.items.length) {
        item = it;
        v.say(s.items[it]);
      }
    }
    if (s.kind == 'kihon' && !s.noCount) {
      final d = widget.app.catalog.byId(s.techId!)!.anim!.duration, r = ((el + .5) * s.speed / d + .3).floor();
      if (r != rep && r >= 1 && r <= s.reps) {
        rep = r;
        final c = widget.app.learn.count[(r - 1) % 10];
        v.say(c.kana, lang: 'ja-JP');
        count = '${c.romaji.split(' ').first} · $r';
      }
    }
    if (el >= s.dur) _next();
    setState(() {});
  }

  void _next() {
    if (i < widget.plan.length - 1) {
      i++;
      _start();
    } else {
      _finish();
    }
  }

  void _finish() {
    final p = widget.app.progress, minutes = total / 60;
    for (final x in widget.plan) {
      if (x.kind == 'kihon') p.rate(x.techId!, true);
    }
    done = true;
    timer?.cancel();
    if (widget.onFinished != null) {
      widget.onFinished!(context, minutes);
    } else {
      p.addLog('allenamento', 15, minutes, widget.logTitle);
      widget.app.voice.say('Allenamento finito. Otsukaresama deshita');
    }
    widget.app.changed();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    if (done && widget.onFinished == null) {
      return Paper(back: 'home', children: [
        const Card2(title: 'Allenamento finito', text: 'Otsukaresama deshita: "grazie per la fatica". Le tecniche del kihon sono segnate come ripassate. +15 punti.'),
        GoalCard(app),
      ]);
    }
    final doneT = widget.plan.take(i).fold(0.0, (a, x) => a + x.dur) + el, left = (s.dur - el).clamp(0.0, s.dur);
    final tech = s.kind == 'kihon' ? app.catalog.byId(s.techId!) : null;
    return Paper(back: 'esci', badge: '${i + 1}/${widget.plan.length} · ${clock(total - doneT)} alla fine', children: [
      Bar(doneT / total),
      Eyebrow(s.kind == 'kihon' ? (s.noCount ? 'Combinazione o kata' : 'Kihon') : 'Allenamento'),
      Text(tech?.nameJp ?? s.title, style: K.hand.copyWith(fontSize: 36)),
      Muted('${s.kind == 'kihon' ? (s.noCount ? '${s.reps} ${s.reps > 1 ? 'volte' : 'volta'} · ' : '${s.reps} ripetizioni, conta ad alta voce · ') : ''}${clock(left)}'),
      const SizedBox(height: 8),
      if (tech != null)
        TechAnimation(key: ValueKey('$i'), tech: tech, controller: ctrl!, insets: false)
      else if (s.kind == 'list')
        for (var j = 0; j < s.items.length; j++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(color: j == item ? K.red.withValues(alpha: .08) : null, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [SizedBox(width: 32, child: Text('${j + 1}', style: K.hand.copyWith(fontSize: 21, color: j == item ? K.red : K.leadSoft))), Expanded(child: Text(s.items[j]))]),
          )
      else
        AspectRatio(aspectRatio: 4 / 3, child: RoughBox(child: Center(child: Text(s.sub, textAlign: TextAlign.center, style: K.hand.copyWith(fontSize: 26))))),
      const SizedBox(height: 8),
      Wrap(children: [
        HandButton(paused ? 'riprendi' : 'pausa', outlined: true, onTap: () => setState(() {
              paused = !paused;
              ctrl?.playing = !paused;
              if (paused) app.voice.stop();
            })),
        HandButton('avanti →', onTap: () => setState(_next)),
        ListenableBuilder(listenable: app, builder: (context, _) => HandButton('voce', on: app.voice.enabled, onTap: app.toggleVoice)),
      ]),
      if (count.isNotEmpty) Center(child: Text(count, style: K.hand.copyWith(fontSize: 48, color: K.red))),
    ]);
  }
}
