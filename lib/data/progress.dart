import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'learn.dart';

String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<T> shuffled<T>(Iterable<T> a, Random r) => a.toList()..shuffle(r);

/// Una voce del diario: lezione, allenamento, quiz o esame.
class LogEntry {
  final String day, kind, title;
  final int xp;
  final double min;
  const LogEntry(this.day, this.kind, this.xp, this.min, this.title);
  Map<String, dynamic> toJson() => {'d': day, 'k': kind, 'xp': xp, 'min': min, 'title': title};
  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(j['d'] as String, j['k'] as String, (j['xp'] as num).toInt(), (j['min'] as num? ?? 0).toDouble(), j['title'] as String? ?? '');
}

/// Compito dell'istruttore, ricevuto con un codice KAT-…
class DojoTask {
  final String id, dojo, title, due, note;
  final List<String> ids, done;
  final int reps;
  DojoTask({required this.id, required this.dojo, required this.title, required this.ids, required this.reps, this.due = '', this.note = '', List<String>? done}) : done = done ?? [];
  bool get complete => done.length >= ids.length;
  Map<String, dynamic> toJson() => {'id': id, 'dojo': dojo, 'title': title, 'ids': ids, 'reps': reps, 'due': due, 'note': note, 'done': done};
  factory DojoTask.fromJson(Map<String, dynamic> j) => DojoTask(
      id: j['id'] as String, dojo: j['dojo'] as String, title: j['title'] as String, ids: [for (final i in j['ids'] as List) i as String], reps: (j['reps'] as num).toInt(), due: j['due'] as String? ?? '', note: j['note'] as String? ?? '', done: [for (final i in (j['done'] as List? ?? const [])) i as String]);
}

/// Codice del compito: "KAT-" + JSON in base64url, lo stesso formato del prototipo.
String encodeTask({required String dojo, required String title, required List<String> ids, required int reps, String due = '', String note = ''}) =>
    'KAT-${base64Url.encode(utf8.encode(jsonEncode({'n': dojo, 't': title, 'i': ids, 'r': reps, 'd': due, 'no': note}))).replaceAll('=', '')}';

Map<String, dynamic> decodeTask(String code) {
  final s = code.trim().replaceFirst(RegExp(r'^KAT-', caseSensitive: false), '');
  return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(s)))) as Map<String, dynamic>;
}

/// Un livello del percorso: le tecniche di un kyu, divise in lezioni da circa 5 minuti.
class Level {
  final int kyu;
  final String belt;
  final List<String> ids;
  final List<List<String>> lessons;
  const Level(this.kyu, this.belt, this.ids, this.lessons);
}

const kyuIds = {
  9: ['zenkutsu', 'gedan', 'ageuke', 'gyaku', 'oizuki', 'maegeri', 'taikyoku1'],
  8: ['kokutsu', 'soto', 'uchiuke', 'shutouke', 'combo1', 'combo2', 'combo3', 'combo4', 'heian1'],
  7: ['kiba', 'kizami', 'urazuki', 'shutouchi', 'uraken', 'empi', 'nukite', 'keage', 'kekomi', 'combo5', 'combo6', 'combo7', 'heian2'],
  6: ['mawashi', 'ushiro'],
};

/// Programma per cintura mostrato nel profilo.
const beltProgram = [
  ('10° kyu', 'prima cintura', ['musubi', 'heiko']),
  ('9° kyu', 'cintura bianca', ['zenkutsu', 'gedan', 'ageuke', 'gyaku', 'oizuki', 'maegeri', 'taikyoku1']),
  ('8° kyu', 'cintura gialla', ['kokutsu', 'soto', 'uchiuke', 'shutouke', 'combo1', 'combo2', 'combo3', 'combo4', 'heian1']),
  ('7° kyu', 'cintura arancio', ['kiba', 'kizami', 'urazuki', 'shutouchi', 'uraken', 'empi', 'nukite', 'keage', 'kekomi', 'combo5', 'combo6', 'combo7', 'heian2']),
  ('6° kyu', 'cintura verde', ['mawashi', 'ushiro']),
];

