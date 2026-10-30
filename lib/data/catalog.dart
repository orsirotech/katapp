import 'dart:convert';

import 'package:flutter/services.dart';

import '../engine/pose.dart';

/// Un passo della scheda: per le tecniche singole il testo, per kata e combinazioni
/// anche il numero, la posizione e il kiai.
class Step {
  final String label; // "1", "Yoi"...
  final String text;
  final String? stance;
  final bool kiai;
  final double t;
  const Step({required this.label, required this.text, this.stance, this.kiai = false, required this.t});

  /// Le righe di kata e combinazioni hanno un numero o una parola di comando (Yoi, Yame).
  bool get isSequence => stance != null;
}

class Technique {
  final String id, categoryId, nameJp, nameIt, description, animPath;
  final int kyu;
  final List<Step> steps;
  final List<String> keyPoints, commonErrors, sources, toVerify;
  Anim? anim;

  Technique({
    required this.id, required this.categoryId, required this.nameJp, required this.nameIt, required this.description, required this.animPath,
    required this.kyu, required this.steps, required this.keyPoints, required this.commonErrors, required this.sources, required this.toVerify,
  });

  bool get isKata => categoryId == 'kata';
  bool get isSequence => steps.isNotEmpty && steps.first.isSequence;

  factory Technique.fromJson(String cat, Map<String, dynamic> j) {
    List<String> strs(String k) => [for (final s in (j[k] as List? ?? const [])) s as String];
    final seq = j['sequenza'] as List?;
    final steps = seq != null
        ? [for (final s in seq) Step(label: s['passo'] as String, text: s['tecnica'] as String, stance: s['posizione'] as String?, kiai: s['kiai'] == true, t: (s['t_anim'] as num).toDouble())]
        : [for (final s in (j['passi'] as List? ?? const [])) Step(label: '${s['n']}', text: s['testo'] as String, t: (s['t_anim'] as num).toDouble())];
    return Technique(
      id: j['id'] as String,
      categoryId: cat,
      nameJp: j['nome_jp'] as String,
      nameIt: j['nome_it'] as String,
      description: j['descrizione'] as String? ?? '',
      animPath: (j['animazione'] as Map?)?['pose'] as String? ?? '',
      kyu: (j['kyu'] as num?)?.toInt() ?? 9,
      steps: steps,
      keyPoints: strs('punti_chiave'),
      commonErrors: strs('errori_comuni'),
      sources: strs('fonti'),
      toVerify: strs('da_verificare'),
    );
  }
}

class Category {
  final String id, nameIt, nameJp;
  final List<Technique> techniques;
  const Category(this.id, this.nameIt, this.nameJp, this.techniques);
}

class Catalog {
  final List<Category> categories;
  Catalog(this.categories);

  List<Technique> get all => [for (final c in categories) ...c.techniques];
  Technique? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Carica schede e animazioni dagli asset (contenuti esportati dal prototipo).
  static Future<Catalog> load(AssetBundle bundle) async {
    final j = jsonDecode(await bundle.loadString('assets/contenuti/tecniche.json')) as Map<String, dynamic>;
    final cats = [
      for (final c in j['categorie'] as List)
        Category(c['id'] as String, c['nome_it'] as String, c['nome_jp'] as String? ?? '', [for (final t in c['tecniche'] as List) Technique.fromJson(c['id'] as String, t as Map<String, dynamic>)])
    ];
    final cat = Catalog(cats);
    final cache = <String, Anim>{};
    for (final t in cat.all) {
      if (t.animPath.isEmpty) continue;
      t.anim = cache[t.animPath] ??= Anim.fromJson(jsonDecode(await bundle.loadString('assets/contenuti/${t.animPath}')) as Map<String, dynamic>);
    }
    return cat;
  }
}
