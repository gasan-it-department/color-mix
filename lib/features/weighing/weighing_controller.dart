import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/bluetooth/stability_detector.dart';
import 'package:colormix_studio/features/formulation/formula_seed.dart';
import 'package:colormix_studio/features/saved_formulas/formula_providers.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_alerts.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

/// no reading for this long while connected = stale, nothing gets confirmed
const staleAfter = Duration(seconds: 1);

/// taps closer than this to the last step change are ignored
const doubleTapGuard = Duration(milliseconds: 600);

/// one weighing session per open screen, keyed by formula id
final weighingProvider = AsyncNotifierProvider.autoDispose
    .family<WeighingController, WeighingState, String>(WeighingController.new);

class WeighingController extends AsyncNotifier<WeighingState> {
  WeighingController(this.formulaId);

  final String formulaId;

  late StabilityDetector _detector;
  StreamSubscription<WeightReading>? _readings;
  Timer? _staleTimer;
  DateTime? _lastReadingAt;

  /// when we started waiting for readings, for a scale that never sends any
  DateTime? _waitingSince;

  /// last step or phase change. "Finish" and "Complete" sit in the same
  /// spot, a double tap mustn't skip the final check
  DateTime? _changedAt;
  bool _closed = false;

  @override
  Future<WeighingState> build() async {
    ref.onDispose(() {
      _closed = true;
      _readings?.cancel();
      _staleTimer?.cancel();
    });

    final formula = await ref.read(formulaRepositoryProvider).find(formulaId);
    if (formula == null) throw StateError('formula $formulaId not found');

    final settings = ref.read(settingsProvider);
    _detector = StabilityDetector(
      thresholdMg: settings.stabilityThresholdMg,
      dwell: Duration(milliseconds: settings.stabilityDwellMs),
    );

    final scale = ref.read(scaleProvider);
    final initial = WeighingState.start(
      sessionId: newId(),
      formula: formula,
      toleranceMg: settings.toleranceDg * 100,
      deviceName: scale.device?.info.name ?? 'No scale',
      connection: scale.connection,
      startedAt: clock.now(),
    );
    await ref
        .read(sessionRepositoryProvider)
        .start(initial, scaleId: scale.device?.info.id ?? 'none');

    _listenTo(scale.device);
    ref.listen<ScaleStatus>(scaleProvider, (prev, next) {
      if (prev?.device != next.device) _listenTo(next.device);
      _onConnection(next.connection);
    });
    _staleTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _checkStale(),
    );

    return initial;
  }

  WeighingState? get _now => state.value;

  void _set(WeighingState next) {
    if (_closed) return;
    state = AsyncData(next);
  }

  // ── scale events ──

  void _listenTo(ScaleDevice? device) {
    _readings?.cancel();
    _detector.reset();
    _waitingSince = clock.now();
    _readings = device?.weightStream.listen(_onReading);
  }

  void _onReading(WeightReading r) {
    final s = _now;
    if (s == null || s.finished) return;
    _lastReadingAt = clock.now();
    _detector.add(r);

    var next = s.withReading(
      liveMg: _detector.smoothedMg,
      stable: _detector.isStable,
      overload: r.overload,
    );
    if (next.pausedNetMg != null && next.stable) next = next.checkDrift();

    _alertOnZoneChange(s, next);
    _set(next);

    if (ref.read(settingsProvider).autoAdvance && next.canConfirm) {
      unawaited(confirmStep());
    }
  }

  void _onConnection(ScaleConnectionState c) {
    final s = _now;
    if (s == null || s.finished || s.connection == c) return;
    if (s.connected && c != ScaleConnectionState.connectedSupported) {
      ref.read(weighingAlertsProvider).disconnected();
    }
    _detector.reset();
    _lastReadingAt = null;
    _waitingSince = clock.now();
    _set(s.withConnection(c));
  }

  void _checkStale() {
    final s = _now;
    final since = _lastReadingAt ?? _waitingSince;
    if (s == null || s.finished || !s.connected || s.stale) return;
    if (since != null && clock.now().difference(since) > staleAfter) {
      _detector.reset();
      _set(s.markStale());
    }
  }

  bool get _tooSoon {
    final at = _changedAt;
    return at != null && clock.now().difference(at) < doubleTapGuard;
  }

  void _stepChanged(WeighingState next) {
    _changedAt = clock.now();
    _set(next);
  }

  void _alertOnZoneChange(WeighingState before, WeighingState after) {
    if (after.phase != WeighPhase.pouring) return;
    if (before.stepIndex != after.stepIndex) return;
    final from = before.zone;
    final to = after.zone;
    if (from == to) return;
    final alerts = ref.read(weighingAlertsProvider);
    switch (to) {
      case PourZone.approaching when from == PourZone.under:
        alerts.approaching();
      case PourZone.onTarget:
        alerts.reached();
      case PourZone.over:
        alerts.over();
      default:
        break;
    }
  }

  // ── actions ──

  void zero() {
    final s = _now;
    if (s == null || !s.canZero) return;
    _set(s.zero());
  }

  void beginPouring() {
    final s = _now;
    if (s == null || !s.canStartPouring || _tooSoon) return;
    _stepChanged(s.beginPouring());
    unawaited(_saveProgress());
  }

  /// [manual] moves on short or over, the deviation stays on record
  Future<void> confirmStep({bool manual = false}) async {
    final s = _now;
    if (s == null || _tooSoon) return;
    if (manual ? !s.canMoveOnAnyway : !s.canConfirm) return;
    _stepChanged(s.confirmStep(clock.now(), manual: manual));
    await _saveProgress();
  }

  Future<void> back() async {
    final s = _now;
    if (s == null || !s.canGoBack || _tooSoon) return;
    _stepChanged(s.back());
    await _saveProgress();
  }

  Future<void> complete() async {
    final s = _now;
    if (s == null || !s.canComplete || _tooSoon) return;
    final done = s.complete();
    _set(done);
    await ref
        .read(sessionRepositoryProvider)
        .finish(done, SessionStatus.completed, at: clock.now());
  }

  Future<void> cancel() async {
    final s = _now;
    if (s == null || s.finished) return;
    final cancelled = s.cancel();
    _set(cancelled);
    await ref
        .read(sessionRepositoryProvider)
        .finish(cancelled, SessionStatus.cancelled, at: clock.now());
  }

  void dismissDrift() {
    final s = _now;
    if (s != null) _set(s.dismissDrift());
  }

  Future<void> _saveProgress() async {
    final s = _now;
    if (s != null) await ref.read(sessionRepositoryProvider).saveProgress(s);
  }
}
