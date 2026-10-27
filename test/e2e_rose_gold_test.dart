import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

import 'fakes/fake_ble.dart';
import 'test_app.dart';

// the blueprint's definition of a working prototype (section 19), all 16
// steps through the real screens: once on the simulated scale on a 360 px
// phone, once on the ColorMix scale over the fake radio on a desktop.
// readings stream the whole time, so fixed pumps, never pumpAndSettle

/// the bench the fake ESP32 sits on: whatever is on the platform, sent as
/// a frame every 100 ms like the firmware does
class Bench {
  Bench(this.radio, this.id);

  final FakeBleTransport radio;
  final String id;
  int mg = 0;
  int _seq = 0;
  Timer? _timer;

  void start() => _timer = Timer.periodic(
    const Duration(milliseconds: 100),
    (_) => radio.sendFrame(id, mg: mg, seq: ++_seq, flags: FrameFlags.stable),
  );

  void stop() => _timer?.cancel();
}

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> wait(WidgetTester tester, [int ms = 300]) async {
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// lazy lists on a phone only build what's near the screen, look both ways
  Future<void> reveal(WidgetTester tester, Finder f) async {
    for (final delta in [300.0, -300.0]) {
      if (f.evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(
          f,
          delta,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
      } on StateError {
        // not that way
      }
    }
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await reveal(tester, f);
    await tester.ensureVisible(f.first);
    await wait(tester, 200);
    await tester.tap(f.first);
    await wait(tester, 400);
  }

  Future<void> see(WidgetTester tester, Finder f) async {
    await reveal(tester, f);
    expect(f, findsWidgets);
  }

  Future<void> tapText(WidgetTester tester, String text) =>
      tap(tester, find.text(text));

  final dyeField = find.widgetWithText(
    TextField,
    'All colors together, not counting developer',
  );
  final ratioCheck = find.text(
    'The developer ratio 1:1 by weight matches the product instructions',
  );
  final startInSheet = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.widgetWithText(FilledButton, 'Start weighing'),
  );

  /// steps 2 to 5: Rose Gold, its recipe, 60 g of dye, the amounts. leaves
  /// the editor open with the formula saved
  Future<void> pickRoseGoldAndSave(
    WidgetTester tester, {
    required bool phone,
  }) async {
    await tapText(tester, 'Colors');
    await tapText(tester, 'Rose Gold');
    // phones keep the recipe in a sheet
    if (phone) await tapText(tester, 'Details');

    // 3. the illustrative recipe, labelled as such
    expect(find.text('Demo recipe'), findsOneWidget);
    expect(find.text('Demo only'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    await tapText(tester, 'Create formula');
    expect(find.text('New formula'), findsOneWidget);

    // 4. 60 g of dye, typed over a different amount
    await tester.enterText(dyeField, '45');
    await wait(tester);
    expect(find.text('22.5 g'), findsWidgets);
    await tester.enterText(dyeField, '60');
    await wait(tester);

    // 5. the amounts: 30 / 18 / 12 g, 60 g developer, 120 g in all
    for (final g in ['30.0 g', '18.0 g', '12.0 g', '120.0 g']) {
      await see(tester, find.text(g));
    }
    await see(tester, find.text('Developer 1:1'));

    await tap(tester, find.widgetWithText(FilledButton, 'Save formula'));
    expect(find.text('Edit formula'), findsOneWidget);
  }

  /// 'of 48.0 g', or anything within 0.3 g of it when the scale is noisy
  Finder cumulative(int dg, {required bool exact}) {
    if (exact) return find.textContaining('of ${formatDecigrams(dg)}');
    final near = [for (var d = dg - 3; d <= dg + 3; d++) formatDecigrams(d)];
    return find.textContaining(RegExp('of (${near.join('|')})'));
  }

  /// steps 9 to 15 once the weighing screen is up. [pour] adds grams to the
  /// bowl, [placeBowl] puts the empty bowl on. [exact] for a scale without
  /// the simulator's noise, so the last digit can be checked too
  Future<void> weighEverything(
    WidgetTester tester, {
    required Future<void> Function() placeBowl,
    required Future<void> Function(int mg) pour,
    required bool exact,
  }) async {
    expect(find.text('Put the empty bowl on the scale'), findsOneWidget);

    // 9. bowl on, zero, about 0.0 g
    await placeBowl();
    await see(tester, find.text('250.0 g'));
    await tap(tester, find.widgetWithText(FilledButton, 'Zero with bowl'));
    await see(tester, find.text('Check it reads about 0.0 g'));
    await wait(tester, 1200);
    await tapText(tester, 'Start with Color A');
    await see(tester, find.text('Step 1 of 4'));

    // 10. pour part of Color A, the numbers follow
    await pour(10000);
    await see(tester, find.text('10.0 g'));
    await see(tester, find.text('20.0 g'));
    // the percent follows the grams on show, noisy scale or not
    await see(tester, find.text('33.3%'));
    expect(find.text('On target'), findsNothing);

    // 11. the rest of it, steady and within tolerance
    await pour(20000);
    await see(tester, find.text('On target'));
    await see(tester, find.text('Steady'));
    await tapText(tester, 'Next ingredient');

    // 12. B and C on top, cumulative targets, C a touch over but within
    await see(tester, find.text('Step 2 of 4'));
    await see(tester, cumulative(480, exact: exact));
    await pour(18000);
    await see(tester, find.text('On target'));
    await tapText(tester, 'Next ingredient');

    await see(tester, find.text('Step 3 of 4'));
    await see(tester, cumulative(600, exact: exact));
    await pour(12200);
    await see(tester, find.text('On target'));
    await tapText(tester, 'Next ingredient');

    // 13. developer to the final target: 60 g on top of what's really in,
    // so C's extra 0.2 g carries through to 120.2 g
    await see(tester, find.text('Step 4 of 4'));
    await see(tester, cumulative(1202, exact: exact));
    await pour(60000);
    await see(tester, find.text('On target'));
    await tapText(tester, 'Finish');

    // 14. actual final weight against the plan, and each step's deviation
    await see(tester, find.text('Check the mixture'));
    await see(tester, find.text('120.0 g'));
    if (exact) {
      await see(tester, find.text('120.2 g'));
      await see(tester, find.text('+0.2 g'));
    }
    await wait(tester, 1200);

    // 15. complete, saved on the device
    await tapText(tester, 'Complete and save');
    await see(tester, find.text('Mixture complete'));
    await see(tester, find.textContaining('Saved to this device'));
    await tapText(tester, 'Done');
    expect(find.text('Edit formula'), findsOneWidget);
  }

  /// step 16: back to the saved formula and straight into weighing it again
  Future<void> reopenAndReuse(WidgetTester tester) async {
    await tester.pageBack();
    await wait(tester, 600);
    await tap(tester, find.text('Formulas'));
    await see(tester, find.text('Rose Gold Demo'));

    await tap(tester, find.byTooltip('More for Rose Gold Demo'));
    await tapText(tester, 'Weigh');
    expect(find.text('Ready to weigh'), findsOneWidget);
    expect(find.text('add 30.0 g'), findsOneWidget);
    // dismiss the sheet, the history has the session from before
    await tester.tapAt(const Offset(5, 5));
    await wait(tester, 600);

    await tapText(tester, 'History');
    expect(find.textContaining('Completed ·'), findsOneWidget);
    await tap(tester, find.textContaining('Completed ·'));
    await see(tester, find.text('Weighing session'));
    await see(tester, find.textContaining('4 of 4 on target'));
  }

  Future<WeighingSession> theSession(WidgetTester tester) async {
    final all = (await tester.runAsync(
      () => SessionRepository(db).watchSessions().first,
    ))!;
    expect(all, hasLength(1));
    return all.single;
  }

  testWidgets('section 19 on the simulated scale, on a 360 px phone', (
    tester,
  ) async {
    late SimulatedScale sim;

    // 1. open it
    await pumpApp(
      tester,
      db,
      size: const Size(360, 780),
      overrides: [
        simulatorFactoryProvider.overrideWithValue(
          () => sim = SimulatedScale(random: Random(19)),
        ),
      ],
    );
    expect(find.text('New color formula'), findsOneWidget);

    await pickRoseGoldAndSave(tester, phone: true);

    // 6 and 7. the developer check and a scale
    await tap(tester, find.text('Start weighing'));
    expect(find.text('Ready to weigh'), findsOneWidget);
    for (final total in ['→ 30.0 g', '→ 48.0 g', '→ 60.0 g', '→ 120.0 g']) {
      await see(tester, find.text(total));
    }
    await tapText(tester, 'Use simulated scale');
    await wait(tester, 600);
    await see(tester, find.text('Simulated scale · Connected'));
    await see(tester, find.text('Tick the developer check first.'));
    await tap(tester, ratioCheck);
    await tap(tester, startInSheet);
    await wait(tester, 800);

    // 8. live readings
    await see(tester, find.text('0.0 g'));

    await weighEverything(
      tester,
      placeBowl: () async {
        sim.placeBowl();
        await wait(tester, 1500);
      },
      pour: (mg) async {
        sim.pourBy(mg);
        await wait(tester, 3500);
      },
      exact: false,
    );

    final s = await theSession(tester);
    expect(s.status, SessionStatus.completed);
    expect(s.deviceName, 'Simulated scale');
    expect(s.measuredTotalMg, closeTo(120200, 300));
    expect(s.steps.every((x) => x.confirmedStable ?? false), isTrue);

    await reopenAndReuse(tester);

    await unmountApp(tester);
  });

  testWidgets('section 19 on the ColorMix scale over the fake radio', (
    tester,
  ) async {
    final esp = fakeEsp32();
    final radio = FakeBleTransport()..add(esp);
    final bench = Bench(radio, esp.id);
    addTearDown(bench.stop);

    // 1. open it
    await pumpApp(tester, db, size: desktop, ble: radio);
    expect(find.text('New color formula'), findsOneWidget);

    await pickRoseGoldAndSave(tester, phone: false);

    // 6. developer check first, no scale yet
    await tap(tester, find.text('Start weighing'));
    await tap(tester, ratioCheck);
    expect(find.text('Connect a scale first.'), findsOneWidget);

    // 7. find and connect the ColorMix scale
    await tapText(tester, 'Find a scale');
    await tapText(tester, 'Scan');
    await tap(tester, find.byKey(ValueKey('connect:${esp.id}')));
    expect(find.text('ColorMix Scale · Connected'), findsOneWidget);
    expect(find.text('Firmware 0.1.0 · calibrated'), findsOneWidget);

    // 8. live readings on the scale tab
    bench.start();
    bench.mg = 1300;
    await wait(tester, 500);
    expect(find.text('1.3 g'), findsOneWidget);
    bench.mg = 0;
    await wait(tester, 500);

    // back to the formula, the sheet now has a scale
    await tap(tester, find.text('Formulas'));
    await tapText(tester, 'Rose Gold Demo');
    await wait(tester, 500);
    await tap(tester, find.text('Start weighing'));
    expect(find.text('ColorMix Scale · Connected'), findsOneWidget);
    await tap(tester, ratioCheck);
    await tap(tester, startInSheet);
    await wait(tester, 800);

    await weighEverything(
      tester,
      placeBowl: () async {
        bench.mg = 250000;
        await wait(tester, 1500);
      },
      // poured at about 10 g a second, then left to settle
      pour: (mg) async {
        final end = bench.mg + mg;
        while (bench.mg < end) {
          bench.mg = min(end, bench.mg + 1000);
          await wait(tester, 100);
        }
        await wait(tester, 1500);
      },
      exact: true,
    );

    final s = await theSession(tester);
    expect(s.status, SessionStatus.completed);
    expect(s.deviceName, 'ColorMix Scale');
    expect(s.deviceId, esp.id);
    expect(s.measuredTotalMg, 120200);
    expect(s.steps.map((x) => x.actualAddedMg), [30000, 18000, 12200, 60000]);

    await reopenAndReuse(tester);

    bench.stop();
    await unmountApp(tester);
  });
}
