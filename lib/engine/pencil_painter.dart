import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'camera.dart';
import 'pose.dart';
import 'rig.dart';
import 'vec.dart';

/// Disegno "matita realistica" del prototipo, portato su Canvas.
/// Lavora nella tavola 480 × 540 e viene scalato sulla dimensione del widget.
class PencilPainter extends CustomPainter {
  final Anim anim;
  final double t;
  final ViewSpec view;
  final bool insets;
  final String? label; // riga del passo (kata e combinazioni)
  final int seed; // varia il tremolio del tratto: 1, 2 o 3

  PencilPainter({required this.anim, required this.t, required this.view, this.insets = true, this.label, this.seed = 1});

  static const paper = Color(0xFFF2EEE4), skin = Color(0xFFEFE6D6);
  static Color ink(double a) => Color.fromRGBO(36, 34, 38, a.clamp(0, 1).toDouble());
  static const red = Color(0xFFA3372C);
  static const light = Offset(-.55, -.83);

  late Camera cam;

  double _rnd(double i) {
    final x = math.sin(i * 12.9898 + seed * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  Offset o(P2 p) => Offset(p.x, p.y);

  /// Tratto morbido e leggermente tremolante (curve quadratiche tra i punti medi).
  Path wobble(List<Offset> pts, {bool closed = false, double jit = 0, double salt = 0}) {
    final q = [for (var k = 0; k < pts.length; k++) pts[k] + Offset((_rnd(salt + k * 3.1) - .5) * 2 * jit, (_rnd(salt + k * 7.7 + 1) - .5) * 2 * jit)];
    final n = q.length, path = Path();
    if (n < 3) {
      path.moveTo(q[0].dx, q[0].dy);
      for (final p in q.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }
    path.moveTo((q[0].dx + q[1].dx) / 2, (q[0].dy + q[1].dy) / 2);
    for (var k = 1; k < (closed ? n + 1 : n - 1); k++) {
      final a = q[k % n], b = q[(k + 1) % n];
      path.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }
    if (closed) {
      path.close();
    } else {
      path.lineTo(q.last.dx, q.last.dy);
    }
    return path;
  }

  List<Offset> resample(List<Offset> pts, double step, {bool closed = true}) {
    final out = <Offset>[];
    final m = closed ? pts.length : pts.length - 1;
    for (var i = 0; i < m; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      out.add(a);
      final n = ((b - a).distance / step).floor();
      for (var k = 1; k < n; k++) {
        out.add(Offset.lerp(a, b, k / n)!);
      }
    }
    if (!closed) out.add(pts.last);
    return out;
  }

  List<Offset> hull(List<Offset> pts) {
    final p = [...pts]..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
    double cr(Offset o, Offset a, Offset b) => (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    final lo = <Offset>[], hi = <Offset>[];
    for (final q in p) {
      while (lo.length >= 2 && cr(lo[lo.length - 2], lo.last, q) <= 0) {
        lo.removeLast();
      }
      lo.add(q);
    }
    for (final q in p.reversed) {
      while (hi.length >= 2 && cr(hi[hi.length - 2], hi.last, q) <= 0) {
        hi.removeLast();
      }
      hi.add(q);
    }
    return [...lo.sublist(0, lo.length - 1), ...hi.sublist(0, hi.length - 1)];
  }

  List<Offset> capsule(Offset a, Offset b, double ra, double rb) {
    final g = math.atan2(b.dy - a.dy, b.dx - a.dx), pts = <Offset>[];
    for (var i = 0; i <= 8; i++) {
      final t = g - math.pi / 2 + math.pi * i / 8;
      pts.add(b + Offset(math.cos(t) * rb, math.sin(t) * rb));
    }
    for (var i = 0; i <= 8; i++) {
      final t = g + math.pi / 2 + math.pi * i / 8;
      pts.add(a + Offset(math.cos(t) * ra, math.sin(t) * ra));
    }
    return pts;
  }

  // tratteggio diagonale riutilizzato per tutte le ombre
  static final Map<int, Path> _hatch = {};
  Path hatchPath() => _hatch.putIfAbsent(seed, () {
        final p = Path();
        for (var k = -70; k < 70; k++) {
          final x0 = 240 + k * 4.2;
          p.addPath(wobble([for (var i = 0; i <= 3; i++) Offset.lerp(Offset(x0 - 160, 470), Offset(x0 + 160, -10), i / 3)!], jit: .5, salt: 70.0 + k), Offset.zero);
        }
        return p;
      });

  void shape(Canvas c, List<Offset> pts, {required double near, bool isSkin = false, Shade? shade}) {
    final body = wobble(pts, closed: true);
    c.drawPath(body, Paint()..color = isSkin ? skin : paper);
    if (shade != null) {
      c.save();
      c.clipPath(body);
      final dir = Offset(-shade.n.dy, shade.n.dx), base = shade.a + shade.n * shade.off;
      c.clipPath(Path()
        ..moveTo(base.dx - dir.dx * 900, base.dy - dir.dy * 900)
        ..lineTo(base.dx + dir.dx * 900, base.dy + dir.dy * 900)
        ..lineTo(base.dx + dir.dx * 900 + shade.n.dx * 900, base.dy + dir.dy * 900 + shade.n.dy * 900)
        ..lineTo(base.dx - dir.dx * 900 + shade.n.dx * 900, base.dy - dir.dy * 900 + shade.n.dy * 900)
        ..close());
      c.drawPath(hatchPath(), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .75
        ..color = ink(.26 + (1 - near) * .12));
      c.restore();
    }
    final passes = near > .4 ? 2 : 1;
    for (var pass = 0; pass < passes; pass++) {
      c.drawPath(
          wobble(resample(pts, 8), closed: true, jit: .9, salt: 100.0 + pass * 300 + pts.length),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = pass == 1 ? .9 : 1.35
            ..color = ink((pass == 1 ? .45 : .82) * (.65 + .35 * near)));
    }
  }

  void stroke(Canvas c, List<Offset> pts, {double w = 1.2, double a = .8, bool closed = false}) {
    c.drawPath(
        wobble(pts, closed: closed, jit: .6, salt: 500.0 + pts.length),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = w
          ..color = ink(a));
  }

  Shade limbShade(Offset a, Offset b, double r) {
    var n = Offset(-(b.dy - a.dy), b.dx - a.dx);
    final l = n.distance == 0 ? 1.0 : n.distance;
    n = n / l;
    if (n.dx * light.dx + n.dy * light.dy > 0) n = -n;
    return Shade(a, n, r * .2);
  }

  // ---------- parti del corpo ----------
  Part limb(V3 a3, V3 b3, double ra, double rb, {bool isSkin = false, bool cuff = false, double bias = 0}) {
    final a = cam.proj(a3), b = cam.proj(b3);
    return Part((a.d + b.d) / 2 + bias, (c, near) {
      shape(c, capsule(o(a), o(b), ra * kScale, rb * kScale), near: near, isSkin: isSkin, shade: limbShade(o(a), o(b), ra * kScale));
      if (cuff) {
        var n = Offset(-(b.y - a.y), b.x - a.x);
        n = n / (n.distance == 0 ? 1 : n.distance);
        stroke(c, [o(b) + n * rb * kScale, o(b) - n * rb * kScale], w: .9, a: .6);
      }
    });
  }

  Part foot(V3 ank, V3 f) {
    var sdv = const V3(0, 1, 0).cross(f);
    sdv = sdv.length < .2 ? const V3(0, 0, -1) : sdv.unit;
    final uf = f.cross(sdv).unit;
    const w = 4.6;
    const sole = <List<double>>[[-6, -w * .8], [-3, -w], [8, -w * 1.05], [15, -w * .95], [19, -w * .3], [19.5, w * .35], [17, w * .9], [8, w], [-3, w * .9], [-6, w * .6]];
    V3 p3(double u, double v, double h) => ank + f * u + sdv * v + uf * (h - 8);
    final pts = <Offset>[];
    for (final s in sole) {
      final u = s[0], v = s[1];
      pts.add(o(cam.proj(p3(u, v, 0))));
      pts.add(o(cam.proj(p3(u, v, u < 6 ? 8 : u < 14 ? 5.5 : 3))));
    }
    return Part(cam.proj(ank).d - 3, (c, near) {
      shape(c, hull(pts), near: near, isSkin: true, shade: Shade(o(cam.proj(p3(6, 0, 4))), const Offset(.55, .83), 2));
      stroke(c, [o(cam.proj(p3(15.5, -w * .9, 2.5))), o(cam.proj(p3(16.5, 0, 3.2))), o(cam.proj(p3(15, w * .85, 2.5)))], w: .8, a: .5);
      stroke(c, [o(cam.proj(p3(-1, -w * .7, 7))), o(cam.proj(p3(-1, w * .6, 7)))], w: .7, a: .35);
    });
  }

  Part fist(ArmState arm) {
    final f = arm.f, p = arm.p, w = f.cross(p), op = arm.open, cc = arm.wr + f * (op ? 8 : 4.5), thumbSide = arm.side > 0 ? 1.0 : -1.0;
    V3 corner(double a, double b, double e) => cc + f * (a * (op ? 8.5 : 4.6)) + w * (b * (op ? 4.2 : 4.4)) + p * (e * (op ? 1.3 : 3.3));
    final pts = <Offset>[
      for (final a in [-1.0, 1.0])
        for (final b in [-1.0, 1.0])
          for (final e in [-1.0, 1.0]) o(cam.proj(corner(a, b, e)))
    ];
    final vd = cam.viewDir, palmVis = p.dot(vd) > .1, backVis = p.dot(vd) < -.1;
    Offset pr(V3 v) => o(cam.proj(v));
    return Part(cam.proj(cc).d + .5, (c, near) {
      shape(c, hull(pts), near: near, isSkin: true, shade: Shade(pr(cc), const Offset(.55, .83), 2));
      if (op) {
        for (var i = 1; i < 4; i++) {
          final b = -1 + i * .5;
          stroke(c, [pr(cc + f * 1 + w * (b * 4.2)), pr(cc + f * 8 + w * (b * 4.2))], w: .7, a: .5);
        }
        stroke(c, [pr(cc + f * -6 + w * (thumbSide * 4.4)), pr(cc + w * (thumbSide * 4.6))], w: 1.6, a: .7);
        return;
      }
      for (var i = 0; i < 4; i++) {
        final b = -.75 + i * .5, k = pr(cc + f * 4.6 + w * (b * 4.4) + p * -1.6);
        c.drawCircle(k, 1.55 * kScale * .72, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9
          ..color = ink(.75));
      }
      if (palmVis) {
        for (var i = 1; i < 4; i++) {
          final b = -1 + i * .5;
          stroke(c, [pr(cc + f * 4.4 + w * (b * 4.4) + p * 3.3), pr(cc + w * (b * 4.4) + p * 3.4)], w: .7, a: .55);
        }
        stroke(c, [pr(cc + f * -2.5 + w * (thumbSide * 4.6) + p * 3.4), pr(cc + f * 2.5 + w * thumbSide + p * 3.8)], w: 2.2, a: .75);
      } else if (!backVis) {
        stroke(c, [pr(cc + f * -3 + w * (thumbSide * 4.7) + p * 2), pr(cc + f * 2.5 + w * (thumbSide * 4.7) + p * 3.5)], w: 2, a: .7);
      }
    });
  }

  Part torso(Body b) {
    final fw = b.fw, sd = b.sd;
    V3 at(double h) => b.at(h);
    final p3 = [
      b.shL + sd * -4, b.shR + sd * 4, b.shL + const V3(0, 4, 0) + fw * 3, b.shR + const V3(0, 4, 0) + fw * 3,
      at(32) + fw * 12, at(32) + fw * -11, at(8) + fw * 12 + sd * -15, at(8) + fw * 12 + sd * 15, at(8) + fw * -11 + sd * -15, at(8) + fw * -11 + sd * 15,
      at(-14) + sd * -16 + fw * 9, at(-14) + sd * 16 + fw * 9, at(-14) + sd * -16 + fw * -9, at(-14) + sd * 16 + fw * -9, at(52),
    ];
    Offset pr(V3 v) => o(cam.proj(v));
    final pts = p3.map(pr).toList(), c2 = pr(at(20)), frontVis = fw.dot(cam.viewDir) > -.25;
    return Part(cam.proj(b.c).d, (c, near) {
      shape(c, hull(pts), near: near, shade: Shade(c2, const Offset(.55, .83), 6));
      if (frontVis) {
        stroke(c, [pr(at(50) + fw * 5 + sd * 5), pr(at(30) + fw * 12 + sd * -2), pr(at(6) + fw * 12 + sd * -6)], w: 1, a: .65);
        stroke(c, [pr(at(50) + fw * 5 + sd * -5), pr(at(36) + fw * 11 + sd * 1)], w: .9, a: .5);
        stroke(c, [pr(at(-2) + fw * 10 + sd * -6), pr(at(-14) + fw * 9 + sd * -8)], w: .8, a: .45);
      }
      // cintura: solo la metà verso la camera
      final dc = cam.proj(at(6)).d;
      final ring = <(V3, P2)>[];
      for (var i = 0; i < 28; i++) {
        final a = i / 28 * math.pi * 2, q = at(6) + fw * (math.cos(a) * 12.5) + sd * (math.sin(a) * 15.5);
        ring.add((q, cam.proj(q)));
      }
      final front = ring.where((r) => r.$2.d >= dc - 1).toList()
        ..sort((x, y) => math.atan2(x.$1.z - b.c.z, x.$1.x - b.c.x).compareTo(math.atan2(y.$1.z - b.c.z, y.$1.x - b.c.x)));
      final belt = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2 * kScale * .8
        ..color = const Color.fromRGBO(40, 38, 42, .85);
      if (front.length > 1) c.drawPath(wobble([for (final r in front) o(r.$2)], jit: .3, salt: 950), belt);
      if (frontVis) {
        final k = at(6) + fw * 13 + sd * -3, ks = pr(k);
        c.drawRect(Rect.fromCenter(center: ks, width: 8, height: 8), Paint()..color = const Color.fromRGBO(40, 38, 42, .85));
        final tail = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color.fromRGBO(40, 38, 42, .85);
        c.drawPath(wobble([ks, pr(k + const V3(0, -16, 0) + sd * -3)], jit: .3, salt: 960), tail);
        c.drawPath(wobble([ks, pr(k + const V3(0, -14, 0) + sd * 3)], jit: .3, salt: 961), tail);
      }
    });
  }

  Part head(Body b) {
    final h = b.head, cp = cam.proj(h), cc = o(cp), r = 10.5 * kScale, f = b.faceDir, sdh = b.sideDir, vd = cam.viewDir;
    Offset pr(V3 v) => o(cam.proj(v));
    return Part(cp.d + 1, (c, near) {
      final pts = <Offset>[
        for (var i = 0; i < 20; i++)
          Offset(cc.dx + math.cos(i / 20 * math.pi * 2) * r * .9, cc.dy + math.sin(i / 20 * math.pi * 2) * r * (math.sin(i / 20 * math.pi * 2) > 0 ? 1.12 : 1))
      ];
      shape(c, pts, near: near, isSkin: true, shade: Shade(cc, const Offset(.55, .83), r * .25));
      // capelli: calotta sul lato opposto al viso, tratteggiata
      final hair = <Offset>[];
      for (var i = 0; i <= 16; i++) {
        final a = math.pi * (i / 16);
        for (final ph in [-.9, -.4, 0.0, .4, .9]) {
          final dirv = (const V3(0, 1, 0) * (math.sin(a) * .9 + .2) + f * (math.cos(a) * math.cos(ph) - .45) + sdh * (math.sin(ph) * math.cos(a) * .9 + math.sin(ph) * .3)).unit;
          if (dirv.dot(f) < .35) hair.add(pr(h + dirv * 11));
        }
      }
      if (hair.length > 2) {
        final hp = hull(hair), clip = wobble(hp, closed: true);
        c.save();
        c.clipPath(clip);
        final lines = Path();
        for (var k = -30; k < 30; k++) {
          final x0 = cc.dx + k * 2.2;
          lines.addPath(wobble([Offset(x0 - 30, cc.dy + 30), Offset(x0 - 10, cc.dy), Offset(x0 + 10, cc.dy - 30)], jit: .4, salt: 800.0 + k), Offset.zero);
        }
        c.drawPath(lines, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = ink(.5));
        c.restore();
        stroke(c, hp, w: 1.1, a: .7, closed: true);
      }
      if (f.dot(vd) > -.35) {
        final nose = cam.proj(h + f * 10.8), mouth = cam.proj(h + f * 9.6 + const V3(0, -5, 0));
        for (final s in [-3.6, 3.6]) {
          final e = cam.proj(h + f * 9.3 + const V3(0, 1.5, 0) + sdh * s);
          if (e.d > cp.d + 2) stroke(c, [Offset(e.x - 2.2, e.y), Offset(e.x + 2.2, e.y + .3)], w: 1, a: .7);
        }
        stroke(c, [Offset(nose.x - 1, nose.y - 2), o(nose), Offset(nose.x - 1.5, nose.y + 1.5)], w: .9, a: .6);
        stroke(c, [Offset(mouth.x - 2.5, mouth.y), Offset(mouth.x + 2.5, mouth.y)], w: .9, a: .55);
      }
    });
  }

  List<(Part, double)> build(Body b) {
    final parts = <Part>[], tD = cam.proj(b.c).d;
    for (final leg in [(b.hipL, b.kneeL, b.ankL, b.footL), (b.hipR, b.kneeR, b.ankR, b.footR)]) {
      final hem = leg.$2 + (leg.$3 - leg.$2) * .86;
      for (final x in [limb(leg.$1, leg.$2, 10.5, 9), limb(leg.$2, hem, 9, 8, cuff: true), limb(hem, leg.$3, 4.2, 4, isSkin: true, bias: -1), foot(leg.$3, leg.$4)]) {
        x.d = math.min(x.d, tD - 30) + x.d * .01; // gambe sempre dietro la giacca
        parts.add(x);
      }
    }
    parts.add(torso(b));
    final hd = head(b)..d = math.max(cam.proj(b.head).d + 1, tD + .5);
    parts.add(hd);
    for (final a in [b.l, b.r]) {
      final sleeveEnd = a.el + a.f * 14;
      final g = [limb(a.sh, a.el, 7.2, 6.6), limb(a.el, sleeveEnd, 6.6, 6.2, cuff: true), limb(sleeveEnd, a.wr, 4.4, 3.8, isSkin: true), fist(a)];
      for (var i = 0; i < g.length; i++) {
        g[i].d += i * .3;
        parts.add(g[i]);
      }
    }
    parts.sort((x, y) => x.d.compareTo(y.d));
    final dmin = parts.first.d, dmax = parts.last.d, span = (dmax - dmin) == 0 ? 1 : dmax - dmin;
    return [for (final p in parts) (p, (p.d - dmin) / span)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / kW;
    canvas.save();
    canvas.scale(k, k);
    canvas.drawRect(const Rect.fromLTWH(0, 0, kW, kH), Paint()..color = paper);
    final b = solveBody(anim.poseAt(t));
    cam = Camera(view, anim.follow ? b.c.x : 0, anim.follow ? b.c.z : 0);
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, kW, kMainH));
    _ground(canvas, b);
    _trails(canvas, b);
    for (final (p, near) in build(b)) {
      p.draw(canvas, near);
    }
    _hipLines(canvas, b);
    if (label != null) _text(canvas, label!, const Offset(18, 10), 23);
    if (anim.kiaiAt(t)) {
      final hp = o(cam.proj(b.head));
      canvas.save();
      canvas.translate(hp.dx + 26, hp.dy - 56);
      canvas.rotate(rad(-8));
      _text(canvas, 'kiai!', Offset.zero, 34, color: red);
      canvas.restore();
    }
    canvas.restore();
    if (insets) _insets(canvas, b);
    canvas.restore();
  }

  void _ground(Canvas c, Body b) {
    if (anim.follow) {
      final g0x = (cam.ctX / 90).floorToDouble() * 90, g0z = (cam.ctZ / 90).floorToDouble() * 90;
      for (var i = -2; i <= 3; i++) {
        stroke(c, resample([o(cam.proj(V3(g0x + i * 90, 0, g0z - 180))), o(cam.proj(V3(g0x + i * 90, 0, g0z + 270)))], 30, closed: false), w: .8, a: .18);
        stroke(c, resample([o(cam.proj(V3(g0x - 180, 0, g0z + i * 90))), o(cam.proj(V3(g0x + 270, 0, g0z + i * 90)))], 30, closed: false), w: .8, a: .18);
      }
    } else {
      final g = [for (final q in const [[-120.0, -45.0], [120.0, -45.0], [120.0, 45.0], [-120.0, 45.0]]) o(cam.proj(V3(q[0], 0, q[1])))];
      stroke(c, resample(g, 30), w: 1, a: .25, closed: true);
    }
    for (final a in [b.ankL, b.ankR]) {
      final sh = [for (var i = 0; i < 18; i++) o(cam.proj(V3(a.x + 5 + math.cos(i / 18 * math.pi * 2) * 17, 0, a.z + math.sin(i / 18 * math.pi * 2) * 8)))];
      c.save();
      c.clipPath(wobble(sh, closed: true));
      c.drawPath(hatchPath(), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = ink(.22));
      c.restore();
    }
  }

  // scie dei pugni nei movimenti veloci
  void _trails(Canvas c, Body b) {
    final past = [b, for (var k = 1; k <= 5; k++) solveBody(anim.poseAt(t - k * .042))];
    for (final left in [true, false]) {
      final tr = [for (final bb in past) o(cam.proj((left ? bb.l : bb.r).wr + (left ? bb.l : bb.r).f * 5))];
      if ((tr.first - tr.last).distance > 22) {
        for (var j = -1; j <= 1; j++) {
          stroke(c, [for (final p in tr.skip(1)) p + Offset(0, j * 5.0)], w: .9, a: .4);
        }
      }
    }
  }

  // linee a matita che mostrano la rotazione delle anche
  void _hipLines(Canvas c, Body b) {
    final b2 = solveBody(anim.poseAt(t - .042)), dyw = (b.yw - b2.yw) * 1.43;
    if (dyw.abs() <= 4) return;
    final sg = dyw.sign, k = math.min(1.0, dyw.abs() / 14);
    for (var j = 0; j < 3; j++) {
      final r = 24 + j * 4.5;
      final pts = [
        for (var i = 0; i <= 10; i++)
          o(cam.proj(b.at(4 - j * 3.0) + b.fw * (math.cos(-sg * (.2 + i * .13) + math.pi * (j == 1 ? .08 : 0)) * r) + b.sd * (math.sin(-sg * (.2 + i * .13) + math.pi * (j == 1 ? .08 : 0)) * r * 1.1)))
      ];
      stroke(c, pts, w: 1.1, a: .25 + .35 * k);
    }
  }

  void _text(Canvas c, String s, Offset at, double size, {Color? color, TextAlign align = TextAlign.left, double maxW = 440}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'Caveat', fontSize: size, fontWeight: FontWeight.w700, color: color ?? ink(.88))),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: maxW);
    tp.paint(c, align == TextAlign.center ? at - Offset(tp.width / 2, 0) : at);
  }

