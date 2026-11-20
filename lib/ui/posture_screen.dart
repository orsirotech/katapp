import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../engine/camera.dart';
import '../engine/pencil_painter.dart';
import '../posture/finder.dart';
import '../posture/stance.dart';
import 'app_state.dart';
import 'theme.dart';
import 'widgets.dart';

/// Scheda nella pagina della tecnica, per le posizioni che l'app sa correggere.
class PostureCard extends StatelessWidget {
  final AppState app;
  final Technique tech;
  const PostureCard({super.key, required this.app, required this.tech});

  @override
  Widget build(BuildContext context) => Card2(
        eyebrow: 'Correggi la posizione',
        title: 'Ti guardo e ti correggo',
        text: '${postureInfo[tech.id]!.$2} Il telefono riconosce ginocchia, anche e spalle e ti dice cosa sistemare. L\'immagine resta sul telefono.',
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PostureScreen(app: app, tech: tech))),
      );
}

/// Linee rosse su spalle, anche, ginocchia e caviglie. [scale] porta i punti nelle coordinate del disegno.
class BonesPainter extends CustomPainter {
  final Points points;
  final double Function(Size size) scale;
  BonesPainter(this.points, {double Function(Size size)? scale}) : scale = scale ?? ((_) => 1);

  @override
  void paint(Canvas canvas, Size size) {
    final k = scale(size), line = Paint()
      ..color = K.red.withValues(alpha: .85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round, dot = Paint()..color = K.red;
    for (final (a, b) in bones) {
      canvas.drawLine(points[a]! * k, points[b]! * k, line);
    }
    for (final p in points.values) {
      canvas.drawCircle(p * k, 4.5, dot);
    }
  }

  @override
  bool shouldRepaint(BonesPainter old) => old.points != points;
}

class PostureScreen extends StatefulWidget {
  final AppState app;
  final Technique tech;
  const PostureScreen({super.key, required this.app, required this.tech});
  @override
  State<PostureScreen> createState() => _PostureScreenState();
}

enum _Mode { none, demoOk, demoWrong, photo, live }

class _PostureScreenState extends State<PostureScreen> {
  final finder = makeFinder();
  _Mode mode = _Mode.none;
  PhotoPose? photo;
  StanceResult? result;
  String? note;
  String lastSaid = '';
  DateTime saidAt = DateTime(2000);

  @override
  void initState() {
    super.initState();
    if (!finder.available) _demo(false);
  }

  @override
  void dispose() {
    widget.app.voice.stop();
    super.dispose();
  }

  void _demo(bool wrong) => setState(() {
        mode = wrong ? _Mode.demoWrong : _Mode.demoOk;
        result = checkStance(widget.tech.id, rigPoints(widget.tech, wrong: wrong).$2);
        note = wrong ? 'Esempio con errori: ${widget.tech.id == 'zenkutsu' || widget.tech.id == 'kokutsu' ? 'bacino alto e busto inclinato' : widget.tech.id == 'kiba' ? 'piedi stretti e ginocchia poco piegate' : 'piedi alla larghezza sbagliata'}.' : 'Il disegno della scheda, misurato come misuro te.';
      });

  Future<void> _photo() async {
    setState(() {
      mode = _Mode.photo;
      note = 'Analizzo la foto…';
      result = null;
      photo = null;
    });
    try {
      final p = await finder.pickPhoto();
      if (!mounted) return;
      setState(() {
        photo = p;
        result = p?.points == null ? null : checkStance(widget.tech.id, p!.points!);
        note = p == null ? null : p.points == null ? 'Non vedo bene gambe e spalle. Riprova con tutto il corpo nella foto e più luce.' : null;
      });
    } catch (e) {
      if (mounted) setState(() => note = 'Non riesco ad analizzare la foto su questo telefono.');
    }
  }

  void _live(Points? p) {
    final r = p == null ? null : checkStance(widget.tech.id, p), tip = r?.firstWrong;
    setState(() {
      result = r;
      note = r == null ? 'Entra tutto nell\'inquadratura.' : null;
    });
    final now = DateTime.now();
    if (tip != null && tip.text != lastSaid && now.difference(saidAt).inSeconds >= 4) {
      lastSaid = tip.text;
      saidAt = now;
      widget.app.voice.say(tip.text);
    }
  }

  Widget _drawing(bool wrong) {
    final (still, pts) = rigPoints(widget.tech, wrong: wrong);
    return AspectRatio(
      aspectRatio: kW / kMainH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: PencilPainter(anim: still, t: 0, view: views[still.view]!, insets: false),
          foregroundPainter: BonesPainter(pts, scale: (s) => s.width / kW),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tech, r = result;
    return Paper(back: 'scheda', title: 'Correggi ${t.nameJp}', subtitle: postureInfo[t.id]!.$2, children: [
      Wrap(children: [
        if (finder.available) ...[
          HandButton('fotocamera', outlined: true, on: mode == _Mode.live, onTap: () => setState(() {
                mode = mode == _Mode.live ? _Mode.none : _Mode.live;
                result = null;
                note = mode == _Mode.live ? 'Carico il riconoscimento…' : null;
              })),
          HandButton('foto', outlined: true, on: mode == _Mode.photo, onTap: _photo),
        ],
        HandButton('esempio giusto', on: mode == _Mode.demoOk, onTap: () => _demo(false)),
        HandButton('esempio sbagliato', on: mode == _Mode.demoWrong, onTap: () => _demo(true)),
      ]),
      if (!finder.available) const Note('La fotocamera e le foto funzionano nell\'app sul telefono. Qui puoi provare gli esempi.'),
      const SizedBox(height: 10),
      if (mode == _Mode.demoOk || mode == _Mode.demoWrong) _drawing(mode == _Mode.demoWrong),
      if (mode == _Mode.live) finder.live(onPose: _live, overlay: (p) => p == null ? const SizedBox() : CustomPaint(painter: BonesPainter(p))),
      if (mode == _Mode.photo && photo != null)
        AspectRatio(
          aspectRatio: photo!.size.width / photo!.size.height,
          child: CustomPaint(
            foregroundPainter: photo!.points == null ? null : BonesPainter(photo!.points!, scale: (s) => s.width / photo!.size.width),
            child: Image(image: photo!.image, fit: BoxFit.fill),
          ),
        ),
      if (note != null) Padding(padding: const EdgeInsets.only(top: 8), child: Muted(note!)),
      if (r != null)
        Card2(title: 'Punteggio ${r.score}/100', badge: r.verdict, children: [
          for (final tip in r.tips) Text('${tip.ok ? '✓' : '✗'} ${tip.text}', style: TextStyle(color: tip.ok ? K.lead : K.red)),
        ]),
    ]);
  }
}
