import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

class ScaleStatus {
  const ScaleStatus({
    this.device,
    this.connection = ScaleConnectionState.disconnected,
  });

  final ScaleDevice? device;
  final ScaleConnectionState connection;

  bool get isConnected => connection == ScaleConnectionState.connectedSupported;
}

/// makes the simulator. tests swap in one with a seeded random
final simulatorFactoryProvider = Provider<SimulatedScale Function()>(
  (ref) => SimulatedScale.new,
);

/// the one scale the app reads from. TODO: phase 6 adds the ble adapters
final scaleProvider = NotifierProvider<ScaleNotifier, ScaleStatus>(
  ScaleNotifier.new,
);

class ScaleNotifier extends Notifier<ScaleStatus> {
  ScaleDevice? _device;
  StreamSubscription<ScaleConnectionState>? _sub;

  @override
  ScaleStatus build() {
    ref.onDispose(() {
      _sub?.cancel();
      final d = _device;
      if (d != null) unawaited(d.close());
    });
    return const ScaleStatus();
  }

  Future<void> useSimulator() async {
    if (_device is! SimulatedScale) {
      await _swap(ref.read(simulatorFactoryProvider)());
    }
    await _device?.connect();
  }

  Future<void> reconnect() async => _device?.connect();

  Future<void> disconnect() async => _device?.disconnect();

  Future<void> tare() async => _device?.tare();

  /// drop the device altogether
  Future<void> forget() => _swap(null);

  Future<void> _swap(ScaleDevice? next) async {
    await _sub?.cancel();
    final old = _device;
    _device = next;
    state = ScaleStatus(
      device: next,
      connection: next?.connectionState ?? ScaleConnectionState.disconnected,
    );
    _sub = next?.connectionStates.listen(
      (c) => state = ScaleStatus(device: next, connection: c),
    );
    await old?.close();
  }
}

final simulatedScaleProvider = Provider<SimulatedScale?>((ref) {
  final device = ref.watch(scaleProvider.select((s) => s.device));
  return device is SimulatedScale ? device : null;
});

/// raw readings from whatever scale is attached
final scaleReadingProvider = StreamProvider<WeightReading>((ref) {
  final device = ref.watch(scaleProvider.select((s) => s.device));
  return device?.weightStream ?? const Stream<WeightReading>.empty();
});
