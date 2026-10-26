import 'package:colormix_studio/core/utils/color_science.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/models/demo_recipe.dart';
import 'package:colormix_studio/shared/models/hair_color.dart';

// demonstration data. swatches are picked by eye for the screen and the
// level/tone numbers are rough guides, the recipes are made up.

const demoShades = <HairColor>[
  // naturals
  HairColor(
    id: 'natural_black',
    name: 'Natural Black',
    rgb: 0x1E1B1A,
    category: HairColorCategory.natural,
    level: 1,
    tone: '0',
  ),
  HairColor(
    id: 'blue_black',
    name: 'Blue Black',
    rgb: 0x1B2030,
    category: HairColorCategory.natural,
    level: 1,
    tone: '1',
  ),
  // browns
  HairColor(
    id: 'dark_brown',
    name: 'Dark Brown',
    rgb: 0x3B2A22,
    category: HairColorCategory.brown,
    level: 3,
    tone: '0',
  ),
  HairColor(
    id: 'chocolate_brown',
    name: 'Chocolate Brown',
    rgb: 0x4E3326,
    category: HairColorCategory.brown,
    level: 4,
    tone: '7',
  ),
  HairColor(
    id: 'ash_brown',
    name: 'Ash Brown',
    rgb: 0x5E5349,
    category: HairColorCategory.brown,
    level: 5,
    tone: '1',
  ),
  HairColor(
    id: 'golden_brown',
    name: 'Golden Brown',
    rgb: 0x7A5634,
    category: HairColorCategory.brown,
    level: 6,
    tone: '3',
  ),
  HairColor(
    id: 'copper_brown',
    name: 'Copper Brown',
    rgb: 0x8A4A2B,
    category: HairColorCategory.brown,
    level: 6,
    tone: '4',
    demoFormulaId: 'copper_brown_demo',
  ),
  // reds
  HairColor(
    id: 'mahogany',
    name: 'Mahogany',
    rgb: 0x6B2E2A,
    category: HairColorCategory.red,
    level: 5,
    tone: '5',
  ),
  HairColor(
    id: 'burgundy',
    name: 'Burgundy',
    rgb: 0x6A1E33,
    category: HairColorCategory.red,
    level: 4,
    tone: '62',
    demoFormulaId: 'burgundy_demo',
  ),
  // blondes
  HairColor(
    id: 'ash_blonde',
    name: 'Ash Blonde',
    rgb: 0xB9A98C,
    category: HairColorCategory.blonde,
    level: 8,
    tone: '1',
    demoFormulaId: 'ash_blonde_demo',
  ),
  HairColor(
    id: 'platinum_blonde',
    name: 'Platinum Blonde',
    rgb: 0xE4DAC7,
    category: HairColorCategory.blonde,
    level: 10,
    tone: '1',
  ),
  // grays
  HairColor(
    id: 'silver_gray',
    name: 'Silver Gray',
    rgb: 0xB8B9B6,
    category: HairColorCategory.gray,
  ),
  // fashion
  HairColor(
    id: 'rose_gold',
    name: 'Rose Gold',
    rgb: 0xB76E79,
    category: HairColorCategory.fashion,
    demoFormulaId: 'rose_gold_demo',
  ),
  HairColor(
    id: 'pastel_pink',
    name: 'Pastel Pink',
    rgb: 0xE8B4C0,
    category: HairColorCategory.fashion,
  ),
  HairColor(
    id: 'violet',
    name: 'Violet',
    rgb: 0x6E4A8C,
    category: HairColorCategory.fashion,
  ),
];

const demoRecipes = <DemoRecipe>[
  // the blueprint's worked example: 50/30/20 with 1:1
  DemoRecipe(
    id: 'rose_gold_demo',
    presetId: 'rose_gold',
    name: 'Rose Gold Demo',
    developerRatio: DeveloperRatio(100),
    parts: [
      DemoPart(name: 'Color A', percentHundredths: 5000, displayRgb: 0xC9868F),
      DemoPart(name: 'Color B', percentHundredths: 3000, displayRgb: 0xD6AE7B),
      DemoPart(name: 'Color C', percentHundredths: 2000, displayRgb: 0x9C7AA6),
    ],
  ),
  DemoRecipe(
    id: 'ash_blonde_demo',
    presetId: 'ash_blonde',
    name: 'Ash Blonde Demo',
    developerRatio: DeveloperRatio(150),
    parts: [
      DemoPart(name: 'Color A', percentHundredths: 6000, displayRgb: 0xB8AE98),
      DemoPart(name: 'Color B', percentHundredths: 3000, displayRgb: 0xC9AE84),
      DemoPart(name: 'Color C', percentHundredths: 1000, displayRgb: 0x8F86A8),
    ],
  ),
  // two parts on purpose, the calculator takes one to three
  DemoRecipe(
    id: 'copper_brown_demo',
    presetId: 'copper_brown',
    name: 'Copper Brown Demo',
    developerRatio: DeveloperRatio(100),
    parts: [
      DemoPart(name: 'Color A', percentHundredths: 6000, displayRgb: 0x9A5A33),
      DemoPart(name: 'Color B', percentHundredths: 4000, displayRgb: 0x6A4A35),
    ],
  ),
  DemoRecipe(
    id: 'burgundy_demo',
    presetId: 'burgundy',
    name: 'Burgundy Demo',
    developerRatio: DeveloperRatio(200),
    parts: [
      DemoPart(name: 'Color A', percentHundredths: 5000, displayRgb: 0x7A2240),
      DemoPart(name: 'Color B', percentHundredths: 3000, displayRgb: 0x9A2A2A),
      DemoPart(name: 'Color C', percentHundredths: 2000, displayRgb: 0x4A3028),
    ],
  ),
];

HairColor? demoShadeById(String id) {
  for (final s in demoShades) {
    if (s.id == id) return s;
  }
  return null;
}

DemoRecipe? demoRecipeById(String? id) {
  if (id == null) return null;
  for (final r in demoRecipes) {
    if (r.id == id) return r;
  }
  return null;
}

String categoryLabel(HairColorCategory c) => switch (c) {
  HairColorCategory.natural => 'Naturals',
  HairColorCategory.brown => 'Browns',
  HairColorCategory.red => 'Reds',
  HairColorCategory.blonde => 'Blondes',
  HairColorCategory.gray => 'Grays',
  HairColorCategory.fashion => 'Fashion',
};

// ── nearest shade ──────────────────────────────────────────

final Map<String, Lab> _shadeLab = {
  for (final s in demoShades) s.id: labFromRgb(s.rgb),
};

/// closest demo shade by CIEDE2000. screen colours only, it says nothing
/// about how a dye would turn out
({HairColor shade, double deltaE}) nearestDemoShade(int rgb) {
  final target = labFromRgb(rgb);
  HairColor best = demoShades.first;
  var bestDe = double.infinity;
  for (final s in demoShades) {
    final de = deltaE2000(target, _shadeLab[s.id]!);
    if (de < bestDe) {
      best = s;
      bestDe = de;
    }
  }
  return (shade: best, deltaE: bestDe);
}

/// plain words for a ΔE00, rough bands
String closenessLabel(double deltaE) {
  if (deltaE < 2) return 'almost the same';
  if (deltaE < 5) return 'close';
  if (deltaE < 12) return 'similar';
  return 'not very close';
}