List<Level> buildLevels(Catalog c) {
  Level make(int kyu, String belt, List<String> ids) {
    ids = ids.where((id) => c.byId(id) != null).toList();
    // due tecniche alla volta, i kata da soli
    final out = <List<String>>[];
    var cur = <String>[];
    for (final id in ids) {
      if (c.byId(id)!.isKata) {
        if (cur.isNotEmpty) out.add(cur);
        out.add([id]);
        cur = [];
      } else {
        cur.add(id);
        if (cur.length == 2) {
          out.add(cur);
          cur = [];
        }
      }
    }
    if (cur.isNotEmpty) out.add(cur);
    return Level(kyu, belt, ids, out);
  }

  return [make(9, 'cintura bianca', ['musubi', 'heiko', ...kyuIds[9]!]), make(8, 'cintura gialla', kyuIds[8]!), make(7, 'cintura arancio', kyuIds[7]!), make(6, 'cintura verde', kyuIds[6]!)];
}

class Question {
  final String kind, q, a, why;
  final List<String> opts;
  final String? techId, say;
  const Question({required this.kind, required this.q, required this.opts, required this.a, required this.why, this.techId, this.say});
}

/// Domande riusabili: dal disegno, dal significato delle parole, dall'ordine nei kata.
class QuizMaker {
  final Catalog c;
  final Learn l;
  final Random r;
  QuizMaker(this.c, this.l, this.r);

  Question pic(Technique x) {
    final other = shuffled(c.all.where((y) => y.id != x.id && !y.isKata && y.categoryId == x.categoryId), r).take(3).toList();
    final rest = shuffled(c.all.where((y) => y.id != x.id && !y.isKata && !other.contains(y)), r);
    while (other.length < 3) {
      other.add(rest.removeLast());
    }
    return Question(kind: 'pic', techId: x.id, q: 'Che tecnica è questa?', opts: shuffled([x, ...other].map((y) => y.nameJp), r), a: x.nameJp, why: x.description);
  }

  Question word(Term g) {
    final other = shuffled(l.glossary.where((h) => h != g && h.category != 'dojo'), r).take(3);
    return Question(kind: 'word', q: 'Cosa vuol dire "${g.romaji}"?', opts: shuffled([g, ...other].map((h) => firstClause(h.meaning)), r), a: firstClause(g.meaning), why: '${g.romaji} ${g.kanji}: ${g.meaning}', say: g.kana);
  }

  Question kata(Technique k) {
    final rows = k.steps, i = 1 + r.nextInt(rows.length - 3), right = rows[i + 1].text;
    final other = shuffled({for (final s in rows.sublist(1, rows.length - 1)) s.text}.where((t) => t != right), r).take(3);
    return Question(
        kind: 'kata',
        techId: k.id,
        q: 'In ${k.nameJp}, cosa viene dopo il passo ${rows[i].label} (${rows[i].text})?',
        opts: shuffled([right, ...other], r),
        a: right,
        why: 'Passo ${rows[i + 1].label}: $right${rows[i + 1].kiai ? ', con kiai' : ''}.');
  }

  List<Term> wordsOf(Iterable<Technique> ts) => {for (final t in ts) ...l.wordsIn(t.nameJp)}.toList();

  /// Tre domande alla fine di una lezione.
  List<Question> lesson(List<String> ids) {
    final ts = [for (final id in ids) c.byId(id)!], q = [for (final x in ts) x.isKata ? kata(x) : pic(x)];
    if (ts.any((x) => x.isKata)) q.add(kata(ts.firstWhere((x) => x.isKata)));
    q.addAll(shuffled(wordsOf(ts), r).take(3 - min(q.length, 2)).map(word));
    return shuffled(q, r).take(3).toList();
  }

  /// Otto domande sul programma fino al kyu scelto.
  List<Question> forKyu(int kyu) {
    final ts = [for (final e in kyuIds.entries) if (e.key >= kyu) for (final id in e.value) ?c.byId(id)], q = <Question>[];
    q.addAll(shuffled(ts.where((x) => !x.isSequence), r).take(3).map(pic));
    q.addAll(shuffled(wordsOf(ts), r).take(3).map(word));
    final kt = ts.where((x) => x.isKata).toList();
    for (var n = 0; n < 2 && kt.isNotEmpty; n++) {
      q.add(kata(kt[r.nextInt(kt.length)]));
    }
    q.add(Question(
        kind: 'phil',
        q: 'Secondo Funakoshi, con cosa inizia e finisce il karate?',
        opts: shuffled(['Con il saluto', 'Con il kiai', 'Con una parata', 'Con il riscaldamento'], r),
        a: 'Con il saluto',
        why: 'Primo dei 20 principi: "Karate-dō wa rei ni hajimari rei ni owaru".'));
    return shuffled(q, r).take(8).toList();
  }
}

