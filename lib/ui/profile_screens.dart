import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progress.dart';
import 'screens.dart';
import 'theme.dart';
import 'widgets.dart';

void _push(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
void openDojo(BuildContext context, AppState app) => _push(context, DojoScreen(app: app));

class ProfileScreen extends StatelessWidget {
  final AppState app;
  const ProfileScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final p = app.progress, g = p.grade, nt = p.tasks.length;
    return Paper(title: 'Profilo', children: [
      Card2(
        eyebrow: 'Grado nell\'app',
        title: '$g° kyu${g < 10 ? ' · esame simulato superato' : ' · cintura bianca'}',
        text: '${app.seen.length} tecniche studiate · 🔥 ${p.streak} giorni di fila · ${p.totalXp} punti',
      ),
      Row(children: [
        Expanded(child: Card2(title: 'Diario', text: 'Calendario, serie, promemoria', onTap: () => _push(context, DiaryScreen(app: app)))),
        const SizedBox(width: 12),
        Expanded(child: Card2(title: 'Il mio dojo', text: nt > 0 ? '$nt ${nt == 1 ? 'compito' : 'compiti'}' : 'Compiti dall\'istruttore', onTap: () => openDojo(context, app))),
      ]),
      Card2(title: 'Preferiti', badge: '${app.favs.length} ☆', onTap: () => _push(context, FavoritesScreen(app: app))),
      const Sec('Programma per cintura'),
      for (final (k, belt, ids) in beltProgram)
        Card2(title: k, badge: belt, children: [
          for (final id in ids)
            if (app.catalog.byId(id) case final t?)
              InkWell(
                onTap: () => app.openTech(context, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${app.seen.contains(id) ? '✓ ' : ''}${t.nameJp}'),
                    TextSpan(text: '  · ${t.nameIt}', style: const TextStyle(fontSize: 12, color: K.leadSoft)),
                  ])),
                ),
              ),
        ]),
      const Note('Programma di esempio, da allineare a quello del tuo dojo.'),
    ]);
  }
}

class FavoritesScreen extends StatelessWidget {
  final AppState app;
  const FavoritesScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final list = [for (final t in app.catalog.all) if (app.favs.contains(t.id)) t];
          return Paper(back: 'profilo', title: 'Preferiti', badge: 'offline', children: [
            if (list.isEmpty) const Card2(title: 'Ancora niente', text: 'Tocca la stella ☆ in una tecnica per salvarla qui e ripassarla anche senza rete.') else TechGrid(app: app, techs: list),
          ]);
        },
      );
}

class DiaryScreen extends StatefulWidget {
  final AppState app;
  const DiaryScreen({super.key, required this.app});
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  @override
  Widget build(BuildContext context) {
    final app = widget.app, p = app.progress, log = p.log, now = p.now();
    final mins = log.fold(0.0, (a, e) => a + e.min).round(), sess = log.where((e) => e.kind == 'allenamento').length, lez = log.where((e) => e.kind == 'lezione').length;
    const months = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'];
    return Paper(back: 'profilo', title: 'Diario', subtitle: '${months[now.month - 1]} ${now.year}', children: [
      GoalCard(app),
      Card2(children: [_Calendar(p), const Muted('Pieno: obiettivo raggiunto. Tratteggiato: un po\' di pratica.')]),
      Row(children: [
        for (final (n, l) in [(p.streak, 'giorni di fila'), (mins, 'minuti'), (sess, 'allenamenti'), (lez, 'lezioni')])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: RoughBox(padding: const EdgeInsets.all(8), child: Column(children: [Text('$n', style: K.hand.copyWith(fontSize: 30)), Text(l, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)])),
            ),
          ),
      ]),
      const Sec('Ultime attività'),
      if (log.isEmpty) const Muted('Ancora niente: fai la prima lezione del percorso.'),
      for (final e in log.reversed.take(6))
        Text.rich(TextSpan(children: [TextSpan(text: '${itDate(e.day, month: false)} · ${e.title.isEmpty ? e.kind : e.title}'), TextSpan(text: '  +${e.xp}', style: const TextStyle(color: K.leadSoft))])),
      const SizedBox(height: 12),
      Card2(title: 'Promemoria', children: [
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          HandButton(p.remindOn ? 'attivo' : 'spento', outlined: true, on: p.remindOn, onTap: () async {
            if (!p.remindOn && app.reminder.supported && !await app.reminder.askPermission()) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Per il promemoria serve il permesso per le notifiche.')));
              return;
            }
            setState(() => p.setRemind(!p.remindOn, p.remindAt));
            app.changed();
          }),
          HandButton('alle ${p.remindAt}', onTap: () async {
            final parts = p.remindAt.split(':');
            final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
            if (t == null) return;
            setState(() => p.setRemind(p.remindOn, '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'));
            app.changed();
          }),
        ]),
        Muted(p.remindOn ? 'Ogni giorno alle ${p.remindAt}, se non ti sei ancora allenato.' : 'Un avviso al giorno per non rompere la serie.'),
        if (!app.reminder.supported) const Note('Le notifiche funzionano nell\'app sul telefono.'),
      ]),
    ]);
  }
}

class _Calendar extends StatelessWidget {
  final Progress p;
  const _Calendar(this.p);

