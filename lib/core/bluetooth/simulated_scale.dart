import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/shared/models/scale_device_info.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

/// a pretend scale so the whole flow works with no hardware. same interface
/// as the real ones, readings at 10 Hz with a little noise like a load cell.
///
/// the extra controls (bowl, pour, unsteady, freeze, drop) are what the
/// simulator panel drives. listeners hear about every change.
class SimulatedScale extends ChangeNotifier implements ScaleDevice {
  SimulatedScale({
    Random? random,
    this.tick = const Duration(milliseconds: 100),
    this.connectDelay = const Duration(milliseconds: 400),
  }) : _random = random ?? Random();

  /// the real load cell is 1 kg
  static const capacityMg = 1000000;
  static const bowlMg = 250000;

  final Random _random;
  final Duration tick;
  final Duration connectDelay;

  final _readings = StreamController<WeightReading>.broadcast();
  final _states = StreamController<ScaleConnectionState>.broadcast();

  ScaleConnectionState _state = ScaleConnectionState.disconnected;
  Timer? _ticker;
  Timer? _connecting;
  bool _closed = false;

  int _grossMg = 0;
  int _tareMg = 0;
  int _seq = 0;
  int _pourMgPerTick = 0;
  int _rampLeftMg = 0;
  int _rampStepMg = 0;
  bool _unsteady = false;
  bool _frozen = false;

  // ── ScaleDevice ──

  @override
  ScaleDeviceInfo get info => const ScaleDeviceInfo(
    id: 'simulator',
    name: 'Simulated scale',
    connectionType: ScaleConnectionType.simulated,
    adapterType: ScaleAdapterType.simulated,
    isSupported: true,
  );

  @override
  ScaleConnectionState get connectionState => _state;

  @override
  Stream<ScaleConnectionState> get connectionStates => _states.stream;

  @override
  Stream<WeightReading> get weightStream => _readings.stream;

  @override
  bool get isConnected => _state == ScaleConnectionState.connectedSupported;

  @override
  bool get supportsTare => true;

  @override
  String? get problem => null;

  @override
  Future<void> connect() {
    if (_closed || isConnected || _state == ScaleConnectionState.connecting) {
      return Future.value();
    }
    _setState(ScaleConnectionState.connecting);
    final done = Completer<void>();
    _connecting = Timer(connectDelay, () {
      _setState(ScaleConnectionState.connectedSupported);
      _ticker = Timer.periodic(tick, (_) => _tick());
      done.complete();
    });
    return done.future;
  }

  @override
  Future<void> disconnect() async {
    _stopTimers();
    _setState(ScaleConnectionState.disconnected);
  }

  @override
  Future<void> tare() async {
    _tareMg = _grossMg;
    notifyListeners();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _stopTimers();
    await _readings.close();
    await _states.close();
    dispose();
  }

  // ── simulator controls ──

  /// what's physically on the platform, before tare and noise
  int get grossMg => _grossMg;
  int get tareMg => _tareMg;
  bool get unsteady => _unsteady;
  bool get frozen => _frozen;
  bool get pouring => _pourMgPerTick > 0 || _rampLeftMg > 0;

  void placeBowl() => add(bowlMg);

  void clearPlatform() {
    _grossMg = 0;
    _pourMgPerTick = 0;
    _rampLeftMg = 0;
    notifyListeners();
  }

  /// negative takes weight off
  void add(int mg) {
    _grossMg = max(0, _grossMg + mg);
    notifyListeners();
  }

  /// hold-to-pour: keeps adding until [stopPouring]
  void startPouring({int gramsPerSecond = 5}) {
    _pourMgPerTick = gramsPerSecond * tick.inMilliseconds;
    notifyListeners();
  }

  void stopPouring() {
    _pourMgPerTick = 0;
    notifyListeners();
  }

  /// pours exactly [mg] spread over about [over], like a steady hand
  void pourBy(int mg, {Duration over = const Duration(milliseconds: 1500)}) {
    if (mg <= 0) return;
    final ticks = max(1, over.inMilliseconds ~/ tick.inMilliseconds);
    _rampLeftMg = mg;
    _rampStepMg = (mg + ticks - 1) ~/ ticks;
    notifyListeners();
  }

  /// readings jump around by about a gram either way
  set unsteady(bool value) {
    _unsteady = value;
    notifyListeners();
  }

  /// connected but nothing comes through, to test stale readings
  set frozen(bool value) {
    _frozen = value;
    notifyListeners();
  }

  /// the link goes away without anyone asking
  void dropConnection() {
    _stopTimers();
    _setState(ScaleConnectionState.disconnected);
  }

  // ── internals ──

  void _tick() {
    if (_pourMgPerTick > 0) _grossMg += _pourMgPerTick;
    if (_rampLeftMg > 0) {
      final step = min(_rampStepMg, _rampLeftMg);
      _grossMg += step;
      _rampLeftMg -= step;
    }
    if (_pourMgPerTick > 0 || _rampStepMg > 0) {
      if (_rampLeftMg == 0) _rampStepMg = 0;
      notifyListeners();
    }
    if (_frozen || !isConnected || _closed) return;

    final noise = _unsteady
        ? _random.nextInt(2401) - 1200
        : _random.nextInt(81) - 40;
    _seq = (_seq + 1) & 0xFFFF;
    _readings.add(
      WeightReading(
        milligrams: _grossMg - _tareMg + noise,
        isStable: !pouring && !_unsteady,
        timestamp: clock.now(),
        sequence: _seq,
        overload: _grossMg > capacityMg,
      ),
    );
  }

  void _setState(ScaleConnectionState s) {
    if (_closed) return;
    _state = s;
    _states.add(s);
    notifyListeners();
  }

  void _stopTimers() {
    _ticker?.cancel();
    _ticker = null;
    _connecting?.cancel();
    _connecting = null;
  }
}
