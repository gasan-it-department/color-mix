import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.soundsOn = true,
    this.toleranceDg = 3,
    this.autoAdvance = false,
    this.defaultDyeDg = 600,
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

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundsOn,
    int? toleranceDg,
    bool? autoAdvance,
    int? defaultDyeDg,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundsOn: soundsOn ?? this.soundsOn,
      toleranceDg: toleranceDg ?? this.toleranceDg,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      defaultDyeDg: defaultDyeDg ?? this.defaultDyeDg,
    );
  }
}
