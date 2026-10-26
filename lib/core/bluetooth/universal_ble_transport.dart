import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import 'package:colormix_studio/core/bluetooth/ble_transport.dart';

/// the real radio. android, windows and ios through universal_ble.
/// the web preview has no scale, web bluetooth needs a picker flow this
/// app doesn't have
class UniversalBleTransport implements BleTransport {
  const UniversalBleTransport();

  @override
  bool get supported => !kIsWeb;

  @override
  Future<BleAvailability> availability() async =>
      _map(await UniversalBle.getBluetoothAvailabilityState());

  @override
  Stream<BleAvailability> get availabilityChanges =>
      UniversalBle.availabilityStream.map(_map);

  static BleAvailability _map(AvailabilityState s) => switch (s) {
    AvailabilityState.poweredOn => BleAvailability.poweredOn,
    AvailabilityState.poweredOff => BleAvailability.poweredOff,
    AvailabilityState.unauthorized => BleAvailability.unauthorized,
    AvailabilityState.unsupported => BleAvailability.unsupported,
    _ => BleAvailability.unknown,
  };

  @override
  Future<bool> hasPermissions() => UniversalBle.hasPermissions();

  @override
  Future<void> requestPermissions() async {
    try {
      await UniversalBle.requestPermissions();
    } catch (_) {
      throw const BlePermissionDenied();
    }
  }

  @override
  Future<bool> enableBluetooth() async {
    try {
      return await UniversalBle.enableBluetooth();
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<BleScanResult> get scanResults => UniversalBle.scanStream.map(
    (d) => BleScanResult(
      deviceId: d.deviceId,
      name: d.name,
      rssi: d.rssi,
      services: [for (final s in d.services) normalizeUuid(s)],
    ),
  );

  // everything nearby, the scale screen sorts out what's a scale
  @override
  Future<void> startScan() => UniversalBle.startScan();

  @override
  Future<void> stopScan() => UniversalBle.stopScan();

  @override
  Future<void> connect(String deviceId, {required Duration timeout}) =>
      UniversalBle.connect(deviceId, timeout: timeout);

  @override
  Future<void> disconnect(String deviceId) => UniversalBle.disconnect(deviceId);

  @override
  Stream<bool> connectionChanges(String deviceId) =>
      UniversalBle.connectionStream(deviceId);

  @override
  Future<List<BleServiceInfo>> discoverServices(String deviceId) async {
    final services = await UniversalBle.discoverServices(deviceId);
    return [
      for (final s in services)
        BleServiceInfo(
          uuid: normalizeUuid(s.uuid),
          characteristics: [
            for (final c in s.characteristics)
              BleCharInfo(
                uuid: normalizeUuid(c.uuid),
                read: c.properties.contains(CharacteristicProperty.read),
                write:
                    c.properties.contains(CharacteristicProperty.write) ||
                    c.properties.contains(
                      CharacteristicProperty.writeWithoutResponse,
                    ),
                notify: c.properties.contains(CharacteristicProperty.notify),
                indicate: c.properties.contains(
                  CharacteristicProperty.indicate,
                ),
              ),
          ],
        ),
    ];
  }

  @override
  Future<void> subscribe(
    String deviceId,
    String service,
    String characteristic, {
    bool indicate = false,
  }) => indicate
      ? UniversalBle.subscribeIndications(deviceId, service, characteristic)
      : UniversalBle.subscribeNotifications(deviceId, service, characteristic);

  @override
  Stream<Uint8List> values(String deviceId, String characteristic) =>
      UniversalBle.characteristicValueStream(deviceId, characteristic);

  @override
  Future<Uint8List> read(
    String deviceId,
    String service,
    String characteristic,
  ) => UniversalBle.read(deviceId, service, characteristic);

  @override
  Future<void> write(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
  ) => UniversalBle.write(deviceId, service, characteristic, value);
}
