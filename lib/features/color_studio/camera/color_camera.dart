import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/features/color_studio/camera/camera_reading.dart';

/// what the camera screen needs from a camera. tests hand in a fake that
/// returns a made-up photo
abstract interface class ColorCamera {
  /// throws [CameraUnavailable] with a message for the stylist
  Future<void> open();

  /// the live view, [overlay] drawn over exactly the picture's area
  Widget preview({required Widget overlay});

  /// one still, decoded
  Future<RgbaImage> capture();

  Future<void> close();
}

class CameraUnavailable implements Exception {
  const CameraUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

final colorCameraFactoryProvider = Provider<ColorCamera Function()>(
  (ref) => PluginColorCamera.new,
);

/// the back camera through the camera plugin. stills only: streaming isn't
/// there on web, and one still is all a reading needs
class PluginColorCamera implements ColorCamera {
  CameraController? _controller;

  @override
  Future<void> open() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      throw _unavailable(e);
    }
    if (cameras.isEmpty) {
      throw const CameraUnavailable('No camera found on this device.');
    }
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      await controller.dispose();
      throw _unavailable(e);
    }
    // the flash would light the hair, not the room the card was read in
    try {
      await controller.setFlashMode(FlashMode.off);
    } on Object {
      // web and some cameras have no flash
    }
    _controller = controller;
  }

  @override
  Widget preview({required Widget overlay}) =>
      CameraPreview(_controller!, child: overlay);

  @override
  Future<RgbaImage> capture() async {
    final file = await _controller!.takePicture();
    return decodeRgba(await file.readAsBytes());
  }

  @override
  Future<void> close() async {
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }

  static CameraUnavailable _unavailable(CameraException e) {
    final code = e.code.toLowerCase();
    if (code.contains('denied') ||
        code.contains('permission') ||
        code.contains('restricted')) {
      return const CameraUnavailable(
        'The app isn\'t allowed to use the camera. Allow it in the phone\'s '
        'settings (Apps, ColorMix Studio, Permissions), then try again.',
      );
    }
    if (code.contains('notfound') || code.contains('nocamera')) {
      return const CameraUnavailable('No camera found on this device.');
    }
    return CameraUnavailable(
      'The camera didn\'t start: ${e.description ?? e.code}',
    );
  }
}

/// a jpeg or png to pixels, scaled down: averaging is all the reading
/// needs, and a 12 MP still is slow to walk through
Future<RgbaImage> decodeRgba(Uint8List encoded, {int maxSide = 800}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(encoded);
  // not ImageDescriptor: its width and height throw on web
  final codec = await ui.instantiateImageCodecWithSize(
    buffer,
    getTargetSize: (w, h) {
      if (w <= maxSide && h <= maxSide) return ui.TargetImageSize();
      return w >= h
          ? ui.TargetImageSize(width: maxSide)
          : ui.TargetImageSize(height: maxSide);
    },
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final out = RgbaImage(image.width, image.height, data!.buffer.asUint8List());
  image.dispose();
  codec.dispose();
  return out;
}
