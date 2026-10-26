import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/connection_chip.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';

/// last look before pouring: the order, the developer check, a scale
Future<void> showStartWeighingSheet(BuildContext context, ColorFormula f) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _StartSheet(formula: f),
  );
}

class _StartSheet extends ConsumerStatefulWidget {
  const _StartSheet({required this.formula});

  final ColorFormula formula;

  @override
  ConsumerState<_StartSheet> createState() => _StartSheetState();
}

class _StartSheetState extends ConsumerState<_StartSheet> {
  bool _ratioChecked = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.formula;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final scale = ref.watch(scaleProvider);
    final steps = stepsFor(f);
    final ratio = f.developerRatio;
    final settings = ref.watch(settingsProvider);
    final device = scale.device;
    // a standard 0x181D scale sends the odd reading, not a live weight
    final cantGuide = device is BleScaleDevice && device.experimental;
    final ready =
        scale.isConnected && !cantGuide && (ratio == null || _ratioChecked);
    final showLast =
        settings.lastScaleId != null &&
        !(device is BleScaleDevice && device.deviceId == settings.lastScaleId);

    // what the scale should read after each step
    final totals = <int>[];
    for (final s in steps) {
      totals.add((totals.isEmpty ? 0 : totals.last) + s.targetAddedMg);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ready to weigh', style: theme.textTheme.titleLarge),
            Text(f.name, style: muted),
            const SizedBox(height: 16),
            Text('Order', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final (i, step) in steps.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(width: 20, child: Text('${i + 1}', style: muted)),
                    ColorSwatchDot(rgb: step.rgb, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(step.name, style: theme.textTheme.bodyMedium),
                    ),
                    Text(
                      'add ${formatMilligrams(step.targetAddedMg)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      width: 92,
                      child: Text(
                        '→ ${formatMilligrams(totals[i])}',
                        textAlign: TextAlign.end,
                        style: muted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Everything goes in one bowl. The scale is zeroed once with the '
              'empty bowl, not between colors.',
              style: muted,
            ),
            if (ratio != null) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _ratioChecked,
                onChanged: (v) => setState(() => _ratioChecked = v ?? false),
                title: Text(
                  'The developer ratio ${ratio.label} by weight matches the '
                  'product instructions',
                ),
              ),
            ],
            const SizedBox(height: 16),
            // stacked, side by side the button squeezes the status on phones
            if (device == null)
              Text('No scale connected', style: theme.textTheme.bodyMedium)
            else ...[
              ConnectionChip(name: device.info.name, state: scale.connection),
              if (device.problem != null && !scale.isConnected) ...[
                const SizedBox(height: 4),
                Text(device.problem!, style: muted),
              ],
            ],
            if (!scale.isConnected) ...[
              const SizedBox(height: 10),
              if (showLast) ...[
                FilledButton.tonalIcon(
                  onPressed: () =>
                      ref.read(scaleProvider.notifier).connectLast(),
                  icon: const Icon(Icons.bluetooth, size: 18),
                  label: Text(
                    'Connect ${settings.lastScaleName ?? 'last scale'}',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.go(Routes.scale);
                },
                icon: const Icon(Icons.bluetooth_searching, size: 18),
                label: const Text('Find a scale'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(scaleProvider.notifier).useSimulator(),
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Use simulated scale'),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: ready
                  ? () {
                      final router = GoRouter.of(context);
                      Navigator.pop(context);
                      router.push(Routes.weigh(f.id));
                    }
                  : null,
              child: const Text('Start weighing'),
            ),
            if (!ready) ...[
              const SizedBox(height: 6),
              Text(
                !scale.isConnected
                    ? 'Connect a scale first.'
                    : cantGuide
                    ? 'This scale only sends a reading now and then, it '
                          'can\'t guide pouring. Use the ColorMix scale or '
                          'the simulator.'
                    : 'Tick the developer check first.',
                textAlign: TextAlign.center,
                style: muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
