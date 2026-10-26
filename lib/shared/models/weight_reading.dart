class WeightReading {
  const WeightReading({
    required this.milligrams,
    required this.isStable,
    required this.timestamp,
    this.sequence,
    this.overload = false,
    this.uncalibrated = false,
  });

  /// signed, net of the device's own tare
  final int milligrams;

  /// the device's own flag. the weighing studio decides stability itself
  /// so every scale (and the simulator) is judged the same way
  final bool isStable;

  /// when the app received it, not when the device sampled it
  final DateTime timestamp;

  /// frame counter from the device, null when the adapter has none
  final int? sequence;
  final bool overload;
  final bool uncalibrated;

  double get grams => milligrams / 1000;
}
