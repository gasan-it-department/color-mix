import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/confirm_sheet.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/history/session_tile.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/widgets/weighing_bits.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

/// what happened in one weighing: totals, then target vs added per step
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete this session?',
      message: 'It comes out of the history. The formula stays as it is.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(sessionRepositoryProvider);
    Navigator.of(context).pop();
    await repo.delete(sessionId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Session deleted')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionByIdProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weighing session'),
        actions: [
          if (session case AsyncData(value: _?))
            IconButton(
              tooltip: 'Delete session',
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (session) {
        AsyncData(value: final s?) => _Detail(session: s),
        AsyncData() => const EmptyState(
          icon: Icons.history,
          title: 'Session not found',
          message: 'It may have been deleted.',
        ),
        AsyncError() => const EmptyState(
          icon: Icons.error_outline,
          title: 'Couldn\'t open this session',
          message: 'Go back and try again.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.session});

  final WeighingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final s = session;
    final look = statusLook(s.status);
    // old sessions didn't record it, judge them by today's setting
    final toleranceMg =
        s.toleranceMg ?? ref.watch(settingsProvider).toleranceDg * 100;
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;

    final plannedMg = s.plannedTotalDg * 100;
    final weighed = s.weighedMg;
    final done = s.steps.where((x) => x.isDone).toList();
    final onTarget = done
        .where((x) => x.deviationMg!.abs() <= toleranceMg)
        .length;
    final movedOn = done.where((x) => x.confirmedStable == false).length;

    final note = switch (s.status) {
      SessionStatus.interrupted =>
        'The app closed before this session finished. The steps confirmed '
            'before that are kept.',
      SessionStatus.cancelled => 'Stopped before the end.',
      _ => null,
    };

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            narrow ? 16 : 24,
            8,
            narrow ? 16 : 24,
            32,
          ),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          s.formulaName,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      LabelTag(look.label, tone: look.tone),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      sessionWhen.format(s.startedAt),
                      if (s.completedAt != null)
                        _duration(s.completedAt!.difference(s.startedAt)),
                      s.deviceName,
                    ].join(' · '),
                    style: muted,
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 8),
                    Text(note, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 32,
                    runSpacing: 12,
                    children: [
                      _Stat(
                        label: 'Planned',
                        value: formatMilligrams(plannedMg),
                      ),
                      _Stat(
                        label: 'Weighed',
                        value: weighed == null
                            ? '—'
                            : formatMilligrams(weighed),
                        strong: true,
                      ),
                      if (weighed != null &&
                          s.status == SessionStatus.completed)
                        _Stat(
                          label: 'Difference',
                          value: signedMg(weighed - plannedMg),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Each step',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DeviationTable.ofSession(s, toleranceMg: toleranceMg),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    [
                      '$onTarget of ${s.steps.length} on target '
                          '(within ±${formatMilligrams(toleranceMg)})',
                      if (movedOn > 0)
                        '$movedOn moved on before ${movedOn == 1 ? 'it' : 'they'} '
                            'settled or reached the target',
                    ].join(' · '),
                    style: muted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (s.formulaId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(Routes.formula(s.formulaId!)),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Open formula'),
                ),
              )
            else
              Text(
                'The formula was deleted. This record of the weighing stays.',
                style: muted,
              ),
          ],
        ),
      ),
    );
  }

  static String _duration(Duration d) {
    if (d.inMinutes == 0) return '${d.inSeconds} s';
    final s = d.inSeconds % 60;
    return s == 0 ? '${d.inMinutes} min' : '${d.inMinutes} min $s s';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
