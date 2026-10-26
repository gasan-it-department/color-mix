import 'package:flutter/material.dart';

import 'package:colormix_studio/core/utils/color_utils.dart';

/// round swatch with a hairline so pale colours still show on white
class ColorSwatchDot extends StatelessWidget {
  const ColorSwatchDot({super.key, required this.rgb, this.size = 36});

  final int rgb;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorFromRgb(rgb),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
