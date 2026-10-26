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

/// every weight in the app comes through this, real scale or simulator
abstract interface class ScaleDevice {
  ScaleDeviceInfo get info;

  ScaleConnectionState get connectionState;
  Stream<ScaleConnectionState> get connectionStates;

  Stream<WeightReading> get weightStream;

  bool get isConnected;

  /// standard 0x181D scales can't be tared remotely
  bool get supportsTare;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> tare();
  Future<void> dispose();
}
