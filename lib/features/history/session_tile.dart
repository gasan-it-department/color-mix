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
    final iconColor = switch (look.tone) {
      TagTone.success => context.status.success,
      TagTone.warning => context.status.warning,
      _ => scheme.onSurfaceVariant,
    };
    final when = sessionWhen.format(s.startedAt);
    final steps = '${s.doneSteps} of ${s.steps.length} steps';

    return ListTile(
      onTap: () => context.push(Routes.session(s.id)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(look.icon, size: 20, color: iconColor),
      ),
      title: Text(
        showFormula ? s.formulaName : when,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        showFormula
            ? '${look.label} · $when · $steps'
            : '${look.label} · $steps',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            s.weighedMg == null ? '—' : formatMilligrams(s.weighedMg!),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'of ${formatDecigrams(s.plannedTotalDg)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
