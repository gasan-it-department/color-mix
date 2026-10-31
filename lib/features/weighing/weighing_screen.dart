import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/core/utils/screen_awake.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/confirm_sheet.dart';
import 'package:colormix_studio/core/widgets/connection_chip.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';
import 'package:colormix_studio/features/scale/widgets/simulator_panel.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/features/weighing/weighing_controller.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/features/weighing/widgets/weighing_bits.dart';
import 'package:colormix_studio/features/weighing/widgets/weighing_panels.dart';
import 'package:colormix_studio/core/widgets/app_page.dart';

/// full screen, big numbers, screen kept on
class WeighingScreen extends ConsumerStatefulWidget {
  const WeighingScreen({super.key, required this.formulaId});

  final String formulaId;

  @override
  ConsumerState<WeighingScreen> createState() => _WeighingScreenState();
}

class _WeighingScreenState extends ConsumerState<WeighingScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(keepScreenOn(true));
  }

  @override
  void dispose() {
    unawaited(keepScreenOn(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (ref.watch(weighingProvider(widget.formulaId))) {
      AsyncData(:final value) => _WeighingView(
        state: value,
        formulaId: widget.formulaId,
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(title: const Text('Weighing')),
        body: const EmptyState(
          icon: Icons.scale_outlined,
          title: 'Couldn\'t start weighing',
          message: 'The formula may have been deleted. Go back and try again.',
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _WeighingView extends ConsumerWidget {
  const _WeighingView({required this.state, required this.formulaId});

  final WeighingState state;
  final String formulaId;

  Future<void> _stop(BuildContext context, WeighingController ctrl) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Stop weighing?',
      message:
          'The session is kept as cancelled. Whatever is in the bowl '
          'stays as it is.',
      confirmLabel: 'Stop',
      cancelLabel: 'Keep weighing',
      destructive: true,
    );
    if (!ok) return;
    await ctrl.cancel();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    final ctrl = ref.read(weighingProvider(formulaId).notifier);
    final sim = ref.watch(simulatedScaleProvider);
    final wide = isTwoPane(context);

    final main = <Widget>[
      ..._banners(context, ref, ctrl),
      switch (s.phase) {
        WeighPhase.placeBowl ||
        WeighPhase.zeroed => PreparePanel(state: s, controller: ctrl),
        WeighPhase.pouring => PourPanel(state: s, controller: ctrl),
        WeighPhase.review => ReviewPanel(state: s, controller: ctrl),
        WeighPhase.done => DonePanel(
          state: s,
          onDone: () => Navigator.of(context).pop(),
        ),
        WeighPhase.cancelled => const SizedBox.shrink(),
      },
    ];

    final side = <Widget>[
      StepList(state: s),
      if (sim != null && !s.finished) ...[
        const SizedBox(height: 12),
        SimulatorPanel(scale: sim, extraActions: _simActions(sim)),
      ],
    ];

    return PopScope(
      canPop: s.finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stop(context, ctrl);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Stop weighing',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(s.formula.name),
          actions: [
            if (wide)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: ConnectionChip(name: s.deviceName, state: s.connection),
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: wide
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Breakpoints.workbenchMaxWidth,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(32, 16, 12, 32),
                          children: main,
                        ),
                      ),
                      SizedBox(
                        width: 380,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 16, 32, 32),
                          children: side,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ConnectionChip(
                      name: s.deviceName,
                      state: s.connection,
                    ),
                  ),
                  ...main,
                  const SizedBox(height: 12),
                  ...side,
                ],
              ),
      ),
    );
  }

  List<Widget> _banners(
    BuildContext context,
    WidgetRef ref,
    WeighingController ctrl,
  ) {
    final s = state;
    if (s.finished) return const [];
    final scale = ref.read(scaleProvider.notifier);

    return [
      if (s.connection == ScaleConnectionState.connecting)
        const StatusBanner(
          tone: BannerTone.warning,
          icon: Icons.bluetooth_searching,
          title: 'Reconnecting…',
          message: 'Readings come back as soon as the scale answers.',
        )
      else if (!s.connected)
        StatusBanner(
          tone: BannerTone.danger,
          icon: Icons.bluetooth_disabled,
          title: 'Scale disconnected',
          message:
              'Readings are paused and your progress is kept. Reconnect '
              'to carry on.',
          // no device at all (forgotten, or opened by link): the last scale
          // if there is one, else the simulator. leaving for the scale tab
          // would end the session, so it's not offered here
          action: ref.read(scaleProvider).device != null
              ? FilledButton.tonal(
                  onPressed: scale.reconnect,
                  child: const Text('Reconnect'),
                )
              : ref.read(settingsProvider).lastScaleId != null
              ? FilledButton.tonal(
                  onPressed: scale.connectLast,
                  child: const Text('Connect last scale'),
                )
              : FilledButton.tonal(
                  onPressed: scale.useSimulator,
                  child: const Text('Use simulated scale'),
                ),
        )
      else if (s.stale)
        const StatusBanner(
          tone: BannerTone.warning,
          icon: Icons.hourglass_empty,
          title: 'Waiting for readings',
          message:
              'The scale is connected but nothing is coming through. '
              'Nothing is confirmed until it does.',
        ),
      if (s.overload)
        const StatusBanner(
          tone: BannerTone.danger,
          icon: Icons.warning_amber_rounded,
          title: 'Too much on the scale',
          message: 'Take some weight off. The 1 kg scale can\'t read this.',
        ),
      if (s.driftMg != null)
        StatusBanner(
          tone: BannerTone.warning,
          icon: Icons.info_outline,
          title: 'The reading changed while the scale was away',
          message:
              'It moved ${signedMg(s.driftMg!)}. Check the bowl is '
              'still on the scale before you carry on.',
          action: TextButton(
            onPressed: ctrl.dismissDrift,
            child: const Text('OK'),
          ),
        ),
    ];
  }

  /// quick hands for the simulator: pour exactly, or pour too much
  List<Widget> _simActions(SimulatedScale sim) {
    final s = state;
    if (s.phase != WeighPhase.pouring || s.remainingMg == null) return const [];
    final remaining = s.remainingMg!;
    return [
      if (remaining > s.toleranceMg)
        FilledButton.tonal(
          onPressed: () => sim.pourBy(remaining),
          child: Text('Pour to target (${formatMilligrams(remaining)})'),
        ),
      OutlinedButton(
        onPressed: () => sim.pourBy((remaining > 0 ? remaining : 0) + 2000),
        child: const Text('Pour 2 g too much'),
      ),
    ];
  }
}
