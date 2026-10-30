import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../engine/camera.dart';
import '../posture/stance.dart';
import '../services/voice.dart';
import 'app_state.dart';
import 'learn_screens.dart';
import 'path_screens.dart';
import 'posture_screen.dart';
import 'profile_screens.dart';
import 'tech_view.dart';
import 'theme.dart';
import 'train_screen.dart';
import 'widgets.dart';

export 'app_state.dart';

class Shell extends StatefulWidget {
  final AppState app;
  const Shell({super.key, required this.app});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final pages = [HomeScreen(app: app, goTab: (i) => setState(() => tab = i)), PathScreen(app: app), CatalogScreen(app: app), LearnScreen(app: app), ProfileScreen(app: app)];
    return Scaffold(
      body: SafeArea(child: ListenableBuilder(listenable: app, builder: (context, _) => IndexedStack(index: tab, children: pages))),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Percorso'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Catalogo'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Impara'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profilo'),
        ],
      ),
    );
  }
}

void openTech(BuildContext context, AppState app, Technique t) => app.openTech(context, t);

class HomeScreen extends StatelessWidget {
  final AppState app;
  final void Function(int tab) goTab;
  const HomeScreen({super.key, required this.app, required this.goTab});

  @override
  Widget build(BuildContext context) {
    final p = app.progress, c = app.catalog, t = c.byId('combo1') ?? c.all.first;
    final nl = p.nextLesson, due = p.dueList(app.seen), pr = app.learn.nijukun[dayIndex(p.now()) % app.learn.nijukun.length];
    final task = p.tasks.where((x) => !x.complete).firstOrNull;
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Eyebrow('Ciao'),
      Text('Oggi al dojo', style: K.hand.copyWith(fontSize: 34)),
      const SizedBox(height: 14),
      GoalCard(app),
      if (nl != null)
        Card2(
          eyebrow: 'Continua il percorso · verso il ${p.levels[nl.$1].kyu}° kyu',
          title: 'Lezione ${nl.$2 + 1}: ${p.lessonName(p.levels[nl.$1].lessons[nl.$2])}',
          text: '5 minuti, poi 3 domande. +10 punti.',
          onTap: () => openLesson(context, app, nl.$1, nl.$2),
        ),
      Card2(eyebrow: 'Allenamento su misura', title: 'Allenati con me, da 5 a 30 minuti', text: 'Scegli tempo e obiettivo: kihon, calci, kata o il tuo esame. Cambia ogni volta.', onTap: () => openTraining(context, app)),
      if (task != null) Card2(eyebrow: 'Dal tuo dojo', title: task.title, text: 'Compito dell\'istruttore da completare.', onTap: () => openDojo(context, app)),
      if (due.isNotEmpty)
        Card2(title: 'Da ripassare oggi', badge: '${due.length}', children: [
          const SizedBox(height: 6),
          Wrap(children: [for (final x in due.take(6)) Pill(x.nameJp, onTap: () => openTech(context, app, x))]),
        ]),
      Card2(eyebrow: 'Il principio di oggi', title: pr.it, text: pr.explain, onTap: () => goTab(3)),
      RoughBox(
        onTap: () => openTech(context, app, t),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow('Tecnica del giorno'),
          const SizedBox(height: 6),
          TechAnimation(tech: t, controller: TechController(view: t.anim!.view), insets: false),
          const SizedBox(height: 6),
          Text(t.nameJp, style: K.hand.copyWith(fontSize: 26)),
          Text('${t.nameIt}. Tocca per i passi.', style: const TextStyle(color: K.leadSoft)),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Ripassa', style: K.hand.copyWith(fontSize: 24)),
      const SizedBox(height: 8),
      TechGrid(app: app, techs: [for (final id in ['gedan', 'gyaku', 'oizuki', 'maegeri']) ?c.byId(id)]),
    ]);
  }
}

