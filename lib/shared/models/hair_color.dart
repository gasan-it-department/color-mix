enum HairColorCategory { natural, brown, red, blonde, gray, fashion }

/// a visual target colour. never a promise of what the dye will do on hair.
class HairColor {
  const HairColor({
    required this.id,
    required this.name,
    required this.rgb,
    required this.category,
    this.level,
    this.tone,
    this.demoFormulaId,
  });

  final String id;
  final String name;

  /// 0xRRGGBB
  final int rgb;
  final HairColorCategory category;

  /// depth 1-10, the way stylists name shades (7 in 7.43)
  final int? level;

  /// reflect digits after the level ('43' in 7.43)
  final String? tone;
  final String? demoFormulaId;

  int get red => (rgb >> 16) & 0xFF;
  int get green => (rgb >> 8) & 0xFF;
  int get blue => rgb & 0xFF;

  String get hexValue =>
      '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

  String? get levelTone =>
      level == null ? null : (tone == null ? '$level' : '$level.$tone');
}
