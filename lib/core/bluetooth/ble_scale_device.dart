import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import 'package:colormix_studio/core/bluetooth/ble_transport.dart';
import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/shared/models/scale_device_info.dart';
import 'package:colormix_studio/shared/models/weight_reading.dart';

/// standard bluetooth weight scale service and its measurement
final weightScaleService = normalizeUuid('181D');
final weightMeasurementChar = normalizeUuid('2A9D');

/// what a scan result looks like it is, before connecting
ScaleAdapterType guessAdapter(BleScanResult r) {
  if (r.services.contains(normalizeUuid(ColorMixScaleUuids.service)) ||
      r.name == ColorMixScaleUuids.advertisedName) {
    return ScaleAdapterType.esp32Custom;
  }
  if (r.services.contains(weightScaleService)) {
    return ScaleAdapterType.standardWeightScale;
  }
  return ScaleAdapterType.unknown;
}

/// a scale over ble. connects, looks at the services to decide what it is
/// (our esp32, a standard 0x181D scale, or neither), checks the esp32 speaks
/// our protocol version, then turns notifications into readings.
///
/// a dropped link is retried a few times on its own. a disconnect asked for
/// by the app isn't.
class BleScaleDevice extends ChangeNotifier implements ScaleDevice {
  BleScaleDevice({
    required this.transport,
    required this.deviceId,
    required this.name,
    ScaleAdapterType guess = ScaleAdapterType.unknown,
    this.connectTimeout = const Duration(seconds: 10),
    this.commandTimeout = const Duration(seconds: 4),
    this.calibrationTimeout = const Duration(seconds: 8),
    this.reconnectDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ],
  }) : _adapter = guess;

  final BleTransport transport;
  final String deviceId;
  final Duration connectTimeout;
  final Duration commandTimeout;

  /// calibration replies come after the scale's 2 s average
  final Duration calibrationTimeout;
  final List<Duration> reconnectDelays;

  final String name;
  ScaleAdapterType _adapter;
  ScaleConnectionState _state = ScaleConnectionState.disconnected;
  String? _problem;
  bool _sensorFault = false;
  Map<String, String> _deviceInfo = const {};

  final _readings = StreamController<WeightReading>.broadcast();
  final _states = StreamController<ScaleConnectionState>.broadcast();
  final _replies = StreamController<Uint8List>.broadcast();

  StreamSubscription<bool>? _linkSub;
  StreamSubscription<Uint8List>? _weightSub;
  StreamSubscription<Uint8List>? _controlSub;
  Timer? _retry;
  int _retries = 0;
  bool _reconnecting = false;
  int? _lastSeq;
  int _badFrames = 0;
  int _missedFrames = 0;
  bool _wanted = false;
  bool _closed = false;

  // ── ScaleDevice ──

  @override
  ScaleDeviceInfo get info => ScaleDeviceInfo(
    id: deviceId,
    name: name,
    connectionType: ScaleConnectionType.bluetoothLe,
    adapterType: _adapter,
    isSupported:
        _adapter == ScaleAdapterType.esp32Custom ||
        _adapter == ScaleAdapterType.standardWeightScale,
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
  bool get supportsTare => _adapter == ScaleAdapterType.esp32Custom;

  @override
  String? get problem => _problem;

  /// sends a reading now and then, not a live stream. can't guide pouring
  bool get experimental => _adapter == ScaleAdapterType.standardWeightScale;

  /// from the esp32's info characteristic: fw, proto, cap_g, cal
  Map<String, String> get deviceInfo => _deviceInfo;

  bool get calibrated => _deviceInfo['cal'] == '1';

  /// only our esp32 takes calibration commands
  bool get supportsCalibration => _adapter == ScaleAdapterType.esp32Custom;

  bool get sensorFault => _sensorFault;

  /// frames that didn't decode, for diagnostics
  int get badFrames => _badFrames;

  /// gaps in the sequence since this connection was set up: frames the
  /// scale sent that never arrived
  int get missedFrames => _missedFrames;

  @override
  Future<void> connect() async {
    if (_closed) return;
    if (_state == ScaleConnectionState.connecting || isConnected) return;
    _wanted = true;
    _retries = 0;
    _reconnecting = false;
    _retry?.cancel();
    await _connectOnce();
  }

  @override
  Future<void> disconnect() async {
    _wanted = false;
    _retry?.cancel();
    await _teardown();
    try {
      await transport.disconnect(deviceId);
    } catch (_) {
      // already gone
    }
    _set(ScaleConnectionState.disconnected, problem: null);
  }

  @override
  Future<void> tare() async {
    if (!supportsTare) {
      throw const ScaleCommandException(
        'This scale can\'t be tared from the app.',
      );
    }
    if (!isConnected) {
      throw const ScaleCommandException('The scale isn\'t connected.');
    }
    final result = await _command(ControlOp.tare);
    if (result == ControlResult.busy) {
      throw const ScaleCommandException(
        'The reading isn\'t steady yet. Try again once it settles.',
      );
    }
    if (result != ControlResult.ok) {
      throw const ScaleCommandException('The scale couldn\'t tare. Try again.');
    }
  }

  // ── calibration, esp32 only ──

  /// step 1, platform empty. the scale averages 2 s before it answers
  Future<void> calibrateZero() async {
    _checkCalibratable();
    final result = await _command(
      ControlOp.calZero,
      timeout: calibrationTimeout,
    );
    switch (result) {
      case ControlResult.ok:
        return;
      case ControlResult.busy:
        throw const ScaleCommandException(
          'The reading isn\'t steady. Keep the platform empty and still, '
          'then try again.',
        );
      case ControlResult.failed:
        throw const ScaleCommandException(
          'The reading moved while the scale was measuring. Keep it still '
          'and try again.',
        );
      default:
        throw const ScaleCommandException(_oldFirmware);
    }
  }

  /// step 2, the reference weight is on. [mg] is its real mass
  Future<void> calibrateKnownMass(int mg) async {
    _checkCalibratable();
    if (mg < minCalibrationMassMg) {
      throw const ScaleCommandException(
        'Use a reference weight of at least 10 g.',
      );
    }
    final result = await _command(
      ControlOp.calKnownMass,
      payload: mg,
      timeout: calibrationTimeout,
    );
    switch (result) {
      case ControlResult.ok:
        await refreshInfo();
      case ControlResult.busy:
        throw const ScaleCommandException(
          'The reading isn\'t steady yet. Let the weight settle, then try '
          'again.',
        );
      case ControlResult.failed:
        // not zeroed since power-up, or barely any change from the zero
        throw const ScaleCommandException(
          'The scale couldn\'t use that. Check the weight sits in the '
          'middle of the platform and its mass is right. If it still '
          'fails, start again from step 1.',
        );
      default:
        throw const ScaleCommandException(_oldFirmware);
    }
  }

  /// reads the info text again, it says cal=1 once calibrated
  Future<void> refreshInfo() async {
    if (!isConnected || !supportsCalibration) return;
    try {
      await _command(ControlOp.getStatus);
      await _readInfo();
    } catch (_) {
      // keep what we had, the next connect reads it again
    }
  }

  /// the scale tab's "test connection": GET_STATUS there and back, then the
  /// info text read again. returns how long the scale took to answer
  Future<Duration> testConnection() async {
    if (!supportsTare) {
      throw const ScaleCommandException(
        'Only the ColorMix scale answers a connection test.',
      );
    }
    if (!isConnected) {
      throw const ScaleCommandException('The scale isn\'t connected.');
    }
    final sent = clock.now();
    final result = await _command(ControlOp.getStatus);
    final took = clock.now().difference(sent);
    if (result != ControlResult.ok) {
      throw const ScaleCommandException(
        'The scale answered but couldn\'t send its status. Switch it off '
        'and on again.',
      );
    }
    try {
      await _readInfo();
    } catch (_) {
      throw const ScaleCommandException(
        'The scale answered but its details couldn\'t be read. Try again.',
      );
    }
    return took;
  }

  Future<void> _readInfo() async {
    final text = utf8.decode(
      await transport.read(
        deviceId,
        ColorMixScaleUuids.service,
        ColorMixScaleUuids.info,
      ),
      allowMalformed: true,
    );
    _deviceInfo = parseInfo(text);
    if (!_sensorFault) _problem = calibrated ? null : _uncalibratedNote;
    notifyListeners();
  }

  void _checkCalibratable() {
    if (!supportsCalibration) {
      throw const ScaleCommandException(
        'Only the ColorMix scale can be calibrated from the app.',
      );
    }
    if (!isConnected) {
      throw const ScaleCommandException('The scale isn\'t connected.');
    }
  }

  static const _uncalibratedNote =
      'The scale isn\'t calibrated yet, readings are only rough.';
  static const _oldFirmware =
      'The scale\'s firmware doesn\'t know this command. Flash the ColorMix '
      'firmware again.';

  @override
  Future<void> close() async {
    if (_closed) return;
    await disconnect();
    _closed = true;
    await _readings.close();
    await _states.close();
    await _replies.close();
    dispose();
  }

  // ── connecting ──

  Future<void> _connectOnce() async {
    _set(ScaleConnectionState.connecting, problem: null);
    try {
      await transport.connect(deviceId, timeout: connectTimeout);
    } catch (_) {
      _lost(
        'Couldn\'t reach the scale. Check it\'s switched on and close by, '
        'then try again.',
      );
      return;
    }
    if (!_wanted || _closed) return;

    unawaited(_linkSub?.cancel());
    _linkSub = transport.connectionChanges(deviceId).listen((up) {
      if (!up) _onLinkDown();
    });

    try {
      final services = await transport.discoverServices(deviceId);
      final ours = _find(services, ColorMixScaleUuids.service);
      final standard = _find(services, weightScaleService);
      if (ours != null) {
        _adapter = ScaleAdapterType.esp32Custom;
        await _setUpEsp32(ours);
      } else if (standard != null) {
        _adapter = ScaleAdapterType.standardWeightScale;
        await _setUpStandard(standard);
      } else {
        _adapter = ScaleAdapterType.unknown;
        _set(
          ScaleConnectionState.connectedUnsupported,
          problem:
              'This isn\'t a scale the app knows. Pick the ColorMix '
              'scale from the list.',
        );
      }
    } on _Unsupported catch (e) {
      _set(ScaleConnectionState.connectedUnsupported, problem: e.message);
    } catch (_) {
      await _teardown();
      _lost('Connected, but couldn\'t set the scale up. Try again.');
    }
  }

  Future<void> _setUpEsp32(BleServiceInfo service) async {
    final weight = service.characteristic(ColorMixScaleUuids.weight);
    final info = service.characteristic(ColorMixScaleUuids.info);
    final control = service.characteristic(ColorMixScaleUuids.control);
    if (weight == null ||
        !weight.notify ||
        info == null ||
        !info.read ||
        control == null ||
        !control.write) {
      throw const _Unsupported(
        'This scale\'s firmware doesn\'t match the app. Flash the ColorMix '
        'firmware again.',
      );
    }

    final text = utf8.decode(
      await transport.read(deviceId, service.uuid, info.uuid),
      allowMalformed: true,
    );
    _deviceInfo = parseInfo(text);
    final proto = _deviceInfo['proto'];
    if (proto != '$protocolVersion') {
      throw _Unsupported(
        'The scale\'s firmware speaks protocol ${proto ?? 'unknown'}, this '
        'app needs $protocolVersion. Update one of them so they match.',
      );
    }

    _lastSeq = null;
    _missedFrames = 0;
    _sensorFault = false;
    unawaited(_weightSub?.cancel());
    _weightSub = transport.values(deviceId, weight.uuid).listen(_onEsp32Frame);
    await transport.subscribe(deviceId, service.uuid, weight.uuid);

    if (control.notify) {
      unawaited(_controlSub?.cancel());
      _controlSub = transport
          .values(deviceId, control.uuid)
          .listen((v) => _replies.add(v));
      await transport.subscribe(deviceId, service.uuid, control.uuid);
    }

    _retries = 0;
    _reconnecting = false;
    _set(
      ScaleConnectionState.connectedSupported,
      problem: calibrated ? null : _uncalibratedNote,
    );
  }

  Future<void> _setUpStandard(BleServiceInfo service) async {
    final measurement = service.characteristic(weightMeasurementChar);
    if (measurement == null || !(measurement.indicate || measurement.notify)) {
      throw const _Unsupported(
        'This weight scale doesn\'t share its measurements.',
      );
    }
    unawaited(_weightSub?.cancel());
    _weightSub = transport
        .values(deviceId, measurement.uuid)
        .listen(_onStandardMeasurement);
    await transport.subscribe(
      deviceId,
      service.uuid,
      measurement.uuid,
      indicate: measurement.indicate,
    );
    _retries = 0;
    _reconnecting = false;
    _set(
      ScaleConnectionState.connectedSupported,
      problem:
          'Experimental: this scale sends a reading now and then, not '
          'a live weight. It can\'t guide pouring.',
    );
  }

  BleServiceInfo? _find(List<BleServiceInfo> services, String uuid) {
    final want = normalizeUuid(uuid);
    for (final s in services) {
      if (normalizeUuid(s.uuid) == want) return s;
    }
    return null;
  }

  // ── losing it and getting it back ──

  void _onLinkDown() {
    if (_closed || !_wanted) return;
    unawaited(_teardown());
    _reconnecting = true;
    _lost('Lost the connection to the scale.');
  }

  /// after a working link drops: try again after a pause, a few times.
  /// a first connect that fails says so straight away, nobody wants to
  /// wait a minute to learn the scale is off
  void _lost(String message) {
    if (!_wanted || _closed) return;
    if (_reconnecting && _retries < reconnectDelays.length) {
      final delay = reconnectDelays[_retries++];
      _set(ScaleConnectionState.connecting, problem: '$message Trying again…');
      _retry?.cancel();
      _retry = Timer(delay, () {
        if (_wanted && !_closed) unawaited(_connectOnce());
      });
      return;
    }
    _wanted = false;
    _set(
      ScaleConnectionState.failed,
      problem: _reconnecting
          ? 'Lost the connection to the scale. Check it has power, then '
                'reconnect.'
          : message,
    );
    _reconnecting = false;
  }

  // cancel() isn't awaited anywhere here: a broadcast subscription hands back
  // an already-done root zone future, awaiting it gains nothing and stalls
  // fake-time widget tests
  Future<void> _teardown() async {
    unawaited(_weightSub?.cancel());
    unawaited(_controlSub?.cancel());
    unawaited(_linkSub?.cancel());
    _weightSub = null;
    _controlSub = null;
    _linkSub = null;
  }

  // ── data ──

  void _onEsp32Frame(Uint8List bytes) {
    final (:frame, :error) = decodeWeightFrame(bytes);
    if (frame == null || error != null) {
      _badFrames++;
      return;
    }
    // late or repeated frames never move the reading backwards
    final last = _lastSeq;
    if (last != null && !isNewerSequence(last, frame.sequence)) return;
    if (last != null) _missedFrames += ((frame.sequence - last) & 0xFFFF) - 1;
    _lastSeq = frame.sequence;

    if (frame.sensorFault != _sensorFault) {
      _sensorFault = frame.sensorFault;
      _problem = _sensorFault
          ? 'The scale\'s sensor isn\'t answering. Check the load cell wiring.'
          : (calibrated ? null : _problem);
      notifyListeners();
    }
    // no weight from a dead sensor: the weighing screen goes stale instead
    if (frame.sensorFault) return;

    _readings.add(frame.toReading(clock.now()));
  }

  void _onStandardMeasurement(Uint8List bytes) {
    final mg = parseWeightMeasurement(bytes);
    if (mg == null) {
      _badFrames++;
      return;
    }
    _readings.add(
      WeightReading(milligrams: mg, isStable: true, timestamp: clock.now()),
    );
  }

  /// writes [op], waits for the scale's reply on the control characteristic
  Future<int> _command(int op, {int? payload, Duration? timeout}) async {
    final reply = _replies.stream
        .where((v) => v.length >= 2 && v[0] == (op | ControlOp.replyBit))
        .first
        .timeout(timeout ?? commandTimeout);
    try {
      await transport.write(
        deviceId,
        ColorMixScaleUuids.service,
        ColorMixScaleUuids.control,
        encodeControl(op, payload),
      );
      return (await reply)[1];
    } on TimeoutException {
      throw const ScaleCommandException('The scale didn\'t answer. Try again.');
    } catch (e) {
      if (e is ScaleCommandException) rethrow;
      throw const ScaleCommandException('Couldn\'t send that to the scale.');
    }
  }

  void _set(ScaleConnectionState s, {required String? problem}) {
    if (_closed) return;
    _problem = problem;
    _state = s;
    _states.add(s);
    notifyListeners();
  }
}

class _Unsupported implements Exception {
  const _Unsupported(this.message);

  final String message;
}

/// 0x2A9D weight measurement -> mg. flags bit 0: 0 = SI (0.005 kg steps),
/// 1 = imperial (0.01 lb steps). null when it's too short or flagged as
/// "measurement unsuccessful" (0xFFFF)
int? parseWeightMeasurement(Uint8List bytes) {
  if (bytes.length < 3) return null;
  final imperial = bytes[0] & 0x01 == 1;
  final raw = bytes[1] | (bytes[2] << 8);
  if (raw == 0xFFFF) return null;
  return imperial ? (raw * 4535.9237).round() : raw * 5000;
}

/// rough signal bars from rssi, 0-4
int signalBars(int? rssi) {
  if (rssi == null) return 0;
  return max(0, min(4, ((rssi + 100) / 10).floor()));
}
