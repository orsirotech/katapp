import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/catalog.dart';
import '../engine/camera.dart';
import '../engine/pencil_painter.dart';

/// Istante "più leggibile" per l'anteprima di una tecnica.
double thumbTime(Technique t) {
  final a = t.anim!;
  if (a.marks.length > 2) return a.marks[2] + .3;
  return a.duration * .5;
}

/// Anteprima ferma, per le griglie.
class TechThumb extends StatelessWidget {
  final Technique tech;
  const TechThumb(this.tech, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = tech.anim;
    if (a == null) return const AspectRatio(aspectRatio: 1, child: Center(child: Text('in arrivo')));
    // solo la parte alta della tavola, inquadrata sulla figura
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: kMainH,
            height: kMainH,
            child: OverflowBox(
              alignment: const Alignment(-.05, -1),
              maxWidth: kW,
              maxHeight: kH,
              child: CustomPaint(size: const Size(kW, kH), painter: PencilPainter(anim: a, t: thumbTime(tech), view: views[a.view] ?? views['34']!, insets: false, seed: 2)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Controller dell'animazione principale: tempo, velocità, vista, play.
class TechController extends ChangeNotifier {
  double t = 0, speed = .5;
  bool playing = true;
  String view;
  TechController({this.view = '34'});

  void toggle() {
    playing = !playing;
    notifyListeners();
  }

  void setSpeed(double s) {
    speed = s;
    notifyListeners();
  }

  void setView(String v) {
    view = v;
    notifyListeners();
  }

  void jump(double to) {
    t = to;
    playing = false;
    notifyListeners();
  }
}

/// Animazione a matita a ~20 fotogrammi al secondo, il ritmo dei disegni animati "a passo due".
class TechAnimation extends StatefulWidget {
  final Technique tech;
  final TechController controller;
  final bool insets;

  /// Chiamata quando inizia un passo, con mezzo secondo di anticipo (per la voce).
  final void Function(int step, int loop)? onCue;
  const TechAnimation({super.key, required this.tech, required this.controller, this.insets = true, this.onCue});

  @override
  State<TechAnimation> createState() => _TechAnimationState();
}

class _TechAnimationState extends State<TechAnimation> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero, _lastDraw = Duration.zero;
  int _seed = 1, _cueStep = -1, _cueLoop = -1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    widget.controller.addListener(_onCtrl);
  }

  void _onCtrl() {
    final a = widget.tech.anim!, c = widget.controller;
    final tv = c.t + .5 * c.speed;
    _cueStep = a.stepAt(tv);
    _cueLoop = (tv / a.duration).floor();
    setState(() {});
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, .1);
    _last = now;
    final c = widget.controller, a = widget.tech.anim!;
    if (c.playing) {
      c.t += dt * c.speed;
      final tv = c.t + .5 * c.speed, step = a.stepAt(tv), loop = (tv / a.duration).floor();
      if (step != _cueStep || loop != _cueLoop) {
        if (_cueStep >= 0) widget.onCue?.call(step, loop);
        _cueStep = step;
        _cueLoop = loop;
      }
    }
    if ((now - _lastDraw).inMilliseconds >= 48 && (c.playing || _seedChanged(now))) {
      _lastDraw = now;
      setState(() {});
    }
  }

  bool _seedChanged(Duration now) {
    final s = (now.inMilliseconds ~/ 110) % 3 + 1;
    if (s == _seed) return false;
    _seed = s;
    return true;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrl);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, a = widget.tech.anim!, tech = widget.tech;
    String? label;
    if (tech.isSequence) {
      final s = tech.steps[a.stepAt(c.t).clamp(0, tech.steps.length - 1)];
      label = RegExp(r'\d').hasMatch(s.label) ? '${s.label} · ${s.text}' : s.text;
    }
    _seed = (_last.inMilliseconds ~/ 110) % 3 + 1;
    return AspectRatio(
      aspectRatio: kW / (widget.insets ? kH : kMainH),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: PencilPainter(anim: a, t: c.t, view: views[c.view]!, insets: widget.insets, label: label, seed: _seed),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
