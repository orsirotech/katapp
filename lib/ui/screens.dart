import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../engine/camera.dart';
import '../services/voice.dart';
import 'tech_view.dart';
import 'theme.dart';

/// Stato dell'app salvato sul telefono: preferiti e tecniche viste.
class AppState extends ChangeNotifier {
  final Catalog catalog;
  final SharedPreferences prefs;
  final Voice voice = Voice();
  AppState(this.catalog, this.prefs) {
    voice.enabled = prefs.getBool('voce') ?? true;
  }

  Set<String> get favs => (prefs.getStringList('preferiti') ?? const []).toSet();
  Set<String> get seen => (prefs.getStringList('viste') ?? const []).toSet();

  void toggleFav(String id) {
    final f = favs;
    f.contains(id) ? f.remove(id) : f.add(id);
    prefs.setStringList('preferiti', f.toList());
    notifyListeners();
  }

  void markSeen(String id) {
    final s = seen..add(id);
    prefs.setStringList('viste', s.toList());
  }

  void toggleVoice() {
    voice.enabled = !voice.enabled;
    prefs.setBool('voce', voice.enabled);
    if (!voice.enabled) voice.stop();
    notifyListeners();
  }
}

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
    final pages = [HomeScreen(app: app), const ComingSoon('Percorso', ['Lezioni da 5 minuti per cintura', 'Serie di giorni e obiettivo giornaliero', 'Esame simulato']), CatalogScreen(app: app),
      const ComingSoon('Impara', ['Glossario parlante', 'Comandi e conteggio', 'Quiz, Dōjō kun e i 20 principi']), const ComingSoon('Profilo', ['Diario e promemoria', 'Il mio dojo', 'Preferiti'])];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
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

void openTech(BuildContext context, AppState app, Technique t) {
  app.markSeen(t.id);
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(app: app, tech: t)));
}

class HomeScreen extends StatelessWidget {
  final AppState app;
  const HomeScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final t = app.catalog.byId('combo1') ?? app.catalog.all.first;
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Eyebrow('Ciao'),
      Text('Oggi al dojo', style: K.hand.copyWith(fontSize: 34)),
      const SizedBox(height: 14),
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
      TechGrid(app: app, techs: [for (final id in ['gedan', 'gyaku', 'oizuki', 'maegeri']) ?app.catalog.byId(id)]),
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
          Text(t.description, style: const TextStyle(color: K.leadSoft)),
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
          const SizedBox(height: 12),
          Text('Punti chiave', style: K.hand.copyWith(fontSize: 24)),
          for (final p in t.keyPoints) Text('•  $p'),
          const SizedBox(height: 12),
          Text('Errori comuni', style: K.hand.copyWith(fontSize: 24)),
          for (final p in t.commonErrors) Text('•  $p'),
          const SizedBox(height: 12),
          if (t.toVerify.isNotEmpty) Text('Da verificare con un istruttore: ${t.toVerify.join('; ')}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: K.leadSoft)),
          Text('Fonti: ${t.sources.join('; ')}. Testo riscritto.', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: K.leadSoft)),
        ]),
      ),
    );
  }
}

class ComingSoon extends StatelessWidget {
  final String title;
  final List<String> items;
  const ComingSoon(this.title, this.items, {super.key});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
        Text(title, style: K.hand.copyWith(fontSize: 34)),
        const SizedBox(height: 12),
        RoughBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nella prossima versione', style: K.hand.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            for (final i in items) Text('•  $i'),
          ]),
        ),
      ]);
}
