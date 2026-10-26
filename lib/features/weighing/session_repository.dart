import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/core/database/database_provider.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);

/// one row per session, one per step. planned amounts are copied in at the
/// start so editing the formula later doesn't change history
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  static String _stepId(String sessionId, int i) => '$sessionId-$i';

  Future<void> start(WeighingState s, {required String scaleId}) {
    return _db.transaction(() async {
      await _db
          .into(_db.weighingSessions)
          .insert(
            WeighingSessionsCompanion.insert(
              id: s.sessionId,
              formulaId: Value(s.formula.id),
              formulaName: s.formula.name,
              scaleId: scaleId,
              scaleName: s.deviceName,
              plannedTotalDg: s.plannedTotalMg ~/ 100,
              status: SessionStatus.inProgress,
              startedAt: s.startedAt,
            ),
          );
      await _db.batch((b) {
        b.insertAll(_db.weighingSteps, [
          for (final (i, step) in s.steps.indexed)
            WeighingStepsCompanion.insert(
              id: _stepId(s.sessionId, i),
              sessionId: s.sessionId,
              position: i,
              ingredientName: step.name,
              displayRgb: step.rgb,
              isDeveloper: Value(step.isDeveloper),
              targetAddedDg: step.targetAddedMg ~/ 100,
              targetCumulativeDg: s.plannedCumulativeMg(i) ~/ 100,
            ),
        ]);
      });
    });
  }

  /// current step plus every step's actuals, cleared ones included
  Future<void> saveProgress(WeighingState s) {
    return _db.transaction(() async {
      await (_db.update(
        _db.weighingSessions,
      )..where((x) => x.id.equals(s.sessionId))).write(
        WeighingSessionsCompanion(currentStepIndex: Value(s.stepIndex)),
      );
      for (final (i, r) in s.records.indexed) {
        await (_db.update(
          _db.weighingSteps,
        )..where((x) => x.id.equals(_stepId(s.sessionId, i)))).write(
          WeighingStepsCompanion(
            actualCumulativeMg: Value(r?.cumulativeMg),
            actualAddedMg: Value(r?.addedMg),
            confirmedStable: Value(r == null ? null : !r.manual),
            confirmedAt: Value(r?.at),
          ),
        );
      }
    });
  }

  Future<void> finish(
    WeighingState s,
    SessionStatus status, {
    required DateTime at,
  }) async {
    await saveProgress(s);
    await (_db.update(
      _db.weighingSessions,
    )..where((x) => x.id.equals(s.sessionId))).write(
      WeighingSessionsCompanion(
        status: Value(status),
        measuredTotalMg: Value(s.measuredTotalMg),
        finishedAt: Value(at),
      ),
    );
  }

  Future<WeighingSessionRow?> find(String id) => (_db.select(
    _db.weighingSessions,
  )..where((x) => x.id.equals(id))).getSingleOrNull();

  Future<List<WeighingStepRow>> stepsOf(String sessionId) =>
      (_db.select(_db.weighingSteps)
            ..where((x) => x.sessionId.equals(sessionId))
            ..orderBy([(x) => OrderingTerm.asc(x.position)]))
          .get();
}
