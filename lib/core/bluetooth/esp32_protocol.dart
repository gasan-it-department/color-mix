// the ColorMix scale's ble protocol, see docs/protocol.md. the firmware has
// to match this byte for byte, the test vectors live in
// test/esp32_protocol_test.dart.

import 'dart:typed_data';

import 'package:colormix_studio/shared/models/weight_reading.dart';

abstract final class ColorMixScaleUuids {
  static const service = '7a3e0001-5c2d-4f1b-9c8e-0d6b2f4a1e90';

  /// notify, 8 byte weight frame at about 10 Hz
  static const weight = '7a3e0002-5c2d-4f1b-9c8e-0d6b2f4a1e90';

  /// read, utf-8 'key=value;key=value'
  static const info = '7a3e0003-5c2d-4f1b-9c8e-0d6b2f4a1e90';

  /// write with response + notify, 1 byte opcode then payload
  static const control = '7a3e0004-5c2d-4f1b-9c8e-0d6b2f4a1e90';

  static const advertisedName = 'ColorMix Scale';
}

const protocolVersion = 1;
const weightFrameLength = 8;

/// CAL_KNOWN_MASS fails below this
const minCalibrationMassMg = 10000;

abstract final class FrameFlags {
  static const stable = 0x01;
  static const overload = 0x02;
  static const uncalibrated = 0x04;
  static const sensorFault = 0x08;
}

abstract final class ControlOp {
  static const tare = 0x01;
  static const getStatus = 0x02;

  /// phase 7, the in-app calibration wizard
  static const calZero = 0x10;
  static const calKnownMass = 0x11;

  /// replies come back as the opcode with this bit set
  static const replyBit = 0x80;
}

abstract final class ControlResult {
  static const ok = 0;
  static const busy = 1;
  static const failed = 2;
  static const unknownOp = 3;
}

class WeightFrame {
  const WeightFrame({
    required this.version,
    required this.flags,
    required this.sequence,
    required this.milligrams,
  });

  final int version;
  final int flags;
  final int sequence;
  final int milligrams;

  bool get stable => flags & FrameFlags.stable != 0;
  bool get overload => flags & FrameFlags.overload != 0;
  bool get uncalibrated => flags & FrameFlags.uncalibrated != 0;
  bool get sensorFault => flags & FrameFlags.sensorFault != 0;

  WeightReading toReading(DateTime receivedAt) => WeightReading(
    milligrams: milligrams,
    isStable: stable,
    timestamp: receivedAt,
    sequence: sequence,
    overload: overload,
    uncalibrated: uncalibrated,
  );
}

enum FrameError { wrongLength, unsupportedVersion }

/// little endian: [0] version, [1] flags, [2-3] uint16 sequence,
/// [4-7] int32 milligrams
({WeightFrame? frame, FrameError? error}) decodeWeightFrame(List<int> bytes) {
  if (bytes.length != weightFrameLength) {
    return (frame: null, error: FrameError.wrongLength);
  }
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final version = data.getUint8(0);
  if (version != protocolVersion) {
    return (frame: null, error: FrameError.unsupportedVersion);
  }
  return (
    frame: WeightFrame(
      version: version,
      flags: data.getUint8(1),
      sequence: data.getUint16(2, Endian.little),
      milligrams: data.getInt32(4, Endian.little),
    ),
    error: null,
  );
}

Uint8List encodeWeightFrame({
  required int milligrams,
  required int sequence,
  int flags = 0,
}) {
  final data = ByteData(weightFrameLength)
    ..setUint8(0, protocolVersion)
    ..setUint8(1, flags)
    ..setUint16(2, sequence & 0xFFFF, Endian.little)
    ..setInt32(4, milligrams, Endian.little);
  return data.buffer.asUint8List();
}

/// true when [next] comes after [prev], allowing for the 16-bit wrap.
/// a frame that isn't newer is late or repeated and gets dropped
bool isNewerSequence(int prev, int next) {
  final diff = (next - prev) & 0xFFFF;
  return diff != 0 && diff < 0x8000;
}

/// 'fw=0.1.0;proto=1;cap_g=1000;cal=1' -> map
Map<String, String> parseInfo(String text) => {
  for (final pair in text.split(';'))
    if (pair.contains('='))
      pair.substring(0, pair.indexOf('=')).trim(): pair
          .substring(pair.indexOf('=') + 1)
          .trim(),
};

Uint8List encodeControl(int op, [int? int32Payload]) {
  if (int32Payload == null) return Uint8List.fromList([op]);
  final data = ByteData(5)
    ..setUint8(0, op)
    ..setInt32(1, int32Payload, Endian.little);
  return data.buffer.asUint8List();
}
