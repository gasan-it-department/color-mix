import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

// one bowl, weighed cumulatively: zero once with the empty bowl, then every
// ingredient goes on top without taring again.
//
// each step's target is the *actual* reading the previous step was
// confirmed at plus this step's planned amount. so if Color A goes 0.5 g
// over, Color B still gets its full planned amount and the extra stays
// recorded against A. nothing is adjusted to "make up" for it.

enum WeighPhase {
  /// put the empty bowl on and zero
  placeBowl,

  /// zeroed, check it reads about 0 before pouring
  zeroed,
  pouring,

  /// all in, check the final weight
  review,
  done,
  cancelled,
}

enum PourZone {
  /// no live reading
  waiting,
  under,

  /// close, slow down
  approaching,
  onTarget,
  over,
}

/// cream swatch for the developer step
const developerRgb = 0xEDE6D8;

class StepPlan {
  const StepPlan({
    required this.name,
    required this.rgb,
    required this.targetAddedMg,
    this.isDeveloper = false,
    this.form = ProductForm.cream,
  });

  final String name;
  final int rgb;
  final int targetAddedMg;
  final bool isDeveloper;

  /// sets the slow-down band and the pour hints
  final ProductForm form;
}

class StepRecord {
  const StepRecord({
    required this.cumulativeMg,
    required this.addedMg,
    required this.at,
    this.manual = false,
  });

  /// net reading (bowl zeroed) when the step was confirmed
  final int cumulativeMg;
  final int addedMg;
  final DateTime at;

  /// moved on outside tolerance, short or over, because the stylist said so
  final bool manual;
}

List<StepPlan> stepsFor(ColorFormula f) => [
  for (final i in f.ingredients)
    StepPlan(
      name: i.name,
      rgb: i.displayRgb,
      targetAddedMg: i.requiredDg * 100,
      form: i.form,
    ),
  if (f.developerDg > 0)
    StepPlan(
      name: f.developerRatio == null
          ? 'Developer'
          : 'Developer ${f.developerRatio!.label}',
      rgb: developerRgb,
      targetAddedMg: f.developerDg * 100,
      isDeveloper: true,
      form: f.developerForm,
    ),
];

class WeighingState {
  const WeighingState({
    required this.sessionId,
    required this.formula,
    required this.steps,
    required this.records,
    required this.toleranceMg,
    required this.deviceName,
    required this.connection,
    required this.startedAt,
    this.phase = WeighPhase.placeBowl,
    this.stepIndex = 0,
    this.zeroMg,
    this.liveMg,
    this.stable = false,
    this.stale = false,
    this.overload = false,
    this.measuredTotalMg,
    this.pausedNetMg,
    this.driftMg,
  });

  factory WeighingState.start({
    required String sessionId,
    required ColorFormula formula,
    required int toleranceMg,
    required String deviceName,
    required ScaleConnectionState connection,
    required DateTime startedAt,
  }) {
    final steps = stepsFor(formula);
    return WeighingState(
      sessionId: sessionId,
      formula: formula,
      steps: steps,
      records: List.filled(steps.length, null),
      toleranceMg: toleranceMg,
      deviceName: deviceName,
      connection: connection,
      startedAt: startedAt,
    );
  }

  final String sessionId;
  final ColorFormula formula;
  final List<StepPlan> steps;
  final List<StepRecord?> records;
  final WeighPhase phase;
  final int stepIndex;
  final int toleranceMg;
  final String deviceName;
  final ScaleConnectionState connection;
  final DateTime startedAt;

  /// device reading taken as zero, with the empty bowl on
  final int? zeroMg;

  /// smoothed device reading, null while the scale is away
  final int? liveMg;
  final bool stable;
  final bool stale;
  final bool overload;
  final int? measuredTotalMg;

  /// net reading when the scale went away, to compare once it's back
  final int? pausedNetMg;

  /// how much the reading moved while the scale was away, when it's a lot
  final int? driftMg;

  // ── derived ──

  bool get connected => connection == ScaleConnectionState.connectedSupported;

  /// readings we can act on
  bool get live => connected && !stale && liveMg != null;

  /// what's in the bowl
  int? get netMg => liveMg == null || zeroMg == null ? null : liveMg! - zeroMg!;

  StepPlan get step => steps[stepIndex];

  bool get isLastStep => stepIndex == steps.length - 1;

  int get plannedTotalMg => steps.fold(0, (s, x) => s + x.targetAddedMg);

  /// planned cumulative reading after step [i], from the formula alone
  int plannedCumulativeMg(int i) =>
      steps.take(i + 1).fold(0, (s, x) => s + x.targetAddedMg);

  /// what the bowl held when this step started
  int get previousCumulativeMg =>
      stepIndex == 0 ? 0 : records[stepIndex - 1]!.cumulativeMg;

  int get targetAddedMg => step.targetAddedMg;

  int get targetCumulativeMg => previousCumulativeMg + targetAddedMg;

  /// added in this step so far
  int? get addedMg => netMg == null ? null : netMg! - previousCumulativeMg;

  int? get remainingMg => addedMg == null ? null : targetAddedMg - addedMg!;

  /// 1.0 = on target, can go past
  double? get progress => addedMg == null ? null : addedMg! / targetAddedMg;

  /// slow-down band before the target, wider for a liquid than a cream.
  /// see ProductForm
  int get approachMg => step.form.approachMg(targetAddedMg);

