import 'package:flutter/foundation.dart';

import 'package:colormix_studio/shared/models/scale_device_info.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

enum ScaleConnectionState {
  disconnected,
  connecting,
  connectedSupported,

  /// connected but we can't read weight from it
  connectedUnsupported,
  failed,
}

/// a command the scale turned down or never answered. the message is for
/// the stylist, plain words
class ScaleCommandException implements Exception {
  const ScaleCommandException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// every weight in the app comes through this, real scale or simulator.
/// listeners hear about anything the screens might show (problem text,
/// device details), the streams carry connection state and readings
abstract interface class ScaleDevice implements Listenable {
  ScaleDeviceInfo get info;

  ScaleConnectionState get connectionState;
  Stream<ScaleConnectionState> get connectionStates;

  Stream<WeightReading> get weightStream;

  bool get isConnected;

  /// standard 0x181D scales can't be tared remotely
  bool get supportsTare;

  /// what's wrong right now in plain words, null when nothing is
  String? get problem;

  Future<void> connect();
  Future<void> disconnect();

  /// throws [ScaleCommandException] when the scale says no or goes quiet
  Future<void> tare();

  /// done with this device for good: stop everything, close the streams
  Future<void> close();
}
