import 'package:flutter/material.dart';

/// Look unico "carta e grafite" del prototipo.
class K {
  static const paper = Color(0xFFF2EEE4), paper2 = Color(0xFFE9E4D7), lead = Color(0xFF2A292C), leadSoft = Color(0xFF6B675F), red = Color(0xFFA3372C);

  static const hand = TextStyle(fontFamily: 'Caveat', fontWeight: FontWeight.w700, color: lead, height: 1.05);

  static ThemeData theme() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: lead, surface: paper, primary: lead, secondary: red),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: lead, fontSize: 15, height: 1.45)),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: paper,
          indicatorColor: paper2,
          labelTextStyle: WidgetStateProperty.all(hand.copyWith(fontSize: 16)),
        ),
      );
}

/// Riquadro dal bordo "a mano libera".
class RoughBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? fill;
  const RoughBox({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.fill});

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: fill ?? Colors.white.withValues(alpha: .25),
        border: Border.all(color: K.lead.withValues(alpha: .8), width: 1.6),
        borderRadius: const BorderRadius.only(topLeft: Radius.elliptical(11, 9), topRight: Radius.elliptical(8, 12), bottomRight: Radius.elliptical(12, 8), bottomLeft: Radius.elliptical(9, 11)),
      ),
      child: Padding(padding: padding, child: child),
    );
    return onTap == null ? box : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: box);
  }
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.5, color: K.leadSoft));
}

class HandButton extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  final bool outlined;
  const HandButton(this.label, {super.key, required this.onTap, this.on = false, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final t = Text(label, style: K.hand.copyWith(fontSize: 20, color: on ? K.red : K.lead));
    return Semantics(
      button: true,
      selected: on,
      child: outlined ? RoughBox(onTap: onTap, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), child: t) : InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: t)),
    );
  }
}
