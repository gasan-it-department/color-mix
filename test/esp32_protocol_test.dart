import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/esp32_protocol.dart';

/// '01 01 2A 00' -> bytes
List<int> hex(String s) => [
  for (final b in s.split(' ')) int.parse(b, radix: 16),
];

void main() {
  // the same vectors are in docs/protocol.md, the firmware has to agree
  final vectors = <(String, int, int, int)>[
    ('01 01 2A 00 30 75 00 00', FrameFlags.stable, 42, 30000),
    ('01 00 FF FF F4 FF FF FF', 0, 65535, -12),
    ('01 02 00 01 40 42 0F 00', FrameFlags.overload, 256, 1000000),
    ('01 04 05 00 00 00 00 00', FrameFlags.uncalibrated, 5, 0),
    (
      '01 09 07 00 E8 03 00 00',
      FrameFlags.stable | FrameFlags.sensorFault,
      7,
      1000,
    ),
  ];

  for (final (bytes, flags, seq, mg) in vectors) {
    test('decodes $bytes', () {
      final r = decodeWeightFrame(hex(bytes));
      expect(r.error, isNull);
      expect(r.frame!.version, 1);
      expect(r.frame!.flags, flags);
      expect(r.frame!.sequence, seq);
      expect(r.frame!.milligrams, mg);
    });

    test('encodes back to $bytes', () {
      expect(
        encodeWeightFrame(milligrams: mg, sequence: seq, flags: flags),
        hex(bytes),
      );
    });
  }

  test('flag getters', () {
    final f = decodeWeightFrame(hex('01 09 07 00 E8 03 00 00')).frame!;
    expect(f.stable, isTrue);
    expect(f.sensorFault, isTrue);
    expect(f.overload, isFalse);
    expect(f.uncalibrated, isFalse);

    final reading = decodeWeightFrame(hex('01 02 00 01 40 42 0F 00')).frame!
        .toReading(DateTime(2026));
    expect(reading.overload, isTrue);
    expect(reading.grams, 1000);
  });

  test('wrong length and unknown versions are rejected', () {
    expect(
      decodeWeightFrame(hex('01 01 00 00 00 00 00')).error,
      FrameError.wrongLength,
    );
    expect(
      decodeWeightFrame(hex('02 01 00 00 00 00 00 00')).error,
      FrameError.unsupportedVersion,
    );
  });

  test('sequence order allows for the 16-bit wrap', () {
    expect(isNewerSequence(41, 42), isTrue);
    expect(isNewerSequence(42, 42), isFalse);
    expect(isNewerSequence(42, 41), isFalse);
    expect(isNewerSequence(65535, 0), isTrue);
    expect(isNewerSequence(65530, 3), isTrue);
    expect(isNewerSequence(3, 65530), isFalse);
  });

  test('info text and control writes', () {
    expect(parseInfo('fw=0.1.0;proto=1;cap_g=1000;cal=1'), {
      'fw': '0.1.0',
      'proto': '1',
      'cap_g': '1000',
      'cal': '1',
    });
    expect(encodeControl(ControlOp.tare), [0x01]);
    expect(encodeControl(ControlOp.calKnownMass, 100000), [
      0x11,
      0xA0,
      0x86,
      0x01,
      0x00,
    ]);
  });
}
