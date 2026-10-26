import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/connection_chip.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/settings/app_settings.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';

/// tolerance choices, decigrams
const toleranceChoicesDg = [1, 2, 3, 5, 10];

/// steady = readings stay within this, mg
const steadyChoicesMg = [100, 200, 300, 500];

/// ...for this long, ms
const settleChoicesMs = [500, 800, 1200, 2000];

/// starting dye amount bounds and step, decigrams
const minDefaultDyeDg = 100;
const maxDefaultDyeDg = 3000;
const defaultDyeStepDg = 50;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              narrow ? 16 : 24,
              8,
              narrow ? 16 : 24,
              32,
            ),
            children: const [
              _Appearance(),
              SizedBox(height: 12),
              _Weighing(),
              SizedBox(height: 12),
              _Formulas(),
              SizedBox(height: 12),
              _Scale(),
              SizedBox(height: 12),
              _About(),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle? _muted(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
}

class _Appearance extends ConsumerWidget {
  const _Appearance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return SectionCard(
      title: 'Appearance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(settingsProvider.notifier).setThemeMode(s.first),
          ),
        ],
      ),
    );
  }
}

class _Weighing extends ConsumerStatefulWidget {
  const _Weighing();

  @override
  ConsumerState<_Weighing> createState() => _WeighingState();
}

class _WeighingState extends ConsumerState<_Weighing> {
  bool _advanced = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final muted = _muted(context);
    const defaults = AppSettings();
    final changed =
        s.toleranceDg != defaults.toleranceDg ||
        s.stabilityThresholdMg != defaults.stabilityThresholdMg ||
        s.stabilityDwellMs != defaults.stabilityDwellMs;

    return SectionCard(
      title: 'Weighing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.soundsOn,
            onChanged: n.setSoundsOn,
            title: const Text('Sounds'),
            subtitle: const Text(
              'A click on target, an alert when over or when the scale drops. '
              'The phone still buzzes with sounds off.',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.autoAdvance,
            onChanged: n.setAutoAdvance,
            title: const Text('Move on by itself'),
            subtitle: const Text(
              'Goes to the next color once the reading is steady and on '
              'target. Off, you tap Confirm each time.',
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),
          Text('On target within', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          _Choices<int>(
            values: toleranceChoicesDg,
            selected: s.toleranceDg,
            label: (dg) => '±${formatDecigrams(dg)}',
            onSelected: n.setToleranceDg,
          ),
          const SizedBox(height: 6),
          Text(
            'How close a step has to be to count as done. Tighter than the '
            'scale can really hold makes steps hard to confirm.',
            style: muted,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _advanced = !_advanced),
              icon: Icon(_advanced ? Icons.expand_less : Icons.expand_more),
              label: Text(_advanced ? 'Hide advanced' : 'Advanced'),
            ),
          ),
          if (_advanced) ...[
            const SizedBox(height: 4),
            Text(
              'Steady means the reading stays within',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _Choices<int>(
              values: steadyChoicesMg,
              selected: s.stabilityThresholdMg,
              label: formatMilligrams,
              onSelected: (mg) => n.setStability(thresholdMg: mg),
            ),
            const SizedBox(height: 12),
            Text('for', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            _Choices<int>(
              values: settleChoicesMs,
              selected: s.stabilityDwellMs,
              label: (ms) => '${(ms / 1000).toStringAsFixed(1)} s',
              onSelected: (ms) => n.setStability(dwellMs: ms),
            ),
            const SizedBox(height: 6),
            Text(
              'Looser or shorter confirms sooner but may catch the scale '
              'still moving. Leave these unless steps won\'t settle.',
              style: muted,
            ),
            if (changed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: n.resetWeighing,
                  child: const Text('Back to defaults'),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text('Changes apply from the next weighing.', style: muted),
        ],
      ),
    );
  }
}

class _Formulas extends ConsumerWidget {
  const _Formulas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dg = ref.watch(settingsProvider.select((s) => s.defaultDyeDg));
    final n = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    void step(int delta) =>
        n.setDefaultDyeDg((dg + delta).clamp(minDefaultDyeDg, maxDefaultDyeDg));

    return SectionCard(
      title: 'Formulas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Starting dye amount', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Less',
                onPressed: dg > minDefaultDyeDg
                    ? () => step(-defaultDyeStepDg)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 96,
                child: Text(
                  formatDecigrams(dg),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: 'More',
                onPressed: dg < maxDefaultDyeDg
                    ? () => step(defaultDyeStepDg)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'What a new formula starts with, dye only. Each formula can '
            'change it.',
            style: _muted(context),
          ),
        ],
      ),
    );
  }
}

class _Scale extends ConsumerWidget {
  const _Scale();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(scaleProvider);
    final lastName = ref.watch(settingsProvider.select((s) => s.lastScaleName));
    final device = status.device;
    final muted = _muted(context);

    Widget body(BuildContext context) {
      final ble = device is BleScaleDevice ? device : null;
      final calibratable = ble != null && ble.supportsCalibration;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (device == null)
            Text(
              lastName == null
                  ? 'No scale connected.'
                  : 'No scale connected. Last used: $lastName.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ConnectionChip(name: device.info.name, state: status.connection),
          if (calibratable && status.isConnected) ...[
            const SizedBox(height: 4),
            Text(
              ble.calibrated ? 'Calibrated' : 'Not calibrated yet',
              style: muted,
            ),
          ],
          if (device is SimulatedScale) ...[
            const SizedBox(height: 4),
            Text('The simulated scale needs no calibration.', style: muted),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => context.go(Routes.scale),
                child: const Text('Manage scale'),
              ),
              if (calibratable)
                FilledButton.tonal(
                  onPressed: status.isConnected
                      ? () => context.push(Routes.calibrate)
                      : null,
                  child: const Text('Calibrate'),
                ),
            ],
          ),
        ],
      );
    }

    return SectionCard(
      title: 'Scale',
      // calibration state comes from the device, not the provider
      child: device is BleScaleDevice
          ? ListenableBuilder(listenable: device, builder: (c, _) => body(c))
          : body(context),
    );
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppInfo.name} · prototype ${AppInfo.version}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Demo formulas are examples only. Always follow the dye maker\'s '
            'mixing instructions. The color on screen is a visual target, not '
            'a guaranteed result.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: v == selected,
            onSelected: (_) => onSelected(v),
          ),
      ],
    );
  }
}
