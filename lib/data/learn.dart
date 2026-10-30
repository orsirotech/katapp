import 'dart:convert';

import 'package:flutter/services.dart';

/// Testo senza macron né accenti, in minuscolo, per cercare e collegare le parole (Chūdan → chudan).
String plain(String s) {
  const from = 'āēīōūĀĒĪŌŪàáèéìíòóùú', to = 'aeiouaeiouaaeeiioouu';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

/// La prima frase di una definizione, per le liste e le risposte del quiz.
String firstClause(String s) => s.split(RegExp(r'[.:]')).first;

class Term {
  final String id, romaji, kanji, kana, meaning, category;
  final List<(String, String)> parts;
  final List<String> alias;
  const Term({required this.id, required this.romaji, required this.kanji, required this.kana, required this.meaning, required this.category, this.parts = const [], this.alias = const []});

  factory Term.fromJson(Map<String, dynamic> j) => Term(
        id: j['id'] as String,
        romaji: j['romaji'] as String,
        kanji: j['kanji'] as String,
        kana: j['kana'] as String,
        meaning: j['significato'] as String,
        category: j['categoria'] as String,
        parts: [for (final p in (j['parti'] as List? ?? const [])) (p['parte'] as String, p['senso'] as String)],
        alias: [for (final a in (j['alias'] as List? ?? const [])) a as String],
      );
}

class Said {
  final String romaji, kana, meaning;
  const Said(this.romaji, this.kana, this.meaning);
}

class Principle {
  final String jp, it, explain, ask;
  const Principle(this.jp, this.it, this.explain, [this.ask = '']);
}

/// Contenuti di Impara: glossario, comandi, conteggio, filosofia, etichetta.
class Learn {
  final List<Term> glossary;
  final List<Said> commands, count;
  final List<Principle> dojoKun, nijukun;
  final Map<String, (String, String)> kataMeaning;
  final List<(String, List<String>)> etiquette;
  final Map<String, Term> _byWord = {};

  Learn({required this.glossary, required this.commands, required this.count, required this.dojoKun, required this.nijukun, required this.kataMeaning, required this.etiquette}) {
    for (final g in glossary) {
      _byWord[plain(g.romaji)] = g;
      for (final a in g.alias) {
        _byWord[a] = g;
      }
    }
  }

  static const categories = [('tutte', 'Tutte'), ('gen', 'Generale'), ('dojo', 'Dojo'), ('dachi', 'Posizioni'), ('uke', 'Parate'), ('att', 'Attacchi'), ('geri', 'Calci'), ('kata', 'Kata')];

  /// La voce del glossario per una parola, se c'è ("do" è escluso: in italiano è una parola comune).
  Term? word(String w) => w.length > 1 && w != 'do' ? _byWord[plain(w)] : null;

  Term? byId(String id) {
    for (final g in glossary) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Le parole del glossario contenute in un nome di tecnica (Gyaku-zuki chūdan → gyaku, zuki, chudan).
  List<Term> wordsIn(String name) => {for (final w in name.split(RegExp(r'[^A-Za-zōūŌŪ]+'))) ?word(w)}.toList();

  List<Term> search(String q, String cat) {
    final p = plain(q.trim());
    return [
      for (final g in glossary)
        if ((cat == 'tutte' || g.category == cat) && (p.isEmpty || plain('${g.romaji} ${g.meaning} ${g.alias.join(' ')}').contains(p))) g
    ];
  }

  factory Learn.fromJson(Map<String, dynamic> j) => Learn(
        glossary: [for (final g in j['glossario'] as List) Term.fromJson(g as Map<String, dynamic>)],
        commands: [for (final c in j['comandi'] as List) Said(c['romaji'] as String, c['kana'] as String, c['significato'] as String)],
        count: [for (final c in j['conteggio'] as List) Said(c['romaji'] as String, c['kana'] as String, '${c['numero']}')],
        dojoKun: [for (final d in j['dojo_kun'] as List) Principle(d['giapponese'] as String, d['italiano'] as String, d['spiegazione'] as String)],
        nijukun: [for (final d in j['nijukun'] as List) Principle(d['giapponese'] as String, d['italiano'] as String, d['spiegazione'] as String, d['domanda'] as String? ?? '')],
        kataMeaning: {for (final e in (j['significato_kata'] as Map).entries) e.key as String: (e.value['nome'] as String, e.value['insegna'] as String)},
        etiquette: [for (final e in j['etichetta'] as List) (e['titolo'] as String, [for (final p in e['punti'] as List) p as String])],
      );

  static Future<Learn> load(AssetBundle bundle) async => Learn.fromJson(jsonDecode(await bundle.loadString('assets/contenuti/impara.json')) as Map<String, dynamic>);
}
