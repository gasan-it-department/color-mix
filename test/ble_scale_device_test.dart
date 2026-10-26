import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/ble_transport.dart';
import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/shared/models/scale_device_info.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

import 'fakes/fake_ble.dart';

Future<void> settle([int ms = 30]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late FakeBleTransport radio;
  late List<BleScaleDevice> devices;

  setUp(() {
    radio = FakeBleTransport();
    devices = [];
  });

  tearDown(() async {
    for (final d in devices) {
      await d.close();
    }
  });

  BleScaleDevice deviceFor(FakePeripheral p) {
    radio.add(p);
    final d = BleScaleDevice(
      transport: radio,
      deviceId: p.id,
      name: p.name ?? 'Unnamed device',
      guess: guessAdapter(p.scanResult),
      commandTimeout: const Duration(milliseconds: 60),
      reconnectDelays: const [
        Duration(milliseconds: 10),
        Duration(milliseconds: 10),
        Duration(milliseconds: 10),
      ],
    );
    devices.add(d);
    return d;
  }

  group('esp32', () {
    test(
      'connects, checks the service and protocol, streams readings',
      () async {
        final p = fakeEsp32();
        final scale = deviceFor(p);
        final readings = <WeightReading>[];
        scale.weightStream.listen(readings.add);

        await scale.connect();

        expect(scale.connectionState, ScaleConnectionState.connectedSupported);
        expect(scale.info.adapterType, ScaleAdapterType.esp32Custom);
        expect(scale.info.isSupported, isTrue);
        expect(scale.supportsTare, isTrue);
        expect(scale.deviceInfo['fw'], '0.1.0');
        expect(scale.calibrated, isTrue);
        expect(scale.problem, isNull);
        expect(
          radio.subscribed,
          contains(normalizeUuid(ColorMixScaleUuids.weight)),
        );
        expect(
          radio.subscribed,
          contains(normalizeUuid(ColorMixScaleUuids.control)),
        );

        radio.sendFrame(p.id, mg: 30000, seq: 1, flags: FrameFlags.stable);
        radio.sendFrame(p.id, mg: -12, seq: 2, flags: FrameFlags.overload);
        await settle();

        expect(readings.map((r) => r.milligrams), [30000, -12]);
        expect(readings.first.isStable, isTrue);
        expect(readings.last.overload, isTrue);
      },
    );

    test('late, repeated and broken frames are dropped', () async {
      final p = fakeEsp32();
      final scale = deviceFor(p);
      final readings = <int>[];
      scale.weightStream.listen((r) => readings.add(r.milligrams));
      await scale.connect();

      radio.sendFrame(p.id, mg: 1000, seq: 10);
      radio.sendFrame(p.id, mg: 9999, seq: 10); // repeat
      radio.sendFrame(p.id, mg: 9999, seq: 9); // late
      radio.sendBytes(p.id, ColorMixScaleUuids.weight, [1, 2, 3]); // garbage
      radio.sendFrame(p.id, mg: 2000, seq: 11);
      await settle();

      expect(readings, [1000, 2000]);
      expect(scale.badFrames, 1);
    });

    test('the sequence number wrapping round is still in order', () async {
      final p = fakeEsp32();
      final scale = deviceFor(p);
      final readings = <int>[];
      scale.weightStream.listen((r) => readings.add(r.milligrams));
      await scale.connect();

      radio.sendFrame(p.id, mg: 1000, seq: 65534);
      radio.sendFrame(p.id, mg: 2000, seq: 65535);
      radio.sendFrame(p.id, mg: 3000, seq: 0);
      radio.sendFrame(p.id, mg: 4000, seq: 1);
      await settle();

      expect(readings, [1000, 2000, 3000, 4000]);
    });

    test('a sensor fault gives no weight and says what\'s wrong', () async {
      final p = fakeEsp32();
      final scale = deviceFor(p);
      final readings = <int>[];
      scale.weightStream.listen((r) => readings.add(r.milligrams));
      await scale.connect();

      radio.sendFrame(p.id, mg: 5000, seq: 1, flags: FrameFlags.sensorFault);
      await settle();
      expect(readings, isEmpty);
      expect(scale.sensorFault, isTrue);
      expect(scale.problem, contains('sensor isn\'t answering'));

      radio.sendFrame(p.id, mg: 5000, seq: 2);
      await settle();
      expect(readings, [5000]);
      expect(scale.sensorFault, isFalse);
      expect(scale.problem, isNull);
    });

    test('an uncalibrated scale connects with a warning', () async {
      final scale = deviceFor(
        fakeEsp32(info: 'fw=0.1.0;proto=1;cap_g=1000;cal=0'),
      );
      await scale.connect();
      expect(scale.isConnected, isTrue);
      expect(scale.problem, contains('isn\'t calibrated'));
    });

    test('another protocol version is refused', () async {
      final scale = deviceFor(
        fakeEsp32(info: 'fw=0.9.0;proto=2;cap_g=1000;cal=1'),
      );
      await scale.connect();
      expect(scale.connectionState, ScaleConnectionState.connectedUnsupported);
      expect(scale.problem, contains('protocol 2'));
    });

    test('missing characteristics are refused', () async {
      final scale = deviceFor(fakeEsp32(controlChar: false));
      await scale.connect();
      expect(scale.connectionState, ScaleConnectionState.connectedUnsupported);
      expect(scale.problem, contains('firmware doesn\'t match'));
    });

    test('tare: ok, busy and no answer', () async {
      final p = fakeEsp32();
      final scale = deviceFor(p);
      await scale.connect();

      await scale.tare();
      expect(radio.writes.last, [ControlOp.tare]);

      p.tareResult = ControlResult.busy;
      await expectLater(
        scale.tare(),
        throwsA(
          isA<ScaleCommandException>().having(
            (e) => e.message,
            'message',
            contains('steady'),
          ),
        ),
      );

      p.answersControl = false;
      await expectLater(
        scale.tare(),
        throwsA(
          isA<ScaleCommandException>().having(
            (e) => e.message,
            'message',
            contains('didn\'t answer'),
          ),
        ),
      );
    });
  });

  group('connection', () {
    test('a scale that can\'t be reached fails straight away', () async {
      final p = fakeEsp32()..reachable = false;
      final scale = deviceFor(p);

      await scale.connect();
      await settle(80);

      expect(scale.connectionState, ScaleConnectionState.failed);
      expect(scale.problem, contains('Couldn\'t reach the scale'));
      expect(radio.connectCalls, 1);
    });

    test('a dropped link comes back by itself', () async {
      final p = fakeEsp32();
      final scale = deviceFor(p);
      final readings = <int>[];
      final states = <ScaleConnectionState>[];
      scale.weightStream.listen((r) => readings.add(r.milligrams));
      scale.connectionStates.listen(states.add);
      await scale.connect();
      radio.sendFrame(p.id, mg: 1000, seq: 500);
      await settle();

      radio.dropLink(p.id);
      await settle(80);

      expect(states, contains(ScaleConnectionState.connecting));
      expect(scale.connectionState, ScaleConnectionState.connectedSupported);
      expect(radio.connectCalls, 2);

      // a restarted esp32 counts from 1 again, that's not "late"
      radio.sendFrame(p.id, mg: 2000, seq: 1);
      await settle();
      expect(readings, [1000, 2000]);
    });

    test('a link that stays down gives up after a few tries', () async {
      final p = fakeEsp32();
      final scale = deviceFor(p);
      await scale.connect();

      p.reachable = false;
      radio.dropLink(p.id);
      await settle(150);

      expect(scale.connectionState, ScaleConnectionState.failed);
      expect(scale.problem, contains('Lost the connection'));
      // first connect plus three retries
      expect(radio.connectCalls, 4);
    });

    test('a disconnect the app asked for isn\'t retried', () async {
      final p = fakeEsp32();
      final scale = deviceFor(p);
      await scale.connect();

      await scale.disconnect();
      await settle(80);

      expect(scale.connectionState, ScaleConnectionState.disconnected);
      expect(radio.connectCalls, 1);
      expect(radio.connected, isEmpty);
    });
  });

  group('other devices', () {
    test('a standard weight scale works, experimental, no tare', () async {
      final p = fakeWeightScale();
      final scale = deviceFor(p);
      final readings = <int>[];
      scale.weightStream.listen((r) => readings.add(r.milligrams));
      await scale.connect();

      expect(scale.isConnected, isTrue);
      expect(scale.info.adapterType, ScaleAdapterType.standardWeightScale);
      expect(scale.experimental, isTrue);
      expect(scale.supportsTare, isFalse);
      expect(scale.problem, contains('Experimental'));
      await expectLater(scale.tare(), throwsA(isA<ScaleCommandException>()));

      // 40 x 5 g, then 1 lb
      radio.sendBytes(p.id, weightMeasurementChar, [0x00, 40, 0]);
      radio.sendBytes(p.id, weightMeasurementChar, [0x01, 100, 0]);
      await settle();
      expect(readings, [200000, 453592]);
    });

    test('anything else connects but is marked unsupported', () async {
      final scale = deviceFor(fakeHeadphones());
      await scale.connect();
      expect(scale.connectionState, ScaleConnectionState.connectedUnsupported);
      expect(scale.info.isSupported, isFalse);
      expect(scale.problem, contains('isn\'t a scale the app knows'));
    });
  });

  group('helpers', () {
    test('uuids normalize', () {
      expect(normalizeUuid('181D'), '0000181d-0000-1000-8000-00805f9b34fb');
      expect(normalizeUuid('0x2A9D'), '00002a9d-0000-1000-8000-00805f9b34fb');
      expect(
        normalizeUuid('7A3E0001-5C2D-4F1B-9C8E-0D6B2F4A1E90'),
        ColorMixScaleUuids.service,
      );
    });

    test('scan results are sorted out by what they advertise', () {
      expect(
        guessAdapter(fakeEsp32().scanResult),
        ScaleAdapterType.esp32Custom,
      );
      expect(
        guessAdapter(
          const BleScanResult(deviceId: 'x', name: 'ColorMix Scale'),
        ),
        ScaleAdapterType.esp32Custom,
      );
      expect(
        guessAdapter(fakeWeightScale().scanResult),
        ScaleAdapterType.standardWeightScale,
      );
      expect(
        guessAdapter(fakeHeadphones().scanResult),
        ScaleAdapterType.unknown,
      );
    });

    test('weight measurement parsing', () {
      expect(
        parseWeightMeasurement(Uint8List.fromList([0, 0xFF, 0xFF])),
        isNull,
      );
      expect(parseWeightMeasurement(Uint8List.fromList([0, 1])), isNull);
      expect(signalBars(-50), 4);
      expect(signalBars(-85), 1);
      expect(signalBars(null), 0);
    });
  });

  test('closing stops everything', () async {
    final scale = deviceFor(fakeEsp32());
    await scale.connect();
    final done = Completer<void>();
    scale.weightStream.listen(null, onDone: done.complete);
    await scale.close();
    devices.remove(scale);
    await done.future.timeout(const Duration(seconds: 1));
  });
}
