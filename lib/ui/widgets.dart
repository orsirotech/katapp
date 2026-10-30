import 'package:flutter/material.dart';

import '../data/learn.dart';
import '../data/progress.dart';
import 'app_state.dart';
import 'theme.dart';

/// Pagina con il titolo a mano e il pulsante per tornare indietro.
class Paper extends StatelessWidget {
  final String? back, title, subtitle, badge;
  final List<Widget> children;
  const Paper({super.key, this.back, this.title, this.subtitle, this.badge, required this.children});

  @override
  Widget build(BuildContext context) {
    final list = ListView(padding: const EdgeInsets.all(18), children: [
      if (back != null || badge != null)
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          if (back != null) HandButton('← $back', onTap: () => Navigator.of(context).maybePop()) else const SizedBox(),
          if (badge != null) Tag(badge!),
        ]),
      if (title != null) Text(title!, style: K.hand.copyWith(fontSize: 36)),
      if (subtitle != null) Muted(subtitle!),
      if (title != null || subtitle != null) const SizedBox(height: 10),
      ...children,
    ]);
    return back == null ? list : Scaffold(body: SafeArea(child: list));
  }
}

class Muted extends StatelessWidget {
  final String text;
  const Muted(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: K.leadSoft));
}

class Tag extends StatelessWidget {
  final String text;
  const Tag(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1, color: K.leadSoft));
}

class Sec extends StatelessWidget {
  final String text;
  const Sec(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(text, style: K.hand.copyWith(fontSize: 24)));
}

class Note extends StatelessWidget {
  final String text;
  const Note(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 10), child: Text(text, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: K.leadSoft)));
}

/// Scheda con titolo, testo e un'etichetta in alto.
class Card2 extends StatelessWidget {
  final String? eyebrow, title, text, badge;
  final List<Widget> children;
  final VoidCallback? onTap;
  const Card2({super.key, this.eyebrow, this.title, this.text, this.badge, this.children = const [], this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RoughBox(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (eyebrow != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: Eyebrow(eyebrow!)),
              if (title != null || badge != null)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(title ?? '', style: K.hand.copyWith(fontSize: 25))),
                  if (badge != null) Padding(padding: const EdgeInsets.only(top: 6, left: 8), child: Tag(badge!)),
                ]),
              if (text != null) Muted(text!),
              ...children,
            ]),
          ),
        ),
      );
}

class Bar extends StatelessWidget {
  final double value;
  const Bar(this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 7, backgroundColor: K.paper2, color: K.red),
        ),
      );
}

/// Pulsante a pillola per scelte e filtri.
class Pill extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback? onTap;
  const Pill(this.label, {super.key, this.on = false, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Semantics(
          selected: on,
          button: true,
          child: RoughBox(
            fill: on ? K.lead : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            onTap: onTap,
            child: Text(label, style: K.hand.copyWith(fontSize: 19, color: on ? K.paper : K.lead)),
          ),
        ),
      );
}

class SayButton extends StatelessWidget {
  final AppState app;
  final String kana;
  const SayButton(this.app, this.kana, {super.key});
  @override
  Widget build(BuildContext context) => IconButton(tooltip: 'ascolta', icon: const Icon(Icons.volume_up_outlined, color: K.lead), onPressed: () => app.voice.say(kana, lang: 'ja-JP', force: true));
}

/// Obiettivo del giorno e serie di giorni di fila.
class GoalCard extends StatelessWidget {
  final AppState app;
  const GoalCard(this.app, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.progress, xp = p.xpOn(p.today), st = p.streak;
    return Card2(
      title: st > 0 ? '🔥 $st ${st == 1 ? 'giorno' : 'giorni'} di fila' : 'Inizia la tua serie',
      badge: '${xp.clamp(0, goal)}/$goal punti oggi',
      children: [Bar(xp / goal), Muted(xp >= goal ? 'Obiettivo di oggi raggiunto. Domani la serie continua.' : 'Una lezione vale 10 punti, un allenamento 15.')],
    );
  }
}

/// Testo in cui le parole del glossario si toccano per aprire la loro scheda.
class LinkText extends StatelessWidget {
  final AppState app;
  final String text;
  final TextStyle? style;
  const LinkText(this.app, this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[], re = RegExp(r'[A-Za-zÀ-ÿōūŌŪ]+');
    var at = 0;
    for (final m in re.allMatches(text)) {
      final g = app.learn.word(m[0]!);
      if (g == null) continue;
      spans.add(TextSpan(text: text.substring(at, m.start)));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => showTerm(context, app, g),
          child: Text(m[0]!, style: (style ?? DefaultTextStyle.of(context).style).copyWith(decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted, decorationColor: K.red)),
        ),
      ));
      at = m.end;
    }
    spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(children: spans), style: style);
  }
}

/// Scheda di una parola: kanji, pronuncia, significato, pezzi e tecniche in cui compare.
void showTerm(BuildContext context, AppState app, Term g) {
  final techs = [for (final t in app.catalog.all) if (app.learn.wordsIn(t.nameJp).contains(g)) t].take(6).toList();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: K.paper,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), children: [
        Text(g.kanji, style: const TextStyle(fontSize: 46, color: K.lead)),
        Row(children: [Text(g.romaji, style: K.hand.copyWith(fontSize: 32)), SayButton(app, g.kana), Muted(g.kana)]),
        Text(g.meaning),
        if (g.parts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (var i = 0; i < g.parts.length; i++) ...[
              if (i > 0) const Text('+', style: TextStyle(color: K.leadSoft)),
              RoughBox(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Column(children: [Text(g.parts[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)), Muted(g.parts[i].$2)])),
            ],
          ]),
        ],
        if (techs.isNotEmpty) ...[
          const Sec('Lo trovi in'),
          Wrap(children: [
            for (final t in techs)
              Pill(t.nameJp, onTap: () {
                Navigator.of(ctx).pop();
                app.openTech(context, t);
              }),
          ]),
        ],
        const Note('Se la voce non suona giapponese, il telefono non ha una voce giapponese installata.'),
      ]),
    ),
  );
}

/// Indice del giorno, per il principio di oggi.
int dayIndex(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

String itDate(String day, {bool month = true}) {
  const m = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'];
  final p = day.split('-');
  if (p.length < 3) return day;
  final mm = m[int.parse(p[1]) - 1];
  return '${int.parse(p[2])} ${month ? mm : mm.substring(0, 3)}';
}

String clock(double s) => '${s ~/ 60}:${(s % 60).floor().toString().padLeft(2, '0')}';

