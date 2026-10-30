import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/backup/backup_file.dart';
import 'package:colormix_studio/features/backup/backup_repository.dart';
import 'package:colormix_studio/features/formulation/formula_math.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

import 'product_form_test.dart' show mixedForms;

/// mixedForms in mL, Color A's sheet says 1.05 and the developer's 1.02
ColorFormula inMl() {
  final f = mixedForms();
  return f.copyWith(
    unit: MeasureUnit.ml,
    ingredients: [
      f.ingredients[0].copyWith(densityMilli: () => 1050),
      f.ingredients[1],
      f.ingredients[2],
    ],
    developerDensityMilli: () => 1020,
  );
}

FormulaInputs draft({
  MeasureUnit unit = MeasureUnit.g,
  String dye = '60',
  List<(String, ProductForm, String)> parts = const [
    ('50', ProductForm.cream, ''),
    ('30', ProductForm.cream, ''),
    ('20', ProductForm.cream, ''),
  ],
  DeveloperMode mode = DeveloperMode.preset,
  String developerDensity = '',
  int? pinnedDyeDg,
}) {
  return FormulaInputs(
    name: 'Rose Gold Demo',
    dyeText: dye,
    parts: [
      for (final (i, (pct, form, density)) in parts.indexed)
        PartInput(
          name: 'Color ${'ABC'[i]}',
          percentText: pct,
          form: form,
          densityText: density,
        ),
    ],
    developerMode: mode,
    presetRatioHundredths: 100,
    unit: unit,
    developerDensityText: developerDensity,
    pinnedDyeDg: pinnedDyeDg,
  );
}

