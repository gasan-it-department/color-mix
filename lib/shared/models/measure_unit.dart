import 'package:colormix_studio/core/utils/weight_format.dart';

/// what a formula's amounts are typed and shown in. underneath everything is
/// still grams: the scale weighs grams, the maths and the ratios are by
/// weight. a mass unit converts exactly. a volume unit goes through each
/// product's density (g per mL), which only the product sheet really knows
enum MeasureUnit {
  g(symbol: 'g', label: 'grams', decimals: 1, step: 5, example: '60 or 62.5'),
  oz(
    symbol: 'oz',
    label: 'ounces',
    decimals: 2,
    step: 0.25,
    example: '2 or 2.25',
  ),
  ml(
    symbol: 'mL',
    label: 'mL',
    decimals: 1,
    step: 5,
    example: '60 or 62.5',
    isVolume: true,
  ),
  flOz(
    symbol: 'fl oz',
    label: 'fl oz',
    decimals: 2,
    step: 0.25,
    example: '2 or 2.25',
    isVolume: true,
  );

  const MeasureUnit({
    required this.symbol,
    required this.label,
    required this.decimals,
    required this.step,
    required this.example,
    this.isVolume = false,
  });

  final String symbol;

  /// for messages: "Enter the dye amount in ounces". not `name`, that one
  /// is the enum's own and goes in the db, settings and backups
  final String label;

  /// places shown and accepted when typed
  final int decimals;

  /// what the editor's − and + buttons move by
  final double step;
  final String example;

  /// mL and fl oz: needs a density to become grams
  final bool isVolume;

  static const _mgPerOz = 28349.523125;
  static const _mlPerFlOz = 29.5735295625;

  /// milligrams in one of this unit, for a product of [densityMilli]
  /// (g per mL × 1000; a mix of colors can land between whole figures).
  /// mass units ignore the density
  double mgPerUnit(num densityMilli) => switch (this) {
    g => 1000,
    oz => _mgPerOz,
    ml => densityMilli.toDouble(),
    flOz => _mlPerFlOz * densityMilli,
  };

  double fromMg(int mg, {num densityMilli = 1000}) =>
      mg / mgPerUnit(densityMilli);

  int toMg(double value, {num densityMilli = 1000}) =>
      (value * mgPerUnit(densityMilli)).round();

  /// '30.0 g', '1.06 oz', '30.0 mL'. grams keep the app's own rounding so
  /// they always match what the scale screens say
  String format(int mg, {int densityMilli = 1000, bool withSymbol = true}) {
    final text = this == g
        ? formatMilligrams(mg, unit: false)
        : _fixed(fromMg(mg, densityMilli: densityMilli));
    return withSymbol ? '$text $symbol' : text;
  }

  String formatDg(int dg, {int densityMilli = 1000}) =>
      format(dg * 100, densityMilli: densityMilli);

  /// a value already in this unit: '61.3 mL'
  String formatValue(double value) => '${_fixed(value)} $symbol';

  /// for putting a number back in a text field: '60', '2.12', '62.5'
  String fieldText(int mg, {int densityMilli = 1000}) =>
      _trim(format(mg, densityMilli: densityMilli, withSymbol: false));

  /// the same for a value already in this unit
  String fieldTextOf(double value) => _trim(_fixed(value));

  static String _trim(String text) =>
      text.contains('.') ? text.replaceFirst(RegExp(r'\.?0+$'), '') : text;

  /// a typed amount, null if it isn't a plain number with at most
  /// [decimals] places. a comma works as the point
  double? parse(String text) {
    final t = text.trim().replaceAll(',', '.');
    final m = RegExp(r'^(\d{1,6})(?:\.(\d*))?$').firstMatch(t);
    if (m == null) return null;
    if ((m.group(2) ?? '').length > decimals) return null;
    return double.parse(t.endsWith('.') ? t.substring(0, t.length - 1) : t);
  }

  String _fixed(double v) {
    final s = v.toStringAsFixed(decimals);
    // a hair under zero reads 0, not -0.00
    return RegExp(r'^-0\.?0*$').hasMatch(s) ? s.substring(1) : s;
  }
}

/// density bounds the editor accepts, g per mL × 1000. a loose powder can
/// be lighter than half, nothing a salon uses is three times water
const minDensityMilli = 200;
const maxDensityMilli = 3000;

/// '1.00' from 1000
String densityText(int milli) => (milli / 1000).toStringAsFixed(2);

/// '1.05' -> 1050, null when it isn't a number with up to 3 places
int? parseDensityMilli(String text) {
  final t = text.trim().replaceAll(',', '.');
  final m = RegExp(r'^(\d{1,2})(?:\.(\d{0,3}))?$').firstMatch(t);
  if (m == null) return null;
  final frac = (m.group(2) ?? '').padRight(3, '0');
  return int.parse(m.group(1)!) * 1000 + int.parse(frac);
}
