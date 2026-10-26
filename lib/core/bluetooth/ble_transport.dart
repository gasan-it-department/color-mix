import 'dart:typed_data';

// the few ble calls the app makes, behind an interface so tests can stand
// a fake esp32 in for the real radio. uuids are always the full lowercase
// 128-bit form, see normalizeUuid

enum BleAvailability {
  unknown,
  unsupported,
  unauthorized,
  poweredOff,
  poweredOn,
}

class BlePermissionDenied implements Exception {
  const BlePermissionDenied();
}

class BleScanResult {
  const BleScanResult({
    required this.deviceId,
    this.name,
    this.rssi,
    this.services = const [],
  });

  final String deviceId;
  final String? name;
  final int? rssi;

  /// advertised service uuids, normalized
  final List<String> services;
}

class BleCharInfo {
  const BleCharInfo({
    required this.uuid,
    this.read = false,
    this.write = false,
    this.notify = false,
    this.indicate = false,
  });

  final String uuid;
  final bool read;
  final bool write;
  final bool notify;
  final bool indicate;
}

class BleServiceInfo {
  const BleServiceInfo({required this.uuid, required this.characteristics});

  final String uuid;
  final List<BleCharInfo> characteristics;

  BleCharInfo? characteristic(String uuid) {
    final want = normalizeUuid(uuid);
    for (final c in characteristics) {
      if (normalizeUuid(c.uuid) == want) return c;
    }
    return null;
  }
}

abstract interface class BleTransport {
  /// false where the app can't use ble (the web preview)
  bool get supported;

  Future<BleAvailability> availability();
  Stream<BleAvailability> get availabilityChanges;

  Future<bool> hasPermissions();

  /// throws [BlePermissionDenied]
  Future<void> requestPermissions();

  /// android can switch it on after asking, elsewhere false
  Future<bool> enableBluetooth();

  Stream<BleScanResult> get scanResults;
  Future<void> startScan();
  Future<void> stopScan();

  /// throws when it can't connect within [timeout]
  Future<void> connect(String deviceId, {required Duration timeout});
  Future<void> disconnect(String deviceId);

  /// true / false as the link comes and goes
  Stream<bool> connectionChanges(String deviceId);

  Future<List<BleServiceInfo>> discoverServices(String deviceId);

  Future<void> subscribe(
    String deviceId,
    String service,
    String characteristic, {
    bool indicate = false,
  });

  Stream<Uint8List> values(String deviceId, String characteristic);

  Future<Uint8List> read(
    String deviceId,
    String service,
    String characteristic,
  );

  Future<void> write(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
  );
}

const _bluetoothBase = '-0000-1000-8000-00805f9b34fb';

/// '181D' / '0x181d' -> '0000181d-0000-1000-8000-00805f9b34fb', full ones
/// just lowercased
String normalizeUuid(String uuid) {
  var u = uuid.trim().toLowerCase();
  if (u.startsWith('0x')) u = u.substring(2);
  if (u.length == 4) return '0000$u$_bluetoothBase';
  if (u.length == 8) return '$u$_bluetoothBase';
  return u;
}
