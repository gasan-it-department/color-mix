import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

import 'product_form_test.dart' show mixedForms;
import 'test_app.dart';

// the simulator streams readings: fixed pumps once it's connected

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> wait(WidgetTester tester, [int ms = 300]) async {
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

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

  Future<ColorFormula> savedRoseGold(WidgetTester tester) async {
    final all = (await tester.runAsync(
      () => FormulaRepository(db).watchAll().first,
    ))!;
    return all.single;
  }

  for (final (label, size, phone) in [
    ('desktop', desktop, false),
    ('360 px phone', const Size(360, 780), true),
  ]) {
    testWidgets('each color and the developer get a form ($label)', (
      tester,
    ) async {
      // any overflow on the way fails the test
      await pumpApp(tester, db, size: size);
      await tap(tester, find.text('Colors'));
      await tap(tester, find.text('Rose Gold'));
      if (phone) await tap(tester, find.text('Details'));
      await tap(tester, find.text('Create formula'));

      // every color starts as a cream
      expect(find.byTooltip('Product form'), findsNWidgets(3));
      await tap(tester, find.byTooltip('Product form').first);
      await tap(tester, find.text('Liquid').last);
      await tap(tester, find.byTooltip('Product form').last);
      await tap(tester, find.text('Powder').last);

      // the developer: cream or liquid, never powder
      final devChips = find.ancestor(
        of: find.text('Liquid'),
        matching: find.byType(ChoiceChip),
      );
      await reveal(tester, devChips);
      expect(
        find.ancestor(
          of: find.text('Powder'),
          matching: find.byType(ChoiceChip),
        ),
        findsNothing,
      );
      await tap(tester, devChips);

      await tap(tester, find.widgetWithText(FilledButton, 'Save formula'));
      final f = await savedRoseGold(tester);
      expect(f.ingredients.map((i) => i.form), [
        ProductForm.liquid,
        ProductForm.cream,
        ProductForm.powder,
      ]);
      expect(f.developerForm, ProductForm.liquid);

      // reset goes back to the saved forms, not to cream. on a phone the
      // colors scrolled away while saving, bring them back first
      await reveal(tester, find.byTooltip('Product form'));
      await tap(tester, find.byTooltip('Product form').at(1));
      await tap(tester, find.text('Powder').last);
      await tap(tester, find.byTooltip('Reset'));
      await tap(tester, find.widgetWithText(FilledButton, 'Reset'));
      final shown = tester
          .widgetList<PopupMenuButton<ProductForm>>(
            find.byType(PopupMenuButton<ProductForm>),
          )
          .map((m) => m.initialValue);
      expect(shown, [
        ProductForm.liquid,
        ProductForm.cream,
        ProductForm.powder,
      ]);

      await unmountApp(tester);
    });
  }

  testWidgets('weighing shows the form and hints to match it', (tester) async {
    late SimulatedScale sim;
    await tester.runAsync(() => FormulaRepository(db).save(mixedForms()));
    await pumpApp(
      tester,
      db,
      size: const Size(1280, 1000),
      overrides: [
        simulatorFactoryProvider.overrideWithValue(
          () => sim = SimulatedScale(random: Random(5)),
        ),
      ],
    );
    await tap(tester, find.text('Formulas'));
    await tap(tester, find.text('Rose Gold Demo'));
    await wait(tester, 500);
    await tap(tester, find.text('Start weighing'));

    // the sheet lists each step's form under its name (the editor under it
    // has its own labels, so only look in the sheet)
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );
    expect(inSheet('Liquid'), findsNWidgets(2));
    expect(inSheet('Powder'), findsOneWidget);
    expect(inSheet('Cream'), findsOneWidget);

    await tap(tester, find.text('Use simulated scale'));
    await wait(tester, 600);
    await tap(
      tester,
      find.text(
        'The developer ratio 1:1 by weight matches the product instructions',
      ),
    );
    await tap(
      tester,
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(FilledButton, 'Start weighing'),
      ),
    );
    await wait(tester, 800);

    sim.placeBowl();
    await wait(tester, 1500);
    await tap(tester, find.widgetWithText(FilledButton, 'Zero with bowl'));
    await wait(tester, 1200);
    await tap(tester, find.text('Start with Color A'));

    // Color A is a liquid
    expect(find.text('Liquid'), findsWidgets);
    expect(find.text('Pour slowly, it runs fast.'), findsOneWidget);

    // 26 of 30 g: amber already for a liquid (it would still be pouring
    // for a cream)
    sim.pourBy(26000);
    await wait(tester, 4000);
    expect(find.text('Almost there, slow down'), findsOneWidget);
    expect(find.textContaining('A few drops at a time now'), findsOneWidget);

    await tap(tester, find.textContaining('Pour to target'));
    await wait(tester, 3000);
    expect(find.text('On target'), findsOneWidget);
    // no pouring hint once it's there
    expect(find.textContaining('A few drops'), findsNothing);
    await tap(tester, find.text('Next ingredient'));

    // Color B is a cream
    expect(find.text('Squeeze it in steadily.'), findsOneWidget);
    await tap(tester, find.textContaining('Pour to target'));
    await wait(tester, 3000);
    await tap(tester, find.text('Next ingredient'));

    // Color C is a powder
    expect(find.text('Spoon it in.'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('a past session shows what form each step was', (tester) async {
    await tester.runAsync(() async {
      await FormulaRepository(db).save(mixedForms());
      await SessionRepository(db).start(
        WeighingState.start(
          sessionId: 'sess',
          formula: mixedForms(),
          toleranceMg: 300,
          deviceName: 'Simulated scale',
          connection: ScaleConnectionState.connectedSupported,
          startedAt: DateTime(2026, 10, 27, 9),
        ),
        scaleId: 'simulator',
      );
    });
    await pumpApp(tester, db, size: const Size(360, 780));

    await tap(tester, find.text('Formulas'));
    await tap(tester, find.text('History'));
    await tap(tester, find.textContaining('In progress ·'));
    await reveal(tester, find.text('Each step'));

    expect(find.text('Liquid'), findsNWidgets(2));
    expect(find.text('Powder'), findsOneWidget);
    expect(find.text('Cream'), findsOneWidget);

    await unmountApp(tester);
  });
}
