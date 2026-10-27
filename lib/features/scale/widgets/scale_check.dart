import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/bluetooth/ble_scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/utils/reading_stats.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

/// how long the noise measurement runs
const noiseRun = Duration(seconds: 10);

/// 0.04 g. the noise numbers need the second decimal the display rounds off
String _g(num mg, {bool sign = false}) {
  var s = (mg / 1000).toStringAsFixed(2);
  // a hair either side of zero reads 0.00, not -0.00 or +0.00
  if (s == '-0.00') s = '0.00';
  return sign && mg > 0 && s != '0.00' ? '+$s g' : '$s g';
}

/// for setting up a scale: is the link healthy, how noisy is it, do the
/// steady and tolerance settings suit it. folded away, a stylist doesn't
/// need it day to day. the numbers go on docs/hardware_test.md
class ScaleCheck extends ConsumerStatefulWidget {
  const ScaleCheck({super.key, required this.device});

  final ScaleDevice device;

  @override
  ConsumerState<ScaleCheck> createState() => _ScaleCheckState();
}

class _ScaleCheckState extends ConsumerState<ScaleCheck> {
  bool _open = false;
  StreamSubscription<WeightReading>? _sub;
  Timer? _tick;

  /// arrival times over the last 2 s, for the rate
  final _recent = Queue<DateTime>();

  bool _testing = false;
  String? _testResult;
  bool _testFailed = false;

  ReadingStats? _running;
  DateTime? _runStarted;
  bool _runUncalibrated = false;
  ReadingStats? _result;
  bool _resultUncalibrated = false;
  String? _runProblem;

  @override
  void didUpdateWidget(ScaleCheck old) {
    super.didUpdateWidget(old);
    if (old.device != widget.device) {
      _stop();
      _resetResults();
      if (_open) _start();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    _sub = widget.device.weightStream.listen(_onReading);
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) => _onTick());
  }

  void _stop() {
    // not awaited, see ble_scale_device.dart
    unawaited(_sub?.cancel());
    _sub = null;
    _tick?.cancel();
    _tick = null;
    _recent.clear();
    _running = null;
  }

  void _resetResults() {
    _testResult = null;
    _result = null;
    _runProblem = null;
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _start() : _stop();
  }

  // the last 2 s, not counting both ends: 20 readings is 10 a second
  void _trim(DateTime now) {
    while (_recent.isNotEmpty &&
        now.difference(_recent.first) >= const Duration(seconds: 2)) {
      _recent.removeFirst();
    }
  }

  void _onReading(WeightReading r) {
    final now = clock.now();
    _recent.add(now);
    _trim(now);
    final run = _running;
    if (run != null) {
      run.add(r.milligrams);
      _runUncalibrated |= r.uncalibrated;
    }
  }

  void _onTick() {
    final now = clock.now();
    _trim(now);
    final started = _runStarted;
    if (_running != null &&
        started != null &&
        now.difference(started) >= noiseRun) {
      _finishRun();
    }
    if (mounted) setState(() {});
  }

  void _measure() {
    setState(() {
      _running = ReadingStats();
      _runStarted = clock.now();
      _runUncalibrated = false;
      _result = null;
      _runProblem = null;
    });
  }

  void _finishRun() {
    final run = _running!;
    _running = null;
    if (run.count < 2) {
      _runProblem =
          'Hardly any readings came in. Check the scale is connected and '
          'sending.';
      return;
    }
    _result = run;
    _resultUncalibrated = _runUncalibrated;
  }

  Future<void> _testConnection(BleScaleDevice ble) async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final took = await ble.testConnection();
      final info = ble.deviceInfo;
      _testFailed = false;
      _testResult = [
        'Answered in ${took.inMilliseconds} ms',
        if (info['fw'] != null) 'firmware ${info['fw']}',
        if (info['proto'] != null) 'protocol ${info['proto']}',
        if (info['cap_g'] != null) 'up to ${info['cap_g']} g',
        ble.calibrated ? 'calibrated' : 'not calibrated',
      ].join(' · ');
    } on ScaleCommandException catch (e) {
      _testFailed = true;
      _testResult = e.message;
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SectionCard(
      title: 'Scale check',
      trailing: TextButton(
        onPressed: _toggle,
        child: Text(_open ? 'Hide' : 'Show'),
      ),
      child: _open
          ? _body(context)
          : Text(
              'Connection and noise checks, for setting up a scale.',
              style: muted,
            ),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final device = widget.device;
    final ble = device is BleScaleDevice ? device : null;
    final rate = (_recent.length / 2).round();
    final run = _running;
    final started = _runStarted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          [
            '$rate readings a second',
            if (ble != null) ...[
              '${ble.missedFrames} missed',
              '${ble.badFrames} unreadable',
            ],
          ].join(' · '),
          style: theme.textTheme.bodyMedium,
        ),
        if (ble != null && ble.supportsTare) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _testing || !device.isConnected
                  ? null
                  : () => _testConnection(ble),
              child: Text(_testing ? 'Testing…' : 'Test connection'),
            ),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 6),
            Text(
              _testResult!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _testFailed ? context.status.danger : null,
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        Text('Noise', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Leave the platform still, empty or with a weight on, and measure '
          'for ${noiseRun.inSeconds} s.',
          style: muted,
        ),
        const SizedBox(height: 10),
        if (run != null && started != null) ...[
          LinearProgressIndicator(
            value:
                (clock.now().difference(started).inMilliseconds /
                        noiseRun.inMilliseconds)
                    .clamp(0, 1)
                    .toDouble(),
          ),
          const SizedBox(height: 6),
          Text('Measuring, keep it still…', style: muted),
        ] else
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: device.isConnected ? _measure : null,
              child: Text(_result == null ? 'Measure noise' : 'Measure again'),
            ),
          ),
        if (_runProblem != null) ...[
          const SizedBox(height: 8),
          Text(
            _runProblem!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.status.danger,
            ),
          ),
        ],
        if (_result != null && run == null) ...[
          const SizedBox(height: 12),
          _NoiseResult(stats: _result!, uncalibrated: _resultUncalibrated),
        ],
      ],
    );
  }
}

