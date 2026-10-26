import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

ColorFormula roseGold({String id = 'f1', DateTime? updatedAt}) {
  final now = DateTime(2026, 10, 26, 9);
  return ColorFormula(
    id: id,
    name: 'Rose Gold Demo',
    targetRgb: 0xB76E79,
    isDemo: true,
    totalDyeDg: 600,
    developerRatio: const DeveloperRatio(100),
    developerVolume: 20,
    developerDg: 600,
    totalMixtureDg: 1200,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    // ingredient ids are primary keys, so they're unique per formula
    ingredients: [
      FormulaIngredient(
        id: '$id-a',
        name: 'Color A',
        percentHundredths: 5000,
        requiredDg: 300,
        displayRgb: 0xC98B8F,
      ),
      FormulaIngredient(
        id: '$id-b',
        name: 'Color B',
        percentHundredths: 3000,
        requiredDg: 180,
        displayRgb: 0xD8B48A,
      ),
      FormulaIngredient(
        id: '$id-c',
        name: 'Color C',
        percentHundredths: 2000,
        requiredDg: 120,
        displayRgb: 0x8E5A6B,
      ),
    ],
  );
}

void main() {
  late AppDatabase db;
  late FormulaRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FormulaRepository(db);
  });

  tearDown(() => db.close());

  test(
    'saves and reads back a formula with its ingredients in order',
    () async {
      await repo.save(roseGold());

      final f = (await repo.find('f1'))!;
      expect(f.name, 'Rose Gold Demo');
      expect(f.isDemo, isTrue);
      expect(f.developerRatio, const DeveloperRatio(100));
      expect(f.developerVolume, 20);
      expect(f.totalMixtureDg, 1200);
      expect(f.ingredients.map((i) => i.name), [
        'Color A',
        'Color B',
        'Color C',
      ]);
      expect(f.ingredients.map((i) => i.requiredDg), [300, 180, 120]);
    },
  );

  test('saving again replaces the ingredient list', () async {
    await repo.save(roseGold());
    final edited = roseGold().copyWith(
      ingredients: [
        roseGold().ingredients.first.copyWith(
          percentHundredths: 10000,
          requiredDg: 600,
        ),
      ],
      developerRatio: () => null,
      developerDg: 0,
      totalMixtureDg: 600,
    );
    await repo.save(edited);

    final f = (await repo.find('f1'))!;
    expect(f.ingredients, hasLength(1));
    expect(f.developerRatio, isNull);
    expect(f.totalMixtureDg, 600);
  });

  test('delete removes the ingredients too', () async {
    await repo.save(roseGold());
    await repo.delete('f1');

    expect(await repo.find('f1'), isNull);
    expect(await db.select(db.formulaIngredients).get(), isEmpty);
  });

  test('watchAll lists newest first and respects the limit', () async {
    await repo.save(roseGold(id: 'old', updatedAt: DateTime(2026, 10, 1)));
    await repo.save(roseGold(id: 'new', updatedAt: DateTime(2026, 10, 20)));

    final all = await repo.watchAll().first;
    expect(all.map((f) => f.id), ['new', 'old']);

    final one = await repo.watchAll(limit: 1).first;
    expect(one.map((f) => f.id), ['new']);
  });
}
