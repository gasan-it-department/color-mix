import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

import 'product_form_test.dart' show mixedForms;
import 'test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final dyeField = find.widgetWithText(
    TextField,
    'All colors together, not counting developer',
  );

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

  /// the editor's list drops the field once it's scrolled well away
  Future<String> dyeText(WidgetTester tester) async {
    await reveal(tester, dyeField);
    return tester.widget<TextField>(dyeField).controller!.text;
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await reveal(tester, f);
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  Future<void> pickUnit(WidgetTester tester, String label) async {
    await tap(tester, find.byTooltip('Unit'));
    // the menu's item, not the field's own symbol
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> openRoseGold(
    WidgetTester tester, {
    Size size = desktop,
    bool phone = false,
    AppSettings settings = const AppSettings(),
  }) async {
    await pumpApp(tester, db, size: size, settings: settings);
    await tap(tester, find.text('Colors'));
    await tap(tester, find.text('Rose Gold'));
    if (phone) await tap(tester, find.text('Details'));
    await tap(tester, find.text('Create formula'));
  }

  Future<ColorFormula> savedOne(WidgetTester tester) async =>
      (await tester.runAsync(() => FormulaRepository(db).watchAll().first))!
          .single;

  for (final (label, size, phone) in [
    ('desktop', desktop, false),
    ('360 px phone', const Size(360, 780), true),
  ]) {
    testWidgets('units change what\'s shown, never the grams ($label)', (
      tester,
    ) async {
      // any overflow on the way fails the test
      await openRoseGold(tester, size: size, phone: phone);
      expect(await dyeText(tester), '60');

      await pickUnit(tester, 'oz');
      expect(await dyeText(tester), '2.12');
      expect(find.text('1.06 oz'), findsWidgets);
      await reveal(tester, find.textContaining('120.0 g on the scale'));
      expect(find.textContaining('120.0 g on the scale'), findsOneWidget);
      expect(find.text('4.23 oz'), findsWidgets);

      // and back: 2.12 oz read back would be 60.1 g
      await pickUnit(tester, 'g');
      expect(await dyeText(tester), '60');
      expect(find.textContaining('on the scale'), findsNothing);
      expect(find.text('Density'), findsNothing);

      // mL brings the densities, every cream at the usual 1.00
      await pickUnit(tester, 'mL  (by volume)');
      expect(await dyeText(tester), '60');
      await reveal(tester, find.text('Density'));
      final density = find.widgetWithText(TextField, 'g/mL');
      expect(density, findsNWidgets(4));

      // Color A's sheet says 1.05: the field keeps its 60 mL, the grams
      // under it move
      await tester.ensureVisible(density.first);
      await tester.pumpAndSettle();
      await tester.enterText(density.first, '1.05');
      await tester.pumpAndSettle();
      expect(await dyeText(tester), '60');
      for (final amount in ['29.3 mL', '60.0 mL', '121.5 mL']) {
        await reveal(tester, find.text(amount));
        expect(find.text(amount), findsWidgets, reason: amount);
      }

      await tap(tester, find.widgetWithText(FilledButton, 'Save formula'));
      final f = await savedOne(tester);
      expect(f.unit, MeasureUnit.ml);
      expect(f.totalDyeDg, 615);
      expect(f.ingredients.map((i) => i.requiredDg), [308, 184, 123]);
      expect(f.ingredients.map((i) => i.densityMilli), [1050, null, null]);
      expect(f.developerDensityMilli, isNull);

      // the next new formula starts in mL
      final s = (await tester.runAsync(() => SettingsRepository(db).load()))!;
      expect(s.formulaUnit, MeasureUnit.ml);

      await unmountApp(tester);
    });
  }

  testWidgets('a new formula starts in the last unit picked', (tester) async {
    await openRoseGold(
      tester,
      settings: const AppSettings(formulaUnit: MeasureUnit.oz),
    );
    expect(await dyeText(tester), '2.12');

    // the steppers go a quarter ounce
    await tap(tester, find.byTooltip('More dye'));
    expect(await dyeText(tester), '2.37');

    await tap(tester, find.widgetWithText(FilledButton, 'Save formula'));
    final f = await savedOne(tester);
    expect(f.unit, MeasureUnit.oz);
    // 2.37 oz
    expect(f.totalDyeDg, 672);

    await unmountApp(tester);
  });

  testWidgets('a formula in ounces lists, opens and weighs in ounces', (
    tester,
  ) async {
    await tester.runAsync(
      () =>
          FormulaRepository(db)
              .save(mixedForms().copyWith(unit: MeasureUnit.oz)),
    );
    await pumpApp(tester, db, size: const Size(360, 780));

    await tap(tester, find.text('Formulas'));
    expect(find.text('2.12 oz dye · 1:1 developer'), findsOneWidget);

    await tap(tester, find.text('Rose Gold Demo'));
    expect(await dyeText(tester), '2.12');
    expect(find.text('1.06 oz'), findsWidgets);

    // the order: each step in ounces, its grams under the name, the
    // running total in grams because that's what the scale shows
    await tap(tester, find.text('Start weighing'));
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );
    expect(inSheet('add 1.06 oz'), findsOneWidget);
    expect(inSheet('Liquid · 30.0 g'), findsOneWidget);
    expect(inSheet('add 0.42 oz'), findsOneWidget);
    expect(inSheet('Powder · 12.0 g'), findsOneWidget);
    expect(inSheet('add 2.12 oz'), findsOneWidget);
    expect(inSheet('→ 120.0 g'), findsOneWidget);

    await unmountApp(tester);
  });
}
