import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/utils/reading_stats.dart';

// same vectors as the firmware's test_noise_stats, so the app's scale check
// and serial `n` give the same numbers for the same readings

void main() {
  test('a steady reading has no swing, spread or drift', () {
    final s = ReadingStats();
    expect(s.swingMg, 0);
    for (var i = 0; i < 25; i++) {
      s.add(5);
    }
    expect(s.count, 25);
    expect(s.swingMg, 0);
    expect(s.stdDevMg, 0);
    expect(s.driftMg, 0);
    expect(s.meanMg, 5);
  });

  test('a slow creep shows as swing, spread and drift', () {
    final s = ReadingStats();
    for (var i = 0; i < 30; i++) {
      s.add(i * 10);
    }
    expect(s.minMg, 0);
    expect(s.maxMg, 290);
    expect(s.swingMg, 290);
    expect(s.meanMg, closeTo(145, 1e-9));
    // sample sd of an arithmetic run: step * sqrt(n(n+1)/12)
    expect(s.stdDevMg, closeTo(88.03, 0.01));
    // last ten average 245, first ten 45
    expect(s.driftMg, closeTo(200, 1e-9));
  });

  test('too short a run says nothing about drift', () {
    final s = ReadingStats();
    for (var i = 0; i < 15; i++) {
      s.add(i * 100);
    }
    expect(s.driftMg, 0);
    expect(s.swingMg, 1400);
  });

  test('negative readings, as an empty platform gives', () {
    final s = ReadingStats()
      ..add(-40)
      ..add(30)
      ..add(-10);
    expect(s.minMg, -40);
    expect(s.maxMg, 30);
    expect(s.swingMg, 70);
    expect(s.meanMg, closeTo(-6.67, 0.01));
  });
}
