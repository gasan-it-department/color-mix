import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/models/demo_recipe.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

/// what we know about making the target: a demo recipe, or nothing and the
/// closest demo shade for reference
class RecipePanel extends ConsumerWidget {
  const RecipePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(colorTargetProvider);
    if (target == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final recipe = target.demoRecipe;

    return SectionCard(
      title: recipe != null ? 'Demo recipe' : 'Formula',
      trailing: recipe != null
          ? const LabelTag('Demo only', tone: TagTone.warning)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recipe != null)
            _RecipeBody(recipe: recipe)
          else if (target.isCustom) ...[
            Text(
              'Custom colors have no recipe. You\'ll enter the formula '
              'yourself.',
              style: muted,
            ),
            const SizedBox(height: 12),
            _NearestShade(rgb: target.rgb),
          ] else
            Text(
              'No demo recipe for this shade. You\'ll enter the formula '
              'yourself.',
              style: muted,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _createFormula(context),
            child: const Text('Create formula'),
          ),
        ],
      ),
    );
  }
}

void _createFormula(BuildContext context) {
  final router = GoRouter.of(context);
  // on phones this panel sits in the details sheet, close it first
  if (ModalRoute.of(context) is ModalBottomSheetRoute) Navigator.pop(context);
  router.push(Routes.formulaNew);
}

class _RecipeBody extends StatelessWidget {
  const _RecipeBody({required this.recipe});

  final DemoRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final ratio = recipe.developerRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in recipe.parts)
          _Line(
            leading: ColorSwatchDot(rgb: p.displayRgb, size: 22),
            label: p.name,
            value: formatPercentHundredths(p.percentHundredths),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(),
        ),
        _Line(
          leading: Icon(Icons.water_drop_outlined, size: 22, color: muted),
          label: 'Developer',
          value: _developerText(ratio),
        ),
        const SizedBox(height: 10),
        Text(
          'Example percentages for trying the app, not a product formula. '
          'Follow the dye maker\'s mixing instructions.',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }

  static String _developerText(DeveloperRatio? r) =>
      r == null ? 'None' : '${r.label} by weight';
}

class _Line extends StatelessWidget {
  const _Line({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 22, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearestShade extends ConsumerWidget {
  const _NearestShade({required this.rgb});

  final int rgb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nearest = nearestDemoShade(rgb);
    final hasRecipe = nearest.shade.demoFormulaId != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ColorSwatchDot(rgb: nearest.shade.rgb, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Closest demo shade on screen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${nearest.shade.name} · ${closenessLabel(nearest.deltaE)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasRecipe)
                  Text(
                    'Has a demo recipe',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(colorTargetProvider.notifier).pickShade(nearest.shade);
              ref.read(studioModeProvider.notifier).set(StudioMode.palette);
            },
            child: const Text('Use it'),
          ),
        ],
      ),
    );
  }
}
