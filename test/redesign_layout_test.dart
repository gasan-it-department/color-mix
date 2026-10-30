import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';

import 'test_app.dart';
import 'weighing_state_test.dart' show roseGold;

const _longName =
    'Soft rose and copper gloss for shoulder-length hair — autumn refresh';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  for (final size in const [Size(360, 780), Size(800, 800), Size(1280, 860)]) {
    for (final appearance in const [
      (theme: ThemeMode.light, scale: 1.0),
      (theme: ThemeMode.dark, scale: 1.5),
    ]) {
      testWidgets('workspace flows fit ${size.width.toInt()}px '
          '${appearance.theme.name} at ${appearance.scale}x text', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = appearance.scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.runAsync(() async {
          final formula = roseGold().copyWith(
            name: _longName,
            notes: () =>
                'Keep this longer client note readable when reviewing '
                'the saved formula on a small screen.',
          );
          await FormulaRepository(db).save(formula);
          final sessions = SessionRepository(db);
          await sessions.start(
            WeighingState.start(
              sessionId: 'responsive-interrupted-session',
              formula: formula,
              toleranceMg: 300,
              deviceName: 'ColorMix studio bench scale',
              connection: ScaleConnectionState.connectedSupported,
              startedAt: DateTime(2026, 10, 29, 10),
            ),
            scaleId: 'responsive-test-scale',
          );
          await sessions.markInterrupted();
        });

        await pumpApp(
          tester,
          db,
          size: size,
          settings: AppSettings(themeMode: appearance.theme),
        );
        _expectNoLayoutError(tester, 'Home');
        expect(find.text('New color formula'), findsOneWidget);
        await _tap(tester, find.text('Colors').first);
        expect(find.text('Demo palette'), findsOneWidget);
        _expectNoLayoutError(tester, 'Color Studio');

        await _tap(tester, find.text('Copper Brown').first);
        _expectNoLayoutError(tester, 'selected color');
        await _scrollLists(tester, 'palette');

        await _tap(tester, find.text('Formulas').first);
        expect(find.text(_longName), findsOneWidget);
        _expectNoLayoutError(tester, 'saved formula with long name');
        await _tap(tester, find.byTooltip('More for $_longName'));
        expect(find.text('Weigh'), findsOneWidget);
        expect(find.text('Duplicate'), findsOneWidget);
        _expectNoLayoutError(tester, 'formula menu');
        // Dismiss the menu without editing or deleting the saved formula.
        await tester.pageBack();
        await tester.pumpAndSettle();

        await _tap(tester, find.text('History'));
        _expectNoLayoutError(tester, 'history with long formula name');
        await _tap(tester, find.textContaining('Interrupted ·'));
        expect(find.text('Weighing session'), findsOneWidget);
        _expectNoLayoutError(tester, 'session detail');
        await _scrollLists(tester, 'session detail');
        await tester.pageBack();
        await tester.pumpAndSettle();

        await _tap(tester, find.text('Scale').first);
        expect(find.text('Connected scale'), findsOneWidget);
        await _tap(tester, find.text('Use simulated scale'));
        expect(find.widgetWithText(OutlinedButton, 'Tare'), findsOneWidget);
        _expectNoLayoutError(tester, 'connected simulator');
        await _scrollLists(tester, 'scale controls');

        final settings = find.byTooltip('Settings');
        await _tap(
          tester,
          settings.evaluate().isNotEmpty ? settings : find.text('Settings'),
        );
        expect(find.text('Appearance'), findsOneWidget);
        _expectNoLayoutError(tester, 'settings');
        await _scrollLists(tester, 'settings sections');
        expect(find.text('About'), findsOneWidget);

        await unmountApp(tester);
      });
    }
  }

  testWidgets('archive remains usable above the keyboard with enlarged text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      db,
      size: const Size(360, 780),
      settings: const AppSettings(themeMode: ThemeMode.dark),
    );
    await _tap(tester, find.text('Formulas').first);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'empty archive above the keyboard');
    expect(find.text('No saved formulas yet'), findsOneWidget);

    await tester.runAsync(
      () => FormulaRepository(db).save(roseGold().copyWith(name: _longName)),
    );
    await tester.enterText(find.byType(TextField), 'unmatched shade');
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'no search results above the keyboard');
    expect(find.text('Nothing matches "unmatched shade"'), findsOneWidget);
    await _tap(tester, find.text('Clear search'));
    expect(find.text(_longName), findsOneWidget);
    _expectNoLayoutError(tester, 'restored search results above the keyboard');
    await unmountApp(tester);
  });
}

void _expectNoLayoutError(WidgetTester tester, String screen) {
  expect(
    tester.takeException(),
    isNull,
    reason: '$screen must fit the viewport',
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(finder.first.hitTestable(), findsOneWidget);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Visit each vertical viewport, including the two-pane Color Studio, so
/// lazy content below the fold participates in the overflow regression.
Future<void> _scrollLists(WidgetTester tester, String screen) async {
  final lists = find.byType(Scrollable);
  final count = lists.evaluate().length;
  for (var i = 0; i < count; i++) {
    final list = lists.at(i);
    final state = tester.state<ScrollableState>(list);
    if (axisDirectionToAxis(state.axisDirection) != Axis.vertical) continue;
    for (var step = 0; step < 20; step++) {
      if (state.position.pixels >= state.position.maxScrollExtent - 1) break;
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();
      _expectNoLayoutError(tester, screen);
    }
  }
}
