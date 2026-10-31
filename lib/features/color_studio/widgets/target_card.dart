import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/features/color_studio/widgets/recipe_panel.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

/// A color reference with its exact digital values. Dye colors never inherit
/// interface tints, shadows or decorative overlays.
class TargetCard extends ConsumerWidget {
  const TargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(colorTargetProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (target == null) return const _UnselectedTarget();

    final rgb = target.rgb;
    final shade = target.shade;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 132,
              decoration: BoxDecoration(
                color: colorFromRgb(rgb),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              target.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: LabelTag(
                target.isCustom ? 'Custom color' : 'Demo shade',
                tone: TagTone.accent,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, c) {
                final factWidth = (c.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: factWidth,
                      child: _Fact('HEX', hexFromRgb(rgb)),
                    ),
                    SizedBox(
                      width: factWidth,
                      child: _Fact(
                        'RGB',
                        '${(rgb >> 16) & 0xFF}, ${(rgb >> 8) & 0xFF}, ${rgb & 0xFF}',
                      ),
                    ),
                    if (shade?.levelTone != null)
                      SizedBox(
                        width: factWidth,
                        child: _Fact('Level', shade!.levelTone!),
                      ),
                    if (shade != null)
                      SizedBox(
                        width: factWidth,
                        child: _Fact('Family', categoryLabel(shade.category)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 12),
            const _VisualTargetNote(),
          ],
        ),
      ),
    );
  }
}

class _UnselectedTarget extends StatelessWidget {
  const _UnselectedTarget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR COLOR TARGET', style: context.type.eyebrow),
            const SizedBox(height: 24),
            ExcludeSemantics(
              child: SizedBox(
                height: 136,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Transform.rotate(
                        angle: -0.2,
                        child: Container(
                          width: 104,
                          height: 124,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(22, 0),
                        child: Transform.rotate(
                          angle: 0.14,
                          child: Container(
                            width: 104,
                            height: 124,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(Radii.md),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: scheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(
                                        Radii.sm,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(color: scheme.outlineVariant),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No color picked',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a demo shade or make your own color.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Your target and recipe will appear here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _VisualTargetNote extends StatelessWidget {
  const _VisualTargetNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.visibility_outlined, size: 16, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Visual target only. Results depend on the starting hair, '
            'underlying pigment, porosity and product.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

/// Pinned above the picker on phones, with the recipe one tap away.
class TargetStrip extends ConsumerWidget {
  const TargetStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(colorTargetProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final subtitle = switch (target) {
      null => 'Choose a demo shade or make your own',
      final t when t.isCustom => '${hexFromRgb(t.rgb)} · Custom color',
      final t when t.demoRecipe != null => '${hexFromRgb(t.rgb)} · Demo recipe',
      final t => '${hexFromRgb(t.rgb)} · Demo shade',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: target == null
                      ? scheme.primaryContainer
                      : colorFromRgb(target.rgb),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: target == null
                    ? Icon(
                        Icons.colorize_outlined,
                        size: 20,
                        color: scheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      target?.name ?? 'No color picked',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (target != null)
                TextButton(
                  onPressed: () => showTargetDetails(context),
                  child: const Text('Details'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showTargetDetails(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [TargetCard(), SizedBox(height: 16), RecipePanel()],
        ),
      ),
    ),
  );
}
