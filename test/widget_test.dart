import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';

import 'test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  testWidgets('opens on the dashboard with the main actions', (tester) async {
    await pumpApp(tester, db);

    expect(find.text('New color formula'), findsOneWidget);
    expect(find.text('Connect scale'), findsWidgets);
    expect(find.text('No saved formulas yet'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('bottom bar switches tabs', (tester) async {
    await pumpApp(tester, db);

    await tester.tap(find.text('Formulas'));
    await tester.pumpAndSettle();
    expect(find.text('Saved formulas'), findsOneWidget);

    await tester.tap(find.text('Scale'));
    await tester.pumpAndSettle();
    expect(find.text('No scale connected'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('tablets get the rail, desktops the labelled sidebar', (
    tester,
  ) async {
    await pumpApp(tester, db, size: const Size(800, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await unmountApp(tester);

    await pumpApp(tester, db, size: desktop);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Formulas'));
    await tester.pumpAndSettle();
    expect(find.text('Saved formulas'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('theme choice is saved to the database', (tester) async {
    await pumpApp(tester, db);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.themeMode, ThemeMode.dark);

    await unmountApp(tester);
  });
}
