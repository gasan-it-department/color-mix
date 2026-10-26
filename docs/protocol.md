# ColorMix scale BLE protocol

Version 1. The Dart side is `lib/core/bluetooth/esp32_protocol.dart`, the test vectors at the bottom are in `test/esp32_protocol_test.dart`. Firmware (phase 5) has to match this byte for byte.

## Advertising

- Name: `ColorMix Scale`
- Service UUID in the advert so the app can filter the scan

## GATT

| What | UUID | Properties |
|---|---|---|
| Service | `7a3e0001-5c2d-4f1b-9c8e-0d6b2f4a1e90` | |
| Weight | `7a3e0002-5c2d-4f1b-9c8e-0d6b2f4a1e90` | notify |
| Info | `7a3e0003-5c2d-4f1b-9c8e-0d6b2f4a1e90` | read |
| Control | `7a3e0004-5c2d-4f1b-9c8e-0d6b2f4a1e90` | write with response, notify |

## Weight frame

8 bytes, little endian, about 10 per second (HX711 in its 10 SPS mode). Fits the default 20 byte payload, no MTU change needed.

| Byte | Type | Meaning |
|---|---|---|
| 0 | uint8 | protocol version, 1 |
| 1 | uint8 | flags |
| 2-3 | uint16 | sequence, wraps 65535 -> 0 |
| 4-7 | int32 | weight in milligrams, signed, after the device's tare |

Flags:

| Bit | Meaning |
|---|---|
| 0 | stable (device's own guess, the app only shows it in diagnostics) |
| 1 | overload, gross weight near or over capacity. Checked on the gross reading, before tare, since the bowl is still on the load cell |
| 2 | uncalibrated, no calibration factor saved |
| 3 | sensor fault, HX711 not answering |

The app drops a frame whose sequence isn't newer than the last one (allowing for the wrap). No frame for 1 s while connected counts as stale: the weighing screen pauses and won't confirm a step.

## Info

UTF-8 text, `key=value` pairs split by `;`. Example: `fw=0.1.0;proto=1;cap_g=1000;cal=1`

| Key | Meaning |
|---|---|
| fw | firmware version |
| proto | protocol version |
| cap_g | capacity in grams |
| cal | 1 when a calibration factor is saved |

## Control

The app writes one opcode byte, then the payload if any. The scale answers by notifying on the same characteristic with `opcode | 0x80` and a result byte.

| Opcode | Name | Payload | Notes |
|---|---|---|---|
| 0x01 | TARE | none | zero the device. The weighing screen doesn't use it, it keeps its own session zero |
| 0x02 | GET_STATUS | none | refresh the info characteristic |
| 0x10 | CAL_ZERO | none | phase 7, first calibration step with nothing on the platform |
| 0x11 | CAL_KNOWN_MASS | int32 mg | phase 7, the reference weight now on the platform |

Result byte: 0 ok, 1 busy, 2 failed, 3 unknown opcode.

Until phase 7, calibration goes through the serial menu.

## Test vectors

| Bytes | Version | Flags | Sequence | mg |
|---|---|---|---|---|
| `01 01 2A 00 30 75 00 00` | 1 | stable | 42 | 30000 (30.0 g) |
| `01 00 FF FF F4 FF FF FF` | 1 | none | 65535 | -12 |
| `01 02 00 01 40 42 0F 00` | 1 | overload | 256 | 1000000 (1 kg) |
| `01 04 05 00 00 00 00 00` | 1 | uncalibrated | 5 | 0 |
| `01 09 07 00 E8 03 00 00` | 1 | stable + sensor fault | 7 | 1000 |
| `02 01 00 00 00 00 00 00` | rejected, unsupported version | | | |
| `01 01 00 00 00 00 00` | rejected, 7 bytes | | | |
