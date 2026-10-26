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
import 'package:colormix_studio/features/settings/settings_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(400, 860),
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

  // drift stream queries need the tree gone before the db closes
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('opens on the dashboard with the main actions', (tester) async {
    await pumpApp(tester);

    expect(find.text('New color formula'), findsOneWidget);
    expect(find.text('Connect scale'), findsWidgets);
    expect(find.text('No saved formulas yet'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('bottom bar switches tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Formulas'));
    await tester.pumpAndSettle();
    expect(find.text('Saved formulas'), findsOneWidget);

    await tester.tap(find.text('Scale'));
    await tester.pumpAndSettle();
    expect(find.text('No scale connected'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('tablets get the rail, desktops the labelled sidebar', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(800, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await unmount(tester);

    await pumpApp(tester, size: const Size(1280, 800));
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Formulas'));
    await tester.pumpAndSettle();
    expect(find.text('Saved formulas'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('theme choice is saved to the database', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.themeMode, ThemeMode.dark);

    await unmount(tester);
  });
}
