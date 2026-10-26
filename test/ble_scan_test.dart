import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/ble_transport.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/core/database/database_provider.dart';
import 'package:colormix_studio/features/scale/ble_scan.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';
import 'package:colormix_studio/shared/models/scale_device_info.dart';

import 'fakes/fake_ble.dart';
import 'test_app.dart' show memoryDb;

Future<void> settle([int ms = 30]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late FakeBleTransport radio;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    radio = FakeBleTransport();
    db = memoryDb();
    container = ProviderContainer(
      overrides: [
        bleTransportProvider.overrideWithValue(radio),
        databaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(const AppSettings()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await settle();
    await db.close();
  });

  BleScanNotifier scan() => container.read(bleScanProvider.notifier);
  BleScanState scanState() => container.read(bleScanProvider);

  group('scanning', () {
    test('the browser preview says scales need the apps', () async {
      radio.supported = false;
      await scan().start();
      expect(scanState().scanning, isFalse);
      expect(scanState().problem, contains('Android and Windows apps'));
    });

    test('bluetooth off and no bluetooth get plain messages', () async {
      radio.state = BleAvailability.poweredOff;
      await scan().start();
      expect(scanState().problem, contains('Bluetooth is off'));

      radio.state = BleAvailability.unsupported;
      await scan().start();
      expect(scanState().problem, contains('no Bluetooth'));
    });

    test('asks for permission, explains when it\'s refused', () async {
      radio
        ..permissionsGranted = false
        ..grantOnRequest = false;
      await scan().start();
      expect(scanState().problem, contains('Nearby devices'));
      expect(radio.scanning, isFalse);

      radio.grantOnRequest = true;
      await scan().start();
      expect(scanState().problem, isNull);
      expect(radio.scanning, isTrue);
    });

    test(
      'lists colormix scales first, other scales next, then the rest',
      () async {
        radio
          ..add(fakeHeadphones())
          ..add(fakeWeightScale())
          ..add(fakeEsp32())
          ..add(FakePeripheral(id: 'nameless', rssi: -40));

        await scan().start();
        await settle();

        final s = scanState();
        expect(s.scanning, isTrue);
        expect(s.scales.map((f) => f.kind), [
          ScaleAdapterType.esp32Custom,
          ScaleAdapterType.standardWeightScale,
        ]);
        // unnamed junk isn't worth listing
        expect(s.others.map((f) => f.result.name), ['Headphones']);

        await scan().stop();
        expect(scanState().scanning, isFalse);
        expect(radio.scanning, isFalse);
        // results stay after stopping
        expect(scanState().scales, hasLength(2));
      },
    );

    test('a later sighting without a name keeps the name', () async {
      await scan().start();
      radio.advertise(fakeEsp32());
      radio.advertise(FakePeripheral(id: fakeEsp32().id, rssi: -40));
      await settle();

      final found = scanState().scales.single.result;
      expect(found.name, 'ColorMix Scale');
      expect(found.rssi, -40);
    });
  });

  group('connecting and remembering', () {
    test('a connected scale is remembered, forget clears it', () async {
      final p = fakeEsp32();
      radio.add(p);
      final scale = container.read(scaleProvider.notifier);

      await scale.connectBle(p.scanResult);
      expect(container.read(scaleProvider).isConnected, isTrue);
      expect(container.read(settingsProvider).lastScaleId, p.id);
      expect(
        (await SettingsRepository(db).load()).lastScaleName,
        'ColorMix Scale',
      );

      await scale.forget();
      expect(container.read(scaleProvider).device, isNull);
      expect(container.read(settingsProvider).lastScaleId, isNull);
      expect((await SettingsRepository(db).load()).lastScaleId, isNull);
    });

    test('the last scale reconnects without a scan', () async {
      final p = fakeEsp32();
      radio.add(p);
      final scale = container.read(scaleProvider.notifier);
      await container
          .read(settingsProvider.notifier)
          .setLastScale(p.id, 'ColorMix Scale');

      await scale.connectLast();

      final status = container.read(scaleProvider);
      expect(status.isConnected, isTrue);
      expect(status.device, isA<BleScaleDevice>());
      expect(status.device!.info.name, 'ColorMix Scale');
    });

    test('something that isn\'t a scale isn\'t remembered', () async {
      final p = fakeHeadphones();
      radio.add(p);
      await container.read(scaleProvider.notifier).connectBle(p.scanResult);

      expect(
        container.read(scaleProvider).connection,
        ScaleConnectionState.connectedUnsupported,
      );
      expect(container.read(settingsProvider).lastScaleId, isNull);
    });

    test('switching to the simulator drops the ble scale', () async {
      final p = fakeEsp32();
      radio.add(p);
      final scale = container.read(scaleProvider.notifier);
      await scale.connectBle(p.scanResult);

      await scale.useSimulator();
      await settle(500);

      expect(radio.connected, isEmpty);
      expect(container.read(scaleProvider).isConnected, isTrue);
      expect(
        container.read(scaleProvider).device!.info.name,
        'Simulated scale',
      );
    });
  });
}
