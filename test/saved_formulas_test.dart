import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

import 'test_app.dart';
import 'weighing_state_test.dart' show roseGold;

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

  ColorFormula named(String id, String name, {String? notes}) =>
      roseGold().copyWith(name: name, notes: () => notes).withId(id);

  Future<void> seedFormulas(WidgetTester tester) async {
    await tester.runAsync(() async {
      final repo = FormulaRepository(db);
      await repo.save(roseGold());
      await repo.save(named('f2', 'Copper Glow', notes: 'for Ana, level 7'));
      await repo.save(named('f3', 'Ash Blonde'));
    });
  }

  /// a completed session with Color A 2 g over and moved on by hand, and
  /// one the app closed in the middle of
  Future<void> seedSessions(WidgetTester tester) async {
    await tester.runAsync(() async {
      await FormulaRepository(db).save(roseGold());
      final repo = SessionRepository(db);

      WeighingState start(String id, DateTime at) => WeighingState.start(
        sessionId: id,
        formula: roseGold(),
        toleranceMg: 300,
        deviceName: 'Simulated scale',
        connection: ScaleConnectionState.connectedSupported,
        startedAt: at,
      );
      WeighingState net(WeighingState s, int mg) =>
          s.withReading(liveMg: 250000 + mg, stable: true, overload: false);

      var s = start('done', DateTime(2026, 10, 26, 10));
      await repo.start(s, scaleId: 'simulator');
      s = net(s, 0).zero().beginPouring();
      s = net(
        s,
        32000,
      ).confirmStep(DateTime(2026, 10, 26, 10, 1), manual: true);
      for (final c in [50000, 62000, 122000]) {
        s = net(s, c).confirmStep(DateTime(2026, 10, 26, 10, 2));
      }
      await repo.finish(
        net(s, 122000).complete(),
        SessionStatus.completed,
        at: DateTime(2026, 10, 26, 10, 3, 20),
      );

      await repo.start(start('cut', DateTime(2026, 10, 27, 9)), scaleId: 'x');
      await repo.markInterrupted();
    });
  }

  Future<void> openFormulas(WidgetTester tester, {Size size = phone}) async {
    await pumpApp(tester, db, size: size);
    await tester.tap(find.text('Formulas').first);
    await wait(tester, 500);
  }

  testWidgets('search looks at names and notes', (tester) async {
    await seedFormulas(tester);
    await openFormulas(tester);
    expect(find.text('Ash Blonde'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ana');
    await wait(tester);
    expect(find.text('Copper Glow'), findsOneWidget);
    expect(find.text('Rose Gold Demo'), findsNothing);
    expect(find.text('Ash Blonde'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ASH');
    await wait(tester);
    expect(find.text('Ash Blonde'), findsOneWidget);
    expect(find.text('Copper Glow'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await wait(tester);
    expect(find.text('Nothing matches "zzz"'), findsOneWidget);
    await tap(tester, find.text('Clear search'));
    expect(find.text('Copper Glow'), findsOneWidget);
    expect(find.text('Rose Gold Demo'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('duplicate and delete from the menu', (tester) async {
    await seedFormulas(tester);
    await openFormulas(tester);

    await tap(tester, find.byTooltip('More for Rose Gold Demo'));
    await tap(tester, find.text('Duplicate'));
    expect(find.text('Rose Gold Demo (copy)'), findsOneWidget);
    expect(find.text('Copied as "Rose Gold Demo (copy)"'), findsOneWidget);
    // the Open shortcut doesn't keep it up for good
    await wait(tester, 5000);
    expect(find.text('Copied as "Rose Gold Demo (copy)"'), findsNothing);

    await tap(tester, find.byTooltip('More for Rose Gold Demo (copy)'));
    await tap(tester, find.text('Delete'));
    expect(find.text('Delete "Rose Gold Demo (copy)"?'), findsOneWidget);
    // backing out keeps it
    await tap(tester, find.text('Cancel'));
    expect(find.text('Rose Gold Demo (copy)'), findsOneWidget);

    await tap(tester, find.byTooltip('More for Rose Gold Demo (copy)'));
    await tap(tester, find.text('Delete'));
    await tap(tester, find.widgetWithText(FilledButton, 'Delete'));
    await wait(tester, 1000);
    expect(find.text('Rose Gold Demo (copy)'), findsNothing);
    expect(find.text('Deleted "Rose Gold Demo (copy)"'), findsOneWidget);
    expect(find.text('Rose Gold Demo'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('Weigh from the menu opens the start sheet', (tester) async {
    await seedFormulas(tester);
    await openFormulas(tester);

    await tap(tester, find.byTooltip('More for Copper Glow'));
    await tap(tester, find.text('Weigh'));
    expect(find.text('Ready to weigh'), findsOneWidget);
    expect(find.text('Copper Glow'), findsWidgets);

    await unmountApp(tester);
  });

  testWidgets('history lists sessions and opens the detail', (tester) async {
    await seedSessions(tester);
    await openFormulas(tester);

    await tap(tester, find.text('History'));
    expect(find.textContaining('Completed ·'), findsOneWidget);
    expect(find.textContaining('Interrupted ·'), findsOneWidget);
    expect(find.text('122.0 g'), findsOneWidget);
    expect(find.text('of 120.0 g'), findsNWidgets(2));

    await tap(tester, find.textContaining('Completed ·'));
    expect(find.text('Weighing session'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Difference'), findsOneWidget);
    expect(find.text('+2.0 g'), findsWidgets);
    expect(find.text('Moved on'), findsOneWidget);
    expect(
      find.textContaining('3 of 4 on target (within ±0.3 g) · 1 moved on'),
      findsOneWidget,
    );
    expect(find.textContaining('3 min 20 s'), findsOneWidget);
    expect(find.text('Open formula'), findsOneWidget);

    await tap(tester, find.byTooltip('Delete session'));
    await tap(tester, find.widgetWithText(FilledButton, 'Delete'));
    await wait(tester, 600);
    expect(find.text('Session deleted'), findsOneWidget);
    expect(find.textContaining('Completed ·'), findsNothing);
    expect(find.textContaining('Interrupted ·'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('deleting the formula keeps its history', (tester) async {
    await seedSessions(tester);
    await openFormulas(tester);

    await tap(tester, find.byTooltip('More for Rose Gold Demo'));
    await tap(tester, find.text('Delete'));
    expect(find.textContaining('stay in History'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Delete'));
    expect(find.text('No saved formulas yet'), findsOneWidget);

    await tap(tester, find.text('History'));
    await tap(tester, find.textContaining('Interrupted ·'));
    expect(find.textContaining('The app closed before'), findsOneWidget);
    expect(find.textContaining('The formula was deleted'), findsOneWidget);
    expect(find.text('Open formula'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('the editor\'s history catches up after a route on top', (
    tester,
  ) async {
    await tester.runAsync(() => FormulaRepository(db).save(roseGold()));
    await openFormulas(tester, size: const Size(1280, 1800));
    await tap(tester, find.text('Rose Gold Demo'));
    await wait(tester, 500);
    expect(find.text('Not weighed yet.'), findsOneWidget);

    // the weighing screen covers the editor while the session is saved
    await tap(tester, find.text('Start weighing'));
    await tap(tester, find.text('Use simulated scale'));
    await tap(tester, find.byType(Checkbox));
    await tap(tester, find.widgetWithText(FilledButton, 'Start weighing'));
    await wait(tester, 500);
    expect(find.text('Put the empty bowl on the scale'), findsOneWidget);
    await tap(tester, find.byTooltip('Stop weighing'));
    await tap(tester, find.widgetWithText(FilledButton, 'Stop'));
    await wait(tester, 800);

    expect(find.text('Not weighed yet.'), findsNothing);
    expect(find.textContaining('Cancelled · 0 of 4 steps'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('the editor shows the formula\'s own sessions', (tester) async {
    await seedSessions(tester);
    await openFormulas(tester, size: const Size(1280, 1800));

    await tap(tester, find.text('Rose Gold Demo'));
    await wait(tester, 500);
    expect(find.text('Weighing history'), findsOneWidget);
    expect(find.textContaining('Completed · 4 of 4 steps'), findsOneWidget);
    expect(find.textContaining('Interrupted · 0 of 4 steps'), findsOneWidget);

    await tap(tester, find.textContaining('Completed · 4 of 4'));
    expect(find.text('Weighing session'), findsOneWidget);

    await unmountApp(tester);
  });
}

extension on ColorFormula {
  /// same formula under another id, ingredients included
  ColorFormula withId(String id) => ColorFormula(
    id: id,
    name: name,
    targetRgb: targetRgb,
    ingredients: [
      for (final i in ingredients)
        FormulaIngredient(
          id: '$id-${i.id}',
          name: i.name,
          percentHundredths: i.percentHundredths,
          requiredDg: i.requiredDg,
          displayRgb: i.displayRgb,
        ),
    ],
    totalDyeDg: totalDyeDg,
    developerRatio: developerRatio,
    developerDg: developerDg,
    totalMixtureDg: totalMixtureDg,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
