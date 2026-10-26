import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';

import 'fakes/fake_ble.dart';
import 'test_app.dart';
import 'weighing_state_test.dart' show roseGold;

// scanning shows a spinner, so these pump fixed times, not pumpAndSettle

void main() {
  late AppDatabase db;
  late FakeBleTransport radio;

  setUp(() {
    db = memoryDb();
    radio = FakeBleTransport()
      ..add(fakeEsp32())
      ..add(fakeWeightScale())
      ..add(fakeHeadphones());
  });
  tearDown(() => db.close());

  Future<void> wait(WidgetTester tester, [int ms = 300]) async {
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f.first);
    await wait(tester, 200);
    await tester.tap(f.first);
    await wait(tester, 300);
  }

  Future<void> openScaleTab(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    Size size = phone,
  }) async {
    await pumpApp(tester, db, size: size, settings: settings, ble: radio);
    // "Scale" is also the dashboard card's title, go by the nav icon
    await tester.tap(find.byIcon(Icons.scale_outlined).first);
    await tester.pumpAndSettle();
  }

  /// the Connect button on a scan row
  Finder connectFor(FakePeripheral p) =>
      find.byKey(ValueKey('connect:${p.id}'));

  testWidgets('scan, connect, live reading and tare', (tester) async {
    await openScaleTab(tester);

    expect(
      find.text('Switch the scale on, keep it close by, then scan.'),
      findsOneWidget,
    );
    await tap(tester, find.text('Scan'));

    expect(find.text('ColorMix Scale'), findsOneWidget);
    expect(find.text('ColorMix scale'), findsOneWidget);
    expect(find.text('Body Scale'), findsOneWidget);
    expect(find.textContaining('experimental'), findsOneWidget);
    // not a scale, folded away
    expect(find.text('Headphones'), findsNothing);
    expect(find.text('Show 1 other device'), findsOneWidget);

    await tap(tester, connectFor(fakeEsp32()));

    expect(radio.scanning, isFalse);
    expect(find.text('ColorMix Scale · Connected'), findsOneWidget);
    expect(find.text('Firmware 0.1.0 · calibrated'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);

    radio.sendFrame(
      fakeEsp32().id,
      mg: 30000,
      seq: 1,
      flags: FrameFlags.stable,
    );
    await wait(tester);
    expect(find.text('30.0 g'), findsOneWidget);

    await tap(tester, find.widgetWithText(OutlinedButton, 'Tare'));
    expect(find.text('Tared'), findsOneWidget);

    radio.peripherals[fakeEsp32().id]!.tareResult = ControlResult.busy;
    await tap(tester, find.widgetWithText(OutlinedButton, 'Tare'));
    // the "Tared" snackbar animates out first
    await wait(tester, 1000);
    expect(find.textContaining('isn\'t steady yet'), findsOneWidget);

    // remembered for next time
    final saved = (await tester.runAsync(() => SettingsRepository(db).load()))!;
    expect(saved.lastScaleName, 'ColorMix Scale');

    await unmountApp(tester);
  });

  testWidgets('a dropped scale shows what happened and reconnects', (
    tester,
  ) async {
    await openScaleTab(tester);
    await tap(tester, find.text('Scan'));
    await tap(tester, connectFor(fakeEsp32()));

    radio.dropLink(fakeEsp32().id);
    await wait(tester, 200);
    expect(
      find.textContaining('Lost the connection to the scale'),
      findsOneWidget,
    );

    // the first retry is 2 s later
    await wait(tester, 2500);
    expect(find.text('ColorMix Scale · Connected'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('the last scale connects without scanning', (tester) async {
    await openScaleTab(
      tester,
      settings: AppSettings(
        lastScaleId: fakeEsp32().id,
        lastScaleName: 'ColorMix Scale',
      ),
    );

    await tap(tester, find.text('Connect ColorMix Scale'));
    expect(find.text('ColorMix Scale · Connected'), findsOneWidget);
    expect(radio.scanning, isFalse);

    await tap(tester, find.text('Forget this scale'));
    expect(find.text('No scale connected.'), findsOneWidget);
    expect(find.text('Connect ColorMix Scale'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('something that isn\'t a scale says so', (tester) async {
    await openScaleTab(tester);
    await tap(tester, find.text('Scan'));
    await tap(tester, find.text('Show 1 other device'));
    await tap(tester, connectFor(fakeHeadphones()));

    expect(find.textContaining('isn\'t a scale the app knows'), findsOneWidget);
    expect(
      find.text('Headphones · Connected, can\'t read weight'),
      findsOneWidget,
    );

    await unmountApp(tester);
  });

  testWidgets('the browser preview explains there\'s no bluetooth', (
    tester,
  ) async {
    radio.supported = false;
    await openScaleTab(tester);

    expect(find.textContaining('not in this browser preview'), findsOneWidget);
    expect(find.text('Scan'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('a standard weight scale can\'t start weighing', (tester) async {
    await tester.runAsync(() => FormulaRepository(db).save(roseGold()));
    await openScaleTab(tester, size: desktop);
    await tap(tester, find.text('Scan'));
    await tap(tester, connectFor(fakeWeightScale()));
    expect(find.text('Body Scale · Connected'), findsOneWidget);
    expect(find.text('Experimental'), findsOneWidget);

    await tap(tester, find.text('Formulas'));
    await tap(tester, find.text('Rose Gold Demo'));
    await wait(tester, 500);
    await tap(tester, find.text('Start weighing'));

    expect(find.text('Ready to weigh'), findsOneWidget);
    expect(
      find.textContaining('can\'t guide pouring. Use the ColorMix'),
      findsOneWidget,
    );

    await unmountApp(tester);
  });
}
