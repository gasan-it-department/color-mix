# Decisions

Notes to self on what I picked and why. Spec is the blueprint docx.

## Stack

- **universal_ble**, not flutter_blue_plus. FBP moved to its own licence: any for-profit use needs a paid licence and it pings a licence server at build time. Its Windows support is a separate package last released Feb 2025. universal_ble is BSD-3 and does Android + Windows + iOS natively.
- **drift** for SQLite. Typed, reactive queries, runs on Windows too (sqflite doesn't without ffi).
- **Riverpod 3** without codegen. drift already needs build_runner, didn't want a second generator.
- **go_router** with a `StatefulShellRoute`, each tab keeps its own stack.
- **flex_color_picker** for phase 2, has the wheel, HEX input and color names.
- **wakelock_plus** wasn't in the blueprint. Screen can't sleep mid-pour.
- No permission_handler. universal_ble has its own `hasPermissions` / `requestPermissions` (scan + connect on Android 12+, location below that), and permission_handler 13 needs compileSdk 37 which AGP 9.1 doesn't support yet.
- No custom font yet. Platform default (Roboto / Segoe UI), bundling one later if it's worth it. Google Fonts at runtime is out since the app is offline.

## Design

- Blueprint says "subtle shadows". Not doing that: every elevation and surface tint is zeroed in `theme.dart`, cards are 1px borders on a warm off-white canvas.
- 4 tabs (Home, Colors, Formulas, Scale), Settings moved out of the bar. 5 tabs is cramped at 360 px.
- Wide screens get a hand-built sidebar instead of the extended NavigationRail. The rail only tints the icon, I want the whole row as the pill.
- Weighing screen (phase 4): full screen, no nav, wakelock on, color only for state.

## Data

- Integers everywhere, see README units.
- Rounding (phase 3): largest remainder so the rounded parts add up to the total. 50 g at 33.3/33.3/33.4 rounds naively to 16.7 + 16.7 + 16.7 = 50.1 g, largest remainder gives 16.7 + 16.6 + 16.7 = 50.0 g.
- Sessions have per-ingredient step rows (target vs actual, added amount, stable or not). Targets are copied in at session start so editing a formula doesn't rewrite history. Deleting a formula keeps its sessions (`formula_id` goes null).
- Developer strength (10/20/30/40 vol) stored as a record only, no logic.
- Developer ratios are by weight only for now. Volume needs a density per product.
- Presets get optional level/tone (7.43) since that's how stylists name shades.
- Nearest demo shade (phase 2) by CIELAB distance, not RGB.

## Scale

- Every weight goes through `ScaleDevice` (`lib/core/bluetooth/scale_device.dart`), simulator included.
- The app decides "stable", not the firmware. Configurable threshold and dwell, same rule for every scale. Firmware's flag is diagnostic.
- Session zero is the stable reading with the empty bowl, kept in the app. Works the same on the simulator, the ESP32 and 0x181D scales that can't be tared remotely, and no risk of an in-flight pre-tare frame being read as zero. Firmware TARE stays for the scale screen.
- Overload is checked on the gross weight. Tare hides the bowl but the load cell still carries it.
- Calibration: serial menu first (phase 5), then CAL_ZERO + CAL_KNOWN_MASS over BLE for the in-app wizard (phase 7).
- Weight frame (phase 4 protocol doc), 8 bytes little-endian: version, flags (stable, overload, uncalibrated, sensor fault), uint16 sequence, int32 milligrams. 10 Hz from the HX711's 10 SPS mode. No frame for 1 s or sequence going backwards = stale, weighing pauses.

## Firmware

- PlatformIO `platform = espressif32` (v8 ships Arduino core 3.3.12, no pioarduino fork needed).
- NimBLE-Arduino 2.5 over the core's Bluedroid BLE. Lighter, and it sidesteps the core's BLE rewrite planned for v4.
- RobTillaart/HX711. bogde's hasn't had a release since 2021.

## Machine notes

- Flutter SDK lives in `Desktop\JMLPROJECT\JML\flutterTest\flutter`, upgraded 3.29.3 -> 3.47.8 on 2026-10-26.
- New Android cmdline-tools replaced sdkmanager with `android sdk`. Gradle can't auto-download through it, so install by path: `android sdk install --sdk=<sdk> ndk/28.2.13676358`.
- `kotlin.incremental=false` in `android/gradle.properties`. Project is on D:, pub cache on C:, kotlin's incremental caches can't span drives and the plugin builds fail.
- Windows Developer Mode is needed for plugin symlinks.
