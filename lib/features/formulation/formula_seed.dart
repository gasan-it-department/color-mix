import 'package:uuid/uuid.dart';

import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/features/formulation/formula_math.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

/// swatch per slot for colors the stylist adds by hand
const slotColors = [0xB07A5A, 0xC9A27E, 0x8E6A8A];

const slotNames = ['Color A', 'Color B', 'Color C'];

class SeedPart {
  const SeedPart({
    required this.id,
    required this.name,
    required this.displayRgb,
    this.percentHundredths,
  });

  final String id;
  final String name;
  final int displayRgb;

  /// null leaves the field empty
  final int? percentHundredths;
}

/// what the editor starts from: a new formula for the picked color (from its
/// demo recipe when there is one) or a saved formula
class FormulaSeed {
  const FormulaSeed({
    required this.id,
    required this.isSaved,
    required this.name,
    required this.targetRgb,
    required this.targetLabel,
    required this.dyeDg,
    required this.parts,
    required this.developerMode,
    this.presetId,
    this.isDemo = false,
    this.ratioHundredths,
    this.developerVolume,
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final bool isSaved;
  final String name;
  final int targetRgb;
  final String targetLabel;
  final String? presetId;
  final bool isDemo;
  final int dyeDg;
  final List<SeedPart> parts;
  final DeveloperMode developerMode;
  final int? ratioHundredths;
  final int? developerVolume;
  final String notes;
  final DateTime? createdAt;

  factory FormulaSeed.fromTarget(ColorTarget target, {required int dyeDg}) {
    final recipe = target.demoRecipe;
    final label = '${target.name} · ${hexFromRgb(target.rgb)}';

    if (recipe == null) {
      // manual formula: one color at 100% to start, developer left for the
      // stylist to choose
      return FormulaSeed(
        id: newId(),
        isSaved: false,
        name: target.name,
        targetRgb: target.rgb,
        targetLabel: label,
        presetId: target.shade?.id,
        dyeDg: dyeDg,
        parts: [
          SeedPart(
            id: newId(),
            name: slotNames[0],
            displayRgb: slotColors[0],
            percentHundredths: fullPercent,
          ),
        ],
        developerMode: DeveloperMode.unset,
      );
    }

    final ratio = recipe.developerRatio?.hundredths;
    return FormulaSeed(
      id: newId(),
      isSaved: false,
      name: recipe.name,
      targetRgb: target.rgb,
      targetLabel: label,
      presetId: target.shade?.id,
      isDemo: true,
      dyeDg: dyeDg,
      parts: [
        for (final p in recipe.parts)
          SeedPart(
            id: newId(),
            name: p.name,
            displayRgb: p.displayRgb,
            percentHundredths: p.percentHundredths,
          ),
      ],
      developerMode: _modeFor(ratio),
      ratioHundredths: ratio,
    );
  }

  factory FormulaSeed.fromFormula(ColorFormula f) {
    final ratio = f.developerRatio?.hundredths;
    final shade = f.presetId == null ? null : demoShadeById(f.presetId!);
    return FormulaSeed(
      id: f.id,
      isSaved: true,
      name: f.name,
      targetRgb: f.targetRgb,
      targetLabel: shade == null
          ? hexFromRgb(f.targetRgb)
          : '${shade.name} · ${hexFromRgb(f.targetRgb)}',
      presetId: f.presetId,
      isDemo: f.isDemo,
      dyeDg: f.totalDyeDg,
      parts: [
        for (final i in f.ingredients)
          SeedPart(
            id: i.id,
            name: i.name,
            displayRgb: i.displayRgb,
            percentHundredths: i.percentHundredths,
          ),
      ],
      developerMode: _modeFor(ratio),
      ratioHundredths: ratio,
      developerVolume: f.developerVolume,
      notes: f.notes ?? '',
      createdAt: f.createdAt,
    );
  }

  static DeveloperMode _modeFor(int? ratio) {
    if (ratio == null) return DeveloperMode.none;
    final isPreset = DeveloperRatio.presets.any((r) => r.hundredths == ratio);
    return isPreset ? DeveloperMode.preset : DeveloperMode.custom;
  }
}
