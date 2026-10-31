import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

/// 'Oct 27, 9:41 AM'
final sessionWhen = DateFormat.MMMd().add_jm();

({String label, TagTone tone, IconData icon}) statusLook(SessionStatus s) =>
    switch (s) {
      SessionStatus.completed => (
        label: 'Completed',
        tone: TagTone.success,
        icon: Icons.check_circle_outline,
      ),
      SessionStatus.cancelled => (
        label: 'Cancelled',
        tone: TagTone.neutral,
        icon: Icons.do_not_disturb_on_outlined,
      ),
      SessionStatus.interrupted => (
        label: 'Interrupted',
        tone: TagTone.warning,
        icon: Icons.warning_amber_rounded,
      ),
      SessionStatus.inProgress => (
        label: 'In progress',
        tone: TagTone.accent,
        icon: Icons.timelapse,
      ),
    };

/// one past session. [showFormula] off where every row is the same formula
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    this.showFormula = true,
  });

  final WeighingSession session;
  final bool showFormula;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = session;
    final look = statusLook(s.status);
    final (wash, iconColor) = switch (look.tone) {
      TagTone.success => (context.status.successWash, context.status.success),
      TagTone.warning => (context.status.warningWash, context.status.warning),
      TagTone.accent => (scheme.primaryContainer, scheme.onPrimaryContainer),
      TagTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
    };
    final when = sessionWhen.format(s.startedAt);
    final steps = '${s.doneSteps} of ${s.steps.length} steps';

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.session(s.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: wash,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Icon(look.icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showFormula ? s.formulaName : when,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          showFormula
                              ? '${look.label} · $when · $steps'
                              : '${look.label} · $steps',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        s.weighedMg == null
                            ? '—'
                            : formatMilligrams(s.weighedMg!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of ${formatDecigrams(s.plannedTotalDg)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < s.steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: s.steps[i].isDone
                              ? iconColor
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(Radii.bar),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
