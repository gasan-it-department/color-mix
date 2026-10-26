import 'dart:math' as math;

/// CIELAB, D65 white. L 0-100.
class Lab {
  const Lab(this.l, this.a, this.b);

  final double l;
  final double a;
  final double b;

  @override
  String toString() =>
      'Lab(${l.toStringAsFixed(2)}, ${a.toStringAsFixed(2)}, ${b.toStringAsFixed(2)})';
}

/// 0xRRGGBB (sRGB) -> CIELAB
Lab labFromRgb(int rgb) {
  final r = _linear((rgb >> 16) & 0xFF);
  final g = _linear((rgb >> 8) & 0xFF);
  final b = _linear(rgb & 0xFF);

  // srgb -> xyz, D65
  final x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b;
  final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
  final z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b;

  final fx = _f(x / 0.95047);
  final fy = _f(y / 1.0);
  final fz = _f(z / 1.08883);

  return Lab(116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
}

double _linear(int channel) {
  final c = channel / 255;
  return c <= 0.04045
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

const _delta = 6 / 29;

double _f(double t) => t > _delta * _delta * _delta
    ? math.pow(t, 1 / 3).toDouble()
    : t / (3 * _delta * _delta) + 4 / 29;

/// CIEDE2000 colour difference (Sharma, Wu, Dalal 2005), kL = kC = kH = 1.
/// under ~2 most people can't tell two colours apart on screen.
double deltaE2000(Lab p, Lab q) {
  final c1 = math.sqrt(p.a * p.a + p.b * p.b);
  final c2 = math.sqrt(q.a * q.a + q.b * q.b);
  final cBar7 = _pow7((c1 + c2) / 2);
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + _pow25to7)));

  final a1 = (1 + g) * p.a;
  final a2 = (1 + g) * q.a;
  final c1p = math.sqrt(a1 * a1 + p.b * p.b);
  final c2p = math.sqrt(a2 * a2 + q.b * q.b);
  final h1p = _hueDegrees(p.b, a1);
  final h2p = _hueDegrees(q.b, a2);

  final dL = q.l - p.l;
  final dC = c2p - c1p;

  var dh = 0.0;
  if (c1p * c2p != 0) {
    dh = h2p - h1p;
    if (dh > 180) {
      dh -= 360;
    } else if (dh < -180) {
      dh += 360;
    }
  }
  final dH = 2 * math.sqrt(c1p * c2p) * math.sin(_rad(dh / 2));

  final lBar = (p.l + q.l) / 2;
  final cBar = (c1p + c2p) / 2;

  double hBar;
  if (c1p * c2p == 0) {
    hBar = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBar = (h1p + h2p) / 2;
  } else if (h1p + h2p < 360) {
    hBar = (h1p + h2p + 360) / 2;
  } else {
    hBar = (h1p + h2p - 360) / 2;
  }

  final t =
      1 -
      0.17 * math.cos(_rad(hBar - 30)) +
      0.24 * math.cos(_rad(2 * hBar)) +
      0.32 * math.cos(_rad(3 * hBar + 6)) -
      0.20 * math.cos(_rad(4 * hBar - 63));

  final dTheta = 30 * math.exp(-math.pow((hBar - 275) / 25, 2));
  final cBar7p = _pow7(cBar);
  final rc = 2 * math.sqrt(cBar7p / (cBar7p + _pow25to7));
  final lSq = (lBar - 50) * (lBar - 50);

  final sl = 1 + 0.015 * lSq / math.sqrt(20 + lSq);
  final sc = 1 + 0.045 * cBar;
  final sh = 1 + 0.015 * cBar * t;
  final rt = -math.sin(_rad(2 * dTheta)) * rc;

  final lTerm = dL / sl;
  final cTerm = dC / sc;
  final hTerm = dH / sh;

  return math.sqrt(
    lTerm * lTerm + cTerm * cTerm + hTerm * hTerm + rt * cTerm * hTerm,
  );
}

double deltaE2000Rgb(int rgb1, int rgb2) =>
    deltaE2000(labFromRgb(rgb1), labFromRgb(rgb2));

final double _pow25to7 = math.pow(25, 7).toDouble();

double _pow7(double v) => math.pow(v, 7).toDouble();

double _rad(double deg) => deg * math.pi / 180;

double _hueDegrees(double b, double a) {
  if (a == 0 && b == 0) return 0;
  final h = math.atan2(b, a) * 180 / math.pi;
  return h >= 0 ? h : h + 360;
}
