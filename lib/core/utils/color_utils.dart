import 'dart:ui';

/// 0xRRGGBB -> opaque Color
Color colorFromRgb(int rgb) => Color(0xFF000000 | (rgb & 0xFFFFFF));

int rgbFromColor(Color color) => color.toARGB32() & 0xFFFFFF;

String hexFromRgb(int rgb) =>
    '#${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
