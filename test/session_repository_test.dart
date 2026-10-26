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

  test('deleting the formula keeps the session', () async {
    await repo.start(start(), scaleId: 'simulator');
    await FormulaRepository(db).delete('f');

    final row = (await repo.find('sess'))!;
    expect(row.formulaId, isNull);
    expect(row.formulaName, 'Rose Gold Demo');
    expect(await repo.stepsOf('sess'), hasLength(4));
  });
}
