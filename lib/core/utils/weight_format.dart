/// 300 -> '30.0 g'
String formatDecigrams(int dg, {bool unit = true}) {
  final sign = dg < 0 ? '-' : '';
  final abs = dg.abs();
  final text = '$sign${abs ~/ 10}.${abs % 10}';
  return unit ? '$text g' : text;
}

/// rounds half away from zero to the nearest 0.1 g
int milligramsToDecigrams(int mg) {
  final abs = (mg.abs() + 50) ~/ 100;
  // on web ints are js numbers, and -0 prints as "-0.0"
  if (abs == 0) return 0;
  return mg < 0 ? -abs : abs;
}

String formatMilligrams(int mg, {bool unit = true}) =>
    formatDecigrams(milligramsToDecigrams(mg), unit: unit);

/// 5000 -> '50%', 3333 -> '33.33%', 3330 -> '33.3%'
String formatPercentHundredths(int hundredths) {
  final whole = hundredths ~/ 100;
  final frac = hundredths % 100;
  if (frac == 0) return '$whole%';
  if (frac % 10 == 0) return '$whole.${frac ~/ 10}%';
  return '$whole.${frac.toString().padLeft(2, '0')}%';
}
