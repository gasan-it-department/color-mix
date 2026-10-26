import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/bluetooth/simulated_scale.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

void main() {
  test(
    'connects after a short delay and streams about 10 readings a second',
    () {
      fakeAsync((async) {
        final scale = SimulatedScale(random: Random(1));
        final states = <ScaleConnectionState>[];
        final readings = <WeightReading>[];
        scale.connectionStates.listen(states.add);
        scale.weightStream.listen(readings.add);

        scale.connect();
        async.flushMicrotasks();
        expect(scale.connectionState, ScaleConnectionState.connecting);

        async.elapse(const Duration(milliseconds: 400));
        expect(scale.isConnected, isTrue);
        expect(states, [
          ScaleConnectionState.connecting,
          ScaleConnectionState.connectedSupported,
        ]);

        async.elapse(const Duration(seconds: 1));
        expect(readings.length, 10);
        // empty platform, small noise only
        expect(readings.every((r) => r.milligrams.abs() <= 40), isTrue);
        // sequence counts up
        expect(readings.map((r) => r.sequence), [
          for (var i = 1; i <= 10; i++) i,
        ]);

        scale.close();
        async.flushMicrotasks();
      });
    },
  );

  test('bowl, pour and tare move the reading', () {
    fakeAsync((async) {
      final scale = SimulatedScale(random: Random(2));
      WeightReading? last;
      scale.weightStream.listen((r) => last = r);
      scale.connect();
      async.elapse(const Duration(milliseconds: 500));

      scale.placeBowl();
      async.elapse(const Duration(milliseconds: 200));
      expect(last!.milligrams, closeTo(SimulatedScale.bowlMg, 40));

      scale.pourBy(30000, over: const Duration(seconds: 1));
      expect(scale.pouring, isTrue);
      async.elapse(const Duration(milliseconds: 1200));
      expect(scale.pouring, isFalse);
      expect(scale.grossMg, SimulatedScale.bowlMg + 30000);

      scale.tare();
      async.elapse(const Duration(milliseconds: 200));
      expect(last!.milligrams, closeTo(0, 40));

      scale.startPouring(gramsPerSecond: 10);
      async.elapse(const Duration(seconds: 1));
      scale.stopPouring();
      expect(scale.grossMg, SimulatedScale.bowlMg + 30000 + 10000);

      scale.close();
      async.flushMicrotasks();
    });
  });

  test('frozen sends nothing, dropping the link stops readings', () {
    fakeAsync((async) {
      final scale = SimulatedScale(random: Random(3));
      final readings = <WeightReading>[];
      scale.weightStream.listen(readings.add);
      scale.connect();
      async.elapse(const Duration(milliseconds: 500));

      scale.frozen = true;
      final before = readings.length;
      async.elapse(const Duration(seconds: 2));
      expect(readings.length, before);

      scale.frozen = false;
      async.elapse(const Duration(milliseconds: 300));
      expect(readings.length, greaterThan(before));

      scale.dropConnection();
      expect(scale.connectionState, ScaleConnectionState.disconnected);
      final atDrop = readings.length;
      async.elapse(const Duration(seconds: 1));
      expect(readings.length, atDrop);

      scale.close();
      async.flushMicrotasks();
    });
  });

  test('unsteady readings jump about a gram, overload flags past 1 kg', () {
    fakeAsync((async) {
      final scale = SimulatedScale(random: Random(4));
      final readings = <WeightReading>[];
      scale.weightStream.listen(readings.add);
      scale.connect();
      async.elapse(const Duration(milliseconds: 400));

      scale.unsteady = true;
      async.elapse(const Duration(seconds: 2));
      final values = readings.map((r) => r.milligrams);
      expect(values.reduce(max) - values.reduce(min), greaterThan(1000));

      scale.unsteady = false;
      scale.add(1000001);
      async.elapse(const Duration(milliseconds: 200));
      expect(readings.last.overload, isTrue);

      scale.close();
      async.flushMicrotasks();
    });
  });
}
