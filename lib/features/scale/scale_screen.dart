import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/ble_transport.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/core/widgets/connection_chip.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/scale/ble_scan.dart';
import 'package:colormix_studio/features/scale/widgets/scale_check.dart';
import 'package:colormix_studio/features/scale/widgets/simulator_panel.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/shared/models/scale_device_info.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

class ScaleScreen extends ConsumerWidget {
  const ScaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sim = ref.watch(simulatedScaleProvider);
    final device = ref.watch(scaleProvider.select((s) => s.device));

    return AppPage(
      title: 'Scale',
      body: ListView(
        padding: pagePadding(context),
        children: [
          const _ConnectedScale(),
          const SizedBox(height: 12),
          const _FindScale(),
          if (sim != null) ...[
            const SizedBox(height: 12),
            SimulatorPanel(scale: sim),
          ],
          if (device != null) ...[
            const SizedBox(height: 12),
            ScaleCheck(device: device),
          ],
        ],
      ),
    );
  }
}

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

// ── the scale in use ───────────────────────────────────────

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
      final settings = ref.watch(settingsProvider);
      final lastName = settings.lastScaleName ?? 'the last scale';
      return SectionCard(
        title: 'Connected scale',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No scale connected.', style: muted),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (settings.lastScaleId != null)
                  FilledButton.tonalIcon(
                    onPressed: notifier.connectLast,
                    icon: const Icon(Icons.bluetooth, size: 18),
                    label: Text('Connect $lastName'),
                  ),
                OutlinedButton.icon(
                  onPressed: notifier.useSimulator,
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: const Text('Use simulated scale'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // the device tells us about problem text and details as they change
    return ListenableBuilder(
      listenable: device,
      builder: (context, _) {
        final ble = device is BleScaleDevice ? device : null;
        final reading = ref.watch(scaleReadingProvider).value;
        final connected = status.isConnected;
        final problem = device.problem;
        final trouble =
            status.connection == ScaleConnectionState.failed ||
            status.connection == ScaleConnectionState.connectedUnsupported ||
            (ble?.sensorFault ?? false);

        return SectionCard(
          title: 'Connected scale',
          trailing: ble != null && ble.experimental
              ? const LabelTag('Experimental', tone: TagTone.warning)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConnectionChip(name: device.info.name, state: status.connection),
              if (ble != null && ble.deviceInfo['fw'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Firmware ${ble.deviceInfo['fw']} · '
                  '${ble.calibrated ? 'calibrated' : 'not calibrated'}',
                  style: muted,
                ),
              ],
              if (problem != null) ...[
                const SizedBox(height: 8),
                Text(
                  problem,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: trouble
                        ? context.status.danger
                        : context.status.warning,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Live reading', style: muted),
              Text(
                connected && reading != null
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
                  // a scale that still needs it gets the stronger button
                  if (ble != null && ble.supportsCalibration && connected)
                    ble.calibrated
                        ? OutlinedButton(
                            onPressed: () => context.push(Routes.calibrate),
                            child: const Text('Calibrate'),
                          )
                        : FilledButton.tonal(
                            onPressed: () => context.push(Routes.calibrate),
                            child: const Text('Calibrate'),
                          ),
                  if (device.supportsTare)
                    OutlinedButton(
                      onPressed: connected
                          ? () async {
                              try {
                                await notifier.tare();
                                if (context.mounted) _say(context, 'Tared');
                              } on ScaleCommandException catch (e) {
                                if (context.mounted) _say(context, e.message);
                              }
                            }
                          : null,
                      child: const Text('Tare'),
                    ),
                  if (connected ||
                      status.connection ==
                          ScaleConnectionState.connectedUnsupported)
                    OutlinedButton(
                      onPressed: notifier.disconnect,
                      child: const Text('Disconnect'),
                    )
                  else
                    FilledButton.tonal(
                      onPressed:
                          status.connection == ScaleConnectionState.connecting
                          ? null
                          : notifier.reconnect,
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
      },
    );
  }
}

// ── finding one ────────────────────────────────────────────

class _FindScale extends ConsumerWidget {
  const _FindScale();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(bleScanProvider);
    final notifier = ref.read(bleScanProvider.notifier);
    final transport = ref.watch(bleTransportProvider);
    final availability = ref.watch(bleAvailabilityProvider).value;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (!transport.supported) {
      return SectionCard(
        title: 'Find a scale',
        child: Text(
          'Bluetooth scales work in the Android and Windows apps, not in '
          'this browser preview. The simulated scale runs the whole flow.',
          style: muted,
        ),
      );
    }

    return SectionCard(
      title: 'Find a scale',
      trailing: scan.scanning
          ? TextButton.icon(
              onPressed: notifier.stop,
              icon: const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Stop'),
            )
          : FilledButton.tonalIcon(
              onPressed: notifier.start,
              icon: const Icon(Icons.bluetooth_searching, size: 18),
              label: Text(scan.scannedOnce ? 'Scan again' : 'Scan'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Availability(availability: availability),
          if (scan.problem != null) ...[
            const SizedBox(height: 8),
            Text(
              scan.problem!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.status.danger,
              ),
            ),
          ],
          if (!scan.scannedOnce && scan.problem == null)
            Text(
              'Switch the scale on, keep it close by, then scan.',
              style: muted,
            ),
          for (final f in scan.scales) _FoundTile(found: f),
          if (scan.scannedOnce &&
              !scan.scanning &&
              scan.scales.isEmpty &&
              scan.problem == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No scales found. Check the scale is switched on and close '
                'by, then scan again.',
                style: muted,
              ),
            ),
          if (scan.others.isNotEmpty) _OtherDevices(others: scan.others),
        ],
      ),
    );
  }
}

class _Availability extends ConsumerWidget {
  const _Availability({required this.availability});

  final BleAvailability? availability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final text = switch (availability) {
      BleAvailability.poweredOff => 'Bluetooth is off.',
      BleAvailability.unauthorized =>
        'ColorMix isn\'t allowed to use Bluetooth yet, scanning will ask.',
      BleAvailability.unsupported => 'This device has no Bluetooth.',
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 18,
            color: context.status.warning,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          if (availability == BleAvailability.poweredOff)
            TextButton(
              onPressed: () async {
                final on = await ref
                    .read(bleTransportProvider)
                    .enableBluetooth();
                if (!on && context.mounted) {
                  _say(context, 'Turn Bluetooth on in the system settings.');
                }
              },
              child: const Text('Turn on'),
            ),
        ],
      ),
    );
  }
}

