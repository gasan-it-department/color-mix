enum SessionStatus { inProgress, completed, cancelled, interrupted }

/// one ingredient poured during a session. targets are copied from the
/// formula when the session starts so editing the formula later doesn't
/// rewrite history.
class WeighingStep {
  const WeighingStep({
    required this.id,
    required this.position,
    required this.ingredientName,
    required this.displayRgb,
    required this.targetAddedDg,
    required this.targetCumulativeDg,
    this.isDeveloper = false,
    this.actualCumulativeMg,
    this.actualAddedMg,
    this.confirmedStable,
    this.confirmedAt,
  });

  final String id;
  final int position;
  final String ingredientName;
  final int displayRgb;
  final bool isDeveloper;
  final int targetAddedDg;
  final int targetCumulativeDg;
  final int? actualCumulativeMg;
  final int? actualAddedMg;
  final bool? confirmedStable;
  final DateTime? confirmedAt;

  bool get isDone => actualCumulativeMg != null;

  /// actual minus target for what was added in this step
  int? get deviationMg =>
      actualAddedMg == null ? null : actualAddedMg! - targetAddedDg * 100;
}

class WeighingSession {
  const WeighingSession({
    required this.id,
    required this.formulaName,
    required this.deviceId,
    required this.deviceName,
    required this.steps,
    required this.plannedTotalDg,
    required this.status,
    required this.startedAt,
    this.formulaId,
    this.currentStepIndex = 0,
    this.measuredTotalMg,
    this.completedAt,
  });

  final String id;

  /// null once the formula is deleted, the session stays
  final String? formulaId;
  final String formulaName;
  final String deviceId;
  final String deviceName;
  final List<WeighingStep> steps;
  final int currentStepIndex;
  final int plannedTotalDg;
  final int? measuredTotalMg;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
}
