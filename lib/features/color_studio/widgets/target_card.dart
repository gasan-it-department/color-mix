import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/features/color_studio/widgets/recipe_panel.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

/// big swatch + numbers for the current target
class TargetCard extends ConsumerWidget {
  const TargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(colorTargetProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (target == null) {
      return const SectionCard(
        child: EmptyState(
          compact: true,
          icon: Icons.palette_outlined,
          title: 'No color picked',
          message: 'Choose a demo shade or make your own color.',
        ),
      );
    }

    final rgb = target.rgb;
    final shade = target.shade;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 132,
              decoration: BoxDecoration(
                color: colorFromRgb(rgb),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(target.name, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LabelTag(
                    target.isCustom ? 'Custom color' : 'Demo shade',
                    tone: TagTone.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Fact('HEX', hexFromRgb(rgb)),
            _Fact(
              'RGB',
              '${(rgb >> 16) & 0xFF}, ${(rgb >> 8) & 0xFF}, ${rgb & 0xFF}',
            ),
            if (shade?.levelTone != null) _Fact('Level', shade!.levelTone!),
            if (shade != null) _Fact('Family', categoryLabel(shade.category)),
            const SizedBox(height: 12),
            const _VisualTargetNote(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
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
        Icon(Icons.visibility_outlined, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Visual target only. The real result depends on the starting '
            'hair color, underlying pigment, porosity and the product.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

// ── phone strip ────────────────────────────────────────────

/// pinned above the picker on phones so the live colour is always in view
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

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: target == null
                    ? scheme.surfaceContainerHigh
                    : colorFromRgb(target.rgb),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: target == null
                  ? Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: scheme.onSurfaceVariant,
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
    );
  }
}

Future<void> showTargetDetails(BuildContext context) {
  // root navigator so the sheet covers the bottom bar too
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
          children: [TargetCard(), SizedBox(height: 12), RecipePanel()],
        ),
      ),
    ),
  );
}
