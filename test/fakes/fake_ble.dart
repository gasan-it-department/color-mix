import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/ble_transport.dart';
import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';

/// something the fake radio can find and talk to
class FakePeripheral {
  FakePeripheral({
    required this.id,
    this.name,
    this.advertised = const [],
    this.services = const [],
    this.info = 'fw=0.1.0;proto=1;cap_g=1000;cal=1',
    this.rssi = -60,
    this.tareResult = ControlResult.ok,
    this.calZeroResult = ControlResult.ok,
    this.calMassResult = ControlResult.ok,
    this.answersControl = true,
  });

  final String id;
  final String? name;
  final List<String> advertised;
  final List<BleServiceInfo> services;
  String info;
  int rssi;
  int tareResult;
  int calZeroResult;
  int calMassResult;
  bool answersControl;

  /// how long calibration replies take, the real one averages 2 s
  Duration calDelay = Duration.zero;

  /// out of range or switched off
  bool reachable = true;

  BleScanResult get scanResult => BleScanResult(
    deviceId: id,
    name: name,
    rssi: rssi,
    services: [for (final s in advertised) normalizeUuid(s)],
  );
}

/// the esp32 the way the firmware sets it up
FakePeripheral fakeEsp32({
  String id = 'AA:BB:CC:00:00:01',
  String name = 'ColorMix Scale',
  String info = 'fw=0.1.0;proto=1;cap_g=1000;cal=1',
  bool controlChar = true,
}) {
  return FakePeripheral(
    id: id,
    name: name,
    info: info,
    advertised: [ColorMixScaleUuids.service],
    services: [
      BleServiceInfo(
        uuid: ColorMixScaleUuids.service,
        characteristics: [
          const BleCharInfo(uuid: ColorMixScaleUuids.weight, notify: true),
          const BleCharInfo(uuid: ColorMixScaleUuids.info, read: true),
          if (controlChar)
            const BleCharInfo(
              uuid: ColorMixScaleUuids.control,
              write: true,
              notify: true,
            ),
        ],
      ),
    ],
  );
}

/// a bathroom-style scale with the standard weight scale service
FakePeripheral fakeWeightScale({String id = 'AA:BB:CC:00:00:02'}) {
  return FakePeripheral(
    id: id,
    name: 'Body Scale',
    rssi: -70,
    advertised: [weightScaleService],
    services: [
      BleServiceInfo(
        uuid: weightScaleService,
        characteristics: [
          BleCharInfo(uuid: weightMeasurementChar, indicate: true),
        ],
      ),
    ],
  );
}

/// something that isn't a scale at all
FakePeripheral fakeHeadphones({String id = 'AA:BB:CC:00:00:03'}) {
  return FakePeripheral(
    id: id,
    name: 'Headphones',
    rssi: -50,
    advertised: ['110A'],
    services: [
      BleServiceInfo(
        uuid: normalizeUuid('180F'),
        characteristics: [
          BleCharInfo(uuid: normalizeUuid('2A19'), read: true, notify: true),
        ],
      ),
    ],
  );
}

/// a radio in memory. answers control writes the way the firmware does
class FakeBleTransport implements BleTransport {
  @override
  bool supported = true;

  BleAvailability state = BleAvailability.poweredOn;
  bool permissionsGranted = true;
  bool grantOnRequest = true;
  bool scanning = false;
  int connectCalls = 0;

  final peripherals = <String, FakePeripheral>{};
  final connected = <String>{};
  final subscribed = <String>[];
  final writes = <Uint8List>[];

  final _availability = StreamController<BleAvailability>.broadcast();
  final _scan = StreamController<BleScanResult>.broadcast();
  final _links = <String, StreamController<bool>>{};
  final _values = <String, StreamController<Uint8List>>{};

  void add(FakePeripheral p) => peripherals[p.id] = p;

  StreamController<bool> _link(String id) =>
      _links.putIfAbsent(id, StreamController<bool>.broadcast);

  StreamController<Uint8List> _value(String id, String char) =>
      _values.putIfAbsent(
        '$id|${normalizeUuid(char)}',
        StreamController<Uint8List>.broadcast,
      );

