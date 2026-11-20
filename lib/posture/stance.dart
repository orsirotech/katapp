import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../data/catalog.dart';
import '../engine/camera.dart';
import '../engine/pose.dart' as pose;
import '../engine/rig.dart';
import '../engine/vec.dart';

/// Le posizioni che l'app sa correggere, con la vista consigliata per la fotocamera.
const postureInfo = {
  'zenkutsu': ('lato', 'Mettiti di lato rispetto al telefono, a 2-3 metri, con tutto il corpo nell\'inquadratura.'),
  'kokutsu': ('lato', 'Mettiti di lato rispetto al telefono, a 2-3 metri, con tutto il corpo nell\'inquadratura.'),
  'kiba': ('fronte', 'Mettiti di fronte al telefono, a 2-3 metri, con tutto il corpo nell\'inquadratura.'),
  'musubi': ('fronte', 'Mettiti di fronte al telefono, con tutto il corpo nell\'inquadratura.'),
  'heiko': ('fronte', 'Mettiti di fronte al telefono, con tutto il corpo nell\'inquadratura.'),
};

/// I punti del corpo che servono: spalle, anche, ginocchia, caviglie.
const bodyPoints = ['shL', 'shR', 'hipL', 'hipR', 'kneeL', 'kneeR', 'ankL', 'ankR'];
const bones = [('shL', 'shR'), ('shL', 'hipL'), ('shR', 'hipR'), ('hipL', 'hipR'), ('hipL', 'kneeL'), ('kneeL', 'ankL'), ('hipR', 'kneeR'), ('kneeR', 'ankR')];

typedef Points = Map<String, Offset>;

class Tip {
  final bool ok;
  final String text;
  const Tip(this.ok, this.text);
}

class StanceResult {
  final int score;
  final List<Tip> tips;
  const StanceResult(this.score, this.tips);
  String get verdict => score == 100 ? 'ottimo' : score >= 60 ? 'quasi' : 'da correggere';
  Tip? get firstWrong => tips.where((t) => !t.ok).firstOrNull;
}

double _ang(Offset a, Offset b, Offset c) {
  final u = a - b, v = c - b, n = u.distance * v.distance;
  return math.acos(((u.dx * v.dx + u.dy * v.dy) / (n == 0 ? 1 : n)).clamp(-1.0, 1.0)) * 180 / math.pi;
}

Offset _mid(Offset a, Offset b) => (a + b) / 2;

