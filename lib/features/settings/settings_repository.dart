import 'package:flutter/material.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/color_studio/camera/camera_reading.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/shared/models/measure_unit.dart';

/// settings are plain key/value rows, unknown or broken values fall back to
/// the defaults
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _themeMode = 'theme_mode';
  static const _soundsOn = 'sounds_on';
  static const _toleranceDg = 'tolerance_dg';
  static const _autoAdvance = 'auto_advance';
  static const _defaultDyeDg = 'default_dye_dg';
  static const _stabilityThresholdMg = 'stability_threshold_mg';
  static const _stabilityDwellMs = 'stability_dwell_ms';
  static const _formulaUnit = 'formula_unit';
  static const _cameraCard = 'camera_card';
  static const _lastScaleId = 'last_scale_id';
  static const _lastScaleName = 'last_scale_name';

  Future<AppSettings> load() async {
    final rows = await _db.select(_db.appSettingsTable).get();
    final map = {for (final r in rows) r.key: r.value};
    const d = AppSettings();

    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[map[_themeMode]] ?? d.themeMode,
      soundsOn: _bool(map[_soundsOn]) ?? d.soundsOn,
      toleranceDg: int.tryParse(map[_toleranceDg] ?? '') ?? d.toleranceDg,
      autoAdvance: _bool(map[_autoAdvance]) ?? d.autoAdvance,
      defaultDyeDg: int.tryParse(map[_defaultDyeDg] ?? '') ?? d.defaultDyeDg,
      stabilityThresholdMg:
          int.tryParse(map[_stabilityThresholdMg] ?? '') ??
          d.stabilityThresholdMg,
      stabilityDwellMs:
          int.tryParse(map[_stabilityDwellMs] ?? '') ?? d.stabilityDwellMs,
      formulaUnit:
          MeasureUnit.values.asNameMap()[map[_formulaUnit]] ?? d.formulaUnit,
      cameraCard:
          ReferenceCard.values.asNameMap()[map[_cameraCard]] ?? d.cameraCard,
      lastScaleId: _nonEmpty(map[_lastScaleId]),
      lastScaleName: _nonEmpty(map[_lastScaleName]),
    );
  }

  Future<void> save(AppSettings s) async {
    final values = {
      _themeMode: s.themeMode.name,
      _soundsOn: '${s.soundsOn}',
      _toleranceDg: '${s.toleranceDg}',
      _autoAdvance: '${s.autoAdvance}',
      _defaultDyeDg: '${s.defaultDyeDg}',
      _stabilityThresholdMg: '${s.stabilityThresholdMg}',
      _stabilityDwellMs: '${s.stabilityDwellMs}',
      _formulaUnit: s.formulaUnit.name,
      _cameraCard: s.cameraCard.name,
      // empty string = none, rows are never deleted
      _lastScaleId: s.lastScaleId ?? '',
      _lastScaleName: s.lastScaleName ?? '',
    };

    await _db.batch((b) {
      b.insertAllOnConflictUpdate(_db.appSettingsTable, [
        for (final e in values.entries)
          AppSettingsTableCompanion.insert(key: e.key, value: e.value),
      ]);
    });
  }

  static String? _nonEmpty(String? v) => v == null || v.isEmpty ? null : v;

  static bool? _bool(String? v) => switch (v) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}
