import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';
import 'package:colormix_studio/shared/models/hair_color.dart';

/// demo shades grouped by family
class PaletteGrid extends ConsumerWidget {
  const PaletteGrid({super.key});

  static const _gap = 8.0;
  static const _minTile = 112.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(
      colorTargetProvider.select((t) => t?.shade?.id),
    );
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        final cols = math.max(
          3,
          ((c.maxWidth + _gap) / (_minTile + _gap)).floor(),
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
                padding: EdgeInsets.only(top: i == 0 ? 0 : 20, bottom: 8),
                child: Text(
                  categoryLabel(cat),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
    required this.selected,
    required this.onTap,
  });

  final HairColor shade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasRecipe = shade.demoFormulaId != null;
    final nameStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      height: 1.25,
      color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
    );

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
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorFromRgb(shade.rgb),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    if (hasRecipe)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            size: 13,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  // two lines kept even for short names so rows line up
                  child: SizedBox(
                    height: (nameStyle?.fontSize ?? 14) * 1.25 * 2 + 2,
                    child: Text(
                      shade.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Text(
                    shade.levelTone != null
                        ? 'Level ${shade.levelTone}'
                        : shade.hexValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
