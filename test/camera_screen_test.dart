import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/features/color_studio/camera/camera_reading.dart';
import 'package:colormix_studio/features/color_studio/camera/color_camera.dart';
import 'package:colormix_studio/features/settings/settings_repository.dart';

import 'camera_reading_test.dart' show brown, photo;
import 'test_app.dart';

/// hands back whatever photo it's given, or refuses to open
class FakeColorCamera implements ColorCamera {
  FakeColorCamera({this.photo, this.openError});

  RgbaImage? photo;
  final String? openError;
  bool opened = false;
  bool closed = false;

  @override
  Future<void> open() async {
    if (openError != null) throw CameraUnavailable(openError!);
    opened = true;
  }

  @override
  Widget preview({required Widget overlay}) => AspectRatio(
    aspectRatio: 3 / 4,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFEEEEEE)),
        overlay,
      ],
    ),
  );

  @override
  Future<RgbaImage> capture() async => photo!;

  @override
  Future<void> close() async => closed = true;
}

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  Future<void> openCamera(WidgetTester tester, FakeColorCamera camera) async {
    await pumpApp(
      tester,
      db,
      size: const Size(360, 780),
      overrides: [colorCameraFactoryProvider.overrideWithValue(() => camera)],
    );
    await tap(tester, find.text('Colors'));
    await tap(tester, find.text('Camera'));
    expect(find.text('Read from the camera'), findsOneWidget);
    await tap(tester, find.text('Open camera'));
    expect(find.text('Read a color'), findsOneWidget);
  }

  testWidgets('hair on a card becomes the custom target', (tester) async {
    // a warm room: the camera alone would say something else
    final shot = photo(hair: brown, light: (0.8, 0.6, 0.4));
    final expected = readHairColor(shot, ReferenceCard.white).rgb!;
    final camera = FakeColorCamera(photo: shot);
    await openCamera(tester, camera);
    expect(camera.opened, isTrue);

    await tap(tester, find.text('Read color'));
    final hex = hexFromRgb(expected);
    expect(find.text(hex), findsOneWidget);
    expect(find.textContaining('Closest demo shade:'), findsOneWidget);
    expect(find.textContaining('Straight from the camera'), findsOneWidget);

    await tap(tester, find.text('Use this color'));
    expect(camera.closed, isTrue);
    // back in Color Studio: the target and the panel say so
    expect(find.text('$hex · Custom color'), findsOneWidget);
    expect(find.text('Last reading, now the target'), findsOneWidget);

    // and it's an ordinary custom color from here
    await tap(tester, find.text('Fine-tune'));
    expect(find.text('Color controls'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      hex.substring(1),
    );

    await unmountApp(tester);
  });

  testWidgets('a bad photo says why and reads again', (tester) async {
    final camera = FakeColorCamera(
      photo: photo(hair: brown, background: 0x2E7D32),
    );
    await openCamera(tester, camera);

    await tap(tester, find.text('Read color'));
    expect(find.text(notCardProblem), findsOneWidget);
    expect(find.text('Use this color'), findsNothing);

    // fixed: lay it on the card
    camera.photo = photo(hair: brown);
    await tap(tester, find.text('Read again'));
    await tap(tester, find.text('Read color'));
    expect(find.text('Use this color'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('the card picked is remembered', (tester) async {
    final camera = FakeColorCamera(
      photo: photo(hair: brown, card: ReferenceCard.gray),
    );
    await openCamera(tester, camera);

    await tap(tester, find.text('Gray card'));
    final s = (await tester.runAsync(() => SettingsRepository(db).load()))!;
    expect(s.cameraCard, ReferenceCard.gray);

    // read against the gray card it really was on
    await tap(tester, find.text('Read color'));
    final want = readHairColor(camera.photo!, ReferenceCard.gray).rgb!;
    expect(find.text(hexFromRgb(want)), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('a still is decoded and scaled down, colors kept', (
    tester,
  ) async {
    final png = (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..drawRect(
          const Rect.fromLTWH(0, 0, 1200, 600),
          Paint()..color = const Color(0xFFE8D7BE),
        )
        ..drawRect(
          const Rect.fromLTWH(500, 200, 200, 200),
          Paint()..color = const Color(0xFF6B4226),
        );
      final image = await recorder.endRecording().toImage(1200, 600);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    }))!;

    final decoded = (await tester.runAsync(() => decodeRgba(png)))!;
    expect((decoded.width, decoded.height), (800, 400));
    int at(int x, int y) {
      final o = (y * decoded.width + x) * 4;
      return (decoded.bytes[o] << 16) |
          (decoded.bytes[o + 1] << 8) |
          decoded.bytes[o + 2];
    }

    expect(at(10, 10), 0xE8D7BE);
    expect(at(400, 200), 0x6B4226);
  });

  testWidgets('no camera, no button', (tester) async {
    const msg = 'The app isn\'t allowed to use the camera.';
    final camera = FakeColorCamera(openError: msg);
    await openCamera(tester, camera);

    expect(find.text(msg), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    final read = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Read color'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(read.onPressed, isNull);

    await unmountApp(tester);
  });
}
