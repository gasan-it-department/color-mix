// reading a hair color off a photo. no flutter here, the screen hands in the
// decoded pixels.
//
// a phone camera never reports the true color: it picks its own white
// balance and exposure for every shot, and the room light tints everything.
// so the hair lies on a white or gray card, and the photo has both. the
// card's real color is known, so whatever the camera did to the card it
// also did to the hair, and dividing it back out gives the hair's color.
//
// the layout is a square of hair in the middle and four small squares of
// card around it, all the same distance out. turned 90° it's the same
// layout, so it doesn't matter which way up the phone saved the photo, and
// lens shading darkens all four card squares alike.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:colormix_studio/core/utils/color_science.dart';

/// a decoded photo, 4 bytes a pixel: r, g, b, a
class RgbaImage {
  const RgbaImage(this.width, this.height, this.bytes)
    : assert(bytes.length >= width * height * 4);

  final int width;
  final int height;
  final Uint8List bytes;
}

/// what the hair lies on. only its lightness matters, both are neutral
enum ReferenceCard {
  /// plain copy paper, a touch under a perfect white
  white(label: 'White paper', lightness: 94),

  /// a photographer's 18% gray card
  gray(label: 'Gray card', lightness: 50);

  const ReferenceCard({required this.label, required this.lightness});

  /// not `name`: that one is the enum's own and goes in settings
  final String label;

  /// CIELAB L*
  final double lightness;

  /// linear luminance, what R = G = B come to for this card
  double get luminance {
    final f = (lightness + 16) / 116;
    return f * f * f;
  }
}

// ── layout ─────────────────────────────────────────────────

/// where things sit, as fractions of the photo's shorter side, measured from
/// its centre. the camera screen draws its guide from the same numbers
abstract final class ReadingLayout {
  /// the hair square's side
  static const hair = 0.30;

  /// each card square's side
  static const card = 0.10;

  /// how far out the card squares' centres are, up, down, left and right
  static const cardOffset = 0.30;
}

// ── result ─────────────────────────────────────────────────

class ColorReading {
  const ColorReading({
    this.rgb,
    this.cameraRgb,
    this.problem,
    this.warnings = const [],
  });

  /// the hair, corrected by the card. null when [problem] stopped it
  final int? rgb;

  /// the hair as the camera saw it, before the card's correction
  final int? cameraRgb;

  /// why there's no reading
  final String? problem;

  /// there's a reading, but it may be off
  final List<String> warnings;

  bool get ok => rgb != null;
}

// messages, here so the tests can check them
const tooSmallProblem = 'The photo came out too small to read. Try again.';
const tooBrightProblem =
    'The card is washed out. Move out of direct sun or away from the lamp, '
    'and keep the flash off.';
const tooDarkProblem =
    'Too dark to read. Move nearer a window or turn a light on.';
const notCardProblem =
    'The four small squares don\'t look like a white or gray card. Lay the '
    'hair on the card so the card shows in all four.';
const coveredProblem =
    'Part of the card is covered or in shadow. Keep the four small squares '
    'clear and evenly lit.';
const noHairProblem =
    'The middle square looks like the card. Fill it with hair.';
const unevenWarning =
    'The light across the card isn\'t quite even, so the reading may be a '
    'little off.';
const shineWarning =
    'A lot of shine in the middle square. Tilt the hair or the light so it\'s '
    'less glossy.';

// ── reading ────────────────────────────────────────────────

