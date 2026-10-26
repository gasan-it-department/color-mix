import 'package:flutter/material.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/formulation/formula_math.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';

/// the worked-out weights, what's stopping a save, and the actions
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.partNames,
    required this.partColors,
    required this.result,
    required this.developerMode,
    this.onSave,
    this.saving = false,
  });

  final List<String> partNames;
  final List<int> partColors;
  final FormulaResult result;
  final DeveloperMode developerMode;

  /// null hides the save button (phones have it in the bottom bar)
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = result;
    final ratio = r.ratioHundredths;

    final developerLabel = switch (developerMode) {
      DeveloperMode.none => 'No developer',
      DeveloperMode.unset => 'Developer',
      _ when ratio != null => 'Developer ${DeveloperRatio(ratio).label}',
      _ => 'Developer',
    };

    return SectionCard(
      title: 'Weights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, name) in partNames.indexed)
            _Row(
              leading: ColorSwatchDot(rgb: partColors[i], size: 18),
              label: name.trim().isEmpty ? 'Unnamed color' : name.trim(),
              middle: r.percents[i] == null
                  ? null
                  : formatPercentHundredths(r.percents[i]!),
              value: r.weights == null ? '—' : formatDecigrams(r.weights![i]),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(),
          ),
          _Row(
            label: 'Dye',
            value: r.dyeDg == null ? '—' : formatDecigrams(r.dyeDg!),
          ),
          _Row(
            label: developerLabel,
            value: r.developerDg == null
                ? '—'
                : formatDecigrams(r.developerDg!),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(),
          ),
          _Row(
            label: 'Mixture',
            value: r.mixtureDg == null ? '—' : formatDecigrams(r.mixtureDg!),
            strong: true,
          ),
          if (r.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final issue in r.issues) _IssueLine(issue: issue),
          ],
          const SizedBox(height: 16),
          if (onSave != null) ...[
            FilledButton(
              onPressed: saving ? null : onSave,
              child: Text(saving ? 'Saving…' : 'Save formula'),
            ),
            const SizedBox(height: 8),
          ],
          const OutlinedButton(onPressed: null, child: Text('Start weighing')),
          const SizedBox(height: 6),
          Text(
            'Weighing isn\'t in this build yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.leading,
    this.middle,
    this.strong = false,
  });

  final Widget? leading;
  final String label;
  final String? middle;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final numbers =
        (strong ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
            ?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: strong
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium,
            ),
          ),
          if (middle != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                middle!,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          Text(value, style: numbers),
        ],
      ),
    );
  }
}

class _IssueLine extends StatelessWidget {
  const _IssueLine({required this.issue});

  final FormulaIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    final color = issue.blocking ? status.danger : status.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            issue.blocking ? Icons.error_outline : Icons.warning_amber_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issue.message,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
