import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';
import 'package:colormix_studio/shared/models/hair_color.dart';

/// A physical swatch-book layout. The sample itself is always the exact RGB
/// color; selection and recipe marks sit outside that color reference.
class PaletteGrid extends ConsumerWidget {
  const PaletteGrid({super.key});

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(
      colorTargetProvider.select((t) => t?.shade?.id),
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 440;
        final minTile = compact ? 98.0 : 116.0;
        final cols = math.max(
          1,
          ((c.maxWidth + _gap) / (minTile * textScale + _gap)).floor(),
        );
        final tileWidth = (c.maxWidth - _gap * (cols - 1)) / cols;
        final groups = [
          for (final cat in HairColorCategory.values)
            (cat, demoShades.where((s) => s.category == cat).toList()),
        ].where((g) => g.$2.isNotEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, (cat, shades)) in groups.indexed) ...[
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 20, bottom: 10),
                child: Row(
                  children: [
                    Text(categoryLabel(cat), style: theme.textTheme.titleSmall),
                    const SizedBox(width: 10),
                    Text(
                      shades.length.toString().padLeft(2, '0'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                  ],
                ),
              ),
              Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (final s in shades)
                    SizedBox(
                      width: tileWidth,
                      child: _ShadeTile(
                        shade: s,
                        compact: compact,
                        selected: s.id == selectedId,
                        onTap: () =>
                            ref.read(colorTargetProvider.notifier).pickShade(s),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ShadeTile extends StatelessWidget {
  const _ShadeTile({
    required this.shade,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final HairColor shade;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasRecipe = shade.demoFormulaId != null;
    final nameStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: scheme.onSurface,
    );
    final scaledName = MediaQuery.textScalerOf(context)
        .scale(nameStyle?.fontSize ?? 14);

    return Semantics(
      selected: selected,
      button: true,
      label: [
        shade.name,
        if (shade.levelTone != null) 'level ${shade.levelTone}',
        if (hasRecipe) 'has a demo recipe',
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: compact ? 60 : 96,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colorFromRgb(shade.rgb),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: scaledName * 1.2 * 2 + 2,
                      child: Text(
                        shade.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shade.levelTone != null
                                ? 'Level ${shade.levelTone}'
                                : shade.hexValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        if (selected || hasRecipe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            selected ? Icons.check_circle : Icons.receipt_long,
                            size: 14,
                            color: selected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
