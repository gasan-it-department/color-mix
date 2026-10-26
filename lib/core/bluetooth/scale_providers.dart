import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/ble_transport.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/core/bluetooth/universal_ble_transport.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
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

/// the radio. tests swap in a fake esp32
final bleTransportProvider = Provider<BleTransport>(
  (ref) => const UniversalBleTransport(),
);

/// bluetooth on / off / not allowed, as it changes
final bleAvailabilityProvider = StreamProvider<BleAvailability>((ref) async* {
  final transport = ref.watch(bleTransportProvider);
  if (!transport.supported) {
    yield BleAvailability.unsupported;
    return;
  }
  yield await transport.availability();
  yield* transport.availabilityChanges;
});

/// the one scale the app reads from
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
    _sync();
  }

  /// a scale picked from the scan list
  Future<void> connectBle(BleScanResult r) async {
    final current = _device;
    if (current is BleScaleDevice && current.deviceId == r.deviceId) {
      await current.connect();
      _sync();
      return;
    }
    final device = BleScaleDevice(
      transport: ref.read(bleTransportProvider),
      deviceId: r.deviceId,
      name: r.name ?? 'Unnamed device',
      guess: guessAdapter(r),
    );
    await _swap(device);
    await device.connect();
    _sync();
    // only remember real scales
    if (device.isConnected) {
      await ref
          .read(settingsProvider.notifier)
          .setLastScale(device.deviceId, device.name);
    }
  }

  /// the scale used last time, without scanning
  Future<void> connectLast() async {
    final s = ref.read(settingsProvider);
    final id = s.lastScaleId;
    if (id == null) return;
    await connectBle(BleScanResult(deviceId: id, name: s.lastScaleName));
  }

  Future<void> reconnect() async {
    await _device?.connect();
    _sync();
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _sync();
  }

  /// throws [ScaleCommandException] with a message for the stylist
  Future<void> tare() async => _device?.tare();

  /// drop the device altogether, and stop remembering it
  Future<void> forget() async {
    final d = _device;
    await _swap(null);
    if (d is BleScaleDevice) {
      await ref.read(settingsProvider.notifier).setLastScale(null, null);
    }
  }

  // the stream catches up a microtask later, callers awaiting connect()
  // should see where it really ended up
  void _sync() {
    final d = _device;
    if (d == null) return;
    state = ScaleStatus(device: d, connection: d.connectionState);
  }

  Future<void> _swap(ScaleDevice? next) async {
    unawaited(_sub?.cancel());
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
