import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

import 'weighing_state_test.dart' show roseGold;

void main() {
  late AppDatabase db;
  late SessionRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = SessionRepository(db);
    await FormulaRepository(db).save(roseGold());
  });

  tearDown(() => db.close());

  WeighingState start() => WeighingState.start(
    sessionId: 'sess',
    formula: roseGold(),
    toleranceMg: 300,
    deviceName: 'Simulated scale',
    connection: ScaleConnectionState.connectedSupported,
    startedAt: DateTime(2026, 10, 26, 10),
  );

  WeighingState net(WeighingState s, int mg) =>
      s.withReading(liveMg: 250000 + mg, stable: true, overload: false);

  test(
    'start copies the plan in, progress and finish fill the actuals',
    () async {
      var s = start();
      await repo.start(s, scaleId: 'simulator');

      var row = (await repo.find('sess'))!;
      expect(row.status, SessionStatus.inProgress);
      expect(row.plannedTotalDg, 1200);
      expect(row.scaleName, 'Simulated scale');
      var steps = await repo.stepsOf('sess');
      expect(steps.map((x) => x.targetCumulativeDg), [300, 480, 600, 1200]);
      expect(steps.every((x) => x.actualAddedMg == null), isTrue);

      s = net(s, 0).zero().beginPouring();
      s = net(
        s,
        32000,
      ).confirmStep(DateTime(2026, 10, 26, 10, 1), manual: true);
      await repo.saveProgress(s);

      steps = await repo.stepsOf('sess');
      expect(steps[0].actualAddedMg, 32000);
      expect(steps[0].confirmedStable, isFalse);
      expect((await repo.find('sess'))!.currentStepIndex, 1);

      for (final c in [50000, 62000, 122000]) {
        s = net(s, c).confirmStep(DateTime(2026, 10, 26, 10, 2));
      }
      s = net(s, 122000).complete();
      await repo.finish(
        s,
        SessionStatus.completed,
        at: DateTime(2026, 10, 26, 10, 3),
      );

      row = (await repo.find('sess'))!;
      expect(row.status, SessionStatus.completed);
      expect(row.measuredTotalMg, 122000);
      expect(row.finishedAt, isNotNull);
      steps = await repo.stepsOf('sess');
      expect(steps.map((x) => x.actualAddedMg), [32000, 18000, 12000, 60000]);
    },
  );

  test('history comes back newest first with steps, per formula too', () async {
    var s = start();
    await repo.start(s, scaleId: 'simulator');
    s = net(s, 0).zero().beginPouring();
    s = net(s, 31000).confirmStep(DateTime(2026, 10, 26, 10, 1));
    await repo.finish(
      s.cancel(),
      SessionStatus.cancelled,
      at: DateTime(2026, 10, 26, 10, 2),
    );

    final later = WeighingState.start(
      sessionId: 'sess2',
      formula: roseGold(),
      toleranceMg: 300,
      deviceName: 'ColorMix Scale',
      connection: ScaleConnectionState.connectedSupported,
      startedAt: DateTime(2026, 10, 27, 9),
    );
    await repo.start(later, scaleId: 'AA:BB');

    final all = await repo.watchSessions().first;
    expect(all.map((x) => x.id), ['sess2', 'sess']);
    final first = all.last;
    expect(first.status, SessionStatus.cancelled);
    expect(first.steps, hasLength(4));
    expect(first.steps[0].actualAddedMg, 31000);
    expect(first.steps[0].deviationMg, 1000);
    expect(first.steps[1].isDone, isFalse);
    expect(first.completedAt, DateTime(2026, 10, 26, 10, 2));
    expect(all.first.deviceName, 'ColorMix Scale');

    expect(await repo.watchSessions(formulaId: 'f').first, hasLength(2));
    expect(await repo.watchSessions(formulaId: 'other').first, isEmpty);
    expect((await repo.load('sess'))!.steps, hasLength(4));
    expect(await repo.load('nope'), isNull);
  });

  test('markInterrupted only touches sessions still in progress', () async {
    final s = start();
    await repo.start(s, scaleId: 'simulator');
    await repo.finish(
      s.cancel(),
      SessionStatus.cancelled,
      at: DateTime(2026, 10, 26, 10, 2),
    );
    await repo.start(
      WeighingState.start(
        sessionId: 'open',
        formula: roseGold(),
        toleranceMg: 300,
        deviceName: 'Simulated scale',
        connection: ScaleConnectionState.connectedSupported,
        startedAt: DateTime(2026, 10, 26, 11),
      ),
      scaleId: 'simulator',
    );

    expect(await repo.markInterrupted(), 1);
    expect((await repo.find('open'))!.status, SessionStatus.interrupted);
    expect((await repo.find('sess'))!.status, SessionStatus.cancelled);
  });

  test('the tolerance is kept with the session', () async {
    await repo.start(start(), scaleId: 'simulator');
    expect((await repo.load('sess'))!.toleranceMg, 300);
  });

  test('delete takes the steps with it', () async {
    await repo.start(start(), scaleId: 'simulator');
    await repo.delete('sess');
    expect(await repo.find('sess'), isNull);
    expect(await repo.stepsOf('sess'), isEmpty);
  });

  test('deleting the formula keeps the session', () async {
    await repo.start(start(), scaleId: 'simulator');
    await FormulaRepository(db).delete('f');

    final row = (await repo.find('sess'))!;
    expect(row.formulaId, isNull);
    expect(row.formulaName, 'Rose Gold Demo');
    expect(await repo.stepsOf('sess'), hasLength(4));
  });
}
