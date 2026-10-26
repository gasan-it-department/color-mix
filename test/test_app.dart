import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/app/app.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/core/database/database_provider.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';

const phone = Size(400, 860);
const desktop = Size(1280, 860);

AppDatabase memoryDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// the whole app on an in-memory db at the given window size
Future<void> pumpApp(
  WidgetTester tester,
  AppDatabase db, {
  Size size = phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(const AppSettings()),
      ],
      child: const ColorMixApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// drift stream queries need the tree gone before the db closes
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}
