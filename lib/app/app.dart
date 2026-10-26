import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/app/router.dart';
import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';

class ColorMixApp extends ConsumerWidget {
  const ColorMixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
