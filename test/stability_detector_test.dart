import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/stability_detector.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

final t0 = DateTime(2026, 10, 26, 10);

/// readings 100 ms apart
List<WeightReading> series(List<int> mg) => [
  for (final (i, v) in mg.indexed)
    WeightReading(
      milligrams: v,
      isStable: false,
      timestamp: t0.add(Duration(milliseconds: 100 * i)),
    ),
];

StabilityDetector fed(List<int> mg) {
  final d = StabilityDetector(
    thresholdMg: 200,
    dwell: const Duration(milliseconds: 800),
  );
  for (final r in series(mg)) {
    d.add(r);
  }
  return d;
}

void main() {
  test('small noise for long enough is steady', () {
    final d = fed([
      30010,
      29980,
      30040,
      30000,
      29970,
      30020,
      30030,
      29990,
      30010,
      30000,
    ]);
    expect(d.isStable, isTrue);
    expect(d.smoothedMg, closeTo(30000, 40));
  });

  test('needs a full dwell of readings before calling it steady', () {
    expect(fed([30000, 30000, 30000]).isStable, isFalse);
  });

  test('a pour in progress is not steady', () {
    expect(
      fed([for (var i = 0; i < 12; i++) 20000 + i * 500]).isStable,
      isFalse,
    );
  });

  test('a wobbly reading is not steady', () {
    expect(
      fed([
        30000,
        31000,
        29200,
        30800,
        29500,
        30900,
        29100,
        30700,
        29600,
        31000,
      ]).isStable,
      isFalse,
    );
  });

  test('one spike does not move the smoothed value', () {
    final d = fed([30000, 30010, 45000, 30020, 29990]);
    expect(d.smoothedMg, inInclusiveRange(29990, 30020));
  });

  test('a real change shows within a few readings', () {
    final d = fed([30000, 30000, 30000, 31000, 31000, 31000]);
    expect(d.smoothedMg, 31000);
  });

  test('reset forgets everything', () {
    final d = fed([for (var i = 0; i < 12; i++) 30000])..reset();
    expect(d.isStable, isFalse);
    expect(d.smoothedMg, isNull);
  });
}