void main() {
  group('converting', () {
    test('ounces are exact, mass needs no density', () {
      expect(MeasureUnit.oz.toMg(1), 28350);
      expect(MeasureUnit.oz.toMg(2), 56699);
      expect(MeasureUnit.oz.format(30000), '1.06 oz');
      expect(MeasureUnit.oz.format(30000, densityMilli: 500), '1.06 oz');
    });

    test('mL and fl oz go through the density', () {
      expect(MeasureUnit.ml.format(30000), '30.0 mL');
      expect(MeasureUnit.ml.format(30000, densityMilli: 500), '60.0 mL');
      expect(MeasureUnit.ml.toMg(60, densityMilli: 1050), 63000);
      expect(MeasureUnit.flOz.mgPerUnit(1000), closeTo(29573.53, 0.01));
      expect(MeasureUnit.flOz.format(60000), '2.03 fl oz');
    });

    test('grams round the way the scale screens do', () {
      expect(MeasureUnit.g.format(30000), '30.0 g');
      expect(MeasureUnit.g.format(30049), '30.0 g');
      expect(MeasureUnit.g.format(30050), '30.1 g');
      expect(MeasureUnit.g.formatDg(625), '62.5 g');
    });

    test('a hair under zero is 0, never -0', () {
      expect(MeasureUnit.g.format(-40), '0.0 g');
      expect(MeasureUnit.oz.format(-1), '0.00 oz');
      expect(MeasureUnit.ml.format(-1), '0.0 mL');
    });

    test('field text drops the needless zeros', () {
      expect(MeasureUnit.g.fieldText(60000), '60');
      expect(MeasureUnit.g.fieldText(62500), '62.5');
      expect(MeasureUnit.oz.fieldText(60000), '2.12');
      expect(MeasureUnit.oz.fieldText(56699), '2');
      expect(MeasureUnit.oz.fieldTextOf(2.1), '2.1');
      expect(MeasureUnit.ml.fieldTextOf(100), '100');
    });
  });

  group('typing', () {
    test('each unit takes its own decimals', () {
      expect(MeasureUnit.g.parse('62.5'), 62.5);
      expect(MeasureUnit.g.parse('62.55'), isNull);
      expect(MeasureUnit.oz.parse('2.25'), 2.25);
      expect(MeasureUnit.oz.parse('2.255'), isNull);
      expect(MeasureUnit.ml.parse('62,5'), 62.5);
      expect(MeasureUnit.flOz.parse('2.'), 2);
      for (final bad in ['', '-1', 'abc', '1.2.3']) {
        expect(MeasureUnit.oz.parse(bad), isNull, reason: bad);
      }
    });

    test('densities take up to 3 places', () {
      expect(parseDensityMilli('1.05'), 1050);
      expect(parseDensityMilli('1'), 1000);
      expect(parseDensityMilli('0,5'), 500);
      expect(parseDensityMilli('1.0505'), isNull);
      expect(parseDensityMilli('.5'), isNull);
      expect(parseDensityMilli('abc'), isNull);
      expect(densityText(500), '0.50');
    });

    test('every form has a usual density in range', () {
      expect(ProductForm.cream.densityMilli, 1000);
      expect(ProductForm.liquid.densityMilli, 1000);
      expect(ProductForm.powder.densityMilli, 500);
      for (final f in ProductForm.values) {
        expect(
          f.densityMilli,
          inInclusiveRange(minDensityMilli, maxDensityMilli),
        );
      }
    });
  });

  group('the maths', () {
    test('2 oz of dye is worked out in grams, shown in ounces', () {
      final r = calculateFormula(draft(unit: MeasureUnit.oz, dye: '2'));
      expect(r.canSave, isTrue);
      expect(r.dyeDg, 567);
      expect(r.weights, [284, 170, 113]);
      expect(r.developerDg, 567);
      expect(r.dyeAmount, '2.00 oz');
      expect(r.partAmount(0), '1.00 oz');
      expect(r.developerAmount, '2.00 oz');
      expect(r.mixtureAmount, '4.00 oz');
    });

    test('mL of creams is the same number as grams', () {
      final r = calculateFormula(draft(unit: MeasureUnit.ml));
      expect(r.dyeDg, 600);
      expect(r.weights, [300, 180, 120]);
      expect(r.dyeAmount, '60.0 mL');
      expect(r.developerAmount, '60.0 mL');
      expect(r.mixtureAmount, '120.0 mL');
    });

    test('a powder takes more room: the mix goes by weight share', () {
      final r = calculateFormula(
        draft(
          unit: MeasureUnit.ml,
          parts: const [
            ('50', ProductForm.cream, ''),
            ('50', ProductForm.powder, ''),
          ],
        ),
      );
      // 1 / (0.5 / 1.00 + 0.5 / 0.50) = 0.667 g per mL
      expect(r.dyeDg, 400);
      expect(r.weights, [200, 200]);
      expect(r.partAmount(0), '20.0 mL');
      expect(r.partAmount(1), '40.0 mL');
      expect(r.dyeAmount, '60.0 mL');
    });

    test('a typed density beats the form\'s', () {
      final r = calculateFormula(
        draft(
          unit: MeasureUnit.ml,
          parts: const [('100', ProductForm.cream, '1.05')],
          developerDensity: '1.02',
        ),
      );
      expect(r.densities, [1050]);
      expect(r.developerDensity, 1020);
      expect(r.dyeDg, 630);
      expect(r.partAmount(0), '60.0 mL');
    });

    test('a bad density stops a volume, grams don\'t care', () {
      const parts = [('100', ProductForm.cream, '5')];
      final ml = calculateFormula(draft(unit: MeasureUnit.ml, parts: parts));
      expect(ml.canSave, isFalse);
      expect(
        ml.errorFor(IssueField.partDensity, part: 0),
        'Enter grams per mL from the product sheet, between 0.20 and 3.00, '
        'or leave it empty for 1.00.',
      );

      final g = calculateFormula(draft(parts: parts));
      expect(g.canSave, isTrue);
      expect(g.densities, [1000]);
    });

    test('no developer, no developer density to check', () {
      final r = calculateFormula(
        draft(
          unit: MeasureUnit.ml,
          mode: DeveloperMode.none,
          developerDensity: 'abc',
        ),
      );
      expect(r.canSave, isTrue);
      expect(r.errorFor(IssueField.developerDensity), isNull);

      final withDev = calculateFormula(
        draft(unit: MeasureUnit.ml, developerDensity: 'abc'),
      );
      expect(withDev.errorFor(IssueField.developerDensity), isNotNull);
    });

    test('the messages name the unit', () {
      expect(
        calculateFormula(draft(unit: MeasureUnit.oz, dye: '2.125'))
            .errorFor(IssueField.dye),
        'Enter the dye amount in ounces, like 2 or 2.25.',
      );
      expect(
        calculateFormula(draft(unit: MeasureUnit.ml, dye: '0'))
            .errorFor(IssueField.dye),
        'The dye amount has to be more than 0 mL.',
      );
    });

    test('a pinned amount wins over its rounded text', () {
      // 60.0 g shown as 2.12 oz is 60.1 g if read back
      expect(
        calculateFormula(draft(unit: MeasureUnit.oz, dye: '2.12')).dyeDg,
        601,
      );
      final r = calculateFormula(
        draft(unit: MeasureUnit.oz, dye: '2.12', pinnedDyeDg: 600),
      );
      expect(r.dyeDg, 600);
      expect(r.weights, [300, 180, 120]);
    });
  });

  group('a saved formula', () {
    test('shows its amounts in its unit, a volume product by product', () {
      final f = mixedForms();
      expect(f.showDye(), '60.0 g');
      expect(f.showMixture(), '120.0 g');
      expect(f.copyWith(unit: MeasureUnit.oz).showDye(), '2.12 oz');
      expect(f.copyWith(unit: MeasureUnit.oz).showMixture(), '4.23 oz');
      // 30 + 18 + 12 g of powder at 0.5 = 24, then 60 of developer
      final ml = f.copyWith(unit: MeasureUnit.ml);
      expect(ml.showDye(), '72.0 mL');
      expect(ml.showMixture(), '132.0 mL');
    });

    test('weighing steps carry each density, the developer too', () {
      expect(stepsFor(inMl()).map((s) => s.densityMilli), [
        1050,
        1000,
        500,
        1020,
      ]);
      // still weighed in grams
      expect(stepsFor(inMl()).map((s) => s.targetAddedMg), [
        30000,
        18000,
        12000,
        60000,
      ]);
    });
  });

  group('stored', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    void expectInMl(ColorFormula f) {
      expect(f.unit, MeasureUnit.ml);
      expect(f.ingredients.map((i) => i.densityMilli), [1050, null, null]);
      expect(f.ingredients.map((i) => i.density), [1050, 1000, 500]);
      expect(f.developerDensityMilli, 1020);
      expect(f.totalDyeDg, 600);
    }

    test('the unit and densities are kept, duplicates too', () async {
      final repo = FormulaRepository(db);
      await repo.save(inMl());
      expectInMl((await repo.find('f'))!);

      final copy = (await repo.duplicate('f'))!;
      expectInMl((await repo.find(copy.id))!);
    });

    test('grams unless told otherwise', () async {
      await FormulaRepository(db).save(mixedForms());
      final f = (await FormulaRepository(db).find('f'))!;
      expect(f.unit, MeasureUnit.g);
      expect(f.developerDensityMilli, isNull);
    });

    test('the last unit picked is remembered', () async {
      final repo = SettingsRepository(db);
      expect((await repo.load()).formulaUnit, MeasureUnit.g);
      await repo.save(const AppSettings(formulaUnit: MeasureUnit.flOz));
      expect((await repo.load()).formulaUnit, MeasureUnit.flOz);

      await db.customStatement(
        "UPDATE app_settings SET value = 'cups' WHERE key = 'formula_unit'",
      );
      expect((await repo.load()).formulaUnit, MeasureUnit.g);
    });
  });

  group('backup', () {
    late AppDatabase from;
    late AppDatabase to;

    setUp(() {
      from = AppDatabase(NativeDatabase.memory());
      to = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await from.close();
      await to.close();
    });

    Future<Map<String, Object?>> exported() async {
      await FormulaRepository(from).save(inMl());
      final text = encodeBackup(await BackupRepository(from).export());
      return jsonDecode(text) as Map<String, Object?>;
    }

    Map<String, Object?> formulaOf(Map<String, Object?> m) =>
        (m['formulas']! as List).single as Map<String, Object?>;

    test('the unit and densities make the trip', () async {
      final m = await exported();
      await BackupRepository(to).restore(decodeBackup(jsonEncode(m)));
      final f = (await FormulaRepository(to).find('f'))!;
      expect(f.unit, MeasureUnit.ml);
      expect(f.ingredients.map((i) => i.densityMilli), [1050, null, null]);
      expect(f.developerDensityMilli, 1020);
    });

    test('a file from before units restores in grams', () async {
      final m = await exported();
      final f = formulaOf(m)
        ..remove('unit')
        ..remove('developerDensityMilli');
      for (final i in f['ingredients']! as List) {
        (i as Map<String, Object?>).remove('densityMilli');
      }
      await BackupRepository(to).restore(decodeBackup(jsonEncode(m)));
      final back = (await FormulaRepository(to).find('f'))!;
      expect(back.unit, MeasureUnit.g);
      expect(back.ingredients.every((i) => i.densityMilli == null), isTrue);
      expect(back.developerDensityMilli, isNull);
    });

    test('an unknown unit or an odd density is refused', () async {
      Matcher says(String text) => throwsA(
        isA<BackupFormatException>().having(
          (e) => e.message,
          'message',
          contains(text),
        ),
      );

      final m = await exported();
      formulaOf(m)['unit'] = 'cups';
      expect(() => decodeBackup(jsonEncode(m)), says('bad "unit"'));

      formulaOf(m)['unit'] = 'ml';
      formulaOf(m)['developerDensityMilli'] = 50;
      expect(
        () => decodeBackup(jsonEncode(m)),
        says('bad "developerDensityMilli"'),
      );
    });
  });
}
