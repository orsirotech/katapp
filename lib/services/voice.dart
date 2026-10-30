import 'package:flutter_tts/flutter_tts.dart';

/// La voce che chiama le tecniche: italiano per le istruzioni, giapponese per il conteggio.
class Voice {
  final FlutterTts _tts = FlutterTts();
  bool enabled = true;

  static const count = ['いち', 'に', 'さん', 'し', 'ご', 'ろく', 'しち', 'はち', 'く', 'じゅう'];

  /// Romaji letto dalla voce italiana: senza trattini né macron (chūdan → chudan).
  static String clean(String s) {
    const from = 'āēīōūĀĒĪŌŪ', to = 'aeiouAEIOU';
    final b = StringBuffer();
    for (final ch in s.replaceAll('-', ' ').split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    return b.toString();
  }

  /// [force] parla anche con la voce spenta: per i pulsanti 🔊 del glossario.
  Future<void> say(String text, {String lang = 'it-IT', bool force = false}) async {
    if (!enabled && !force) return;
    await _tts.stop();
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(lang == 'ja-JP' ? .42 : .5);
    await _tts.speak(lang == 'it-IT' ? clean(text) : text);
  }

  Future<void> stop() => _tts.stop();
}
