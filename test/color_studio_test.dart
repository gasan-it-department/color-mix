import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/color_studio/widgets/target_card.dart';

import 'test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Finder inCard(String text) =>
      find.descendant(of: find.byType(TargetCard), matching: find.text(text));

  Future<void> openColors(WidgetTester tester) async {
    await tester.tap(find.text('Colors'));
    await tester.pumpAndSettle();
  }

  testWidgets('picking a demo shade shows its labelled recipe', (tester) async {
    await pumpApp(tester, db, size: desktop);
    await openColors(tester);

    expect(find.text('No color picked'), findsOneWidget);

    await tester.ensureVisible(find.text('Rose Gold'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rose Gold'));
    await tester.pumpAndSettle();

    expect(find.text('Demo recipe'), findsOneWidget);
    expect(find.text('Demo only'), findsOneWidget);
    expect(find.text('Demo shade'), findsOneWidget);
    expect(inCard('#B76E79'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('1:1 by weight'), findsOneWidget);

    final create = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create formula'),
    );
    expect(create.onPressed, isNotNull);

    await unmountApp(tester);
  });

  testWidgets('a shade without a recipe says so', (tester) async {
    await pumpApp(tester, db, size: desktop);
    await openColors(tester);

    await tester.ensureVisible(find.text('Mahogany'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mahogany'));
    await tester.pumpAndSettle();

    expect(find.text('Level 5.5'), findsWidgets);
    expect(
      find.textContaining('No demo recipe for this shade'),
      findsOneWidget,
    );
    expect(find.text('Demo only'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('custom hex drives the target and finds the closest shade', (
    tester,
  ) async {
    await pumpApp(tester, db, size: desktop);
    await openColors(tester);

    await tester.tap(find.text('Custom color'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'B97079');
    await tester.pumpAndSettle();

    expect(inCard('#B97079'), findsOneWidget);
    expect(find.text('Custom color'), findsWidgets);
    expect(find.text('Closest demo shade on screen'), findsOneWidget);
    expect(find.text('Rose Gold · almost the same'), findsOneWidget);

    // jump to that shade and its recipe
    await tester.tap(find.text('Use it'));
    await tester.pumpAndSettle();

    expect(find.text('Demo recipe'), findsOneWidget);
    expect(inCard('#B76E79'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('bad hex shows a plain message', (tester) async {
    await pumpApp(tester, db, size: desktop);
    await openColors(tester);

    await tester.tap(find.text('Custom color'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'B97');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    // shorthand is fine, it expands
    expect(inCard('#BB9977'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'B970');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Use 6 characters, like B76E79'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('phones pin the target and open the recipe in a sheet', (
    tester,
  ) async {
    await pumpApp(tester, db);
    await openColors(tester);

    expect(find.text('No color picked'), findsOneWidget);

    await tester.tap(find.text('Copper Brown'));
    await tester.pumpAndSettle();
    expect(find.text('Copper Brown'), findsWidgets);
    expect(find.textContaining('Demo recipe'), findsOneWidget);

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Demo only'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('opening the picker with nothing picked targets its color', (
    tester,
  ) async {
    await pumpApp(tester, db);
    await openColors(tester);

    await tester.tap(find.text('Custom color'));
    await tester.pumpAndSettle();

    expect(find.text('No color picked'), findsNothing);
    expect(find.text('#B76E79 · Custom color'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('labels legend explains the three levels', (tester) async {
    await pumpApp(tester, db);
    await openColors(tester);

    await tester.tap(find.byTooltip('What the labels mean'));
    await tester.pumpAndSettle();

    expect(find.text('Visual target'), findsOneWidget);
    expect(find.text('Demo only'), findsOneWidget);
    expect(find.text('Validated'), findsOneWidget);

    await unmountApp(tester);
  });
}
