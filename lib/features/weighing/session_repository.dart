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
              toleranceMg: Value(s.toleranceMg),
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
              form: Value(step.form),
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

  /// the scale changed mid-session, keep the one that did the weighing
  Future<void> setScale(
    String sessionId, {
    required String scaleId,
    required String scaleName,
  }) => (_db.update(_db.weighingSessions)..where((x) => x.id.equals(sessionId)))
      .write(
        WeighingSessionsCompanion(
          scaleId: Value(scaleId),
          scaleName: Value(scaleName),
        ),
      );

  Future<WeighingSessionRow?> find(String id) => (_db.select(
    _db.weighingSessions,
  )..where((x) => x.id.equals(id))).getSingleOrNull();

  Future<List<WeighingStepRow>> stepsOf(String sessionId) =>
      (_db.select(_db.weighingSteps)
            ..where((x) => x.sessionId.equals(sessionId))
            ..orderBy([(x) => OrderingTerm.asc(x.position)]))
          .get();

  // ── history ──

  /// newest first, steps included. [formulaId] keeps it to one formula.
  /// every progress save touches the session row, so this re-emits as
  /// steps fill in too
  Stream<List<WeighingSession>> watchSessions({String? formulaId, int? limit}) {
    final q = _db.select(_db.weighingSessions)
      ..orderBy([(x) => OrderingTerm.desc(x.startedAt)]);
    if (formulaId != null) q.where((x) => x.formulaId.equals(formulaId));
    if (limit != null) q.limit(limit);
    return q.watch().asyncMap(_withSteps);
  }

  Future<WeighingSession?> load(String id) async {
    final row = await find(id);
    if (row == null) return null;
    return (await _withSteps([row])).single;
  }

  /// steps go with it (cascade)
  Future<void> delete(String id) =>
      (_db.delete(_db.weighingSessions)..where((x) => x.id.equals(id))).go();

  /// nothing can be mid-weighing when the app starts, so anything still
  /// "in progress" was cut off by the app closing. returns how many
  Future<int> markInterrupted() =>
      (_db.update(
        _db.weighingSessions,
      )..where((x) => x.status.equalsValue(SessionStatus.inProgress))).write(
        const WeighingSessionsCompanion(
          status: Value(SessionStatus.interrupted),
        ),
      );

  Future<List<WeighingSession>> _withSteps(
    List<WeighingSessionRow> rows,
  ) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();
    final stepRows =
        await (_db.select(_db.weighingSteps)
              ..where((x) => x.sessionId.isIn(ids))
              ..orderBy([(x) => OrderingTerm.asc(x.position)]))
            .get();

    final bySession = <String, List<WeighingStep>>{};
    for (final s in stepRows) {
      (bySession[s.sessionId] ??= []).add(
        WeighingStep(
          id: s.id,
          position: s.position,
          ingredientName: s.ingredientName,
          displayRgb: s.displayRgb,
          isDeveloper: s.isDeveloper,
          form: s.form,
          targetAddedDg: s.targetAddedDg,
          targetCumulativeDg: s.targetCumulativeDg,
          actualCumulativeMg: s.actualCumulativeMg,
          actualAddedMg: s.actualAddedMg,
          confirmedStable: s.confirmedStable,
          confirmedAt: s.confirmedAt,
        ),
      );
    }

    return [
      for (final r in rows)
        WeighingSession(
          id: r.id,
          formulaId: r.formulaId,
          formulaName: r.formulaName,
          deviceId: r.scaleId,
          deviceName: r.scaleName,
          steps: bySession[r.id] ?? const [],
          currentStepIndex: r.currentStepIndex,
          plannedTotalDg: r.plannedTotalDg,
          measuredTotalMg: r.measuredTotalMg,
          toleranceMg: r.toleranceMg,
          status: r.status,
          startedAt: r.startedAt,
          completedAt: r.finishedAt,
        ),
    ];
  }
}

/// all sessions, or one formula's
final sessionsProvider = StreamProvider.autoDispose
    .family<List<WeighingSession>, String?>(
      (ref, formulaId) => ref
          .watch(sessionRepositoryProvider)
          .watchSessions(formulaId: formulaId),
    );

final sessionByIdProvider = FutureProvider.autoDispose
    .family<WeighingSession?, String>(
      (ref, id) => ref.watch(sessionRepositoryProvider).load(id),
    );
