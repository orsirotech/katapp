import 'package:flutter/material.dart';

import '../data/learn.dart';
import '../data/progress.dart';
import 'app_state.dart';
import 'path_screens.dart';
import 'theme.dart';
import 'widgets.dart';

void _push(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

/// Impara: principio di oggi e le cinque sezioni.
class LearnScreen extends StatelessWidget {
  final AppState app;
  const LearnScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final l = app.learn, i = dayIndex(app.progress.now()) % l.nijukun.length, n = l.nijukun[i];
    final sections = <(String, String, Widget Function())>[
      ('Glossario parlante', '${l.glossary.length} parole con pronuncia, kanji e significato', () => GlossaryScreen(app: app)),
      ('Comandi e conteggio', 'Rei, yoi, hajime… e i numeri da 1 a 10', () => CommandsScreen(app: app)),
      ('Quiz per il prossimo kyu', 'Riconosci le tecniche, le parole e i passi dei kata', () => QuizPickScreen(app: app)),
      ('Filosofia', 'Dōjō kun e i 20 principi di Funakoshi', () => PhilosophyScreen(app: app)),
      ('Etichetta del dojo', 'Come si entra, si saluta e ci si comporta', () => EtiquetteScreen(app: app)),
    ];
    return Paper(title: 'Impara', children: [
      Card2(eyebrow: 'Il principio di oggi · ${i + 1} di ${l.nijukun.length}', title: n.it, text: n.explain, children: [if (n.ask.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(n.ask, style: K.hand.copyWith(fontSize: 19, color: K.red)))]),
      for (final (t, d, page) in sections) Card2(title: t, text: d, onTap: () => _push(context, page())),
    ]);
  }
}

class GlossaryScreen extends StatefulWidget {
  final AppState app;
  const GlossaryScreen({super.key, required this.app});
  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String q = '', cat = 'tutte';

  @override
  Widget build(BuildContext context) {
    final app = widget.app, list = app.learn.search(q, cat);
    return Paper(back: 'Impara', title: 'Glossario', subtitle: '${app.learn.glossary.length} parole. Tocca una parola per la scheda, 🔊 per ascoltarla.', children: [
      TextField(
        decoration: const InputDecoration(hintText: 'Cerca: gyaku, calcio, saluto…', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
        onChanged: (v) => setState(() => q = v),
      ),
      const SizedBox(height: 10),
      Wrap(children: [for (final (id, l) in Learn.categories) Pill(l, on: cat == id, onTap: () => setState(() => cat = id))]),
      if (list.isEmpty) const Muted('Nessuna parola trovata.'),
      for (final g in list)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(width: 56, child: Text(g.kanji, style: const TextStyle(fontSize: 22), maxLines: 1, overflow: TextOverflow.fade, softWrap: false)),
          title: Text(g.romaji, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(firstClause(g.meaning), style: const TextStyle(color: K.leadSoft)),
          trailing: SayButton(app, g.kana),
          onTap: () => showTerm(context, app, g),
        ),
    ]);
  }
}

class CommandsScreen extends StatelessWidget {
  final AppState app;
  const CommandsScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final l = app.learn;
    return Paper(back: 'Impara', title: 'Comandi e conteggio', subtitle: 'Quello che senti a lezione, con la pronuncia.', children: [
      const Sec('Conteggio'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in l.count)
          SizedBox(
            width: 92,
            child: RoughBox(
              padding: const EdgeInsets.all(8),
              onTap: () => app.voice.say(c.kana, lang: 'ja-JP', force: true),
              child: Column(children: [Text(c.meaning, style: K.hand.copyWith(fontSize: 26)), Text(c.romaji, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)]),
            ),
          ),
      ]),
      const SizedBox(height: 10),
      Align(alignment: Alignment.centerLeft, child: HandButton('🔊 conta da 1 a 10', outlined: true, onTap: () => app.voice.say(l.count.map((c) => c.kana).join('、'), lang: 'ja-JP', force: true))),
      const Sec('Comandi del dojo'),
      for (final c in l.commands)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(c.romaji, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(c.meaning, style: const TextStyle(color: K.leadSoft)),
          trailing: SayButton(app, c.kana),
          onTap: () => app.voice.say(c.kana, lang: 'ja-JP', force: true),
        ),
    ]);
  }
}