  @override
  Widget build(BuildContext context) {
    final now = p.now(), first = DateTime(now.year, now.month, 1), days = DateTime(now.year, now.month + 1, 0).day, pad = first.weekday - 1;
    Widget cell(int d) {
      final key = dayKey(DateTime(now.year, now.month, d)), xp = p.xpOn(key), full = xp >= goal, today = d == now.day;
      return Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: full ? K.lead : xp > 0 ? K.lead.withValues(alpha: .18) : null,
          border: today ? Border.all(color: K.red, width: 2) : null,
        ),
        child: Text('$d', style: TextStyle(fontSize: 13, color: full ? K.paper : K.lead)),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final d in ['L', 'M', 'M', 'G', 'V', 'S', 'D']) Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w700))),
        for (var i = 0; i < pad; i++) const SizedBox(),
        for (var d = 1; d <= days; d++) cell(d),
      ],
    );
  }
}

/// Il mio dojo: compiti ricevuti con un codice e, per l'istruttore, la creazione del codice.
class DojoScreen extends StatefulWidget {
  final AppState app;
  const DojoScreen({super.key, required this.app});
  @override
  State<DojoScreen> createState() => _DojoScreenState();
}

class _DojoScreenState extends State<DojoScreen> {
  final code = TextEditingController(), name = TextEditingController(), title = TextEditingController(), note = TextEditingController(), reps = TextEditingController(text: '10');
  final pick = <String>[];
  String? err, out, due;

  @override
  void dispose() {
    for (final c in [code, name, title, note, reps]) {
      c.dispose();
    }
    super.dispose();
  }

  void _add(String c) {
    setState(() => err = widget.app.progress.addTask(c));
    if (err == null) code.clear();
    widget.app.changed();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app, p = app.progress, tasks = p.tasks;
    InputDecoration dec(String h) => InputDecoration(hintText: h, border: const OutlineInputBorder(), isDense: true);
    return Paper(back: 'profilo', title: 'Il mio dojo', subtitle: 'L\'istruttore prepara un compito, lo condivide con un codice nel gruppo del dojo e gli allievi lo trovano qui.', children: [
      const Sec('Compiti ricevuti'),
      if (tasks.isEmpty) const Muted('Nessun compito per ora.'),
      for (final t in tasks)
        Card2(eyebrow: '${t.dojo}${t.due.isNotEmpty ? ' · entro il ${itDate(t.due)}' : ''}', title: t.title, text: t.note.isEmpty ? null : t.note, children: [
          for (final id in t.ids)
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => app.openTech(context, app.catalog.byId(id)!),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: app.catalog.byId(id)!.nameJp, style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: '  ${app.catalog.byId(id)!.isKata ? '2 volte' : '× ${t.reps} per lato'}', style: const TextStyle(color: K.leadSoft)),
                  ])),
                ),
              ),
              HandButton(t.done.contains(id) ? '✓ fatto' : 'fatto?', on: t.done.contains(id), onTap: () => setState(() => p.toggleTaskDone(t.id, id))),
            ]),
          Bar(t.done.length / t.ids.length),
        ]),
      Row(children: [
        Expanded(child: TextField(controller: code, decoration: dec('Incolla il codice KAT-…'))),
        HandButton('aggiungi', outlined: true, onTap: () => _add(code.text)),
      ]),
      if (err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(err!, style: const TextStyle(color: K.red))),
      const Sec('Sono l\'istruttore'),
      Card2(children: [
        TextField(controller: name, decoration: dec('Nome del dojo')),
        const SizedBox(height: 8),
        TextField(controller: title, decoration: dec('Titolo, es. Ripasso per l\'esame')),
        const SizedBox(height: 10),
        const Eyebrow('Tecniche da assegnare'),
        const SizedBox(height: 6),
        Wrap(children: [
          for (final t in app.catalog.all)
            Pill(t.nameJp, on: pick.contains(t.id), onTap: () => setState(() => pick.contains(t.id) ? pick.remove(t.id) : pick.add(t.id))),
        ]),
        Row(children: [
          SizedBox(width: 110, child: TextField(controller: reps, keyboardType: TextInputType.number, decoration: dec('Ripetizioni').copyWith(labelText: 'Ripetizioni'))),
          const SizedBox(width: 8),
          HandButton(due == null ? 'entro il…' : 'entro il ${itDate(due!)}', onTap: () async {
            final n = p.now(), d = await showDatePicker(context: context, firstDate: n, lastDate: n.add(const Duration(days: 365)), initialDate: n.add(const Duration(days: 7)));
            if (d != null) setState(() => due = dayKey(d));
          }),
        ]),
        const SizedBox(height: 8),
        TextField(controller: note, decoration: dec('Nota per gli allievi (facoltativa)')),
        const SizedBox(height: 8),
        HandButton('crea il codice', outlined: true, onTap: pick.isEmpty
            ? () {}
            : () => setState(() => out = encodeTask(dojo: name.text, title: title.text, ids: pick, reps: (int.tryParse(reps.text) ?? 10).clamp(1, 50), due: due ?? '', note: note.text))),
        if (out != null) ...[
          const SizedBox(height: 8),
          const Muted('Manda questo messaggio nel gruppo del dojo:'),
          const SizedBox(height: 4),
          RoughBox(fill: K.paper2, child: SelectableText(_message())),
          Wrap(children: [
            HandButton('copia', outlined: true, onTap: () {
              Clipboard.setData(ClipboardData(text: _message()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaggio copiato')));
            }),
            HandButton('provalo come allievo', onTap: () => _add(out!)),
          ]),
        ],
      ]),
      const Note('Il codice contiene tutto il compito. In una prossima versione il dojo avrà un gruppo condiviso e l\'istruttore vedrà chi l\'ha completato.'),
    ]);
  }

  String _message() => 'Nuovo compito su KatApp: "${title.text.isEmpty ? 'Compito' : title.text}". Apri Profilo → Il mio dojo e incolla il codice: $out';
}
