import 'package:colormix_studio/shared/models/color_formula.dart';

class DemoPart {
  const DemoPart({
    required this.name,
    required this.percentHundredths,
    required this.displayRgb,
  });

  final String name;
  final int percentHundredths;
  final int displayRgb;
}

/// example percentages for trying the app. not tested with real products,
/// so it's never shown without the demo label.
class DemoRecipe {
  const DemoRecipe({
    required this.id,
    required this.presetId,
    required this.name,
    required this.parts,
    this.developerRatio,
  });

  final String id;
  final String presetId;
  final String name;

  /// one to three dye parts, Color A/B/C
  final List<DemoPart> parts;

  /// null = no developer
  final DeveloperRatio? developerRatio;

  int get totalPercentHundredths =>
      parts.fold(0, (sum, p) => sum + p.percentHundredths);
}
