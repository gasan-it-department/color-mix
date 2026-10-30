import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

class FormulaTile extends StatelessWidget {
  const FormulaTile({super.key, required this.formula, this.onTap, this.menu});

  final ColorFormula formula;
  final VoidCallback? onTap;

  /// The saved list supplies the existing weigh, duplicate and delete menu.
  final Widget? menu;

  static final _date = DateFormat.MMMd();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final f = formula;
    final developer = f.developerRatio == null
        ? 'no developer'
        : '${f.developerRatio!.label} developer';
    final date = _date.format(f.updatedAt);

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push(Routes.formula(f.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 520;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: wide ? 64 : 48,
                      height: wide ? 76 : 66,
                      decoration: BoxDecoration(
                        color: colorFromRgb(f.targetRgb),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            for (final ingredient in f.ingredients)
                              Expanded(
                                flex: ingredient.percentHundredths > 0
                                    ? ingredient.percentHundredths
                                    : 1,
                                child: ColoredBox(
                                  color: colorFromRgb(ingredient.displayRgb),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${f.showDye()} dye · $developer',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (f.isDemo)
                              const LabelTag('Demo', tone: TagTone.warning),
                            Text(
                              'Updated $date',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          f.showMixture(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'total mixture',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (menu != null) ...[
                    const SizedBox(width: 4),
                    menu!,
                  ] else ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
