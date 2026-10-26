import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.soundsOn = true,
    this.toleranceDg = 3,
    this.autoAdvance = false,
    this.defaultDyeDg = 600,
    this.stabilityThresholdMg = 200,
    this.stabilityDwellMs = 800,
  });

  final ThemeMode themeMode;
  final bool soundsOn;

  /// how close counts as on target, decigrams. 3 = 0.3 g until the real
  /// scale's noise is measured
  final int toleranceDg;

  /// move to the next ingredient by itself once stable within tolerance
  final bool autoAdvance;

  /// starting dye amount for a new formula, decigrams
  final int defaultDyeDg;

  /// readings over the dwell time must stay within this to count as steady
  final int stabilityThresholdMg;
  final int stabilityDwellMs;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundsOn,
    int? toleranceDg,
    bool? autoAdvance,
    int? defaultDyeDg,
    int? stabilityThresholdMg,
    int? stabilityDwellMs,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundsOn: soundsOn ?? this.soundsOn,
      toleranceDg: toleranceDg ?? this.toleranceDg,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      defaultDyeDg: defaultDyeDg ?? this.defaultDyeDg,
      stabilityThresholdMg: stabilityThresholdMg ?? this.stabilityThresholdMg,
      stabilityDwellMs: stabilityDwellMs ?? this.stabilityDwellMs,
    );
  }
}
