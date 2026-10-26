import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/ble_transport.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/shared/models/scale_device_info.dart';

/// a scan stops on its own after this
const scanFor = Duration(seconds: 15);

class FoundDevice {
  const FoundDevice(this.result, this.kind);

  final BleScanResult result;
  final ScaleAdapterType kind;

  bool get isScale => kind != ScaleAdapterType.unknown;
}

class BleScanState {
  const BleScanState({
    this.scanning = false,
    this.found = const [],
    this.problem,
    this.scannedOnce = false,
  });

  final bool scanning;

  /// colormix scales first, then other scales, then everything else,
  /// each by signal strength
  final List<FoundDevice> found;

  /// why it can't scan, in plain words
  final String? problem;
  final bool scannedOnce;

  List<FoundDevice> get scales => found.where((f) => f.isScale).toList();
  List<FoundDevice> get others =>
      found.where((f) => !f.isScale && f.result.name != null).toList();
}

final bleScanProvider = NotifierProvider<BleScanNotifier, BleScanState>(
  BleScanNotifier.new,
);

class BleScanNotifier extends Notifier<BleScanState> {
  StreamSubscription<BleScanResult>? _sub;
  Timer? _stopTimer;
  final _byId = <String, BleScanResult>{};

  @override
  BleScanState build() {
    ref.onDispose(() {
      _stopTimer?.cancel();
      _sub?.cancel();
    });
    return const BleScanState();
  }

  BleTransport get _transport => ref.read(bleTransportProvider);

  Future<void> start() async {
    if (state.scanning) return;
    final t = _transport;

    if (!t.supported) {
      state = const BleScanState(
        problem:
            'Bluetooth scales work in the Android and Windows apps, '
            'not in this browser preview.',
      );
      return;
    }

    switch (await t.availability()) {
      case BleAvailability.unsupported:
        state = const BleScanState(problem: 'This device has no Bluetooth.');
        return;
      case BleAvailability.poweredOff:
        state = const BleScanState(
          problem: 'Bluetooth is off. Turn it on, then scan again.',
        );
        return;
      default:
        break;
    }

    if (!await t.hasPermissions()) {
      try {
        await t.requestPermissions();
      } on BlePermissionDenied {
        state = const BleScanState(
          problem:
              'ColorMix needs the Nearby devices (Bluetooth) permission '
              'to find the scale. Allow it in the phone\'s settings, then '
              'scan again.',
        );
        return;
      }
    }

    _byId.clear();
    state = const BleScanState(scanning: true, scannedOnce: true);
    unawaited(_sub?.cancel());
    _sub = t.scanResults.listen(_onResult);
    try {
      await t.startScan();
    } catch (_) {
      unawaited(_sub?.cancel());
      state = const BleScanState(
        problem:
            'Couldn\'t start scanning. Check Bluetooth is on and try '
            'again.',
        scannedOnce: true,
      );
      return;
    }
    _stopTimer?.cancel();
    _stopTimer = Timer(scanFor, () => unawaited(stop()));
  }

  Future<void> stop() async {
    _stopTimer?.cancel();
    if (!state.scanning) return;
    try {
      await _transport.stopScan();
    } catch (_) {
      // it stopped anyway
    }
    unawaited(_sub?.cancel());
    state = BleScanState(found: state.found, scannedOnce: true);
  }

  void _onResult(BleScanResult r) {
    final before = _byId[r.deviceId];
    // later sightings sometimes lose the name or services, keep the best
    _byId[r.deviceId] = BleScanResult(
      deviceId: r.deviceId,
      name: r.name ?? before?.name,
      rssi: r.rssi ?? before?.rssi,
      services: r.services.isNotEmpty ? r.services : (before?.services ?? []),
    );
    state = BleScanState(
      scanning: state.scanning,
      scannedOnce: true,
      found: _sorted(),
    );
  }

  List<FoundDevice> _sorted() {
    int rank(ScaleAdapterType k) => switch (k) {
      ScaleAdapterType.esp32Custom => 0,
      ScaleAdapterType.standardWeightScale => 1,
      _ => 2,
    };
    final list = [for (final r in _byId.values) FoundDevice(r, guessAdapter(r))]
      ..sort((a, b) {
        final byKind = rank(a.kind).compareTo(rank(b.kind));
        if (byKind != 0) return byKind;
        return (b.result.rssi ?? -127).compareTo(a.result.rssi ?? -127);
      });
    return list;
  }
}