  // riquadri: piedi visti dall'alto e pugni visti di fronte
  void _insets(Canvas c, Body b) {
    const y0 = kMainH + 8;
    stroke(c, [for (var i = 0; i <= 12; i++) Offset(14 + (kW - 28) * i / 12, y0)], w: 1, a: .45);
    stroke(c, [for (var i = 0; i <= 6; i++) Offset(kW / 2, y0 + 8 + (kH - 20 - y0) * i / 6)], w: .9, a: .35);
    final anyOpen = b.l.open || b.r.open;
    _text(c, "Piedi dall'alto, avanti →", const Offset(22, y0 + 2), 21);
    _text(c, anyOpen ? 'Mani (viste di fronte)' : 'Pugni (visti di fronte)', const Offset(kW / 2 + 12, y0 + 2), 21);
    V3 rel(V3 a) => ry(a - b.c, -b.face);
    final rl = rel(b.ankL), rr = rel(b.ankR);
    final k = [1.35, 170 / ((rl.x - rr.x).abs() + 34), 56 / ((rl.z - rr.z).abs() + 16)].reduce(math.min);
    final mx = (rl.x + rr.x) / 2 + 4, mz = (rl.z + rr.z) / 2;
    const ox = kW / 4 + 4, oz = y0 + 80;
    Offset pl(V3 p) {
      final q = rel(p);
      return Offset(ox + (q.x - mx) * k, oz + (q.z - mz) * k);
    }

    for (final e in [(b.ankL, b.footL, 'S', b.wt), (b.ankR, b.footR, 'D', 100 - b.wt)]) {
      final fr = ry(V3(e.$2.x, 0, e.$2.z).unit, -b.face), sh = math.max(.45, math.sqrt(e.$2.x * e.$2.x + e.$2.z * e.$2.z)), kf = math.max(k, 1.0), c0 = pl(e.$1);
      const s = [[-6.0, -3.7], [-3.0, -4.6], [8.0, -4.8], [15.0, -4.4], [19.0, -1.4], [19.5, 1.6], [17.0, 4.1], [8.0, 4.6], [-3.0, 4.1], [-6.0, 2.8]];
      final sole = [for (final q in s) Offset(c0.dx + (fr.x * q[0] * sh + fr.z * q[1]) * kf, c0.dy + (fr.z * q[0] * sh - fr.x * q[1]) * kf)];
      final air = e.$1.y > 20;
      if (air) {
        stroke(c, [...sole, sole.first], w: 1, a: .35);
      } else {
        shape(c, sole, near: 1, isSkin: true);
      }
      _text(c, '${e.$3} · ${air ? 'in aria' : '${(e.$4 / 5).round() * 5}% peso'}', Offset(c0.dx - 30, c0.dy + (c0.dy >= oz ? 14 : -34)), 19);
    }
    _text(c, b.stance, const Offset(22, kH - 34), 19, color: ink(.7));
    const lx = kW / 2 + 60, rx = kW / 2 + 172, cy = y0 + 72;
    for (final e in [(b.l, lx, 'sinistro'), (b.r, rx, 'destro')]) {
      _fistGlyph(c, e.$1, Offset(e.$2, cy));
      final info = _fistInfo(e.$1, b.faceDir);
      _text(c, e.$3, Offset(e.$2, cy + 18), 19, align: TextAlign.center, maxW: 110);
      _text(c, info.$1, Offset(e.$2, cy + 36), 19, align: TextAlign.center, maxW: 110);
      _text(c, info.$2, Offset(e.$2, cy + 52), 19, align: TextAlign.center, maxW: 110);
    }
  }

