import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';

import 'fakes/fake_ble.dart';
import 'test_app.dart';
import 'weighing_state_test.dart' show roseGold;

// live readings the whole time: fixed pumps, never pumpAndSettle

const tall = Size(1280, 1800);

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
    await wait(tester, 400);
  }

  Future<void> openScaleTab(
    WidgetTester tester, {
    FakeBleTransport? ble,
  }) async {
    await pumpApp(
      tester,
      db,
      size: tall,
      ble: ble,
      overrides: [
        simulatorFactoryProvider.overrideWithValue(
          () => SimulatedScale(random: Random(3)),
        ),
      ],
    );
    await tester.tap(find.byIcon(Icons.scale_outlined).first);
    await wait(tester, 500);
  }

  testWidgets('the simulator passes the noise check', (tester) async {
    await openScaleTab(tester);
    expect(find.text('Scale check'), findsNothing);

    await tap(tester, find.text('Use simulated scale'));
    expect(
      find.text('Connection and noise checks, for setting up a scale.'),
      findsOneWidget,
    );
    await tap(tester, find.text('Show'));
    await wait(tester, 2500);
    expect(find.text('10 readings a second'), findsOneWidget);
    // only the ColorMix scale answers a connection test
    expect(find.text('Test connection'), findsNothing);

    await tap(tester, find.text('Measure noise'));
    expect(find.text('Measuring, keep it still…'), findsOneWidget);
    await wait(tester, 10500);

    expect(find.text('Swing'), findsOneWidget);
    expect(find.textContaining('readings. Swing is'), findsOneWidget);
    expect(find.textContaining('Steady works'), findsOneWidget);
    expect(find.textContaining('at least twice the swing'), findsOneWidget);
    expect(find.text('Measure again'), findsOneWidget);

    await tap(tester, find.text('Hide'));
    expect(find.text('Swing'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('a noisy, uncalibrated ColorMix scale gets told so', (
    tester,
  ) async {
    final esp = fakeEsp32(info: 'fw=0.1.0;proto=1;cap_g=1000;cal=0');
    final radio = FakeBleTransport()..add(esp);
    await openScaleTab(tester, ble: radio);
    await tap(tester, find.text('Scan'));
    await tap(tester, find.byKey(ValueKey('connect:${esp.id}')));
    await tap(tester, find.text('Show'));

    // ±0.4 g of jitter, uncalibrated, every third frame lost on the way
    var seq = 0;
    var flip = false;
    final bench = Timer.periodic(const Duration(milliseconds: 100), (_) {
      seq += (seq % 3 == 2) ? 2 : 1;
      flip = !flip;
      radio.sendFrame(
        esp.id,
        mg: flip ? 400 : -400,
        seq: seq,
        flags: FrameFlags.uncalibrated,
      );
    });
    addTearDown(bench.cancel);

    await wait(tester, 2500);
    expect(find.textContaining('readings a second'), findsOneWidget);
    expect(find.textContaining(RegExp(r'[1-9]\d* missed')), findsOneWidget);
    expect(find.textContaining('0 unreadable'), findsOneWidget);

    await tap(tester, find.text('Test connection'));
    expect(
      find.textContaining(
        'firmware 0.1.0 · protocol 1 · up to 1000 g · not calibrated',
      ),
      findsOneWidget,
    );

    await tap(tester, find.text('Measure noise'));
    await wait(tester, 10500);
    expect(find.text('0.80 g'), findsOneWidget);
    expect(
      find.textContaining('over the 0.2 g steady threshold'),
      findsOneWidget,
    );
    expect(find.textContaining('less than twice the swing'), findsOneWidget);
    expect(find.textContaining('these grams are only rough'), findsOneWidget);

    // the scale stops answering: the test says so
    esp.answersControl = false;
    await tap(tester, find.text('Test connection'));
    await wait(tester, 4500);
    expect(find.textContaining('didn\'t answer'), findsOneWidget);

    bench.cancel();
    await unmountApp(tester);
  });

  testWidgets('weighing opened with no scale offers the last one', (
    tester,
  ) async {
    final esp = fakeEsp32();
    final radio = FakeBleTransport()..add(esp);
    await tester.runAsync(() => FormulaRepository(db).save(roseGold()));
    await pumpApp(
      tester,
      db,
      size: tall,
      ble: radio,
      settings: AppSettings(lastScaleId: esp.id, lastScaleName: esp.name),
    );

    // straight to the weighing screen, the way a link would. push's future
    // is the route's result, nothing to wait for
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push(Routes.weigh('f')),
    );
    await wait(tester, 800);
    expect(find.text('Scale disconnected'), findsOneWidget);

    await tap(tester, find.text('Connect last scale'));
    await wait(tester, 500);
    expect(find.text('Scale disconnected'), findsNothing);
    // the screen and the record name the scale that's really weighing
    expect(find.text('ColorMix Scale · Connected'), findsOneWidget);
    final row = (await tester.runAsync(
      () => db.select(db.weighingSessions).getSingle(),
    ))!;
    expect(row.scaleId, esp.id);
    expect(row.scaleName, 'ColorMix Scale');

    await unmountApp(tester);
  });
}
