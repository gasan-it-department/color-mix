import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('empty database gives the defaults', () async {
    final s = await repo.load();
    expect(s.themeMode, ThemeMode.system);
    expect(s.toleranceDg, 3);
    expect(s.defaultDyeDg, 600);
  });

  test('round trips every value', () async {
    await repo.save(
      const AppSettings(
        themeMode: ThemeMode.dark,
        soundsOn: false,
        toleranceDg: 5,
        autoAdvance: true,
        defaultDyeDg: 450,
      ),
    );

    final s = await repo.load();
    expect(s.themeMode, ThemeMode.dark);
    expect(s.soundsOn, isFalse);
    expect(s.toleranceDg, 5);
    expect(s.autoAdvance, isTrue);
    expect(s.defaultDyeDg, 450);
  });

  test('a broken value falls back to its default', () async {
    await repo.save(const AppSettings());
    await db.customStatement(
      "UPDATE app_settings SET value = 'purple' WHERE key = 'theme_mode'",
    );

    expect((await repo.load()).themeMode, ThemeMode.system);
  });
}
