import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_alerts.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

import 'test_app.dart';
import 'weighing_state_test.dart' show roseGold;

class _Alerts implements WeighingAlerts {
  final calls = <String>[];

  @override
  void approaching() => calls.add('approaching');
  @override
  void reached() => calls.add('reached');
  @override
  void over() => calls.add('over');
  @override
  void disconnected() => calls.add('disconnected');
}

// the simulator streams 10 readings a second, so the tree never settles:
// these tests pump fixed times instead of pumpAndSettle once it's connected

void main() {
  late AppDatabase db;
  late _Alerts alerts;

  setUp(() async {
    db = memoryDb();
    alerts = _Alerts();
  });
  tearDown(() => db.close());

  Future<void> wait(WidgetTester tester, [int ms = 300]) async {
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    // phones: lazy lists only build what's near the screen, look both ways
    for (final delta in [300.0, -300.0]) {
      if (f.evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(
          f,
          delta,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 20,
        );
      } on StateError {
        // not that way
      }
    }
    await tester.ensureVisible(f.first);
    await wait(tester, 200);
    await tester.tap(f.first);
    await wait(tester, 200);
  }

  Future<void> tapText(WidgetTester tester, String text) =>
      tap(tester, find.text(text));

  /// scrolls a phone's lazy list until [f] is built, then expects it
  Future<void> see(WidgetTester tester, Finder f) async {
    for (final delta in [-300.0, 300.0]) {
      if (f.evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(
          f,
          delta,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 20,
        );
      } on StateError {
        // not that way
      }
    }
    expect(f, findsWidgets);
  }

  /// Rose Gold saved, editor open, ready sheet filled in, weighing screen up
  Future<void> openWeighing(
    WidgetTester tester, {
    bool frozen = false,
    Size size = const Size(1280, 1000),
  }) async {
    await tester.runAsync(() => FormulaRepository(db).save(roseGold()));
    await pumpApp(
      tester,
      db,
      size: size,
      overrides: [
        simulatorFactoryProvider.overrideWithValue(
          () => SimulatedScale(random: Random(7))..frozen = frozen,
        ),
        weighingAlertsProvider.overrideWithValue(alerts),
      ],
    );
    await tester.tap(find.text('Formulas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rose Gold Demo'));
    await tester.pumpAndSettle();

    // on phones the result card is far down a lazy list
    await tester.scrollUntilVisible(
      find.text('Start weighing'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapText(tester, 'Start weighing');
    expect(find.text('Ready to weigh'), findsOneWidget);
    expect(find.text('Connect a scale first.'), findsOneWidget);

    await tapText(tester, 'Use simulated scale');
    await wait(tester, 600);
    expect(find.text('Tick the developer check first.'), findsOneWidget);

    await tapText(
      tester,
      'The developer ratio 1:1 by weight matches the product instructions',
    );
    final start = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.widgetWithText(FilledButton, 'Start weighing'),
    );
    await tap(tester, start);
    await wait(tester, 800);
    expect(find.text('Put the empty bowl on the scale'), findsOneWidget);
  }

  /// bowl on, zero, start pouring Color A
  Future<void> zeroAndStart(WidgetTester tester) async {
    await tapText(tester, 'Place bowl');
    await wait(tester, 1500);
    await tap(tester, find.widgetWithText(FilledButton, 'Zero with bowl'));
    expect(find.text('Check it reads about 0.0 g'), findsOneWidget);
    await wait(tester, 1200);
    await tapText(tester, 'Start with Color A');
    expect(find.text('Step 1 of 4'), findsOneWidget);
  }

  Future<void> pourToTarget(WidgetTester tester) async {
    await tap(tester, find.textContaining('Pour to target'));
    await wait(tester, 3000);
  }

  testWidgets('the whole Rose Gold mix on the simulated scale', (tester) async {
    await openWeighing(tester);
    await zeroAndStart(tester);

    // the blueprint's cumulative targets: 30 / 48 / 60 / 120 g
    for (final (i, cumulative) in [
      '30.0 g',
      '48.0 g',
      '60.0 g',
      '120.0 g',
    ].indexed) {
      expect(find.text('Step ${i + 1} of 4'), findsOneWidget);
      expect(find.textContaining('of $cumulative'), findsWidgets);
      await pourToTarget(tester);
      expect(find.text('On target'), findsOneWidget);
      await tapText(tester, i == 3 ? 'Finish' : 'Next ingredient');
    }

    expect(find.text('Check the mixture'), findsOneWidget);
    await wait(tester, 1200);
    await tapText(tester, 'Complete and save');
    expect(find.text('Mixture complete'), findsOneWidget);
    expect(alerts.calls.where((c) => c == 'reached'), hasLength(4));

    final session = (await tester.runAsync(
      () => db.select(db.weighingSessions).getSingle(),
    ))!;
    expect(session.status, SessionStatus.completed);
    expect(session.measuredTotalMg, closeTo(120000, 300));
    final steps = (await tester.runAsync(
      () => SessionRepository(db).stepsOf(session.id),
    ))!;
    for (final (s, target) in [
      (steps[0], 30000),
      (steps[1], 18000),
      (steps[2], 12000),
      (steps[3], 60000),
    ]) {
      expect(s.actualAddedMg, closeTo(target, 300));
      expect(s.confirmedStable, isTrue);
    }

    await tapText(tester, 'Done');
    expect(find.text('Edit formula'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('pouring too much is shown and kept on the record', (
    tester,
  ) async {
    await openWeighing(tester);
    await zeroAndStart(tester);

    await tapText(tester, 'Pour 2 g too much');
    await wait(tester, 3000);

    expect(find.textContaining('Over by'), findsOneWidget);
    expect(find.textContaining('too much.'), findsOneWidget);
    expect(alerts.calls, contains('over'));
    final next = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Next ingredient'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(next.onPressed, isNull);

    await tapText(tester, 'Continue manually');
    expect(find.text('Step 2 of 4'), findsOneWidget);
    // Color B still gets its full 18 g, on top of the 32 g that's in
    expect(find.textContaining('of 50.0 g'), findsOneWidget);
    expect(find.text('Moved on'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('a dropped connection pauses, reconnecting carries on', (
    tester,
  ) async {
    await openWeighing(tester);
    await zeroAndStart(tester);

    await tapText(tester, 'Drop connection');
    expect(find.text('Scale disconnected'), findsOneWidget);
    expect(alerts.calls, contains('disconnected'));

    await tap(tester, find.widgetWithText(FilledButton, 'Reconnect'));
    await wait(tester, 1500);
    expect(find.text('Scale disconnected'), findsNothing);
    expect(find.text('Step 1 of 4'), findsOneWidget);

    await pourToTarget(tester);
    expect(find.text('On target'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('frozen readings go stale and block confirming', (tester) async {
    await openWeighing(tester);
    await zeroAndStart(tester);
    await pourToTarget(tester);
    expect(find.text('On target'), findsOneWidget);

    await tapText(tester, 'Freeze readings');
    await wait(tester, 1500);
    expect(find.text('Waiting for readings'), findsOneWidget);
    final next = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Next ingredient'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(next.onPressed, isNull);

    await unmountApp(tester);
  });

  testWidgets('the whole flow fits on a 360 px phone', (tester) async {
    // any overflow on the way fails the test
    await openWeighing(tester, size: const Size(360, 780));

    await tapText(tester, 'Place bowl');
    await wait(tester, 1500);
    await tap(tester, find.widgetWithText(FilledButton, 'Zero with bowl'));
    await see(tester, find.text('Check it reads about 0.0 g'));
    await wait(tester, 1200);
    await tapText(tester, 'Start with Color A');

    await tapText(tester, 'Pour 2 g too much');
    await wait(tester, 3000);
    await see(tester, find.textContaining('Over by'));
    await tapText(tester, 'Continue manually');

    for (final label in ['Next ingredient', 'Next ingredient', 'Finish']) {
      await pourToTarget(tester);
      await see(tester, find.text('On target'));
      await tapText(tester, label);
    }
    await wait(tester, 1200);
    await see(tester, find.text('Check the mixture'));
    await tapText(tester, 'Complete and save');
    await see(tester, find.text('Mixture complete'));
    await see(tester, find.text('Moved on'));

    await unmountApp(tester);
  });

  testWidgets('a double tap on Finish still stops at the final check', (
    tester,
  ) async {
    await openWeighing(tester);
    await zeroAndStart(tester);
    for (final label in [
      'Next ingredient',
      'Next ingredient',
      'Next ingredient',
    ]) {
      await pourToTarget(tester);
      await tapText(tester, label);
    }
    await pourToTarget(tester);

    final finish = find.text('Finish');
    await tester.ensureVisible(finish);
    await wait(tester, 200);
    await tester.tap(finish);
    await tester.pump(const Duration(milliseconds: 150));
    // second tap lands where "Complete and save" now is
    await tester.tapAt(tester.getCenter(find.text('Complete and save')));
    await wait(tester, 300);

    expect(find.text('Check the mixture'), findsOneWidget);
    expect(find.text('Mixture complete'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('a scale that never sends anything shows as stale', (
    tester,
  ) async {
    await openWeighing(tester, frozen: true);
    await wait(tester, 1500);

    expect(find.text('Waiting for readings'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('stopping halfway keeps the session as cancelled', (
    tester,
  ) async {
    await openWeighing(tester);
    await zeroAndStart(tester);

    await tap(tester, find.byTooltip('Stop weighing'));
    expect(find.text('Stop weighing?'), findsOneWidget);
    await tapText(tester, 'Stop');
    await wait(tester, 600);

    expect(find.text('Edit formula'), findsOneWidget);
    final session = (await tester.runAsync(
      () => db.select(db.weighingSessions).getSingle(),
    ))!;
    expect(session.status, SessionStatus.cancelled);

    await unmountApp(tester);
  });
}