  PourZone get zone {
    final remaining = remainingMg;
    if (phase != WeighPhase.pouring || remaining == null || !live) {
      return PourZone.waiting;
    }
    if (remaining > approachMg) return PourZone.under;
    if (remaining > toleranceMg) return PourZone.approaching;
    if (remaining >= -toleranceMg) return PourZone.onTarget;
    return PourZone.over;
  }

  bool get _readyToAct => live && stable && !overload;

  bool get canZero =>
      (phase == WeighPhase.placeBowl || phase == WeighPhase.zeroed) &&
      _readyToAct;

  bool get canStartPouring =>
      phase == WeighPhase.zeroed && _readyToAct && netMg!.abs() <= toleranceMg;

  bool get canConfirm =>
      phase == WeighPhase.pouring && _readyToAct && zone == PourZone.onTarget;

  /// short or over, only with a steady reading
  bool get canMoveOnAnyway =>
      phase == WeighPhase.pouring &&
      _readyToAct &&
      zone != PourZone.onTarget &&
      zone != PourZone.waiting;

  /// back only while nothing's been poured on top of the previous step
  bool get canGoBack {
    if (!live) return false;
    if (phase == WeighPhase.review) {
      return (netMg! - records.last!.cumulativeMg).abs() <= toleranceMg;
    }
    return phase == WeighPhase.pouring &&
        stepIndex > 0 &&
        addedMg!.abs() <= toleranceMg;
  }

  bool get canComplete => phase == WeighPhase.review && _readyToAct;

  bool get finished =>
      phase == WeighPhase.done || phase == WeighPhase.cancelled;

  // ── transitions, each returns the next state ──

  WeighingState zero() => _copy(zeroMg: liveMg, phase: WeighPhase.zeroed);

  WeighingState beginPouring() =>
      _copy(phase: WeighPhase.pouring, stepIndex: 0);

  WeighingState confirmStep(DateTime at, {bool manual = false}) {
    final next = [...records];
    next[stepIndex] = StepRecord(
      cumulativeMg: netMg!,
      addedMg: addedMg!,
      at: at,
      manual: manual,
    );
    if (isLastStep) {
      return _copy(records: next, phase: WeighPhase.review);
    }
    return _copy(records: next, stepIndex: stepIndex + 1);
  }

  WeighingState back() {
    final next = [...records];
    if (phase == WeighPhase.review) {
      next[steps.length - 1] = null;
      return _copy(
        records: next,
        phase: WeighPhase.pouring,
        stepIndex: steps.length - 1,
      );
    }
    next[stepIndex - 1] = null;
    return _copy(records: next, stepIndex: stepIndex - 1);
  }

  WeighingState complete() =>
      _copy(phase: WeighPhase.done, measuredTotalMg: netMg);

  WeighingState cancel() => _copy(phase: WeighPhase.cancelled);

  WeighingState withReading({
    required int? liveMg,
    required bool stable,
    required bool overload,
  }) {
    return _copy(
      liveMg: liveMg,
      stable: stable,
      overload: overload,
      stale: false,
    );
  }

  WeighingState withConnection(ScaleConnectionState c) {
    final goingAway = connected && c != ScaleConnectionState.connectedSupported;
    return _copy(
      connection: c,
      // keep where the bowl was so we can compare when the scale is back
      pausedNetMg: goingAway ? netMg : pausedNetMg,
      liveMg: goingAway ? null : liveMg,
      stable: goingAway ? false : stable,
    );
  }

  /// a scale connected after the session started (it began with none, or
  /// the last scale was connected from the banner)
  WeighingState withDevice(String name) => _copy(deviceName: name);

  WeighingState markStale() => _copy(stale: true, stable: false);

  /// first steady reading after a reconnect: did anything move?
  WeighingState checkDrift() {
    final before = pausedNetMg;
    final now = netMg;
    if (before == null || now == null) return this;
    final moved = now - before;
    return _copy(pausedNetMg: null, driftMg: moved.abs() > 1000 ? moved : null);
  }

  WeighingState dismissDrift() => _copy(driftMg: null);

  WeighingState _copy({
    List<StepRecord?>? records,
    WeighPhase? phase,
    int? stepIndex,
    ScaleConnectionState? connection,
    String? deviceName,
    int? zeroMg,
    Object? liveMg = _keep,
    bool? stable,
    bool? stale,
    bool? overload,
    int? measuredTotalMg,
    Object? pausedNetMg = _keep,
    Object? driftMg = _keep,
  }) {
    return WeighingState(
      sessionId: sessionId,
      formula: formula,
      steps: steps,
      records: records ?? this.records,
      toleranceMg: toleranceMg,
      deviceName: deviceName ?? this.deviceName,
      connection: connection ?? this.connection,
      startedAt: startedAt,
      phase: phase ?? this.phase,
      stepIndex: stepIndex ?? this.stepIndex,
      zeroMg: zeroMg ?? this.zeroMg,
      liveMg: identical(liveMg, _keep) ? this.liveMg : liveMg as int?,
      stable: stable ?? this.stable,
      stale: stale ?? this.stale,
      overload: overload ?? this.overload,
      measuredTotalMg: measuredTotalMg ?? this.measuredTotalMg,
      pausedNetMg: identical(pausedNetMg, _keep)
          ? this.pausedNetMg
          : pausedNetMg as int?,
      driftMg: identical(driftMg, _keep) ? this.driftMg : driftMg as int?,
    );
  }
}

const Object _keep = Object();
