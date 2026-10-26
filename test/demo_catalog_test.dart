import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';

void main() {
  test('the 15 shades from the blueprint, unique ids', () {
    expect(demoShades, hasLength(15));
    expect(demoShades.map((s) => s.id).toSet(), hasLength(15));
    expect(
      demoShades.map((s) => s.name),
      containsAll([
        'Natural Black',
        'Dark Brown',
        'Chocolate Brown',
        'Ash Brown',
        'Golden Brown',
        'Copper Brown',
        'Burgundy',
        'Rose Gold',
        'Ash Blonde',
        'Platinum Blonde',
        'Silver Gray',
        'Pastel Pink',
        'Violet',
        'Blue Black',
        'Mahogany',
      ]),
    );
  });

  test('every recipe link resolves both ways', () {
    for (final s in demoShades.where((s) => s.demoFormulaId != null)) {
      final r = demoRecipeById(s.demoFormulaId);
      expect(r, isNotNull, reason: s.id);
      expect(r!.presetId, s.id);
    }
    for (final r in demoRecipes) {
      expect(demoShadeById(r.presetId)?.demoFormulaId, r.id);
    }
  });

  test('recipes are 1-3 parts adding up to exactly 100%', () {
    for (final r in demoRecipes) {
      expect(r.parts.length, inInclusiveRange(1, 3), reason: r.id);
      expect(r.totalPercentHundredths, 10000, reason: r.id);
      expect(r.parts.every((p) => p.percentHundredths > 0), isTrue);
    }
  });

  test('a shade is its own nearest match', () {
    for (final s in demoShades) {
      final n = nearestDemoShade(s.rgb);
      expect(n.shade.id, s.id);
      expect(n.deltaE, 0);
    }
  });

  test('a near rose gold finds rose gold', () {
    final n = nearestDemoShade(0xB97079);
    expect(n.shade.id, 'rose_gold');
    expect(closenessLabel(n.deltaE), 'almost the same');
  });

  test('hex parsing', () {
    expect(rgbFromHex('B76E79'), 0xB76E79);
    expect(rgbFromHex(' #b76e79 '), 0xB76E79);
    expect(rgbFromHex('#b6e'), 0xBB66EE);
    expect(rgbFromHex('B76E7'), isNull);
    expect(rgbFromHex('zz6E79'), isNull);
    expect(rgbFromHex(''), isNull);
    expect(hexFromRgb(0x0000FF), '#0000FF');
  });
}