/// Regole del prototipo: angoli delle ginocchia, busto, larghezza e distribuzione del peso.
StanceResult checkStance(String id, Points p) {
  final kL = _ang(p['hipL']!, p['kneeL']!, p['ankL']!), kR = _ang(p['hipR']!, p['kneeR']!, p['ankR']!), bent = math.min(kL, kR), str = math.max(kL, kR);
  final sh = _mid(p['shL']!, p['shR']!), hp = _mid(p['hipL']!, p['hipR']!), tl = (sh - hp).distance, t = tl == 0 ? 1 : tl;
  final lean = (math.atan2(sh.dx - hp.dx, hp.dy - sh.dy) * 180 / math.pi).abs(), wide = (p['ankL']!.dx - p['ankR']!.dx).abs() / t;
  final tips = <Tip>[];
  void rule(bool ok, String good, String bad) => tips.add(Tip(ok, ok ? good : bad));
  rule(lean < 13, 'Busto dritto.', 'Il busto si inclina: tienilo verticale, come se un filo ti tirasse la testa in su.');
  if (id == 'zenkutsu') {
    rule(bent < 128, 'Ginocchio avanti ben piegato.', 'Piega di più il ginocchio avanti: deve arrivare sopra la punta del piede.');
    rule(bent > 78, 'Il ginocchio avanti non supera la punta del piede.', 'Il ginocchio avanti va troppo oltre: allunga un po\' la posizione.');
    rule(str > 152, 'Gamba dietro tesa.', 'Distendi la gamba dietro e spingi il tallone a terra.');
    rule(wide > 1.45, 'Posizione lunga quanto basta.', 'Allunga la posizione: il piede dietro va più indietro.');
  } else if (id == 'kokutsu') {
    // la gamba dietro è quella con il piede più vicino sotto il bacino
    final back = (hp.dx - p['ankL']!.dx).abs() < (hp.dx - p['ankR']!.dx).abs() ? 'L' : 'R', kB = back == 'L' ? kL : kR, kF = back == 'L' ? kR : kL;
    final span = (p['ankL']!.dx - p['ankR']!.dx).abs(), towardBack = (hp.dx - p['ank$back']!.dx).abs() / (span == 0 ? 1 : span);
    rule(kB < 156, 'Ginocchio dietro piegato.', 'Piega di più il ginocchio dietro e scendi con il bacino.');
    rule(kF > 128 && kF < 177, 'Gamba avanti morbida.', kF >= 177 ? 'Ammorbidisci il ginocchio avanti, non bloccarlo.' : 'La gamba avanti è troppo piegata: il peso deve stare dietro.');
    rule(towardBack < .42, 'Peso sulla gamba dietro.', 'Porta il bacino sopra la gamba dietro: circa due terzi del peso stanno lì.');
  } else if (id == 'kiba') {
    rule((kL - kR).abs() < 16, 'Peso distribuito sulle due gambe.', 'Una gamba è più piegata dell\'altra: scendi in mezzo, con il peso al centro.');
    rule(str < 150, 'Ginocchia piegate.', 'Scendi di più: piega entrambe le ginocchia e spingile in fuori.');
    rule(wide > 1.15, 'Piedi larghi quanto serve.', 'Allarga i piedi: circa il doppio della larghezza delle spalle.');
  } else {
    rule(bent > 160, 'Gambe distese.', 'Distendi le gambe: in questa posizione si sta dritti, senza piegare le ginocchia.');
    if (id == 'musubi') {
      rule(wide < .4, 'Talloni uniti.', 'Avvicina i talloni fino a farli toccare, punte aperte.');
    } else {
      rule(wide > .3 && wide < .85, 'Piedi alla larghezza delle anche.', wide <= .3 ? 'Apri un po\' i piedi: alla larghezza delle anche.' : 'Stringi i piedi: alla larghezza delle anche, non oltre.');
    }
  }
  final ok = tips.where((x) => x.ok).length;
  return StanceResult((ok / tips.length * 100).round(), [...tips.where((x) => !x.ok), ...tips.where((x) => x.ok)]);
}

/// Il disegno stesso come modello: la posa della scheda (o con un errore tipico) e i suoi punti proiettati nella vista consigliata.
(pose.Anim, Points) rigPoints(Technique t, {bool wrong = false}) {
  final a = t.anim!, view = views[postureInfo[t.id]!.$1]!;
  var p = Map<String, dynamic>.from(a.poseAt(a.duration * .5));
  List<double> l(String k) => [for (final v in p[k] as List) (v as num).toDouble()];
  if (wrong) {
    final c = l('C'), aL = l('aL'), aR = l('aR');
    if (t.id == 'zenkutsu' || t.id == 'kokutsu') {
      p['C'] = [c[0], c[1] + (t.id == 'kokutsu' ? 12 : 9), c[2]];
      p['lean'] = ((p['lean'] as num?) ?? 0) + 18;
    } else if (t.id == 'kiba') {
      p['C'] = [c[0], c[1] + 4, c[2]];
      p['aL'] = [aL[0], aL[1], aL[2] * .62];
      p['aR'] = [aR[0], aR[1], aR[2] * .62];
    } else {
      final zc = (aL[2] + aR[2]) / 2, k = t.id == 'musubi' ? 14 : 26;
      p['aL'] = [aL[0], aL[1], zc - k];
      p['aR'] = [aR[0], aR[1], zc + k];
    }
  }
  final b = solveBody(p), cam = Camera(view);
  Offset pt(V3 v) {
    final q = cam.proj(v);
    return Offset(q.x, q.y);
  }

  final still = pose.Anim(id: '${t.id}-fermo', duration: 1, follow: false, view: view.id, keys: [pose.Key(0, p, pose.easeByName(null)), pose.Key(1, p, pose.easeByName(null))], marks: const [0], kiai: const []);
  return (still, {'shL': pt(b.shL), 'shR': pt(b.shR), 'hipL': pt(b.hipL), 'hipR': pt(b.hipR), 'kneeL': pt(b.kneeL), 'kneeR': pt(b.kneeR), 'ankL': pt(b.ankL), 'ankR': pt(b.ankR)});
}