  (String, String) _fistInfo(ArmState arm, V3 f) {
    final py = arm.p.y, pf = arm.p.dot(f), w = arm.f.cross(arm.p), horiz = w.y.abs() < .55;
    final palm = py < -.55 ? 'palmo in giù' : py > .55 ? 'palmo in su' : pf > .55 ? 'palmo in avanti' : pf < -.55 ? 'palmo indietro' : 'palmo di lato';
    return (arm.open ? 'mano aperta' : horiz ? 'orizzontale' : 'verticale', palm);
  }

  void _fistGlyph(Canvas c, ArmState arm, Offset at) {
    final f = arm.f;
    var e1 = const V3(0, 1, 0).cross(f);
    if (e1.length < .2) e1 = const V3(0, 0, 1);
    e1 = e1.unit;
    final e2 = f.cross(e1).unit, w = arm.f.cross(arm.p), ang = math.atan2(-w.dot(e2), w.dot(e1)), px = arm.p.dot(e1), py = -arm.p.dot(e2);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(ang);
    if (arm.open) {
      shape(c, [for (var i = 0; i < 16; i++) Offset(math.cos(i / 16 * math.pi * 2) * 21, math.sin(i / 16 * math.pi * 2) * 6)], near: 1, isSkin: true);
      stroke(c, [const Offset(-14, 0), const Offset(14, 0)], w: .8, a: .5);
    } else {
      shape(c, [for (var i = 0; i < 16; i++) Offset(math.cos(i / 16 * math.pi * 2) * 19, math.sin(i / 16 * math.pi * 2) * 12)], near: 1, isSkin: true);
      for (var i = 0; i < 4; i++) {
        c.drawCircle(Offset(-12.0 + i * 8, -3), 3.6, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ink(.8));
      }
    }
    c.restore();
    c.drawCircle(at + Offset(px * 13, py * 13), 3, Paint()..color = ink(.55));
  }

  @override
  bool shouldRepaint(PencilPainter old) => old.t != t || old.view != view || old.anim != anim || old.seed != seed || old.label != label;
}

/// Metà ombreggiata di una forma: punto, normale verso l'ombra, spostamento.
class Shade {
  final Offset a, n;
  final double off;
  const Shade(this.a, this.n, this.off);
}

/// Una parte del corpo da disegnare in ordine di profondità.
class Part {
  double d;
  final void Function(Canvas c, double near) draw;
  Part(this.d, this.draw);
}

/// Utile nei test: rende una tavola in un'immagine.
Future<ui.Image> renderTech(Anim anim, double t, String view, {int w = 480}) async {
  final rec = ui.PictureRecorder(), canvas = Canvas(rec), size = Size(w.toDouble(), w * kH / kW);
  PencilPainter(anim: anim, t: t, view: views[view]!).paint(canvas, size);
  return rec.endRecording().toImage(size.width.round(), size.height.round());
}
