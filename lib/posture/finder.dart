import 'package:flutter/widgets.dart';

import 'stance.dart';
import 'finder_stub.dart' if (dart.library.io) 'finder_mlkit.dart' as impl;

/// Foto analizzata: i punti trovati (null se il corpo non si vede bene) e la sua misura.
class PhotoPose {
  final Points? points;
  final Size size;
  final ImageProvider image;
  const PhotoPose(this.points, this.size, this.image);
}

/// Riconoscimento della postura sul telefono (ML Kit). Sul web non c'è: restano gli esempi.
abstract class PoseFinder {
  bool get available;

  /// Sceglie una foto dalla galleria e la analizza; null se l'utente annulla.
  Future<PhotoPose?> pickPhoto();

  /// Anteprima della fotocamera frontale: [onPose] riceve i punti circa due volte al secondo,
  /// già nelle coordinate dell'anteprima mostrata.
  Widget live({required void Function(Points? points) onPose, required Widget Function(Points? points) overlay});
}

PoseFinder makeFinder() => impl.make();