class TechGrid extends StatelessWidget {
  final AppState app;
  final List<Technique> techs;
  const TechGrid({super.key, required this.app, required this.techs});

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .72,
        children: [
          for (final t in techs)
            RoughBox(
              padding: const EdgeInsets.all(8),
              onTap: () => openTech(context, app, t),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TechThumb(t),
                const SizedBox(height: 6),
                Text(t.nameJp + (app.favs.contains(t.id) ? ' ★' : ''), style: K.hand.copyWith(fontSize: 20), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(t.nameIt, style: const TextStyle(fontSize: 12, color: K.leadSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${t.kyu}° KYU', style: const TextStyle(fontSize: 11, letterSpacing: 1, color: K.leadSoft)),
              ]),
            ),
        ],
      );
}

class CatalogScreen extends StatefulWidget {
  final AppState app;
  const CatalogScreen({super.key, required this.app});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String cat = 'tutte';

  @override
  Widget build(BuildContext context) {
    final c = widget.app.catalog, list = cat == 'tutte' ? c.all : c.categories.firstWhere((x) => x.id == cat).techniques;
    return ListView(padding: const EdgeInsets.all(18), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Catalogo', style: K.hand.copyWith(fontSize: 34)), Text('${c.all.length} TECNICHE', style: const TextStyle(fontSize: 11, color: K.leadSoft))]),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final e in [('tutte', 'Tutte'), for (final k in c.categories) (k.id, k.nameIt)])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: RoughBox(
                fill: cat == e.$1 ? K.lead : null,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                onTap: () => setState(() => cat = e.$1),
                child: Text(e.$2, style: K.hand.copyWith(fontSize: 20, color: cat == e.$1 ? K.paper : K.lead)),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      ListenableBuilder(listenable: widget.app, builder: (context, _) => TechGrid(app: widget.app, techs: list)),
    ]);
  }
}

