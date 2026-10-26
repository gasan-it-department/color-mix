import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';

import 'fakes/fake_ble.dart';
import 'test_app.dart';
import 'weighing_state_test.dart' show roseGold;

// live frames and spinners, so fixed pumps rather than pumpAndSettle

void main() {
  late AppDatabase db;
  late FakeBleTransport radio;
  late FakePeripheral scale;
  var seq = 0;

  setUp(() {
    db = memoryDb();
    scale = fakeEsp32(info: 'fw=0.1.0;proto=1;cap_g=1000;cal=0');
    radio = FakeBleTransport()..add(scale);
    seq = 0;
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
    await wait(tester, 400);
  }

  Future<void> reads(WidgetTester tester, int mg, {bool uncal = false}) async {
    radio.sendFrame(
      scale.id,
      mg: mg,
      seq: ++seq,
      flags: FrameFlags.stable | (uncal ? FrameFlags.uncalibrated : 0),
    );
    await wait(tester, 200);
  }

  Future<void> connectOnScaleTab(
    WidgetTester tester, {
    Size size = phone,
  }) async {
    await pumpApp(tester, db, size: size, ble: radio);
    await tester.tap(find.byIcon(Icons.scale_outlined).first);
    await wait(tester, 500);
    await tap(tester, find.text('Scan'));
    await tap(tester, find.byKey(ValueKey('connect:${scale.id}')));
  }

  testWidgets('the wizard zeroes, calibrates and checks', (tester) async {
    await connectOnScaleTab(tester);
    expect(find.text('Firmware 0.1.0 · not calibrated'), findsOneWidget);

    await tap(tester, find.widgetWithText(FilledButton, 'Calibrate'));
    expect(find.text('Calibrate the scale'), findsOneWidget);
    expect(find.text('Empty the platform'), findsOneWidget);

    await reads(tester, 300, uncal: true);
    expect(find.text('0.3 g'), findsOneWidget);
    expect(find.text('Rough until calibrated'), findsOneWidget);
    expect(find.text('Steady'), findsOneWidget);

    // the real scale averages for 2 s before it answers
    scale.calDelay = const Duration(seconds: 2);
    await tester.tap(find.text('Zero the scale'));
    await wait(tester, 500);
    expect(find.text('Measuring…'), findsOneWidget);
    expect(find.textContaining('Keep it still'), findsOneWidget);
    await wait(tester, 2000);
    expect(find.text('Put the reference weight on'), findsOneWidget);
    expect(radio.writes.last, [ControlOp.calZero]);

    await tap(tester, find.widgetWithText(FilledButton, 'Calibrate'));
    expect(find.text('Its mass in grams, like 200 or 523.4.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '5');
    await wait(tester);
    expect(find.text('At least 10 g.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '200');
    await tap(tester, find.widgetWithText(FilledButton, 'Calibrate'));
    await wait(tester, 2200);
    expect(find.text('Check it'), findsOneWidget);
    expect(
      find.textContaining('Calibrated. The scale keeps it'),
      findsOneWidget,
    );
    expect(
      radio.writes.firstWhere((w) => w[0] == ControlOp.calKnownMass),
      encodeControl(ControlOp.calKnownMass, 200000),
    );

    await reads(tester, 200100);
    expect(find.text('Off by +0.1 g'), findsOneWidget);
    expect(find.text('Within ±0.3 g'), findsOneWidget);

    await reads(tester, 201000);
    expect(find.text('Off by +1.0 g'), findsOneWidget);
    expect(find.text('More than ±0.3 g'), findsOneWidget);

    // another known weight
    await tester.enterText(find.byType(TextField), '201');
    await wait(tester);
    expect(find.text('Within ±0.3 g'), findsOneWidget);

    await tap(tester, find.text('Done'));
    expect(find.text('Firmware 0.1.0 · calibrated'), findsOneWidget);
    expect(find.textContaining('isn\'t calibrated'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('a step the scale refuses explains and stays', (tester) async {
    scale.calZeroResult = ControlResult.busy;
    await connectOnScaleTab(tester);
    await tap(tester, find.widgetWithText(FilledButton, 'Calibrate'));

    await tap(tester, find.text('Zero the scale'));
    expect(find.text('That didn\'t work'), findsOneWidget);
    expect(
      find.textContaining('Keep the platform empty and still'),
      findsOneWidget,
    );
    expect(find.text('Empty the platform'), findsOneWidget);

    scale.calZeroResult = ControlResult.ok;
    await tap(tester, find.text('Zero the scale'));
    expect(find.text('That didn\'t work'), findsNothing);
    expect(find.text('Put the reference weight on'), findsOneWidget);

    await tap(tester, find.text('Back to step 1'));
    expect(find.text('Empty the platform'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('a dropped scale mid-wizard offers to reconnect', (tester) async {
    await connectOnScaleTab(tester);
    await tap(tester, find.widgetWithText(FilledButton, 'Calibrate'));

    radio.dropLink(scale.id);
    await wait(tester, 300);
    expect(find.text('Reconnecting…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Zero the scale'),
          )
          .onPressed,
      isNull,
    );

    await wait(tester, 2500);
    expect(find.text('Reconnecting…'), findsNothing);
    expect(find.text('Empty the platform'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('an uncalibrated scale can\'t start weighing', (tester) async {
    await tester.runAsync(() => FormulaRepository(db).save(roseGold()));
    await connectOnScaleTab(tester, size: desktop);

    await tap(tester, find.text('Formulas'));
    await tap(tester, find.byTooltip('More for Rose Gold Demo'));
    await tap(tester, find.text('Weigh'));
    expect(find.text('Ready to weigh'), findsOneWidget);
    expect(find.textContaining('Calibrate it first'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start weighing'),
          )
          .onPressed,
      isNull,
    );

    await tap(tester, find.text('Calibrate'));
    expect(find.text('Calibrate the scale'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('a calibrated scale doesn\'t block the start sheet', (
    tester,
  ) async {
    scale.info = 'fw=0.1.0;proto=1;cap_g=1000;cal=1';
    await tester.runAsync(() => FormulaRepository(db).save(roseGold()));
    await connectOnScaleTab(tester, size: desktop);

    await tap(tester, find.text('Formulas'));
    await tap(tester, find.byTooltip('More for Rose Gold Demo'));
    await tap(tester, find.text('Weigh'));
    expect(find.textContaining('Calibrate it first'), findsNothing);
    expect(find.text('Tick the developer check first.'), findsOneWidget);

    await unmountApp(tester);
  });
}
