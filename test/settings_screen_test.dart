import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/app/font_licences.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';

import 'fakes/fake_ble.dart';
import 'test_app.dart';

/// tall enough that the whole settings list is built
const tallPhone = Size(400, 2400);

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
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

  Future<AppSettings> saved(WidgetTester tester) async =>
      (await tester.runAsync(() => SettingsRepository(db).load()))!;

  Future<void> openSettings(
    WidgetTester tester, {
    FakeBleTransport? ble,
  }) async {
    await pumpApp(tester, db, size: tallPhone, ble: ble);
    await tester.tap(find.byTooltip('Settings'));
    await wait(tester, 500);
  }

  testWidgets('weighing choices are saved', (tester) async {
    await openSettings(tester);

    await tap(tester, find.text('±0.5 g'));
    await tap(tester, find.text('Sounds'));
    await tap(tester, find.text('Move on by itself'));

    var s = await saved(tester);
    expect(s.toleranceDg, 5);
    expect(s.soundsOn, isFalse);
    expect(s.autoAdvance, isTrue);

    expect(find.text('Steady means the reading stays within'), findsNothing);
    await tap(tester, find.text('Advanced'));
    await tap(tester, find.text('0.3 g'));
    await tap(tester, find.text('1.2 s'));
    s = await saved(tester);
    expect(s.stabilityThresholdMg, 300);
    expect(s.stabilityDwellMs, 1200);

    await tap(tester, find.text('Back to defaults'));
    s = await saved(tester);
    expect(s.toleranceDg, 3);
    expect(s.stabilityThresholdMg, 200);
    expect(s.stabilityDwellMs, 800);
    // the switches aren't part of the reset
    expect(s.soundsOn, isFalse);
    expect(find.text('Back to defaults'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('starting dye amount steps by 5 g within bounds', (tester) async {
    await openSettings(tester);
    expect(find.text('60.0 g'), findsOneWidget);

    await tap(tester, find.byTooltip('More'));
    expect(find.text('65.0 g'), findsOneWidget);
    expect((await saved(tester)).defaultDyeDg, 650);

    await unmountApp(tester);

    await pumpApp(
      tester,
      db,
      size: tallPhone,
      settings: const AppSettings(defaultDyeDg: 100),
    );
    await tester.tap(find.byTooltip('Settings'));
    await wait(tester, 500);
    final less = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(less.onPressed, isNull);

    await unmountApp(tester);
  });

  testWidgets('the scale section follows what\'s connected', (tester) async {
    await openSettings(tester);
    expect(find.text('No scale connected.'), findsOneWidget);
    expect(find.text('Calibrate'), findsNothing);

    await tap(tester, find.text('Manage scale'));
    await tap(tester, find.text('Use simulated scale'));
    await tester.tap(find.byTooltip('Settings'));
    await wait(tester, 500);
    expect(
      find.text('The simulated scale needs no calibration.'),
      findsOneWidget,
    );
    expect(find.text('Calibrate'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('a connected ColorMix scale can be calibrated from here', (
    tester,
  ) async {
    final radio = FakeBleTransport()..add(fakeEsp32());
    await pumpApp(tester, db, size: tallPhone, ble: radio);
    await tester.tap(find.byIcon(Icons.scale_outlined).first);
    await wait(tester, 500);
    await tap(tester, find.text('Scan'));
    await tap(tester, find.byKey(ValueKey('connect:${fakeEsp32().id}')));

    await tester.tap(find.byTooltip('Settings'));
    await wait(tester, 500);
    expect(find.text('ColorMix Scale · Connected'), findsOneWidget);
    expect(find.text('Calibrated'), findsOneWidget);

    await tap(tester, find.text('Calibrate'));
    expect(find.text('Calibrate the scale'), findsOneWidget);
    expect(find.text('Empty the platform'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('the fonts\' licences are there and the page opens', (
    tester,
  ) async {
    final entries = (await tester.runAsync(() => fontLicences().toList()))!;
    expect(entries.expand((e) => e.packages), ['DM Sans', 'Fraunces']);
    for (final e in entries) {
      expect(
        e.paragraphs.map((p) => p.text).join(' '),
        contains('SIL Open Font License'),
      );
    }

    await openSettings(tester);
    await tap(tester, find.text('Licences'));
    expect(find.textContaining('ColorMix Studio'), findsWidgets);

    await unmountApp(tester);
  });
}
