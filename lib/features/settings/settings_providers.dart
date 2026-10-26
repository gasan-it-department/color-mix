import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/database/database_provider.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';

/// loaded in main() before runApp
final initialSettingsProvider = Provider<AppSettings>(
  (ref) =>
      throw UnimplementedError('initialSettingsProvider must be overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setSoundsOn(bool on) => _update(state.copyWith(soundsOn: on));

  Future<void> setAutoAdvance(bool on) =>
      _update(state.copyWith(autoAdvance: on));

  Future<void> setToleranceDg(int dg) =>
      _update(state.copyWith(toleranceDg: dg));

  Future<void> setDefaultDyeDg(int dg) =>
      _update(state.copyWith(defaultDyeDg: dg));

  Future<void> setLastScale(String? id, String? name) =>
      _update(state.withLastScale(id, name));

  // ui updates first, the write follows
  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }
}
