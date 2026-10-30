import 'package:flutter/material.dart';

import 'package:colormix_studio/features/color_studio/camera/camera_reading.dart';
import 'package:colormix_studio/shared/models/measure_unit.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.soundsOn = true,
    this.toleranceDg = 3,
    this.autoAdvance = false,
    this.defaultDyeDg = 600,
    this.stabilityThresholdMg = 200,
    this.stabilityDwellMs = 800,
    this.formulaUnit = MeasureUnit.g,
    this.cameraCard = ReferenceCard.white,
    this.lastScaleId,
    this.lastScaleName,
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

  /// the unit last picked in the editor, new formulas start in it
  final MeasureUnit formulaUnit;

  /// what the hair was last laid on for a camera reading
  final ReferenceCard cameraCard;

  /// the ble scale used last, so it can be reconnected without a scan
  final String? lastScaleId;
  final String? lastScaleName;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundsOn,
    int? toleranceDg,
    bool? autoAdvance,
    int? defaultDyeDg,
    int? stabilityThresholdMg,
    int? stabilityDwellMs,
    MeasureUnit? formulaUnit,
    ReferenceCard? cameraCard,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundsOn: soundsOn ?? this.soundsOn,
      toleranceDg: toleranceDg ?? this.toleranceDg,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      defaultDyeDg: defaultDyeDg ?? this.defaultDyeDg,
      stabilityThresholdMg: stabilityThresholdMg ?? this.stabilityThresholdMg,
      stabilityDwellMs: stabilityDwellMs ?? this.stabilityDwellMs,
      formulaUnit: formulaUnit ?? this.formulaUnit,
      cameraCard: cameraCard ?? this.cameraCard,
      lastScaleId: lastScaleId,
      lastScaleName: lastScaleName,
    );
  }

  /// null clears it
  AppSettings withLastScale(String? id, String? name) => AppSettings(
    themeMode: themeMode,
    soundsOn: soundsOn,
    toleranceDg: toleranceDg,
    autoAdvance: autoAdvance,
    defaultDyeDg: defaultDyeDg,
    stabilityThresholdMg: stabilityThresholdMg,
    stabilityDwellMs: stabilityDwellMs,
    formulaUnit: formulaUnit,
    cameraCard: cameraCard,
    lastScaleId: id,
    lastScaleName: id == null ? null : name,
  );
}
