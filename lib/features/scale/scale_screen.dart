import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/core/widgets/connection_chip.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/scale/widgets/simulator_panel.dart';

class ScaleScreen extends ConsumerWidget {
  const ScaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sim = ref.watch(simulatedScaleProvider);
    final theme = Theme.of(context);

    return AppPage(
      title: 'Scale',
      body: ListView(
        padding: pagePadding(context),
        children: [
          const _ConnectedScale(),
          if (sim != null) ...[
            const SizedBox(height: 12),
            SimulatorPanel(scale: sim),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: 'Bluetooth scales',
            child: Text(
              'Scanning for the ColorMix scale isn\'t in this build yet. The '
              'simulated scale runs the whole weighing flow without hardware.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedScale extends ConsumerWidget {
  const _ConnectedScale();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(scaleProvider);
    final notifier = ref.read(scaleProvider.notifier);
    final device = status.device;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (device == null) {
      return SectionCard(
        title: 'Connected scale',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No scale connected.', style: muted),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: notifier.useSimulator,
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Use simulated scale'),
            ),
          ],
        ),
      );
    }

    final reading = ref.watch(scaleReadingProvider).value;

    return SectionCard(
      title: 'Connected scale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConnectionChip(name: device.info.name, state: status.connection),
          const SizedBox(height: 16),
          Text('Live reading', style: muted),
          Text(
            status.isConnected && reading != null
                ? formatMilligrams(reading.milligrams)
                : '—',
            style: theme.textTheme.displaySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (device.supportsTare)
                OutlinedButton(
                  onPressed: status.isConnected ? notifier.tare : null,
                  child: const Text('Tare'),
                ),
              if (status.isConnected)
                OutlinedButton(
                  onPressed: notifier.disconnect,
                  child: const Text('Disconnect'),
                )
              else
                FilledButton.tonal(
                  onPressed: notifier.reconnect,
                  child: const Text('Connect'),
                ),
              TextButton(
                onPressed: notifier.forget,
                child: const Text('Forget this scale'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
