import 'package:flutter/material.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

/// buttons standing in for hands, bowls and a flaky bluetooth link
class SimulatorPanel extends StatelessWidget {
  const SimulatorPanel({
    super.key,
    required this.scale,
    this.extraActions = const [],
  });

  final SimulatedScale scale;

  /// weighing adds 'pour to target' and 'pour 2 g too much'
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: scale,
      builder: (context, _) {
        final theme = Theme.of(context);
        final muted = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

        return SectionCard(
          title: 'Simulator',
          trailing: const LabelTag('Practice only'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'On the platform: ${formatMilligrams(scale.grossMg)}'
                '${scale.tareMg != 0 ? ' · scale tared at ${formatMilligrams(scale.tareMg)}' : ''}',
                style: muted,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: scale.placeBowl,
                    child: const Text('Place bowl'),
                  ),
                  OutlinedButton(
                    onPressed: scale.clearPlatform,
                    child: const Text('Clear platform'),
                  ),
                  for (final (label, mg) in const [
                    ('+0.1 g', 100),
                    ('+1 g', 1000),
                    ('+5 g', 5000),
                    ('−1 g', -1000),
                  ])
                    OutlinedButton(
                      onPressed: () => scale.add(mg),
                      child: Text(label),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _HoldToPour(scale: scale),
              if (extraActions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: extraActions),
              ],
              const SizedBox(height: 8),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unsteady readings'),
                subtitle: const Text('Jumps about a gram either way'),
                value: scale.unsteady,
                onChanged: (v) => scale.unsteady = v,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Freeze readings'),
                subtitle: const Text('Connected, but nothing comes through'),
                value: scale.frozen,
                onChanged: (v) => scale.frozen = v,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: scale.isConnected
                    ? OutlinedButton.icon(
                        onPressed: scale.dropConnection,
                        icon: const Icon(Icons.bluetooth_disabled, size: 18),
                        label: const Text('Drop connection'),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: scale.connect,
                        icon: const Icon(Icons.bluetooth, size: 18),
                        label: const Text('Reconnect'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// pours while pressed, like tipping the tube
class _HoldToPour extends StatelessWidget {
  const _HoldToPour({required this.scale});

  final SimulatedScale scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = scale.pouring;

    return Semantics(
      button: true,
      label: 'Hold to pour',
      child: Listener(
        onPointerDown: (_) => scale.startPouring(),
        onPointerUp: (_) => scale.stopPouring(),
        onPointerCancel: (_) => scale.stopPouring(),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? scheme.primaryContainer : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  active ? 'Pouring…' : 'Hold to pour (5 g/s)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
