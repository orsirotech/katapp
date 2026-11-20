import 'package:flutter/widgets.dart';

import 'finder.dart';
import 'stance.dart';

class _None implements PoseFinder {
  @override
  bool get available => false;
  @override
  Future<PhotoPose?> pickPhoto() async => null;
  @override
  Widget live({required void Function(Points? points) onPose, required Widget Function(Points? points) overlay}) => const SizedBox();
}

PoseFinder make() => _None();
