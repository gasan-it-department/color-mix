import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';
import 'package:colormix_studio/shared/models/demo_recipe.dart';
import 'package:colormix_studio/shared/models/hair_color.dart';

/// the colour on screen the stylist is aiming for. a visual target only.
class ColorTarget {
  const ColorTarget({required this.rgb, required this.name, this.shade});

  final int rgb;
  final String name;

  /// the demo shade it came from, null for a custom colour
  final HairColor? shade;

  bool get isCustom => shade == null;

  DemoRecipe? get demoRecipe => demoRecipeById(shade?.demoFormulaId);
}

final colorTargetProvider = NotifierProvider<ColorTargetNotifier, ColorTarget?>(
  ColorTargetNotifier.new,
);

class ColorTargetNotifier extends Notifier<ColorTarget?> {
  @override
  ColorTarget? build() => null;

  void pickShade(HairColor shade) {
    state = ColorTarget(rgb: shade.rgb, name: shade.name, shade: shade);
  }

  void pickCustom(int rgb) {
    final current = state;
    if (current != null && current.isCustom && current.rgb == rgb) return;
    state = ColorTarget(
      rgb: rgb,
      name: ColorTools.nameThatColor(colorFromRgb(rgb)),
    );
  }

  void clear() => state = null;
}

enum StudioMode { palette, custom }

final studioModeProvider = NotifierProvider<StudioModeNotifier, StudioMode>(
  StudioModeNotifier.new,
);

class StudioModeNotifier extends Notifier<StudioMode> {
  @override
  StudioMode build() => StudioMode.palette;

  void set(StudioMode mode) => state = mode;
}
