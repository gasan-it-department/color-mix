import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

void main() {
  test('decigrams format to one decimal place', () {
    expect(formatDecigrams(300), '30.0 g');
    expect(formatDecigrams(5), '0.5 g');
    expect(formatDecigrams(0), '0.0 g');
    expect(formatDecigrams(-12), '-1.2 g');
    expect(formatDecigrams(1200, unit: false), '120.0');
  });

  test('milligrams round half away from zero', () {
    expect(milligramsToDecigrams(24849), 248);
    expect(milligramsToDecigrams(24850), 249);
    expect(milligramsToDecigrams(-24850), -249);
    expect(formatMilligrams(30000), '30.0 g');
  });

  test('a hair under zero rounds to a plain zero', () {
    // the web build's ints are js numbers, a -0 there printed as -0.0%.
    // the vm can't show it, docs/decisions.md says how it was checked
    expect(milligramsToDecigrams(-40), 0);
    expect(milligramsToDecigrams(-40).isNegative, isFalse);
    expect(formatMilligrams(-40), '0.0 g');
  });

  test('percentages drop needless zeros', () {
    expect(formatPercentHundredths(5000), '50%');
    expect(formatPercentHundredths(3330), '33.3%');
    expect(formatPercentHundredths(3333), '33.33%');
    expect(formatPercentHundredths(5), '0.05%');
  });

  test('developer ratio labels', () {
    expect(const DeveloperRatio(100).label, '1:1');
    expect(const DeveloperRatio(150).label, '1:1.5');
    expect(const DeveloperRatio(200).label, '1:2');
    expect(const DeveloperRatio(125).label, '1:1.25');
  });
}
