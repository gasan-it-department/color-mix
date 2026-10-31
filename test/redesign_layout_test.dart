import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/color_studio/camera/color_camera.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/saved_formulas/saved_formulas_screen.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';

import 'camera_reading_test.dart' show brown, photo;
import 'camera_screen_test.dart' show FakeColorCamera;
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
          overrides: [
            colorCameraFactoryProvider.overrideWithValue(
              () => FakeColorCamera(photo: photo(hair: brown)),
            ),
          ],
        );
        _expectNoLayoutError(tester, 'Home');
        expect(find.text('New color formula'), findsOneWidget);
        await _tap(tester, find.text('Colors').first);
        expect(find.text('Demo palette'), findsOneWidget);
        _expectNoLayoutError(tester, 'Color Studio');

        // the camera first, the mode buttons scroll away once a shade low
        // in the list is picked. a made-up photo read and its result
        await _tap(tester, find.text('Camera').first);
        _expectNoLayoutError(tester, 'camera panel');
        await _tap(tester, find.text('Open camera'));
        expect(find.text('Read a color'), findsOneWidget);
        _expectNoLayoutError(tester, 'camera screen');
        await _tap(tester, find.text('Read color'));
        expect(find.text('Use this color'), findsOneWidget);
        _expectNoLayoutError(tester, 'camera reading');
        await _scrollLists(tester, 'camera reading');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await _scrollToTop(tester);
        await _tap(tester, find.text('Demo palette'));
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
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Duplicate'), findsNothing);

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
        await tester.pageBack();
        await tester.pumpAndSettle();

        // the densest screens: the editor with a long name, its start sheet,
        // and weighing on the simulator connected above
        await _tap(tester, find.text('Formulas').first);
        // the archive keeps where History was scrolled to
        await _scrollToTop(tester);
        await _tap(
          tester,
          find.descendant(
            of: find.byType(SegmentedButton<SavedView>),
            matching: find.text('Formulas'),
          ),
        );
        await _tap(tester, find.text(_longName));
        expect(find.text('Edit formula'), findsOneWidget);
        _expectNoLayoutError(tester, 'formula editor');
        // the name is over 60 characters, so the editor shows why and holds
        // Start weighing back. the archive's menu weighs it as saved
        expect(find.text('Keep the name under 60 characters.'), findsWidgets);
        await _scrollLists(tester, 'formula editor');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await _tap(tester, find.byTooltip('More for $_longName'));
        await _tap(tester, find.text('Weigh'));
        expect(find.text('Ready to weigh'), findsOneWidget);
        _expectNoLayoutError(tester, 'start weighing sheet');
        await _scrollLists(tester, 'start weighing sheet');
        await _tap(tester, find.byType(Checkbox));
        await _tap(
          tester,
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.widgetWithText(FilledButton, 'Start weighing'),
          ),
        );
        // live readings from here, fixed pumps instead of settling
        await _pumpFor(tester, 800);
        expect(find.text('Put the empty bowl on the scale'), findsOneWidget);
        _expectNoLayoutError(tester, 'weighing');
        await _scrollLists(tester, 'weighing', settle: false);

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
/// [settle] off where live readings keep frames coming.
Future<void> _scrollLists(
  WidgetTester tester,
  String screen, {
  bool settle = true,
}) async {
  // a snapshot: every text field has a scrollable of its own, and they come
  // and go as the list scrolls, so indexes into a live finder shift
  final lists = [
    for (final e in find.byType(Scrollable).evaluate())
      (e as StatefulElement).state as ScrollableState,
  ].where((s) => axisDirectionToAxis(s.axisDirection) == Axis.vertical);
  for (final state in lists.toList()) {
    for (var step = 0; step < 20; step++) {
      if (!state.mounted) break;
      if (state.position.pixels >= state.position.maxScrollExtent - 1) break;
      final box = state.context.findRenderObject()! as RenderBox;
      await tester.dragFrom(
        box.localToGlobal(box.size.center(Offset.zero)),
        const Offset(0, -400),
      );
      settle ? await tester.pumpAndSettle() : await _pumpFor(tester, 400);
      _expectNoLayoutError(tester, screen);
    }
  }
}

/// lazy lists drop what's scrolled well away, so back up before finding it
Future<void> _scrollToTop(WidgetTester tester) async {
  for (final e in find.byType(Scrollable).evaluate()) {
    final state = (e as StatefulElement).state as ScrollableState;
    if (state.position.pixels > 0) state.position.jumpTo(0);
  }
  await tester.pumpAndSettle();
}

Future<void> _pumpFor(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
