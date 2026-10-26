import 'package:flutter/material.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/confirm_sheet.dart';
import 'package:colormix_studio/features/weighing/weighing_controller.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/features/weighing/widgets/weighing_bits.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';

BoxDecoration _panel(BuildContext context, {Color? color, Color? border}) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: color ?? scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border ?? scheme.outlineVariant),
  );
}

// ── zero with the bowl ─────────────────────────────────────

class PreparePanel extends StatelessWidget {
  const PreparePanel({
    super.key,
    required this.state,
    required this.controller,
  });

  final WeighingState state;
  final WeighingController controller;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final placing = s.phase == WeighPhase.placeBowl;
    final reading = placing ? s.liveMg : s.netMg;
    final moved =
        !placing && s.live && s.stable && s.netMg!.abs() > s.toleranceMg;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panel(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(placing ? 'Before you pour' : 'Scale zeroed', style: muted),
          Text(
            placing
                ? 'Put the empty bowl on the scale'
                : 'Check it reads about 0.0 g',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          BigWeight(
            text: reading == null || !s.live ? '—' : formatMilligrams(reading),
          ),
          const SizedBox(height: 8),
          StabilityChip(live: s.live, stable: s.stable),
          const SizedBox(height: 20),
          if (placing) ...[
            FilledButton.icon(
              onPressed: s.canZero ? controller.zero : null,
              icon: const Icon(Icons.exposure_zero),
              label: const Text('Zero with bowl'),
            ),
            const SizedBox(height: 8),
            Text(
              'Wait for a steady reading. Everything after this is weighed on '
              'top of the bowl, the scale isn\'t zeroed again between colors.',
              style: muted,
            ),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: s.canZero ? controller.zero : null,
                  child: const Text('Zero again'),
                ),
                FilledButton(
                  onPressed: s.canStartPouring ? controller.beginPouring : null,
                  child: Text('Start with ${s.steps.first.name}'),
                ),
              ],
            ),
            if (moved) ...[
              const SizedBox(height: 8),
              Text(
                'The reading moved since zeroing. Zero again with only the '
                'empty bowl on.',
                style: muted,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── pouring ────────────────────────────────────────────────

class PourPanel extends StatelessWidget {
  const PourPanel({super.key, required this.state, required this.controller});

  final WeighingState state;
  final WeighingController controller;

  String _message(WeighingState s) => switch (s.zone) {
    PourZone.waiting => 'Waiting for a reading',
    PourZone.under => 'Keep pouring',
    PourZone.approaching => 'Almost there, slow down',
    PourZone.onTarget => s.stable ? 'On target' : 'On target, let it settle',
    PourZone.over => 'Over by ${formatMilligrams(-s.remainingMg!)}',
  };

  Future<void> _moveOnShort(BuildContext context) async {
    final s = state;
    final ok = await showConfirmSheet(
      context,
      title: 'Move on short?',
      message:
          '${s.step.name} is ${formatMilligrams(s.remainingMg!)} short. '
          'That stays on the record and the next amounts stay as planned.',
      confirmLabel: 'Move on',
      cancelLabel: 'Keep pouring',
    );
    if (ok) await controller.confirmStep(manual: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final zone = s.zone;
    final (bg, fg) = zoneColors(context, zone);
    final added = s.addedMg;
    final remaining = s.remainingMg;
    final progress = s.progress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panel(
        context,
        color: bg,
        border: zone == PourZone.under || zone == PourZone.waiting
            ? null
            : fg.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ColorSwatchDot(rgb: s.step.rgb, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${s.stepIndex + 1} of ${s.steps.length}',
                      style: muted,
                    ),
                    Text(
                      s.step.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StabilityChip(live: s.live, stable: s.stable),
            ],
          ),
          const SizedBox(height: 16),
          Text('Added', style: muted),
          BigWeight(
            text: added == null || !s.live ? '—' : formatMilligrams(added),
            color: fg,
          ),
          Text(
            'of ${formatMilligrams(s.targetAddedMg)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress == null ? 0 : progress.clamp(0.0, 1.0),
              minHeight: 14,
              color: zone == PourZone.under || zone == PourZone.waiting
                  ? scheme.primary
                  : fg,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              _Stat(
                label: 'Remaining',
                value: remaining == null || !s.live
                    ? '—'
                    : formatMilligrams(remaining < 0 ? 0 : remaining),
              ),
              _Stat(
                label: 'Progress',
                value: progress == null || !s.live
                    ? '—'
                    // noise can dip a hair under zero, don't show -0.0%
                    : '${(progress < 0 ? 0 : progress * 100).toStringAsFixed(1)}%',
              ),
              _Stat(
                label: 'On the scale',
                value: s.netMg == null || !s.live
                    ? '—'
                    : '${formatMilligrams(s.netMg!)} of ${formatMilligrams(s.targetCumulativeMg)}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _message(s),
            style: theme.textTheme.titleMedium?.copyWith(
              color: zone == PourZone.under ? null : fg,
            ),
          ),
          if (zone == PourZone.over) ...[
            const SizedBox(height: 12),
            _Overshoot(state: s, controller: controller),
          ],
          const SizedBox(height: 18),
          _StepButtons(
            onBack: s.canGoBack ? controller.back : null,
            primaryLabel: s.isLastStep ? 'Finish' : 'Next ingredient',
            primaryIcon: Icons.arrow_forward,
            onPrimary: s.canConfirm ? () => controller.confirmStep() : null,
          ),
          if ((zone == PourZone.under || zone == PourZone.approaching) &&
              s.canMoveOnAnyway)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _moveOnShort(context),
                child: const Text('Move on anyway'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

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
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Overshoot extends StatelessWidget {
  const _Overshoot({required this.state, required this.controller});

  final WeighingState state;
  final WeighingController controller;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final theme = Theme.of(context);
    final status = context.status;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: status.danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target ${formatMilligrams(s.targetAddedMg)}, added '
            '${formatMilligrams(s.addedMg!)}, '
            '${formatMilligrams(-s.remainingMg!)} too much.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'It can\'t be taken back out, and the other amounts won\'t be '
            'changed for you. Carry on as planned or check the dye maker\'s '
            'instructions first.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _showReview(context, s),
                child: const Text('Review'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: status.danger,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: s.canMoveOnAnyway
                    ? () => controller.confirmStep(manual: true)
                    : null,
                child: const Text('Continue manually'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showReview(BuildContext context, WeighingState s) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('So far', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          StepsTable(state: s),
          const SizedBox(height: 12),
          Text(
            'Live: ${s.step.name} ${formatMilligrams(s.addedMg ?? 0)} of '
            '${formatMilligrams(s.targetAddedMg)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

// ── check the total ────────────────────────────────────────

class ReviewPanel extends StatelessWidget {
  const ReviewPanel({super.key, required this.state, required this.controller});

  final WeighingState state;
  final WeighingController controller;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final theme = Theme.of(context);
    final status = context.status;
    final net = s.live ? s.netMg : null;
    final diff = net == null ? null : net - s.plannedTotalMg;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panel(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Check the mixture', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Everything is in. Check the final weight while it\'s steady, '
            'then save.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          StepsTable(state: s),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          _Line('Planned', formatMilligrams(s.plannedTotalMg)),
          _Line(
            'On the scale now',
            net == null ? '—' : formatMilligrams(net),
            bold: true,
          ),
          _Line(
            'Difference',
            diff == null ? '—' : signedMg(diff),
            color: diff != null && diff.abs() > s.toleranceMg
                ? status.danger
                : null,
          ),
          const SizedBox(height: 8),
          StabilityChip(live: s.live, stable: s.stable),
          const SizedBox(height: 18),
          _StepButtons(
            onBack: s.canGoBack ? controller.back : null,
            primaryLabel: 'Complete and save',
            primaryIcon: Icons.check,
            onPrimary: s.canComplete ? controller.complete : null,
          ),
        ],
      ),
    );
  }
}

/// Previous + the main action. side by side when there's room, on phones
/// the main action goes full width on top, easier to hit with gloves on
class _StepButtons extends StatelessWidget {
  const _StepButtons({
    required this.onBack,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
  });

  final VoidCallback? onBack;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 420) {
          return Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Previous'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onPrimary,
                icon: Icon(primaryIcon, size: 18),
                label: Text(primaryLabel),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
              onPressed: onPrimary,
              icon: Icon(primaryIcon, size: 18),
              label: Text(primaryLabel),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Previous'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style:
                (bold
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
          ),
        ],
      ),
    );
  }
}

// ── done ───────────────────────────────────────────────────

class DonePanel extends StatelessWidget {
  const DonePanel({super.key, required this.state, required this.onDone});

  final WeighingState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final theme = Theme.of(context);
    final status = context.status;
    final manual = s.records.where((r) => r?.manual ?? false).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panel(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle, size: 48, color: status.success),
          const SizedBox(height: 8),
          Text(
            'Mixture complete',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${formatMilligrams(s.measuredTotalMg ?? 0)} weighed, '
            '${formatMilligrams(s.plannedTotalMg)} planned. Saved to this '
            'device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (manual > 0) ...[
            const SizedBox(height: 4),
            Text(
              manual == 1
                  ? '1 ingredient was off target, it\'s on the record.'
                  : '$manual ingredients were off target, they\'re on the record.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: status.warning,
              ),
            ),
          ],
          const SizedBox(height: 16),
          StepsTable(state: s),
          const SizedBox(height: 18),
          FilledButton(onPressed: onDone, child: const Text('Done')),
        ],
      ),
    );
  }
}
