import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/formulation/formula_math.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/features/weighing/widgets/weighing_bits.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';
import 'package:colormix_studio/core/widgets/app_page.dart';

enum CalStep { empty, reference, check }

/// the serial menu's z / k steps for the ColorMix scale, then a check
/// against known weights. the scale keeps the result in its own flash
class CalibrationScreen extends ConsumerWidget {
  const CalibrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(scaleProvider.select((s) => s.device));

    return Scaffold(
      appBar: AppBar(title: const Text('Calibrate the scale')),
      body: device is BleScaleDevice && device.supportsCalibration
          // calibrated / problem come from the device as they change
          ? ListenableBuilder(
              listenable: device,
              builder: (context, _) => _Wizard(device: device),
            )
          : EmptyState(
              icon: Icons.scale_outlined,
              title: 'Connect the ColorMix scale first',
              message:
                  'Calibration runs on the scale itself. Connect it, then '
                  'come back here. The simulated scale needs none.',
              action: FilledButton.tonal(
                onPressed: () => context.go(Routes.scale),
                child: const Text('Find a scale'),
              ),
            ),
    );
  }
}

class _Wizard extends ConsumerStatefulWidget {
  const _Wizard({required this.device});

  final BleScaleDevice device;

  @override
  ConsumerState<_Wizard> createState() => _WizardState();
}

class _WizardState extends ConsumerState<_Wizard> {
  final _mass = TextEditingController();
  final _check = TextEditingController();
  var _step = CalStep.empty;
  bool _busy = false;
  String? _error;
  bool _massTouched = false;

  @override
  void dispose() {
    _mass.dispose();
    _check.dispose();
    super.dispose();
  }

  int? get _massMg => parseGramsToMg(_mass.text);

  int get _capacityMg =>
      (int.tryParse(widget.device.deviceInfo['cap_g'] ?? '') ?? 1000) * 1000;

  String? get _massError {
    if (!_massTouched) return null;
    final mg = _massMg;
    if (mg == null) return 'Its mass in grams, like 200 or 523.4.';
    if (mg < minCalibrationMassMg) return 'At least 10 g.';
    if (mg > _capacityMg) {
      return 'More than the scale takes (${formatMilligrams(_capacityMg)}).';
    }
    return null;
  }

