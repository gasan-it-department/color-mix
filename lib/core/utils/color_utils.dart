import 'dart:ui';

/// 0xRRGGBB -> opaque Color
Color colorFromRgb(int rgb) => Color(0xFF000000 | (rgb & 0xFFFFFF));

int rgbFromColor(Color color) => color.toARGB32() & 0xFFFFFF;

String hexFromRgb(int rgb) =>
    '#${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// 'B76E79', '#b76e79' or shorthand 'b6e' -> 0xRRGGBB, null if it isn't one
int? rgbFromHex(String input) {
  var s = input.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) return null;
  if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
  if (s.length != 6) return null;
  return int.parse(s, radix: 16);
}