class _NoiseResult extends ConsumerWidget {
  const _NoiseResult({required this.stats, required this.uncalibrated});

  final ReadingStats stats;
  final bool uncalibrated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final s = stats;
    final steadyMg = settings.stabilityThresholdMg;
    final toleranceMg = settings.toleranceDg * 100;
    final drift = s.driftMg;

    Widget verdict(bool ok, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 18,
            color: ok ? context.status.success : context.status.warning,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _Num('Average', _g(s.meanMg)),
            _Num('Swing', _g(s.swingMg), strong: true),
            _Num('Std dev', _g(s.stdDevMg)),
            _Num('Drift', _g(drift, sign: true)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${s.count} readings. Swing is the biggest minus the smallest.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        // the rules from docs/hardware_test.md, section 4
        s.swingMg <= steadyMg
            ? verdict(
                true,
                'Steady works: the swing stays under the '
                '${formatMilligrams(steadyMg)} steady threshold.',
              )
            : verdict(
                false,
                'The swing is over the ${formatMilligrams(steadyMg)} steady '
                'threshold, steps may not settle. Check nothing touches the '
                'platform, or raise the threshold in Settings.',
              ),
        toleranceMg >= 2 * s.swingMg
            ? verdict(
                true,
                'The ±${formatMilligrams(toleranceMg)} tolerance is at least '
                'twice the swing.',
              )
            : verdict(
                false,
                'The ±${formatMilligrams(toleranceMg)} tolerance is less than '
                'twice the swing, readings may flick in and out of target. '
                'Widen it in Settings, or find a steadier bench.',
              ),
        if (drift.abs() > 100)
          verdict(
            false,
            'It drifted ${_g(drift, sign: true)} in ${noiseRun.inSeconds} s. '
            'Let the scale warm up a few minutes, or move it out of draughts.',
          ),
        if (uncalibrated)
          verdict(
            false,
            'The scale isn\'t calibrated, so these grams are only rough.',
          ),
      ],
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(this.label, this.value, {this.strong = false});

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
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
