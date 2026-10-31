import 'package:flutter/material.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/product_form.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';
import 'package:colormix_studio/core/widgets/app_page.dart';

// small pieces shared by the weighing panels

/// (background, foreground) for a pour zone: neutral while pouring, amber
/// close, green on target, red over
(Color, Color) zoneColors(BuildContext context, PourZone zone) {
  final scheme = Theme.of(context).colorScheme;
  final status = context.status;
  return switch (zone) {
    PourZone.approaching => (status.warningWash, status.warning),
    PourZone.onTarget => (status.successWash, status.success),
    PourZone.over => (status.dangerWash, status.danger),
    _ => (scheme.surfaceContainerLowest, scheme.onSurface),
  };
}

/// +0.2 g / -1.5 g
String signedMg(int mg) {
  // sign from the rounded value, so +20 mg reads 0.0 g and not +0.0 g
  final dg = milligramsToDecigrams(mg);
  if (dg == 0) return formatDecigrams(0);
  return dg > 0 ? '+${formatDecigrams(dg)}' : formatDecigrams(dg);
}

/// the number you read from across the room
class BigWeight extends StatelessWidget {
  const BigWeight({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wide = isTwoPane(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        // bigger still on a tablet propped by the bowl
        style: context.type.figure.copyWith(
          fontSize: wide ? 96 : null,
          color: color,
        ),
      ),
    );
  }
}

class StabilityChip extends StatelessWidget {
  const StabilityChip({super.key, required this.live, required this.stable});

  final bool live;
  final bool stable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.status;
    final quiet = (scheme.surfaceContainerHigh, scheme.onSurfaceVariant);
    final (icon, text, (wash, color)) = !live
        ? (Icons.portable_wifi_off, 'No reading', quiet)
        : stable
        ? (
            Icons.check_circle_outline,
            'Steady',
            (status.successWash, status.success),
          )
        : (Icons.waves, 'Settling…', quiet);

    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: wash,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

enum BannerTone { warning, danger }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final BannerTone tone;
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    final (bg, fg) = tone == BannerTone.danger
        ? (status.dangerWash, status.danger)
        : (status.warningWash, status.warning);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inlineAction = constraints.maxWidth >= 520;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(message, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (action != null && inlineAction) ...[
                    const SizedBox(width: 8),
                    action!,
                  ],
                ],
              ),
              if (action != null && !inlineAction) ...[
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: action!),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// one line of the target vs added table. [addedMg] null = not weighed
typedef DeviationRow = ({
  String name,
  int rgb,
  ProductForm form,
  int targetMg,
  int? addedMg,
  bool movedOn,
});

/// target vs what went in, per step. a table when there's room, two lines
/// per step on phones. used live at the end of weighing and in history
class DeviationTable extends StatelessWidget {
  const DeviationTable({
    super.key,
    required this.rows,
    required this.toleranceMg,
  });

  DeviationTable.ofState(WeighingState s, {Key? key})
    : this(
        key: key,
        toleranceMg: s.toleranceMg,
        rows: [
          for (final (i, step) in s.steps.indexed)
            (
              name: step.name,
              rgb: step.rgb,
              form: step.form,
              targetMg: step.targetAddedMg,
              addedMg: s.records[i]?.addedMg,
              movedOn: s.records[i]?.manual ?? false,
            ),
        ],
      );

  DeviationTable.ofSession(
    WeighingSession s, {
    Key? key,
    required int toleranceMg,
  }) : this(
         key: key,
         toleranceMg: toleranceMg,
         rows: [
           for (final step in s.steps)
             (
               name: step.ingredientName,
               rgb: step.displayRgb,
               form: step.form,
               targetMg: step.targetAddedDg * 100,
               addedMg: step.actualAddedMg,
               movedOn: step.confirmedStable == false,
             ),
         ],
       );

  final List<DeviationRow> rows;
  final int toleranceMg;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) =>
          c.maxWidth >= 440 ? _table(context) : _stacked(context),
    );
  }

  ({DeviationRow row, int? diff, bool off}) _row(int i) {
    final row = rows[i];
    final diff = row.addedMg == null ? null : row.addedMg! - row.targetMg;
    return (
      row: row,
      diff: diff,
      off: diff != null && diff.abs() > toleranceMg,
    );
  }

  Widget _name(BuildContext context, DeviationRow row) {
    return Row(
      children: [
        ColorSwatchDot(rgb: row.rgb, size: 18),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            row.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          row.form.label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (row.movedOn) ...[
          const SizedBox(width: 6),
          const LabelTag('Moved on', tone: TagTone.warning),
        ],
      ],
    );
  }

  Widget _table(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final danger = context.status.danger;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 28),
            Expanded(child: Text('Ingredient', style: muted)),
            for (final h in ['Target', 'Added', 'Off by'])
              SizedBox(
                width: 72,
                child: Text(h, textAlign: TextAlign.end, style: muted),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < rows.length; i++)
          Builder(
            builder: (context) {
              final x = _row(i);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: _name(context, x.row)),
                    _Cell(formatMilligrams(x.row.targetMg)),
                    _Cell(
                      x.row.addedMg == null
                          ? '—'
                          : formatMilligrams(x.row.addedMg!),
                      bold: true,
                    ),
                    _Cell(
                      x.diff == null ? '—' : signedMg(x.diff!),
                      color: x.off ? danger : null,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _stacked(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final danger = context.status.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++)
          Builder(
            builder: (context) {
              final x = _row(i);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _name(context, x.row),
                    Padding(
                      padding: const EdgeInsets.only(left: 28, top: 2),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  'Target ${formatMilligrams(x.row.targetMg)} · added ',
                            ),
                            TextSpan(
                              text: x.row.addedMg == null
                                  ? '—'
                                  : formatMilligrams(x.row.addedMg!),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (x.diff != null)
                              TextSpan(
                                text: ' · ${signedMg(x.diff!)}',
                                style: TextStyle(color: x.off ? danger : null),
                              ),
                          ],
                        ),
                        style: muted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false, this.color});

  final String text;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w700 : null,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// zero, each ingredient, check. done / current / to do
class StepList extends StatelessWidget {
  const StepList({super.key, required this.state});

  final WeighingState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;

    final zeroDone = s.phase.index > WeighPhase.zeroed.index;
    final zeroCurrent =
        s.phase == WeighPhase.placeBowl || s.phase == WeighPhase.zeroed;

    Widget row({
      required bool done,
      required bool current,
      required String title,
      String? detail,
      int? rgb,
    }) {
      final icon = done
          ? Icon(Icons.check_circle, size: 20, color: status.success)
          : current
          ? Icon(Icons.radio_button_checked, size: 20, color: scheme.primary)
          : Icon(Icons.radio_button_unchecked, size: 20, color: scheme.outline);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: current ? scheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            if (rgb != null) ...[
              ColorSwatchDot(rgb: rgb, size: 16),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (detail != null)
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text('Mixing sequence', style: theme.textTheme.titleSmall),
            ),
            row(done: zeroDone, current: zeroCurrent, title: 'Zero the scale'),
            for (final (i, step) in s.steps.indexed)
              row(
                done: s.records[i] != null,
                current: s.phase == WeighPhase.pouring && s.stepIndex == i,
                title: step.name,
                rgb: step.rgb,
                detail: s.records[i] == null
                    ? formatMilligrams(step.targetAddedMg)
                    : formatMilligrams(s.records[i]!.addedMg),
              ),
            row(
              done: s.phase == WeighPhase.done,
              current: s.phase == WeighPhase.review,
              title: 'Check and save',
            ),
          ],
        ),
      ),
    );
  }
}