/// Un tratto dell'allenamento guidato: cerimonia, lista di esercizi o tecnica da ripetere.
class Segment {
  final String kind; // cer, list, kihon
  final String title, sub;
  final List<String> items;
  final double each, speed;
  final String? techId;
  final int reps;
  final bool noCount;
  final String? say;
  double dur;
  Segment({required this.kind, this.title = '', this.sub = '', this.items = const [], this.each = 0, this.techId, this.reps = 0, this.speed = 1, this.noCount = false, this.say, this.dur = 0});
}

const warmUp = ['Rotazione del collo, lenta', 'Cerchi con le spalle avanti e indietro', 'Rotazione delle anche', 'Piegamenti sulle ginocchia', 'Rotazione delle caviglie', 'Saltelli sul posto'];
const stretch = ['Allungamento dei polpacci', 'Affondo laterale, gamba tesa', 'Farfalla da seduti', 'Respiro lento, braccia in alto'];
const focuses = [('misto', 'Misto'), ('kihon', 'Kihon'), ('geri', 'Calci'), ('kata', 'Kata'), ('esame', 'Il mio esame')];
const goal = 20;

/// Progressi salvati sul telefono: diario e punti, ripasso a intervalli, percorso, quiz, compiti del dojo.
class Progress {
  final SharedPreferences prefs;
  final Catalog catalog;
  final DateTime Function() now;
  final Random rnd;
  late final List<Level> levels = buildLevels(catalog);

  Progress(this.prefs, this.catalog, {DateTime Function()? now, Random? rnd})
      : now = now ?? DateTime.now,
        rnd = rnd ?? Random();

  dynamic _get(String k, dynamic def) {
    final s = prefs.getString(k);
    return s == null ? def : jsonDecode(s);
  }

  void _set(String k, Object v) => prefs.setString(k, jsonEncode(v));

  String get today => dayKey(now());
  String addDays(int n) => dayKey(now().add(Duration(days: n)));

  // ---- diario, punti e serie ----
  List<LogEntry> get log => [for (final e in _get('ka-log', []) as List) LogEntry.fromJson(e as Map<String, dynamic>)];
  void addLog(String kind, int xp, double min, String title) => _set('ka-log', [...log.map((e) => e.toJson()), LogEntry(today, kind, xp, min, title).toJson()]);
  int xpOn(String day) => log.where((e) => e.day == day).fold(0, (a, e) => a + e.xp);
  int get totalXp => log.fold(0, (a, e) => a + e.xp);

