import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

class FormulaTile extends StatelessWidget {
  const FormulaTile({super.key, required this.formula, this.onTap, this.menu});

  final ColorFormula formula;
  final VoidCallback? onTap;

  /// goes after the date, the saved list puts its ⋮ menu here
  final Widget? menu;

  static final _date = DateFormat.MMMd();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = formula;
    final developer = f.developerRatio == null
        ? 'no developer'
        : '${f.developerRatio!.label} developer';
    final date = _date.format(f.updatedAt);
    // on a phone with the menu there's no room left for the date on the
    // right, it joins the subtitle and the name gets the width
    final dateBelow =
        menu != null && MediaQuery.sizeOf(context).width < Breakpoints.rail;

    return ListTile(
      // opens the editor unless the caller wants something else
      onTap: onTap ?? () => context.push(Routes.formula(f.id)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: ColorSwatchDot(rgb: f.targetRgb),
      title: Row(
        children: [
          Flexible(
            // two lines so "X" and "X (copy)" don't both end in "X…"
            child: Text(
              f.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (f.isDemo) ...[
            const SizedBox(width: 8),
            const LabelTag('Demo', tone: TagTone.warning),
          ],
        ],
      ),
      subtitle: Text(
        [
          '${formatDecigrams(f.totalDyeDg)} dye',
          developer,
          if (dateBelow) date,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!dateBelow)
            Text(
              date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ?menu,
        ],
      ),
    );
  }
}