  // ── test helpers ──

  void setAvailability(BleAvailability s) {
    state = s;
    _availability.add(s);
  }

  void sendFrame(
    String id, {
    required int mg,
    required int seq,
    int flags = 0,
  }) {
    _value(
      id,
      ColorMixScaleUuids.weight,
    ).add(encodeWeightFrame(milligrams: mg, sequence: seq, flags: flags));
  }

  void sendBytes(String id, String char, List<int> bytes) =>
      _value(id, char).add(Uint8List.fromList(bytes));

  /// the link goes without anyone asking
  void dropLink(String id) {
    connected.remove(id);
    _link(id).add(false);
  }

  /// shows up in an ongoing scan
  void advertise(FakePeripheral p) {
    add(p);
    if (scanning) _scan.add(p.scanResult);
  }

  // ── BleTransport ──

  @override
  Future<BleAvailability> availability() async => state;

  @override
  Stream<BleAvailability> get availabilityChanges => _availability.stream;

  @override
  Future<bool> hasPermissions() async => permissionsGranted;

  @override
  Future<void> requestPermissions() async {
    if (!grantOnRequest) throw const BlePermissionDenied();
    permissionsGranted = true;
  }

  @override
  Future<bool> enableBluetooth() async => false;

  @override
  Stream<BleScanResult> get scanResults => _scan.stream;

  @override
  Future<void> startScan() async {
    scanning = true;
    scheduleMicrotask(() {
      for (final p in peripherals.values) {
        if (scanning && p.reachable) _scan.add(p.scanResult);
      }
    });
  }

  @override
  Future<void> stopScan() async => scanning = false;

  @override
  Future<void> connect(String deviceId, {required Duration timeout}) async {
    connectCalls++;
    final p = peripherals[deviceId];
    if (p == null || !p.reachable) {
      throw TimeoutException('no answer from $deviceId', timeout);
    }
    connected.add(deviceId);
    _link(deviceId).add(true);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    if (connected.remove(deviceId)) _link(deviceId).add(false);
  }

  @override
  Stream<bool> connectionChanges(String deviceId) => _link(deviceId).stream;

  @override
  Future<List<BleServiceInfo>> discoverServices(String deviceId) async =>
      peripherals[deviceId]!.services;

  @override
  Future<void> subscribe(
    String deviceId,
    String service,
    String characteristic, {
    bool indicate = false,
  }) async {
    subscribed.add(normalizeUuid(characteristic));
  }

  @override
  Stream<Uint8List> values(String deviceId, String characteristic) =>
      _value(deviceId, characteristic).stream;

  @override
  Future<Uint8List> read(
    String deviceId,
    String service,
    String characteristic,
  ) async {
    final p = peripherals[deviceId]!;
    if (normalizeUuid(characteristic) ==
        normalizeUuid(ColorMixScaleUuids.info)) {
      return Uint8List.fromList(utf8.encode(p.info));
    }
    return Uint8List(0);
  }

  @override
  Future<void> write(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
  ) async {
    writes.add(value);
    final p = peripherals[deviceId]!;
    if (!p.answersControl) return;
    if (normalizeUuid(characteristic) !=
        normalizeUuid(ColorMixScaleUuids.control)) {
      return;
    }
    final op = value[0];
    final result = switch (op) {
      ControlOp.tare => p.tareResult,
      ControlOp.calZero => p.calZeroResult,
      ControlOp.calKnownMass => p.calMassResult,
      _ => ControlResult.ok,
    };
    void reply() {
      // the firmware rewrites its info text once calibrated
      if (op == ControlOp.calKnownMass && result == ControlResult.ok) {
        p.info = p.info.replaceFirst('cal=0', 'cal=1');
      }
      sendBytes(deviceId, ColorMixScaleUuids.control, [
        op | ControlOp.replyBit,
        result,
      ]);
    }

    final calibrating = op == ControlOp.calZero || op == ControlOp.calKnownMass;
    if (calibrating && p.calDelay > Duration.zero) {
      Timer(p.calDelay, reply);
    } else {
      scheduleMicrotask(reply);
    }
  }
}
