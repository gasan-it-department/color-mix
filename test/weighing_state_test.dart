import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

final t0 = DateTime(2026, 10, 26, 10);

/// the blueprint's example: 30 / 18 / 12 g and 60 g developer
ColorFormula roseGold() => ColorFormula(
  id: 'f',
  name: 'Rose Gold Demo',
  targetRgb: 0xB76E79,
  totalDyeDg: 600,
  developerRatio: const DeveloperRatio(100),
  developerDg: 600,
  totalMixtureDg: 1200,
  createdAt: t0,
  updatedAt: t0,
  ingredients: const [
    FormulaIngredient(
      id: 'a',
      name: 'Color A',
      percentHundredths: 5000,
      requiredDg: 300,
      displayRgb: 1,
    ),
    FormulaIngredient(
      id: 'b',
      name: 'Color B',
      percentHundredths: 3000,
      requiredDg: 180,
      displayRgb: 2,
    ),
    FormulaIngredient(
      id: 'c',
      name: 'Color C',
      percentHundredths: 2000,
      requiredDg: 120,
      displayRgb: 3,
    ),
  ],
);

const bowl = 250000;

WeighingState fresh() => WeighingState.start(
  sessionId: 's',
  formula: roseGold(),
  toleranceMg: 300,
  deviceName: 'Simulated scale',
  connection: ScaleConnectionState.connectedSupported,
  startedAt: t0,
);

extension on WeighingState {
  /// steady device reading
  WeighingState reads(int deviceMg, {bool stable = true}) =>
      withReading(liveMg: deviceMg, stable: stable, overload: false);

  /// bowl net reading
  WeighingState net(int mg, {bool stable = true}) =>
      reads(bowl + mg, stable: stable);
}

/// bowl on, zeroed, pouring step 1
WeighingState pouring() => fresh().reads(bowl).zero().beginPouring();

void main() {
  test('steps come from the formula, developer last', () {
    final s = fresh();
    expect(s.steps.map((x) => x.name), [
      'Color A',
      'Color B',
      'Color C',
      'Developer 1:1',
    ]);
    expect(s.steps.map((x) => x.targetAddedMg), [30000, 18000, 12000, 60000]);
    expect(s.plannedTotalMg, 120000);
    expect(
      [for (var i = 0; i < 4; i++) s.plannedCumulativeMg(i)],
      [30000, 48000, 60000, 120000],
    );
  });

  test('zero needs a steady live reading', () {
    final s = fresh();
    expect(s.canZero, isFalse);
    expect(s.reads(bowl, stable: false).canZero, isFalse);
    expect(s.reads(bowl).canZero, isTrue);

    final zeroed = s.reads(bowl).zero();
    expect(zeroed.phase, WeighPhase.zeroed);
    expect(zeroed.netMg, 0);
    expect(zeroed.canStartPouring, isTrue);

    // something got bumped after zeroing
    expect(zeroed.net(2000).canStartPouring, isFalse);
  });

  test('zones while pouring Color A', () {
    final s = pouring();
    expect(s.net(10000).zone, PourZone.under);
    // approach band is 3 g on a 30 g step
    expect(s.net(27500).zone, PourZone.approaching);
    expect(s.net(29800).zone, PourZone.onTarget);
    expect(s.net(30300).zone, PourZone.onTarget);
    expect(s.net(30400).zone, PourZone.over);

    final mid = s.net(24800);
    expect(mid.addedMg, 24800);
    expect(mid.remainingMg, 5200);
    expect(mid.progress, closeTo(0.827, 0.001));
  });

  test('only a steady on-target reading confirms', () {
    final s = pouring();
    expect(s.net(30000, stable: false).canConfirm, isFalse);
    expect(s.net(25000).canConfirm, isFalse);
    expect(s.net(30100).canConfirm, isTrue);
  });

  test('next target builds on the actual reading, not the plan', () {
    // A went 0.2 g over but within tolerance
    final b = pouring().net(30200).confirmStep(t0);
    expect(b.stepIndex, 1);
    expect(b.previousCumulativeMg, 30200);
    expect(b.targetCumulativeMg, 48200);
    expect(b.net(30200).addedMg, 0);
    expect(b.net(48200).zone, PourZone.onTarget);
  });

  test('overshoot is kept on record, the rest of the plan is unchanged', () {
    final s = pouring().net(32000);
    expect(s.zone, PourZone.over);
    expect(s.canConfirm, isFalse);
    expect(s.canMoveOnAnyway, isTrue);

    final b = s.confirmStep(t0, manual: true);
    expect(b.records[0]!.addedMg, 32000);
    expect(b.records[0]!.manual, isTrue);
    // Color B still gets its full 18 g
    expect(b.targetAddedMg, 18000);
    expect(b.targetCumulativeMg, 50000);
  });

  test('moving on short needs a steady reading too', () {
    final s = pouring();
    expect(s.net(20000, stable: false).canMoveOnAnyway, isFalse);
    expect(s.net(20000).canMoveOnAnyway, isTrue);
  });

  test('back only while nothing is poured on top', () {
    final b = pouring().net(30000).confirmStep(t0);
    expect(b.net(30000).canGoBack, isTrue);
    expect(b.net(33000).canGoBack, isFalse);

    final a = b.net(30000).back();
    expect(a.stepIndex, 0);
    expect(a.records[0], isNull);
    // carries on topping up Color A
    expect(a.net(30000).addedMg, 30000);
  });

  test('the whole mix through to done', () {
    var s = pouring();
    for (final cumulative in [30000, 48000, 60000, 120000]) {
      s = s.net(cumulative);
      expect(s.canConfirm, isTrue, reason: '$cumulative');
      s = s.confirmStep(t0);
    }
    expect(s.phase, WeighPhase.review);
    expect(s.records.map((r) => r!.addedMg), [30000, 18000, 12000, 60000]);

    s = s.net(120100);
    expect(s.canComplete, isTrue);
    expect(s.canGoBack, isTrue);
    final done = s.complete();
    expect(done.phase, WeighPhase.done);
    expect(done.measuredTotalMg, 120100);
    expect(done.finished, isTrue);
  });

  test('losing the scale pauses, a big change after is flagged', () {
    final s = pouring().net(20000);
    final away = s.withConnection(ScaleConnectionState.disconnected);
    expect(away.live, isFalse);
    expect(away.liveMg, isNull);
    expect(away.pausedNetMg, 20000);
    expect(away.canMoveOnAnyway, isFalse);

    final back = away.withConnection(ScaleConnectionState.connectedSupported);
    expect(back.net(20100).checkDrift().driftMg, isNull);
    expect(back.net(23000).checkDrift().driftMg, 3000);
    expect(back.net(23000).checkDrift().dismissDrift().driftMg, isNull);
  });

  test('stale or overloaded readings block every action', () {
    final s = pouring().net(30000);
    expect(s.markStale().canConfirm, isFalse);
    expect(
      s
          .withReading(liveMg: bowl + 30000, stable: true, overload: true)
          .canConfirm,
      isFalse,
    );
  });

  test('no developer means no developer step', () {
    final f = roseGold().copyWith(
      developerRatio: () => null,
      developerDg: 0,
      totalMixtureDg: 600,
    );
    final s = WeighingState.start(
      sessionId: 's',
      formula: f,
      toleranceMg: 300,
      deviceName: 'x',
      connection: ScaleConnectionState.connectedSupported,
      startedAt: t0,
    );
    expect(s.steps, hasLength(3));
    expect(s.plannedTotalMg, 60000);
  });
}
