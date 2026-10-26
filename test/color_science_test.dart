import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/utils/color_science.dart';

void main() {
  group('labFromRgb', () {
    test('white and black sit at the ends of L', () {
      final white = labFromRgb(0xFFFFFF);
      expect(white.l, closeTo(100, 0.01));
      expect(white.a, closeTo(0, 0.01));
      expect(white.b, closeTo(0, 0.01));

      final black = labFromRgb(0x000000);
      expect(black.l, closeTo(0, 0.01));
    });

    test('pure red matches the reference values', () {
      final red = labFromRgb(0xFF0000);
      expect(red.l, closeTo(53.24, 0.05));
      expect(red.a, closeTo(80.09, 0.05));
      expect(red.b, closeTo(67.20, 0.05));
    });
  });

  group('deltaE2000', () {
    // pairs from Sharma, Wu & Dalal's CIEDE2000 test data
    final pairs = <(Lab, Lab, double)>[
      (Lab(50, 2.6772, -79.7751), Lab(50, 0, -82.7485), 2.0425),
      (Lab(50, 0, 0), Lab(50, -1, 2), 2.3669),
      (Lab(50, 2.49, -0.001), Lab(50, -2.49, 0.0009), 7.1792),
      (Lab(50, 2.5, 0), Lab(73, 25, -18), 27.1492),
      (
        Lab(60.2574, -34.0099, 36.2677),
        Lab(60.4626, -34.1751, 39.4387),
        1.2644,
      ),
    ];

    for (final (i, (p, q, expected)) in pairs.indexed) {
      test('reference pair ${i + 1}', () {
        expect(deltaE2000(p, q), closeTo(expected, 1e-4));
        // it's symmetric
        expect(deltaE2000(q, p), closeTo(expected, 1e-4));
      });
    }

    test('identical colours are 0 apart', () {
      expect(deltaE2000Rgb(0xB76E79, 0xB76E79), 0);
    });
  });
}