class _FoundTile extends ConsumerWidget {
  const _FoundTile({required this.found});

  final FoundDevice found;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = found.result;
    final current = ref.watch(scaleProvider);
    final isThis =
        current.device is BleScaleDevice &&
        (current.device! as BleScaleDevice).deviceId == r.deviceId;
    final busy =
        isThis &&
        (current.isConnected ||
            current.connection == ScaleConnectionState.connecting);

    final subtitle = switch (found.kind) {
      ScaleAdapterType.esp32Custom => 'ColorMix scale',
      ScaleAdapterType.standardWeightScale =>
        'Weight scale · experimental, can\'t guide pouring',
      _ => 'Not a scale the app knows',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: found.kind == ScaleAdapterType.esp32Custom
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              found.isScale ? Icons.scale_outlined : Icons.bluetooth,
              size: 20,
              color: found.kind == ScaleAdapterType.esp32Custom
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name ?? 'Unnamed device',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _SignalBars(bars: signalBars(r.rssi)),
          const SizedBox(width: 8),
          isThis && current.isConnected
              ? const LabelTag('Connected', tone: TagTone.success)
              : OutlinedButton(
                  key: ValueKey('connect:${r.deviceId}'),
                  onPressed: busy
                      ? null
                      : () async {
                          // grab both before awaiting, the row rebuilds
                          // when the scan stops
                          final scan = ref.read(bleScanProvider.notifier);
                          final scale = ref.read(scaleProvider.notifier);
                          await scan.stop();
                          await scale.connectBle(r);
                        },
                  child: Text(busy ? 'Connecting…' : 'Connect'),
                ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.bars});

  final int bars;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'signal $bars of 4',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 4,
              height: 6.0 + i * 3,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: i < bars
                    ? scheme.onSurfaceVariant
                    : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

/// everything else nearby, folded away
class _OtherDevices extends StatefulWidget {
  const _OtherDevices({required this.others});

  final List<FoundDevice> others;

  @override
  State<_OtherDevices> createState() => _OtherDevicesState();
}

class _OtherDevicesState extends State<_OtherDevices> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.others.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
            label: Text(
              _open
                  ? 'Hide other devices'
                  : 'Show $n other ${n == 1 ? 'device' : 'devices'}',
            ),
          ),
        ),
        if (_open)
          for (final f in widget.others) _FoundTile(found: f),
      ],
    );
  }
}
