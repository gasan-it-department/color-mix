import 'package:colormix_studio/shared/models/product_form.dart';

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
    this.form = ProductForm.cream,
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
  final ProductForm form;
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
    this.toleranceMg,
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

  /// null for sessions saved before it was recorded
  final int? toleranceMg;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;

  int get doneSteps => steps.where((s) => s.isDone).length;

  /// the final total once finished, otherwise the last confirmed reading
  int? get weighedMg {
    if (measuredTotalMg != null) return measuredTotalMg;
    for (final s in steps.reversed) {
      if (s.isDone) return s.actualCumulativeMg;
    }
    return null;
  }
}
