import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/utils/color_science.dart';
import 'package:colormix_studio/features/color_studio/camera/camera_reading.dart';

/// Rose Gold's hex, and a mid brown
const roseGold = 0xB76E79;
const brown = 0x6B4226;

/// what a camera would save of [hair] laid on [card]: the middle a little
/// bigger than the hair square, card everywhere else, every channel scaled
/// by [light] in linear light (a warm lamp, a dim room, the camera's own
/// white balance and exposure all come to that). [edit] changes pixels
/// after, x and y as fractions of the photo
RgbaImage photo({
  required int hair,
  ReferenceCard card = ReferenceCard.white,
  int? background,
  (double, double, double) light = (1, 1, 1),
  int width = 400,
  int height = 300,
  void Function(double x, double y, List<double> rgb)? edit,
}) {
  final bytes = Uint8List(width * height * 4);
  final side = math.min(width, height);
  final half = (ReadingLayout.hair + 0.04) * side / 2;
  List<double> lin(int rgb) => [
    srgbToLinear((rgb >> 16) & 0xFF),
    srgbToLinear((rgb >> 8) & 0xFF),
    srgbToLinear(rgb & 0xFF),
  ];
  final hairLin = lin(hair);
  final cardLin = background == null
      ? List.filled(3, card.luminance)
      : lin(background);
  final gains = [light.$1, light.$2, light.$3];

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final inHair =
          (x - width / 2).abs() < half && (y - height / 2).abs() < half;
      final rgb = [
        for (var c = 0; c < 3; c++) (inHair ? hairLin : cardLin)[c] * gains[c],
      ];
      edit?.call(x / width, y / height, rgb);
      final o = (y * width + x) * 4;
      bytes[o] = linearToSrgb(rgb[0]);
      bytes[o + 1] = linearToSrgb(rgb[1]);
      bytes[o + 2] = linearToSrgb(rgb[2]);
      bytes[o + 3] = 255;
    }
  }
  return RgbaImage(width, height, bytes);
}

Matcher near(int rgb, double deltaE) => predicate<int?>(
  (v) => v != null && deltaE2000Rgb(v, rgb) < deltaE,
  'within ΔE $deltaE of #${rgb.toRadixString(16)}',
);

