import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/learn.dart';
import '../data/progress.dart';
import '../services/reminder.dart';
import '../services/voice.dart';
import 'screens.dart';

/// Stato dell'app salvato sul telefono: preferiti, tecniche viste, voce e progressi.
class AppState extends ChangeNotifier {
  final Catalog catalog;
  final Learn learn;
  final SharedPreferences prefs;
  final Progress progress;
  final Voice voice = Voice();
  final Reminder reminder = Reminder();
  AppState(this.catalog, this.learn, this.prefs, {Progress? progress}) : progress = progress ?? Progress(prefs, catalog) {
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

  /// Da chiamare dopo ogni modifica ai progressi: aggiorna le schermate e il promemoria.
  void changed() {
    notifyListeners();
    syncReminder();
  }

  Future<void> syncReminder() {
    final p = progress;
    return reminder.sync(on: p.remindOn, at: p.remindAt, trainedToday: p.xpOn(p.today) > 0, body: p.streak > 0 ? 'Non rompere la serie: ${p.streak} giorni di fila.' : 'Pochi minuti di kihon per iniziare la serie.');
  }

  void openTech(BuildContext context, Technique t) {
    markSeen(t.id);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(app: this, tech: t)));
  }
}
