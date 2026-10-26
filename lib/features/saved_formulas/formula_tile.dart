import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';

class FormulaTile extends StatelessWidget {
  const FormulaTile({super.key, required this.formula, this.onTap});

  final ColorFormula formula;
  final VoidCallback? onTap;

  static final _date = DateFormat.MMMd();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = formula;
    final developer = f.developerRatio == null
        ? 'no developer'
        : '${f.developerRatio!.label} developer';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: ColorSwatchDot(rgb: f.targetRgb),
      title: Row(
        children: [
          Flexible(
            child: Text(
              f.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (f.isDemo) ...[const SizedBox(width: 8), const _DemoTag()],
        ],
      ),
      subtitle: Text(
        '${formatDecigrams(f.totalDyeDg)} dye · $developer',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _date.format(f.updatedAt),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DemoTag extends StatelessWidget {
  const _DemoTag();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Demo',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