  int get streak {
    final days = {for (final e in log) e.day};
    var n = 0, d = now();
    if (!days.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
    while (days.contains(dayKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  // ---- ripasso a intervalli: 1, 2, 4, 7, 14 giorni ----
  static const _gaps = [1, 2, 4, 7, 14];
  Map<String, dynamic> get _rev => (_get('ka-rev', <String, dynamic>{}) as Map).cast<String, dynamic>();
  String? reviewDue(String id) => (_rev[id] as Map?)?['due'] as String?;

  void rate(String id, bool ok) {
    final all = _rev, old = all[id] as Map?;
    final box = ok ? min(4, ((old?['box'] as num?)?.toInt() ?? 0) + (old != null ? 1 : 0)) : 0;
    all[id] = {'box': box, 'due': addDays(_gaps[box])};
    _set('ka-rev', all);
  }

  List<Technique> dueList(Set<String> seen) {
    final rev = _rev;
    return [
      for (final t in catalog.all)
        if (seen.contains(t.id) && (rev[t.id] == null || ((rev[t.id] as Map)['due'] as String).compareTo(today) <= 0)) t
    ];
  }

  // ---- percorso ----
  Map<String, dynamic> get _path => (_get('ka-path', <String, dynamic>{}) as Map).cast<String, dynamic>();
  bool lessonDone(int li, int j) => _path['$li-$j'] != null;
  bool levelDone(int li) => [for (var j = 0; j < levels[li].lessons.length; j++) lessonDone(li, j)].every((x) => x);
  bool levelOpen(int li) => li == 0 || levelDone(li - 1);
  bool canStart(int li, int j) => levelOpen(li) && (j == 0 || lessonDone(li, j - 1));
  int? examScore(int kyu) => (_path['exam$kyu'] as num?)?.toInt();
  int get curLevel {
    for (var li = 0; li < levels.length; li++) {
      if (!levelDone(li)) return li;
    }
    return levels.length - 1;
  }

  (int, int)? get nextLesson {
    for (var li = 0; li < levels.length; li++) {
      for (var j = 0; j < levels[li].lessons.length; j++) {
        if (!lessonDone(li, j)) return (li, j);
      }
    }
    return null;
  }

  String lessonName(List<String> ids) => ids.map((id) => catalog.byId(id)!.nameJp).join(' e ');

  void completeLesson(int li, int j) {
    _set('ka-path', _path..['$li-$j'] = 1);
    addLog('lezione', 10, 5, 'Lezione: ${lessonName(levels[li].lessons[j])}');
  }

  void recordExam(int kyu, int ok) {
    final p = _path;
    p['exam$kyu'] = max((p['exam$kyu'] as num?)?.toInt() ?? 0, ok);
    _set('ka-path', p);
    addLog('esame', ok >= 6 ? 30 : 10, 3, 'Esame $kyu° kyu: $ok/8');
  }

  /// Grado nell'app: il kyu più alto con l'esame simulato superato.
  int get grade {
    final passed = [for (final L in levels) if ((examScore(L.kyu) ?? 0) >= 6) L.kyu];
    return passed.isEmpty ? 10 : passed.reduce(min);
  }

  // ---- quiz ----
  int? quizBest(int kyu) => ((_get('ka-quiz', <String, dynamic>{}) as Map)['$kyu'] as num?)?.toInt();
  void recordQuiz(int kyu, int ok) {
    final q = (_get('ka-quiz', <String, dynamic>{}) as Map).cast<String, dynamic>();
    q['$kyu'] = max((q['$kyu'] as num?)?.toInt() ?? 0, ok);
    _set('ka-quiz', q);
    addLog('quiz', 5, 2, 'Quiz $kyu° kyu: $ok/8');
  }

  // ---- promemoria ----
  bool get remindOn => prefs.getBool('ka-remind-on') ?? false;
  String get remindAt => prefs.getString('ka-remind-at') ?? '18:30';
  void setRemind(bool on, String at) {
    prefs.setBool('ka-remind-on', on);
    prefs.setString('ka-remind-at', at);
  }

  // ---- compiti del dojo ----
  List<DojoTask> get tasks => [for (final t in _get('ka-tasks', []) as List) DojoTask.fromJson(t as Map<String, dynamic>)];
  void _saveTasks(List<DojoTask> ts) => _set('ka-tasks', [for (final t in ts) t.toJson()]);

  /// Aggiunge un compito dal codice; restituisce un messaggio d'errore oppure null.
  String? addTask(String code) {
    try {
      final o = decodeTask(code), ids = [for (final i in (o['i'] as List? ?? const [])) if (catalog.byId(i as String) != null) i];
      if (ids.isEmpty) throw const FormatException();
      final c = code.trim(), id = c.substring(max(0, c.length - 10)), ts = tasks;
      if (ts.any((t) => t.id == id)) return 'Questo compito c\'è già.';
      ts.insert(0, DojoTask(id: id, dojo: o['n'] as String? ?? 'Dojo', title: o['t'] as String? ?? 'Compito', ids: ids, reps: (o['r'] as num?)?.toInt() ?? 10, due: o['d'] as String? ?? '', note: o['no'] as String? ?? ''));
      _saveTasks(ts);
      return null;
    } catch (_) {
      return 'Codice non valido: controlla di averlo copiato tutto.';
    }
  }

  void toggleTaskDone(String taskId, String techId) {
    final ts = tasks;
    for (final t in ts) {
      if (t.id == taskId) t.done.contains(techId) ? t.done.remove(techId) : t.done.add(techId);
    }
    _saveTasks(ts);
  }

  // ---- allenamento su misura ----
  double _durOf(Segment s) {
    if (s.kind == 'list') s.dur = s.items.length * s.each;
    if (s.kind == 'kihon') s.dur = catalog.byId(s.techId!)!.anim!.duration / s.speed * s.reps;
    return s.dur;
  }

  List<Segment> makePlan(int minutes, String focus, Set<String> seen) {
    final budget = minutes * 60.0, due = {for (final t in dueList(seen)) t.id}, r = rnd;
    List<String> pri(List<String> a) => [...a.where(due.contains), ...shuffled(a.where((id) => !due.contains(id)), r)];
    final all = catalog.all;
    final pool = (
      kihon: ['gedan', 'ageuke', 'gyaku', 'oizuki', 'soto', 'uchiuke', 'shutouke', 'kizami', 'urazuki', 'shutouchi', 'uraken', 'empi', 'nukite'],
      geri: ['maegeri', 'keage', 'kekomi', 'mawashi', 'ushiro'],
      combo: [for (final t in all) if (t.categoryId == 'combo') t.id],
      kata: [for (final t in all) if (t.isKata) t.id],
    );
    final reps = minutes >= 20 ? 16 : minutes >= 10 ? 10 : 6, nWarm = minutes >= 20 ? 6 : minutes >= 10 ? 5 : 3;
    Segment kh(String id) => Segment(kind: 'kihon', techId: id, reps: reps, speed: .7);
    Segment once(String id, [int n = 1]) => Segment(kind: 'kihon', techId: id, reps: n, speed: .8, noCount: true);
    final head = [
      Segment(kind: 'cer', title: 'Mokusō', sub: 'In seiza, occhi chiusi, respira con calma', dur: minutes >= 10 ? 20 : 12, say: 'Seiza. Mokusō'),
      Segment(kind: 'list', title: 'Riscaldamento', items: shuffled(warmUp, r).take(nWarm).toList(), each: minutes >= 20 ? 30 : 22),
    ];
    final tail = [
      Segment(kind: 'list', title: 'Defaticamento', items: shuffled(stretch, r).take(minutes >= 10 ? 4 : 2).toList(), each: minutes >= 20 ? 30 : 20),
      Segment(kind: 'cer', title: 'Saluto finale', sub: 'Mokusō, poi rei', dur: 15, say: 'Mokusō. Rei'),
    ];
    late List<Segment> Function() mid;
    switch (focus) {
      case 'kihon':
        mid = () => [...pri(pool.kihon).map(kh), ...pri(pool.combo).map((id) => once(id, 3))];
      case 'geri':
        mid = () => [...pri(pool.geri).map(kh), once('combo4', 3), ...pri(pool.geri).map(kh)];
      case 'kata':
        mid = () => [...pri(pool.kata).map((id) => once(id, 2)), ...pri(pool.kihon).take(3).map(kh)];
      case 'esame':
        final t = [for (final id in levels[curLevel].ids) catalog.byId(id)!];
        mid = () => [
              ...pri([for (final x in t) if (!x.isKata && x.categoryId != 'combo' && x.categoryId != 'dachi') x.id]).map(kh),
              ...pri([for (final x in t) if (x.categoryId == 'combo') x.id]).map((id) => once(id, 3)),
              for (final x in t) if (x.isKata) once(x.id, 2),
            ];
      default:
        final k = pri(pool.kihon), g = pri(pool.geri), c = pri(pool.combo), a = pri(pool.kata);
        mid = () => [kh(k[0]), kh(k[1]), kh(g[0]), once(c[0], 3), once(a[0]), kh(k[2]), kh(g[1]), once(c[1], 3), once(a.length > 1 ? a[1] : a[0]), kh(k[3]), once(c[2], 3)];
    }
    var used = [...head, ...tail].fold(0.0, (a, s) => a + _durOf(s));
    final body = <Segment>[];
    // la lista centrale si ripete fino a riempire il tempo scelto
    for (final s in [...mid(), ...mid(), ...mid()]) {
      final d = _durOf(s);
      if (used + d > budget * 1.06) continue;
      body.add(s);
      used += d;
    }
    if (body.isEmpty) body.add(mid().first..dur = 0);
    _durOf(body.first);
    return [...head, ...body, ...tail];
  }

  /// Parte pratica dell'esame simulato: la voce chiama le tecniche come un esaminatore.
  List<Segment> examPlan(int kyu) {
    final L = levels.firstWhere((l) => l.kyu == kyu), ts = [for (final id in L.ids) catalog.byId(id)!];
    final plan = [Segment(kind: 'cer', title: 'Esame simulato', sub: 'Rei. La voce chiama le tecniche come un esaminatore', dur: 12, say: 'Esame simulato per il $kyu° kyu. Rei')];
    plan.addAll(shuffled(ts.where((x) => !x.isKata && x.categoryId != 'combo' && x.categoryId != 'dachi'), rnd).take(4).map((x) => Segment(kind: 'kihon', techId: x.id, reps: 5, speed: .8)));
    plan.addAll(shuffled(ts.where((x) => x.categoryId == 'combo'), rnd).take(2).map((x) => Segment(kind: 'kihon', techId: x.id, reps: 1, speed: .8, noCount: true)));
    plan.addAll(ts.where((x) => x.isKata).map((x) => Segment(kind: 'kihon', techId: x.id, reps: 1, speed: .8, noCount: true)));
    for (final s in plan) {
      _durOf(s);
    }
    return plan;
  }
}
