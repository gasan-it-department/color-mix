import 'package:flutter/material.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';

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
    );
  }

  Future<void> save(AppSettings s) async {
    final values = {
      _themeMode: s.themeMode.name,
      _soundsOn: '${s.soundsOn}',
      _toleranceDg: '${s.toleranceDg}',
      _autoAdvance: '${s.autoAdvance}',
      _defaultDyeDg: '${s.defaultDyeDg}',
    };

    await _db.batch((b) {
      b.insertAllOnConflictUpdate(_db.appSettingsTable, [
        for (final e in values.entries)
          AppSettingsTableCompanion.insert(key: e.key, value: e.value),
      ]);
    });
  }

  static bool? _bool(String? v) => switch (v) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}
