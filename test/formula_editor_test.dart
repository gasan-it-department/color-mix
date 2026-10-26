import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

import 'test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Finder field(String label) => find.widgetWithText(TextField, label);

  final dyeField = field('All colors together, not counting developer');

  Future<List<ColorFormula>> saved(WidgetTester tester) async =>
      (await tester.runAsync(() => FormulaRepository(db).watchAll().first))!;

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  /// Colors tab -> a demo shade -> Create formula, on a desktop window
  Future<void> openFromShade(WidgetTester tester, String shade) async {
    await pumpApp(tester, db, size: desktop);
    await tapText(tester, 'Colors');
    await tapText(tester, shade);
    await tapText(tester, 'Create formula');
  }

  testWidgets('a demo recipe opens with the blueprint weights and saves', (
    tester,
  ) async {
    await openFromShade(tester, 'Rose Gold');

    expect(find.text('New formula'), findsOneWidget);
    expect(find.text('Demo recipe'), findsOneWidget);
    expect(find.text('30.0 g'), findsWidgets);
    expect(find.text('18.0 g'), findsWidgets);
    expect(find.text('12.0 g'), findsWidgets);
    expect(find.text('Developer 1:1'), findsOneWidget);
    expect(find.text('120.0 g'), findsOneWidget);
    expect(find.text('Total 100%'), findsOneWidget);

    await tapText(tester, 'Save formula');

    expect(find.text('Formula saved'), findsOneWidget);
    expect(find.text('Edit formula'), findsOneWidget);

    final list = await saved(tester);
    expect(list, hasLength(1));
    final f = list.single;
    expect(f.name, 'Rose Gold Demo');
    expect(f.isDemo, isTrue);
    expect(f.presetId, 'rose_gold');
    expect(f.ingredients.map((i) => i.requiredDg), [300, 180, 120]);
    expect(f.developerRatio, const DeveloperRatio(100));
    expect(f.totalMixtureDg, 1200);

    await unmountApp(tester);
  });

  testWidgets('changing the dye amount reworks every weight', (tester) async {
    await openFromShade(tester, 'Rose Gold');

    await tester.enterText(dyeField, '50');
    await tester.pumpAndSettle();
    expect(find.text('25.0 g'), findsWidgets);
    expect(find.text('15.0 g'), findsWidgets);
    expect(find.text('10.0 g'), findsWidgets);
    expect(find.text('100.0 g'), findsOneWidget);

    // the stepper moves 5 g
    await tester.tap(find.byTooltip('More dye'));
    await tester.pumpAndSettle();
    expect(find.text('110.0 g'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('percentages off 100% block saving with a plain message', (
    tester,
  ) async {
    await openFromShade(tester, 'Rose Gold');

    await tester.enterText(field('Share').first, '40');
    await tester.pumpAndSettle();

    expect(find.textContaining('add up to 90%'), findsOneWidget);
    expect(find.text('Total 90% · 10% left'), findsOneWidget);

    await tapText(tester, 'Save formula');
    expect(find.text('Fix the marked fields first.'), findsOneWidget);
    expect(await saved(tester), isEmpty);

    await unmountApp(tester);
  });

  testWidgets('a shade without a recipe needs colors and a developer choice', (
    tester,
  ) async {
    await openFromShade(tester, 'Mahogany');

    expect(find.text('Mahogany'), findsOneWidget);
    expect(find.text('Total 100%'), findsOneWidget);
    expect(find.textContaining('Choose the developer ratio'), findsWidgets);

    // second color starts empty because nothing is left to give it
    await tapText(tester, 'Add color');
    expect(find.text('Enter a percentage, like 50 or 33.3.'), findsWidgets);

    await tapText(tester, 'Split evenly');
    expect(find.text('Total 100%'), findsOneWidget);
    expect(find.text('30.0 g'), findsWidgets);

    await tapText(tester, 'No developer');
    expect(find.text('60.0 g'), findsWidgets);
    expect(find.textContaining('Choose the developer ratio'), findsNothing);

    await tapText(tester, 'Save formula');
    final f = (await saved(tester)).single;
    expect(f.isDemo, isFalse);
    expect(f.developerRatio, isNull);
    expect(f.ingredients.map((i) => i.percentHundredths), [5000, 5000]);
    expect(f.ingredients.map((i) => i.name), ['Color A', 'Color B']);

    await unmountApp(tester);
  });

  testWidgets('a custom ratio is checked and saved', (tester) async {
    await openFromShade(tester, 'Mahogany');

    await tapText(tester, 'Custom');
    await tester.enterText(field('Developer parts'), '9');
    await tester.pumpAndSettle();
    expect(find.text('Use a ratio between 1:0.1 and 1:5.'), findsWidgets);

    await tester.enterText(field('Developer parts'), '1.25');
    await tester.pumpAndSettle();
    expect(find.text('Developer 1:1.25'), findsOneWidget);
    expect(find.text('75.0 g'), findsOneWidget);

    await tapText(tester, '20 vol');
    await tapText(tester, 'Save formula');

    final f = (await saved(tester)).single;
    expect(f.developerRatio, const DeveloperRatio(125));
    expect(f.developerVolume, 20);
    expect(f.developerDg, 750);

    await unmountApp(tester);
  });

  testWidgets('a saved formula opens for editing and saves rescaled', (
    tester,
  ) async {
    await openFromShade(tester, 'Rose Gold');
    await tapText(tester, 'Save formula');
    await unmountApp(tester);

    await pumpApp(tester, db, size: desktop);
    await tapText(tester, 'Formulas');
    await tapText(tester, 'Rose Gold Demo');

    expect(find.text('Edit formula'), findsOneWidget);
    await tester.enterText(dyeField, '90');
    await tester.pumpAndSettle();
    await tapText(tester, 'Save formula');

    final list = await saved(tester);
    expect(list, hasLength(1));
    expect(list.single.ingredients.map((i) => i.requiredDg), [450, 270, 180]);
    expect(list.single.totalMixtureDg, 1800);

    await unmountApp(tester);
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    await openFromShade(tester, 'Rose Gold');

    await tester.enterText(field('Formula name'), 'Rose Gold for Ana');
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);

    await tapText(tester, 'Keep editing');
    expect(find.text('New formula'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapText(tester, 'Discard');
    expect(find.text('New formula'), findsNothing);
    expect(find.text('Color Studio'), findsOneWidget);
    expect(await saved(tester), isEmpty);

    await unmountApp(tester);
  });

  testWidgets('reset goes back to the starting recipe', (tester) async {
    await openFromShade(tester, 'Rose Gold');

    await tester.enterText(dyeField, '80');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reset'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Reset');

    expect(find.text('120.0 g'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('phones keep save and the mixture in a bottom bar', (
    tester,
  ) async {
    await pumpApp(tester, db);
    await tapText(tester, 'Colors');
    await tapText(tester, 'Copper Brown');
    await tapText(tester, 'Details');
    await tapText(tester, 'Create formula');

    // the details sheet closed on the way
    expect(find.text('Demo only'), findsNothing);
    expect(find.text('New formula'), findsOneWidget);
    expect(find.text('Mixture'), findsWidgets);
    expect(find.text('120.0 g'), findsWidgets);
    expect(find.text('36.0 g'), findsWidgets);
    expect(find.text('24.0 g'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Save formula'));
    await tester.pumpAndSettle();
    expect((await saved(tester)).single.name, 'Copper Brown Demo');

    await unmountApp(tester);
  });
}
