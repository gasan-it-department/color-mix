import 'dart:math';

/// the scale check's numbers over a run of readings: mean, swing, standard
/// deviation and drift. same sums as the firmware's NoiseStats (serial `n`)
/// so the two can be compared on the hardware sheet
class ReadingStats {
  /// drift compares the average of the first and last this many readings
  static const edge = 10;

  int _count = 0;
  int _min = 0;
  int _max = 0;
  double _mean = 0;
  double _m2 = 0;
  int _firstSum = 0;
  final _last = <int>[];

  int get count => _count;
  int get minMg => _min;
  int get maxMg => _max;

  /// biggest minus smallest
  int get swingMg => _count == 0 ? 0 : _max - _min;
  double get meanMg => _mean;

  /// sample standard deviation, 0 under two readings
  double get stdDevMg => _count < 2 ? 0 : sqrt(_m2 / (_count - 1));

  /// average of the last [edge] readings minus the first [edge]. 0 until
  /// there are two edges' worth, too short to tell drift from noise
  double get driftMg {
    if (_count < 2 * edge) return 0;
    final lastSum = _last.fold<int>(0, (a, b) => a + b);
    return (lastSum - _firstSum) / edge;
  }

  void add(int mg) {
    if (_count == 0) {
      _min = mg;
      _max = mg;
    } else {
      _min = min(_min, mg);
      _max = max(_max, mg);
    }
    _count++;

    // welford, a long run doesn't lose precision
    final delta = mg - _mean;
    _mean += delta / _count;
    _m2 += delta * (mg - _mean);

    if (_count <= edge) _firstSum += mg;
    _last.add(mg);
    if (_last.length > edge) _last.removeAt(0);
  }
}
