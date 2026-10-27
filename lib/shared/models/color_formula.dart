// weights are whole decigrams (0.1 g) and percentages whole hundredths of a
// percent (10000 = 100%) so the maths stays exact

import 'package:colormix_studio/shared/models/product_form.dart';

export 'package:colormix_studio/shared/models/product_form.dart';

/// developer parts per one part dye, by weight. 150 = 1:1.5
class DeveloperRatio {
  const DeveloperRatio(this.hundredths) : assert(hundredths > 0);

  final int hundredths;

  static const presets = [
    DeveloperRatio(100),
    DeveloperRatio(150),
    DeveloperRatio(200),
  ];

  String get label {
    final whole = hundredths ~/ 100;
    final frac = hundredths % 100;
    if (frac == 0) return '1:$whole';
    final digits = frac % 10 == 0
        ? '${frac ~/ 10}'
        : frac.toString().padLeft(2, '0');
    return '1:$whole.$digits';
  }

  @override
  bool operator ==(Object other) =>
      other is DeveloperRatio && other.hundredths == hundredths;

  @override
  int get hashCode => hundredths.hashCode;

  @override
  String toString() => label;
}

class FormulaIngredient {
  const FormulaIngredient({
    required this.id,
    required this.name,
    required this.percentHundredths,
    required this.requiredDg,
    required this.displayRgb,
    this.form = ProductForm.cream,
  });

  final String id;

  /// 'Color A' until the stylist renames it to the real product
  final String name;
  final int percentHundredths;
  final int requiredDg;

  /// swatch colour for the ui only, 0xRRGGBB
  final int displayRgb;

  /// cream, liquid or powder: how it pours, still weighed in grams
  final ProductForm form;

  FormulaIngredient copyWith({
    String? name,
    int? percentHundredths,
    int? requiredDg,
    int? displayRgb,
    ProductForm? form,
  }) {
    return FormulaIngredient(
      id: id,
      name: name ?? this.name,
      percentHundredths: percentHundredths ?? this.percentHundredths,
      requiredDg: requiredDg ?? this.requiredDg,
      displayRgb: displayRgb ?? this.displayRgb,
      form: form ?? this.form,
    );
  }
}

class ColorFormula {
  const ColorFormula({
    required this.id,
    required this.name,
    required this.targetRgb,
    required this.ingredients,
    required this.totalDyeDg,
    required this.developerDg,
    required this.totalMixtureDg,
    required this.createdAt,
    required this.updatedAt,
    this.presetId,
    this.isDemo = false,
    this.developerRatio,
    this.developerVolume,
    this.developerForm = ProductForm.cream,
    this.notes,
  });

  final String id;
  final String name;
  final int targetRgb;
  final String? presetId;

  /// demonstration recipe, not a product-validated one
  final bool isDemo;
  final List<FormulaIngredient> ingredients;
  final int totalDyeDg;

  /// null means no developer
  final DeveloperRatio? developerRatio;

  /// 10/20/30/40 vol as printed on the bottle, recorded only
  final int? developerVolume;

  /// cream or liquid developer, for the pour hints
  final ProductForm developerForm;
  final int developerDg;
  final int totalMixtureDg;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasDeveloper => developerRatio != null;

  ColorFormula copyWith({
    String? name,
    int? targetRgb,
    List<FormulaIngredient>? ingredients,
    int? totalDyeDg,
    DeveloperRatio? Function()? developerRatio,
    int? Function()? developerVolume,
    ProductForm? developerForm,
    int? developerDg,
    int? totalMixtureDg,
    String? Function()? notes,
    bool? isDemo,
    DateTime? updatedAt,
  }) {
    return ColorFormula(
      id: id,
      name: name ?? this.name,
      targetRgb: targetRgb ?? this.targetRgb,
      presetId: presetId,
      isDemo: isDemo ?? this.isDemo,
      ingredients: ingredients ?? this.ingredients,
      totalDyeDg: totalDyeDg ?? this.totalDyeDg,
      developerRatio: developerRatio != null
          ? developerRatio()
          : this.developerRatio,
      developerVolume: developerVolume != null
          ? developerVolume()
          : this.developerVolume,
      developerForm: developerForm ?? this.developerForm,
      developerDg: developerDg ?? this.developerDg,
      totalMixtureDg: totalMixtureDg ?? this.totalMixtureDg,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