void main() {
  group('the card corrects the camera', () {
    test('neutral light reads the hair as it is', () {
      final r = readHairColor(photo(hair: roseGold), ReferenceCard.white);
      expect(r.ok, isTrue);
      expect(r.rgb, near(roseGold, 1));
      expect(r.warnings, isEmpty);
    });

    test('a warm, dim room: the camera is way off, the reading isn\'t', () {
      final p = photo(hair: brown, light: (0.6, 0.42, 0.22));
      final r = readHairColor(p, ReferenceCard.white);
      expect(deltaE2000Rgb(r.cameraRgb!, brown), greaterThan(6));
      expect(r.rgb, near(brown, 1.5));
    });

    test('a cold, bright one, on a gray card', () {
      final r = readHairColor(
        photo(hair: roseGold, card: ReferenceCard.gray, light: (1.2, 1.5, 2)),
        ReferenceCard.gray,
      );
      expect(r.rgb, near(roseGold, 1.5));
    });

    test('the wrong card picked reads lighter or darker, never a new hue', () {
      final r = readHairColor(
        photo(hair: brown, card: ReferenceCard.gray),
        ReferenceCard.white,
      );
      final got = labFromRgb(r.rgb!);
      final want = labFromRgb(brown);
      expect(got.l, greaterThan(want.l + 15));
      final hue = math.atan2(got.b, got.a) - math.atan2(want.b, want.a);
      expect(hue.abs(), lessThan(0.15));
    });

    test('portrait photos read the same', () {
      final r = readHairColor(
        photo(hair: roseGold, width: 300, height: 400, light: (1.1, 0.9, 0.7)),
        ReferenceCard.white,
      );
      expect(r.rgb, near(roseGold, 1.5));
    });

    test('the cards are what the labels say', () {
      expect(ReferenceCard.gray.luminance, closeTo(0.184, 0.001));
      expect(ReferenceCard.white.luminance, closeTo(0.853, 0.001));
    });
  });

  group('hair is uneven', () {
    test('shine and dark gaps between strands are left out', () {
      // stripes: one in ten blown-out shine, one in ten near black
      final p = photo(
        hair: brown,
        edit: (x, y, rgb) {
          if ((x - 0.5).abs() > 0.15 || (y - 0.5).abs() > 0.2) return;
          final stripe = (x * 400).floor() % 10;
          if (stripe == 0) rgb.fillRange(0, 3, 1.0);
          if (stripe == 5) rgb.fillRange(0, 3, 0.002);
        },
      );
      final r = readHairColor(p, ReferenceCard.white);
      expect(r.rgb, near(brown, 1.5));
      expect(r.warnings, isEmpty);
    });

    test('a lot of shine is said', () {
      final p = photo(
        hair: brown,
        edit: (x, y, rgb) {
          if ((x - 0.5).abs() > 0.15 || (y - 0.5).abs() > 0.2) return;
          if ((x * 400).floor() % 3 == 0) rgb.fillRange(0, 3, 1.0);
        },
      );
      final r = readHairColor(p, ReferenceCard.white);
      expect(r.ok, isTrue);
      expect(r.warnings, contains(shineWarning));
    });
  });

  group('the card', () {
    test('a stray strand over one square doesn\'t matter', () {
      final p = photo(
        hair: brown,
        edit: (x, y, rgb) {
          // a thin dark line through the top card square
          if ((y - 0.2).abs() < 0.004) rgb.fillRange(0, 3, 0.01);
        },
      );
      final r = readHairColor(p, ReferenceCard.white);
      expect(r.problem, isNull);
      expect(r.rgb, near(brown, 1));
    });

    test('a soft shadow over part of it is a warning', () {
      final p = photo(
        hair: brown,
        edit: (x, y, rgb) {
          if (y < 0.3) {
            for (var c = 0; c < 3; c++) {
              rgb[c] *= 0.8;
            }
          }
        },
      );
      final r = readHairColor(p, ReferenceCard.white);
      expect(r.ok, isTrue);
      expect(r.warnings, contains(unevenWarning));
    });

    test('a hard one stops it', () {
      final p = photo(
        hair: brown,
        edit: (x, y, rgb) {
          if (x < 0.4) {
            for (var c = 0; c < 3; c++) {
              rgb[c] *= 0.45;
            }
          }
        },
      );
      expect(readHairColor(p, ReferenceCard.white).problem, coveredProblem);
    });

    test('something colored over one square stops it', () {
      final p = photo(
        hair: brown,
        edit: (x, y, rgb) {
          if (x > 0.65) {
            rgb[0] *= 1;
            rgb[1] *= 0.55;
            rgb[2] *= 0.55;
          }
        },
      );
      expect(readHairColor(p, ReferenceCard.white).problem, coveredProblem);
    });

    test('washed out', () {
      final p = photo(hair: brown, light: (1.3, 1.3, 1.3));
      expect(readHairColor(p, ReferenceCard.white).problem, tooBrightProblem);
    });

    test('too dark', () {
      final p = photo(hair: brown, light: (0.02, 0.02, 0.02));
      expect(readHairColor(p, ReferenceCard.white).problem, tooDarkProblem);
    });

    test('no card at all', () {
      final p = photo(hair: brown, background: 0x2E7D32);
      expect(readHairColor(p, ReferenceCard.white).problem, notCardProblem);
    });

    test('no hair in the middle', () {
      final p = photo(hair: 0xEEEEEE);
      expect(readHairColor(p, ReferenceCard.white).problem, noHairProblem);
    });

    test('a tiny photo', () {
      final p = photo(hair: brown, width: 40, height: 40);
      expect(readHairColor(p, ReferenceCard.white).problem, tooSmallProblem);
    });
  });

  test('srgb there and back', () {
    for (var v = 0; v < 256; v++) {
      expect(linearToSrgb(srgbToLinear(v)), v);
    }
    expect(linearToSrgb(-1), 0);
    expect(linearToSrgb(2), 255);
  });
}
