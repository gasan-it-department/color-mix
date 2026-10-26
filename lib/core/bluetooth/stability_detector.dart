import 'dart:collection';

import 'package:colormix_studio/shared/models/weight_reading.dart';

/// decides "steady" the same way for every scale, simulator included.
/// the device's own stable flag is ignored on purpose.
///
/// smoothed value: median of the last few readings, so one spike doesn't
/// move the display but a real pour shows within a couple of readings.
/// steady: readings cover at least [dwell] and all of them sit within
/// [thresholdMg] of each other.
class StabilityDetector {
  StabilityDetector({
    this.thresholdMg = 200,
    this.dwell = const Duration(milliseconds: 800),
    this.smoothing = 5,
  });

  final int thresholdMg;
  final Duration dwell;
  final int smoothing;

  final _samples = Queue<WeightReading>();

  void add(WeightReading r) {
    _samples.add(r);
    final keepFrom = r.timestamp.subtract(dwell * 2);
    while (_samples.length > smoothing &&
        _samples.first.timestamp.isBefore(keepFrom)) {
      _samples.removeFirst();
    }
  }

  void reset() => _samples.clear();

  bool get isEmpty => _samples.isEmpty;

  int? get smoothedMg {
    if (_samples.isEmpty) return null;
    final recent =
        _samples
            .toList()
            .reversed
            .take(smoothing)
            .map((s) => s.milligrams)
            .toList()
          ..sort();
    return recent[recent.length ~/ 2];
  }

  bool get isStable {
    if (_samples.isEmpty) return false;
    final from = _samples.last.timestamp.subtract(dwell);
    // not enough history yet to call it
    if (_samples.first.timestamp.isAfter(from)) return false;

    int? lo;
    int? hi;
    for (final s in _samples) {
      if (s.timestamp.isBefore(from)) continue;
      final mg = s.milligrams;
      if (lo == null || mg < lo) lo = mg;
      if (hi == null || mg > hi) hi = mg;
    }
    return lo != null && hi! - lo <= thresholdMg;
  }
}
