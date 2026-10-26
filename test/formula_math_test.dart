import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/features/formulation/formula_math.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

FormulaInputs inputs({
  String name = 'Rose Gold Demo',
  String dye = '60',
  List<String> percents = const ['50', '30', '20'],
  DeveloperMode mode = DeveloperMode.preset,
  int? ratio = 100,
  String custom = '',
}) {
  return FormulaInputs(
    name: name,
    dyeText: dye,
    parts: [
      for (final (i, p) in percents.indexed)
        PartInput(name: 'Color ${'ABC'[i]}', percentText: p),
    ],
    developerMode: mode,
    presetRatioHundredths: ratio,
    customRatioText: custom,
  );
}

void main() {
  group('parsing', () {
    test('grams take one decimal', () {
      expect(parseDecigrams('60'), 600);
      expect(parseDecigrams(' 62.5 '), 625);
      expect(parseDecigrams('62,5'), 625);
      expect(parseDecigrams('60.'), 600);
      expect(parseDecigrams('0'), 0);
      expect(parseDecigrams('62.55'), isNull);
      expect(parseDecigrams('-5'), isNull);
      expect(parseDecigrams('abc'), isNull);
      expect(parseDecigrams(''), isNull);
    });

    test('percentages take two decimals', () {
      expect(parsePercentHundredths('50'), 5000);
      expect(parsePercentHundredths('33.3'), 3330);
      expect(parsePercentHundredths('33.33'), 3333);
      expect(parsePercentHundredths('33.333'), isNull);
    });

    test('numbers go back to text without needless zeros', () {
      expect(decigramsText(600), '60');
      expect(decigramsText(625), '62.5');
      expect(percentText(5000), '50');
      expect(percentText(3330), '33.3');
      expect(ratioText(150), '1.5');
      expect(ratioText(200), '2');
    });
  });

  group('weights', () {
    test('the blueprint example: 60 g at 50/30/20', () {
      expect(colorWeights(600, [5000, 3000, 2000]), [300, 180, 120]);
    });

    test('rounded parts always add up to the total', () {
      // naive rounding would give 16.7 + 16.7 + 16.7 = 50.1 g
      expect(colorWeights(500, [3330, 3330, 3340]), [167, 166, 167]);
      expect(colorWeights(1000, [3334, 3333, 3333]), [334, 333, 333]);

      for (final total in [1, 7, 333, 455, 999, 1234]) {
        for (final pcts in [
          [3333, 3333, 3334],
          [1, 1, 9998],
          [5000, 5000],
          [10000],
          [2500, 2500, 5000],
        ]) {
          final w = colorWeights(total, pcts);
          expect(w.fold(0, (a, b) => a + b), total, reason: '$total $pcts');
        }
      }
    });

    test('percentages off 100 are refused', () {
      expect(() => colorWeights(600, [5000, 4000]), throwsArgumentError);
    });

    test('developer weight by ratio, half up', () {
      expect(developerWeight(600, 100), 600);
      expect(developerWeight(600, 150), 900);
      expect(developerWeight(600, 200), 1200);
      expect(developerWeight(333, 150), 500); // 49.95 g -> 50.0 g
      expect(developerWeight(333, 125), 416); // 41.625 g -> 41.6 g
    });

    test('even splits', () {
      expect(evenSplit(1), [10000]);
      expect(evenSplit(2), [5000, 5000]);
      expect(evenSplit(3), [3334, 3333, 3333]);
    });

    test('rescaling a saved formula keeps its ratios', () {
      final f = ColorFormula(
        id: 'f',
        name: 'Rose Gold Demo',
        targetRgb: 0xB76E79,
        totalDyeDg: 600,
        developerRatio: const DeveloperRatio(150),
        developerDg: 900,
        totalMixtureDg: 1500,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        ingredients: const [
          FormulaIngredient(
            id: 'a',
            name: 'Color A',
            percentHundredths: 5000,
            requiredDg: 300,
            displayRgb: 0,
          ),
          FormulaIngredient(
            id: 'b',
            name: 'Color B',
            percentHundredths: 3000,
            requiredDg: 180,
            displayRgb: 0,
          ),
          FormulaIngredient(
            id: 'c',
            name: 'Color C',
            percentHundredths: 2000,
            requiredDg: 120,
            displayRgb: 0,
          ),
        ],
      );

      final bigger = rescaleFormula(f, 900);
      expect(bigger.ingredients.map((i) => i.requiredDg), [450, 270, 180]);
      expect(bigger.developerDg, 1350);
      expect(bigger.totalMixtureDg, 2250);
      expect(bigger.ingredients.map((i) => i.percentHundredths), [
        5000,
        3000,
        2000,
      ]);

      final odd = rescaleFormula(f, 455);
      expect(odd.ingredients.fold(0, (a, i) => a + i.requiredDg), 455);
    });
  });

  group('calculateFormula', () {
    test('a good formula works out every number', () {
      final r = calculateFormula(inputs());
      expect(r.canSave, isTrue);
      expect(r.issues, isEmpty);
      expect(r.weights, [300, 180, 120]);
      expect(r.developerDg, 600);
      expect(r.mixtureDg, 1200);
    });

    test('percentages not making 100% block saving', () {
      final under = calculateFormula(inputs(percents: ['40', '30', '20']));
      expect(under.canSave, isFalse);
      expect(under.weights, isNull);
      expect(under.errorFor(IssueField.total), contains('add up to 90%'));

      final over = calculateFormula(inputs(percents: ['60', '30', '20']));
      expect(over.errorFor(IssueField.total), contains('over 100%'));
    });

    test('bad and zero inputs get plain messages', () {
      expect(
        calculateFormula(inputs(dye: '')).errorFor(IssueField.dye),
        'Enter the dye amount in grams, like 60 or 62.5.',
      );
      expect(
        calculateFormula(inputs(dye: '0')).errorFor(IssueField.dye),
        'The dye amount has to be more than 0 g.',
      );
      expect(
        calculateFormula(inputs(dye: '1200')).errorFor(IssueField.dye),
        contains('1 kg'),
      );
      expect(
        calculateFormula(inputs(percents: ['100', '0']))
            .errorFor(IssueField.partPercent, part: 1),
        'Use more than 0%, or remove this color.',
      );
      expect(
        calculateFormula(inputs(percents: ['150']))
            .errorFor(IssueField.partPercent, part: 0),
        'Can\'t be more than 100%.',
      );
      expect(
        calculateFormula(inputs(name: '  ')).errorFor(IssueField.name),
        'Give the formula a name.',
      );
    });

    test('a color too small to weigh is caught', () {
      final r = calculateFormula(inputs(dye: '1', percents: ['99', '1']));
      expect(r.weights, [10, 0]);
      expect(r.canSave, isFalse);
      expect(
        r.errorFor(IssueField.partPercent, part: 1),
        'Color B works out to 0.0 g. Raise its percentage or the dye amount.',
      );
    });

    test('developer has to be chosen, and custom ratios are checked', () {
      expect(
        calculateFormula(inputs(mode: DeveloperMode.unset)).canSave,
        isFalse,
      );

      final none = calculateFormula(inputs(mode: DeveloperMode.none));
      expect(none.canSave, isTrue);
      expect(none.developerDg, 0);
      expect(none.mixtureDg, 600);

      final custom = calculateFormula(
        inputs(mode: DeveloperMode.custom, custom: '1.25'),
      );
      expect(custom.ratioHundredths, 125);
      expect(custom.developerDg, 750);

      expect(
        calculateFormula(inputs(mode: DeveloperMode.custom, custom: '9'))
            .errorFor(IssueField.developer),
        'Use a ratio between 1:0.1 and 1:5.',
      );
      expect(
        calculateFormula(inputs(mode: DeveloperMode.custom, custom: 'x'))
            .canSave,
        isFalse,
      );
    });

    test('mixture over the scale blocks, near the limit only warns', () {
      final over = calculateFormula(inputs(dye: '600', ratio: 200));
      expect(over.errorFor(IssueField.mixture), contains('1800.0 g'));

      final near = calculateFormula(inputs(dye: '400', ratio: 100));
      expect(near.canSave, isTrue);
      expect(near.issues.single.blocking, isFalse);
      expect(near.issues.single.message, contains('little room for the bowl'));
    });
  });
}