/// the hair's color from a photo of hair on [card], laid out as
/// [ReadingLayout] says
ColorReading readHairColor(RgbaImage image, ReferenceCard card) {
  final side = math.min(image.width, image.height);
  if (side < 60) return const ColorReading(problem: tooSmallProblem);
  final cx = image.width / 2;
  final cy = image.height / 2;

  // the card: each square's median, so a stray strand doesn't count
  final patches = <_Rgb>[];
  var clipped = false;
  for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
    final samples = _sample(
      image,
      cx + dx * ReadingLayout.cardOffset * side,
      cy + dy * ReadingLayout.cardOffset * side,
      ReadingLayout.card * side,
      perSide: 14,
    );
    final median = _median(samples);
    if (math.max(median.r, math.max(median.g, median.b)) >= _clipLevel) {
      clipped = true;
    }
    patches.add(median.linear);
  }
  if (clipped) return const ColorReading(problem: tooBrightProblem);

  final cardRgb = _mean(patches);
  if (cardRgb.luminance < 0.03) {
    return const ColorReading(problem: tooDarkProblem);
  }
  // a card under a warm lamp still isn't orange once the camera's had a go
  final lo = math.min(cardRgb.r, math.min(cardRgb.g, cardRgb.b));
  final hi = math.max(cardRgb.r, math.max(cardRgb.g, cardRgb.b));
  if (lo <= 0 || hi / lo > 3) {
    return const ColorReading(problem: notCardProblem);
  }

  // all four squares should be the same card in the same light
  final lums = [for (final p in patches) p.luminance];
  final evenness = lums.reduce(math.max) / lums.reduce(math.min);
  final cardChroma = cardRgb.chromaticity;
  final colorGap = patches
      .map((p) => p.chromaticity.distanceTo(cardChroma))
      .reduce(math.max);
  if (evenness > 1.4 || colorGap > 0.06) {
    return const ColorReading(problem: coveredProblem);
  }

  // the hair: drop the darkest fifth (gaps between strands) and the
  // lightest fifth (shine), average the rest by light, not by number
  final hairSamples = _sample(
    image,
    cx,
    cy,
    ReadingLayout.hair * side,
    perSide: 40,
  );
  final shiny =
      hairSamples
          .where((s) => math.max(s.r, math.max(s.g, s.b)) >= _clipLevel)
          .length /
      hairSamples.length;
  final hairLinear = [for (final s in hairSamples) s.linear]
    ..sort((a, b) => a.luminance.compareTo(b.luminance));
  final cut = hairLinear.length ~/ 5;
  final hairRgb = _mean(hairLinear.sublist(cut, hairLinear.length - cut));

  final cameraRgb = hairRgb.toRgb();
  if (deltaE2000Rgb(cameraRgb, cardRgb.toRgb()) < 4) {
    return const ColorReading(problem: noHairProblem);
  }

  // whatever the camera did to the card, undo on the hair
  final target = card.luminance;
  final corrected = _Rgb(
    hairRgb.r * target / cardRgb.r,
    hairRgb.g * target / cardRgb.g,
    hairRgb.b * target / cardRgb.b,
  );

  return ColorReading(
    rgb: corrected.toRgb(),
    cameraRgb: cameraRgb,
    warnings: [
      if (evenness > 1.15) unevenWarning,
      if (shiny > 0.2) shineWarning,
    ],
  );
}

/// 8-bit level counted as blown out
const _clipLevel = 250;

// ── srgb ───────────────────────────────────────────────────

final _toLinear = List<double>.generate(256, (i) {
  final c = i / 255;
  return c <= 0.04045
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
});

/// 0-255 -> 0-1 linear light
double srgbToLinear(int channel) => _toLinear[channel.clamp(0, 255)];

/// 0-1 linear light -> 0-255, clamped
int linearToSrgb(double v) {
  final c = v.clamp(0.0, 1.0);
  final s = c <= 0.0031308
      ? 12.92 * c
      : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;
  return (s * 255).round().clamp(0, 255);
}

// ── sampling ───────────────────────────────────────────────

/// one pixel, 8 bits a channel
class _Pixel {
  const _Pixel(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;

  _Rgb get linear => _Rgb(srgbToLinear(r), srgbToLinear(g), srgbToLinear(b));
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;

  double get luminance => 0.2126 * r + 0.7152 * g + 0.0722 * b;

  /// r and g as shares of the total, brightness taken out
  ({double r, double g}) get chromaticity {
    final sum = r + g + b;
    return sum <= 0 ? (r: 1 / 3, g: 1 / 3) : (r: r / sum, g: g / sum);
  }

  int toRgb() =>
      (linearToSrgb(r) << 16) | (linearToSrgb(g) << 8) | linearToSrgb(b);
}

extension on ({double r, double g}) {
  double distanceTo(({double r, double g}) o) =>
      math.max((r - o.r).abs(), (g - o.g).abs());
}

/// a grid of up to [perSide]² pixels across the square of [size] centred on
/// ([cx], [cy])
List<_Pixel> _sample(
  RgbaImage image,
  double cx,
  double cy,
  double size, {
  required int perSide,
}) {
  final n = math.max(1, math.min(perSide, size.floor()));
  final step = size / n;
  final x0 = cx - size / 2 + step / 2;
  final y0 = cy - size / 2 + step / 2;
  final out = <_Pixel>[];
  for (var j = 0; j < n; j++) {
    final y = (y0 + j * step).floor().clamp(0, image.height - 1);
    for (var i = 0; i < n; i++) {
      final x = (x0 + i * step).floor().clamp(0, image.width - 1);
      final o = (y * image.width + x) * 4;
      out.add(_Pixel(image.bytes[o], image.bytes[o + 1], image.bytes[o + 2]));
    }
  }
  return out;
}

_Pixel _median(List<_Pixel> px) {
  int mid(List<int> v) => (v..sort())[v.length ~/ 2];
  return _Pixel(
    mid([for (final p in px) p.r]),
    mid([for (final p in px) p.g]),
    mid([for (final p in px) p.b]),
  );
}

_Rgb _mean(List<_Rgb> v) {
  var r = 0.0, g = 0.0, b = 0.0;
  for (final x in v) {
    r += x.r;
    g += x.g;
    b += x.b;
  }
  return _Rgb(r / v.length, g / v.length, b / v.length);
}
