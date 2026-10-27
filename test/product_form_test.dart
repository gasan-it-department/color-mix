import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

import 'weighing_state_test.dart' show roseGold;

/// Rose Gold with a liquid Color A, a powder Color C and a liquid developer
ColorFormula mixedForms() {
  final f = roseGold();
  return f.copyWith(
    ingredients: [
      f.ingredients[0].copyWith(form: ProductForm.liquid),
      f.ingredients[1],
      f.ingredients[2].copyWith(form: ProductForm.powder),
    ],
    developerForm: ProductForm.liquid,
  );
}

void main() {
  group('slow-down band', () {
    test('a gram or a tenth for a cream, as weighing always did', () {
      expect(ProductForm.cream.approachMg(30000), 3000);
      expect(ProductForm.cream.approachMg(5000), 1000);
    });

    test('a liquid slows down sooner, a powder a little sooner', () {
      expect(ProductForm.liquid.approachMg(30000), 4500);
      expect(ProductForm.liquid.approachMg(5000), 2000);
      expect(ProductForm.powder.approachMg(30000), 3000);
      expect(ProductForm.powder.approachMg(5000), 1500);
    });

    test('the same reading is amber for a liquid, still pouring for a '
        'cream', () {
      WeighingState pouring(ColorFormula f) {
        final s = WeighingState.start(
          sessionId: 's',
          formula: f,
          toleranceMg: 300,
          deviceName: 'Simulated scale',
          connection: ScaleConnectionState.connectedSupported,
          startedAt: DateTime(2026, 10, 27),
        );
        return s
            .withReading(liveMg: 250000, stable: true, overload: false)
            .zero()
            .beginPouring()
            // 26 g of Color A's 30 g in: 4 g to go
            .withReading(liveMg: 276000, stable: true, overload: false);
      }

      expect(pouring(roseGold()).zone, PourZone.under);
      expect(pouring(mixedForms()).zone, PourZone.approaching);
    });

    test('steps carry their form, the developer too', () {
      expect(stepsFor(mixedForms()).map((s) => s.form), [
        ProductForm.liquid,
        ProductForm.cream,
        ProductForm.powder,
        ProductForm.liquid,
      ]);
      // nothing set means cream, like everything saved before forms existed
      expect(
        stepsFor(roseGold()).every((s) => s.form == ProductForm.cream),
        isTrue,
      );
    });

    test('there is no powder developer', () {
      expect(ProductForm.developerForms, [
        ProductForm.cream,
        ProductForm.liquid,
      ]);
    });
  });

  group('stored', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('formulas keep each form, duplicates too', () async {
      final repo = FormulaRepository(db);
      await repo.save(mixedForms());

      final f = (await repo.find('f'))!;
      expect(f.ingredients.map((i) => i.form), [
        ProductForm.liquid,
        ProductForm.cream,
        ProductForm.powder,
      ]);
      expect(f.developerForm, ProductForm.liquid);

      final copy = (await repo.duplicate('f'))!;
      final saved = (await repo.find(copy.id))!;
      expect(saved.ingredients.map((i) => i.form), [
        ProductForm.liquid,
        ProductForm.cream,
        ProductForm.powder,
      ]);
      expect(saved.developerForm, ProductForm.liquid);
    });

    test('a session records the form each step was weighed as', () async {
      await FormulaRepository(db).save(mixedForms());
      final repo = SessionRepository(db);
      await repo.start(
        WeighingState.start(
          sessionId: 'sess',
          formula: mixedForms(),
          toleranceMg: 300,
          deviceName: 'Simulated scale',
          connection: ScaleConnectionState.connectedSupported,
          startedAt: DateTime(2026, 10, 27),
        ),
        scaleId: 'simulator',
      );

      // changing the formula later doesn't rewrite history
      await FormulaRepository(db).save(roseGold());

      final s = (await repo.load('sess'))!;
      expect(s.steps.map((x) => x.form), [
        ProductForm.liquid,
        ProductForm.cream,
        ProductForm.powder,
        ProductForm.liquid,
      ]);
    });
  });
}