class DetailScreen extends StatefulWidget {
  final AppState app;
  final Technique tech;
  const DetailScreen({super.key, required this.app, required this.tech});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final TechController ctrl = TechController(view: widget.tech.anim?.view ?? '34');

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.app.voice.stop();
    ctrl.dispose();
    super.dispose();
  }

  /// La voce chiama la tecnica: nei kata e nelle combinazioni ogni passo, nelle tecniche singole il nome e poi il conteggio.
  void cue(int step, int loop) {
    final t = widget.tech, v = widget.app.voice;
    if (t.isSequence) {
      if (step >= t.steps.length) return;
      final s = t.steps[step];
      v.say(RegExp(r'\d').hasMatch(s.label) ? s.text + (s.kiai ? '. Kiai!' : '') : s.label);
    } else if (step == 0) {
      loop % 10 == 0 ? v.say(t.nameJp) : v.say(Voice.count[loop % 10], lang: 'ja-JP');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tech, app = widget.app, a = t.anim;
    final cur = a == null ? -1 : a.stepAt(ctrl.t);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            HandButton('← indietro', onTap: () => Navigator.of(context).pop()),
            ListenableBuilder(
              listenable: app,
              builder: (context, _) {
                final fav = app.favs.contains(t.id);
                return IconButton(tooltip: fav ? 'Togli dai preferiti' : 'Salva nei preferiti', onPressed: () => app.toggleFav(t.id), icon: Icon(fav ? Icons.star : Icons.star_border, color: fav ? K.red : K.lead));
              },
            ),
          ]),
          Eyebrow('${app.catalog.categories.firstWhere((c) => c.id == t.categoryId).nameIt} · ${t.kyu}° kyu'),
          Text(t.nameJp, style: K.hand.copyWith(fontSize: 38)),
          Text(t.nameIt, style: const TextStyle(fontSize: 12, color: K.leadSoft)),
          const SizedBox(height: 10),
          if (a != null) ...[
            TechAnimation(tech: t, controller: ctrl, onCue: cue),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              HandButton(ctrl.playing ? 'pausa' : 'play', outlined: true, onTap: () {
                ctrl.toggle();
                if (ctrl.playing) cue(t.isSequence ? cur : 0, 0);
              }),
              for (final s in [.25, .5, 1.0]) HandButton('${s.toString().replaceAll('.', ',').replaceAll(',0', '')}×', on: ctrl.speed == s, onTap: () => ctrl.setSpeed(s)),
              ListenableBuilder(listenable: app, builder: (context, _) => HandButton('voce', on: app.voice.enabled, onTap: app.toggleVoice)),
            ]),
            Wrap(children: [for (final v in views.values) HandButton(v.label, on: ctrl.view == v.id, onTap: () => ctrl.setView(v.id))]),
          ],
          const SizedBox(height: 8),
          LinkText(app, t.description, style: const TextStyle(color: K.leadSoft)),
          const SizedBox(height: 12),
          Text(t.isSequence ? 'Sequenza' : 'Passi', style: K.hand.copyWith(fontSize: 24)),
          for (var i = 0; i < t.steps.length; i++)
            InkWell(
              onTap: a == null
                  ? null
                  : () {
                      ctrl.jump(t.steps[i].t + .02);
                      t.isSequence ? cue(i, 0) : app.voice.say(t.steps[i].text);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                decoration: BoxDecoration(color: i == cur ? K.red.withValues(alpha: .08) : null, borderRadius: BorderRadius.circular(8)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 44, child: Text(t.steps[i].label, style: K.hand.copyWith(fontSize: 21, color: i == cur ? K.red : K.leadSoft))),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: t.steps[i].text),
                      if (t.steps[i].kiai) const TextSpan(text: '  kiai!', style: TextStyle(color: K.red, fontWeight: FontWeight.w700)),
                      if (t.steps[i].stance != null) TextSpan(text: '  · ${t.steps[i].stance}', style: const TextStyle(fontSize: 12, color: K.leadSoft)),
                    ])),
                  ),
                ]),
              ),
            ),
          if (app.learn.kataMeaning[t.id] case final m?) ...[
            const Sec('Significato'),
            LinkText(app, m.$1, style: const TextStyle(color: K.leadSoft)),
            const SizedBox(height: 4),
            LinkText(app, m.$2, style: const TextStyle(color: K.leadSoft)),
          ],
          if (postureInfo.containsKey(t.id)) ...[const SizedBox(height: 12), PostureCard(app: app, tech: t)],
          const SizedBox(height: 12),
          Text('Punti chiave', style: K.hand.copyWith(fontSize: 24)),
          for (final p in t.keyPoints) LinkText(app, '•  $p'),
          const SizedBox(height: 12),
          Text('Errori comuni', style: K.hand.copyWith(fontSize: 24)),
          for (final p in t.commonErrors) LinkText(app, '•  $p'),
          const SizedBox(height: 12),
          ReviewCard(app: app, tech: t),
          if (t.toVerify.isNotEmpty) Text('Da verificare con un istruttore: ${t.toVerify.join('; ')}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: K.leadSoft)),
          Text('Fonti: ${t.sources.join('; ')}. Testo riscritto.', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: K.leadSoft)),
        ]),
      ),
    );
  }
}

/// "Com'è andato il ripasso?": la tecnica torna dopo 1, 2, 4, 7 o 14 giorni.
class ReviewCard extends StatelessWidget {
  final AppState app;
  final Technique tech;
  const ReviewCard({super.key, required this.app, required this.tech});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final due = app.progress.reviewDue(tech.id);
          return Card2(
            title: 'Com\'è andato il ripasso?',
            text: due == null ? 'Segna come ti è venuta: l\'app te la riproporrà al momento giusto.' : 'Prossimo ripasso: ${due == app.progress.today ? 'oggi' : itDate(due)}',
            children: [
              Wrap(children: [
                for (final (ok, l) in [(false, 'difficile'), (true, 'bene')])
                  HandButton(l, outlined: true, onTap: () {
                    app.progress.rate(tech.id, ok);
                    app.changed();
                  }),
              ]),
            ],
          );
        },
      );
}