  Future<void> _run(Future<void> Function() action, CalStep next) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _step = next);
    } on ScaleCommandException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _zero() => _run(widget.device.calibrateZero, CalStep.reference);

  void _calibrate() {
    setState(() => _massTouched = true);
    final mg = _massMg;
    if (mg == null || _massError != null) return;
    _check.text = _mass.text.trim();
    _run(() => widget.device.calibrateKnownMass(mg), CalStep.check);
  }

  void _restart() => setState(() {
    _step = CalStep.empty;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(scaleProvider.select((s) => s.connection));
    final connected = connection == ScaleConnectionState.connectedSupported;
    final narrow = isNarrow(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.wizardMaxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            narrow ? 16 : 24,
            8,
            narrow ? 16 : 24,
            32,
          ),
          children: [
            _Steps(current: _step),
            const SizedBox(height: 16),
            if (!connected)
              StatusBanner(
                tone: BannerTone.danger,
                icon: Icons.bluetooth_disabled,
                title: connection == ScaleConnectionState.connecting
                    ? 'Reconnecting…'
                    : 'Scale disconnected',
                message:
                    'Reconnect to carry on. If the scale was switched off, '
                    'start again from step 1.',
                action: connection == ScaleConnectionState.connecting
                    ? null
                    : FilledButton.tonal(
                        onPressed: ref.read(scaleProvider.notifier).reconnect,
                        child: const Text('Reconnect'),
                      ),
              ),
            _LiveReading(connected: connected),
            const SizedBox(height: 12),
            switch (_step) {
              CalStep.empty => _emptyStep(context, connected),
              CalStep.reference => _referenceStep(context, connected),
              CalStep.check => _checkStep(context),
            },
            if (_error != null) ...[
              const SizedBox(height: 12),
              StatusBanner(
                tone: BannerTone.danger,
                icon: Icons.error_outline,
                title: 'That didn\'t work',
                message: _error!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _text(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );

  Widget _busyLabel(String idle) => _busy
      ? const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text('Measuring…', overflow: TextOverflow.ellipsis),
            ),
          ],
        )
      : Text(idle);

  /// under the button while the scale averages
  List<Widget> _stillNote(BuildContext context) => [
    if (_busy) ...[
      const SizedBox(height: 8),
      _text(context, 'Keep it still, the scale takes a couple of seconds.'),
    ],
  ];

  Widget _emptyStep(BuildContext context, bool connected) {
    return SectionCard(
      title: 'Empty the platform',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            context,
            'Take everything off the platform, the bowl too, and keep the '
            'bench still. If the scale was just switched on, give it a few '
            'minutes to warm up first.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: connected && !_busy ? _zero : null,
            child: _busyLabel('Zero the scale'),
          ),
          ..._stillNote(context),
        ],
      ),
    );
  }

  Widget _referenceStep(BuildContext context, bool connected) {
    return SectionCard(
      title: 'Put the reference weight on',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _text(
            context,
            'Place a weight you know exactly in the middle of the platform. '
            '200 g or more works best, 10 g at the least: a kitchen-scale '
            'test weight, or a sealed bottle weighed on a good scale.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mass,
            enabled: !_busy,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _calibrate(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Its exact mass',
              hintText: 'e.g. 200',
              suffixText: 'g',
              errorText: _massError,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: connected && !_busy ? _calibrate : null,
                child: _busyLabel('Calibrate'),
              ),
              TextButton(
                onPressed: _busy ? null : _restart,
                child: const Text('Back to step 1'),
              ),
            ],
          ),
          ..._stillNote(context),
        ],
      ),
    );
  }

  Widget _checkStep(BuildContext context) {
    final theme = Theme.of(context);
    final reading = ref.watch(scaleReadingProvider).value;
    final toleranceMg = ref.watch(settingsProvider).toleranceDg * 100;
    final knownMg = parseGramsToMg(_check.text);
    final diff = reading == null || knownMg == null
        ? null
        : reading.milligrams - knownMg;
    final steady = reading?.isStable ?? false;

    Widget verdict() {
      if (knownMg == null) return _text(context, 'Type the weight you put on.');
      if (diff == null || !steady) {
        return _text(context, 'Waiting for a steady reading…');
      }
      final ok = diff.abs() <= toleranceMg;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Off by ${signedMg(diff)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              LabelTag(
                ok
                    ? 'Within ±${formatMilligrams(toleranceMg)}'
                    : 'More than ±${formatMilligrams(toleranceMg)}',
                tone: ok ? TagTone.success : TagTone.warning,
              ),
            ],
          ),
          if (!ok) ...[
            const SizedBox(height: 6),
            _text(
              context,
              'Check the weight sits in the middle and nothing touches the '
              'platform. If it stays off, calibrate again.',
            ),
          ],
        ],
      );
    }

    return SectionCard(
      title: 'Check it',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 20, color: context.status.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Calibrated. The scale keeps it after it\'s switched off.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _text(
            context,
            'The reference weight should read close to its mass. Try one or '
            'two other weights you know as well, change the number to match.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _check,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Known weight on the platform',
              suffixText: 'g',
            ),
          ),
          const SizedBox(height: 12),
          verdict(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Done'),
              ),
              TextButton(
                onPressed: _restart,
                child: const Text('Calibrate again'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 1 empty · 2 reference · 3 check
class _Steps extends StatelessWidget {
  const _Steps({required this.current});

  final CalStep current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const labels = ['Empty', 'Reference', 'Check'];

    return Row(
      children: [
        for (final step in CalStep.values) ...[
          if (step.index > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: step == current ? scheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                  color: step == current
                      ? scheme.primaryContainer
                      : scheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (step.index < current.index)
                    Icon(Icons.check, size: 16, color: context.status.success)
                  else
                    Text(
                      '${step.index + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: step == current
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      labels[step.index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: step == current
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: step == current
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LiveReading extends ConsumerWidget {
  const _LiveReading({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final reading = connected ? ref.watch(scaleReadingProvider).value : null;

    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live reading', style: muted),
                Text(
                  reading == null ? '—' : formatMilligrams(reading.milligrams),
                  style: context.type.figureSmall,
                ),
                if (reading?.uncalibrated ?? false)
                  Text('Rough until calibrated', style: muted),
              ],
            ),
          ),
          StabilityChip(
            live: reading != null,
            stable: reading?.isStable ?? false,
          ),
        ],
      ),
    );
  }
}