class _Numbered extends StatelessWidget {
  final int n;
  final Principle p;
  final bool today;
  const _Numbered(this.n, this.p, {this.today = false});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: today ? K.red.withValues(alpha: .08) : null, borderRadius: BorderRadius.circular(8)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 34, child: Text('$n', style: K.hand.copyWith(fontSize: 24, color: today ? K.red : K.leadSoft))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.it, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(p.jp, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: K.leadSoft)),
              Muted(p.explain),
              if (today && p.ask.isNotEmpty) Text('Per riflettere: ${p.ask}', style: K.hand.copyWith(fontSize: 19, color: K.red)),
            ]),
          ),
        ]),
      );
}

class PhilosophyScreen extends StatelessWidget {
  final AppState app;
  const PhilosophyScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final l = app.learn, n = dayIndex(app.progress.now()) % l.nijukun.length;
    return Paper(back: 'Impara', title: 'Filosofia', children: [
      const Sec('Dōjō kun'),
      const Muted('Le cinque regole del dojo. In molti dojo si recitano a fine lezione, in seiza. Ognuna inizia con "hitotsu", "primo", perché sono tutte ugualmente importanti.'),
      const SizedBox(height: 8),
      for (var i = 0; i < l.dojoKun.length; i++) _Numbered(i + 1, l.dojoKun[i]),
      const Sec('I 20 principi di Funakoshi'),
      const Muted('Shōtō nijū kun: li scrisse il fondatore dello Shotokan. Quello evidenziato è il principio di oggi.'),
      const SizedBox(height: 8),
      for (var i = 0; i < l.nijukun.length; i++) _Numbered(i + 1, l.nijukun[i], today: i == n),
      const Note('Traduzioni libere, da confrontare con il testo del tuo dojo.'),
    ]);
  }
}

class EtiquetteScreen extends StatelessWidget {
  final AppState app;
  const EtiquetteScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) => Paper(back: 'Impara', title: 'Etichetta del dojo', subtitle: 'Le regole non scritte che fanno sentire a casa in qualunque dojo.', children: [
        for (final (t, pts) in app.learn.etiquette) Card2(title: t, children: [for (final p in pts) LinkText(app, '•  $p')]),
      ]);
}

class QuizPickScreen extends StatelessWidget {
  final AppState app;
  const QuizPickScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) => Paper(back: 'Impara', title: 'Quiz per il prossimo kyu', subtitle: '8 domande sul programma fino al grado che scegli.', children: [
          for (final k in [9, 8, 7, 6])
            Card2(
              title: 'Verso il $k° kyu',
              badge: app.progress.quizBest(k) != null ? 'migliore ${app.progress.quizBest(k)}/8' : 'da fare',
              onTap: () => startKyuQuiz(context, app, k),
            ),
        ]),
      );
}

void startKyuQuiz(BuildContext context, AppState app, int kyu, {bool replace = false}) {
  final qs = QuizMaker(app.catalog, app.learn, app.progress.rnd).forKyu(kyu);
  final page = QuizScreen(
    app: app,
    back: 'quiz',
    title: 'Verso il $kyu° kyu',
    questions: qs,
    onDone: (ok) => app.progress.recordQuiz(kyu, ok),
    result: (context, ok) => [
      Card2(
        eyebrow: 'Verso il $kyu° kyu',
        title: '$ok risposte giuste su ${qs.length}',
        text: ok >= 7 ? 'Sei pronto: ripassa solo i dettagli.' : ok >= 5 ? 'Buona base. Ripassa le tecniche che hai sbagliato.' : 'Ripassa con calma e riprova tra qualche giorno.',
      ),
      Wrap(children: [
        HandButton('rifai il quiz', outlined: true, onTap: () => startKyuQuiz(context, app, kyu, replace: true)),
        HandButton('cambia grado', onTap: () => Navigator.of(context).pop()),
      ]),
    ],
  );
  final route = MaterialPageRoute<void>(builder: (_) => page);
  replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}
