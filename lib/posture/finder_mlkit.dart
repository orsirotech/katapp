import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';

import 'finder.dart';
import 'stance.dart';

const _lm = {
  'shL': PoseLandmarkType.leftShoulder,
  'shR': PoseLandmarkType.rightShoulder,
  'hipL': PoseLandmarkType.leftHip,
  'hipR': PoseLandmarkType.rightHip,
  'kneeL': PoseLandmarkType.leftKnee,
  'kneeR': PoseLandmarkType.rightKnee,
  'ankL': PoseLandmarkType.leftAnkle,
  'ankR': PoseLandmarkType.rightAnkle,
};

/// Punti del primo corpo trovato, se gambe e spalle si vedono abbastanza bene.
Points? _points(List<Pose> poses) {
  if (poses.isEmpty) return null;
  final out = <String, Offset>{};
  for (final e in _lm.entries) {
    final l = poses.first.landmarks[e.value];
    if (l == null || l.likelihood < .4) return null;
    out[e.key] = Offset(l.x, l.y);
  }
  return out;
}

class _MlKit implements PoseFinder {
  @override
  bool get available => Platform.isAndroid || Platform.isIOS;

  @override
  Future<PhotoPose?> pickPhoto() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (f == null) return null;
    final bytes = await f.readAsBytes(), img = await decodeImageFromList(bytes);
    final det = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.single, model: PoseDetectionModel.accurate));
    try {
      final pts = _points(await det.processImage(InputImage.fromFilePath(f.path)));
      return PhotoPose(pts, Size(img.width.toDouble(), img.height.toDouble()), MemoryImage(bytes));
    } finally {
      await det.close();
    }
  }

  @override
  Widget live({required void Function(Points? points) onPose, required Widget Function(Points? points) overlay}) => _Live(onPose: onPose, overlay: overlay);
}

PoseFinder make() => _MlKit();

class _Live extends StatefulWidget {
  final void Function(Points? points) onPose;
  final Widget Function(Points? points) overlay;
  const _Live({required this.onPose, required this.overlay});
  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  CameraController? cam;
  final det = PoseDetector(options: PoseDetectorOptions());
  bool busy = false;
  DateTime last = DateTime(2000);
  String? error;
  Points? pts;
  Size upright = const Size(1, 1);

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final all = await availableCameras();
      final d = all.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => all.first);
      final c = CameraController(d, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => cam = c);
      await c.startImageStream((img) => _frame(img, d));
    } catch (e) {
      if (mounted) setState(() => error = 'Non riesco ad aprire la fotocamera. Controlla il permesso nelle impostazioni del telefono.');
    }
  }

  Future<void> _frame(CameraImage img, CameraDescription d) async {
    final now = DateTime.now();
    if (busy || now.difference(last).inMilliseconds < 400) return;
    busy = true;
    last = now;
    try {
      final rot = InputImageRotationValue.fromRawValue(d.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final fmt = InputImageFormatValue.fromRawValue(img.format.raw as int);
      if (fmt == null) return;
      final bytes = img.planes.length == 1 ? img.planes.first.bytes : Uint8List.fromList([for (final p in img.planes) ...p.bytes]);
      final input = InputImage.fromBytes(bytes: bytes, metadata: InputImageMetadata(size: Size(img.width.toDouble(), img.height.toDouble()), rotation: rot, format: fmt, bytesPerRow: img.planes.first.bytesPerRow));
      final p = _points(await det.processImage(input));
      // ML Kit restituisce le coordinate dell'immagine già raddrizzata
      final turned = rot == InputImageRotation.rotation90deg || rot == InputImageRotation.rotation270deg;
      upright = turned ? Size(img.height.toDouble(), img.width.toDouble()) : Size(img.width.toDouble(), img.height.toDouble());
      if (!mounted) return;
      setState(() => pts = p);
      widget.onPose(p);
    } catch (e) {
      debugPrint('posa: $e');
    } finally {
      busy = false;
    }
  }

  @override
  void dispose() {
    cam?.stopImageStream().catchError((_) {});
    cam?.dispose();
    det.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) return Text(error!);
    final c = cam;
    if (c == null || !c.value.isInitialized) return const AspectRatio(aspectRatio: 3 / 4, child: Center(child: Text('Apro la fotocamera…')));
    return AspectRatio(
      aspectRatio: upright.width / upright.height,
      child: LayoutBuilder(builder: (context, box) {
        final k = box.maxWidth / upright.width;
        // anteprima frontale specchiata: i punti vanno specchiati allo stesso modo
        final shown = pts == null ? null : {for (final e in pts!.entries) e.key: Offset(box.maxWidth - e.value.dx * k, e.value.dy * k)};
        return Stack(fit: StackFit.expand, children: [ClipRect(child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: upright.width, height: upright.height, child: CameraPreview(c)))), widget.overlay(shown)]);
      }),
    );
  }
}

