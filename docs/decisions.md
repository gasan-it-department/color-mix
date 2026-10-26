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

## Color Studio (phase 2)

- The 15 demo shades and 4 demo recipes are const data in `lib/shared/data/demo_catalog.dart`, not db rows. Nobody edits them, and saved formulas only keep the preset id.
- Recipes: Rose Gold (the blueprint's 50/30/20 at 1:1), Ash Blonde 1:1.5, Copper Brown (two parts on purpose) 1:1, Burgundy 1:2. All made up, always shown with the "Demo only" tag. No developer strength on them so they don't read as chemistry advice.
- Swatch colors are picked by eye and the level/tone numbers are rough guides.
- Three labels kept apart, with a legend behind the (i): visual target, demo only, validated (none exist yet).
- Nearest demo shade by CIEDE2000 on CIELAB (`lib/core/utils/color_science.dart`, checked against Sharma's reference pairs). Shown in words only: almost the same < 2, close < 5, similar < 12, else not very close.
- Picker: flex_color_picker's `ColorWheelPicker` (hue ring + saturation/brightness square) plus my own H/S/B sliders, HEX field and RGB readout. HSV lives in the picker state so the hue survives greys. Color name from `ColorTools.nameThatColor`.
- Opening the picker with nothing picked makes its starting color the target. A picked shade stays the target until the picker is actually moved.
- Phones: target pinned in a strip above the picker, recipe in a sheet. Sheets open on the root navigator so they cover the bottom bar.
## Formula calculator (phase 3)

- All the maths is in `lib/features/formulation/formula_math.dart`, pure Dart: parsing, largest-remainder split, developer weight, rescaling, and `calculateFormula` which returns the weights plus every problem in plain words. The editor just shows what it returns.
- Grams take one decimal, percentages two, ratios two. `60,5` works as well as `60.5`.
- Developer weight = dye × ratio, rounded half up to 0.1 g. Ratios are dye : developer by weight only, the section says so and warns 1 mL isn't always 1 g.
- A new formula from a shade without a recipe starts at Color A 100% and no developer choice. The stylist has to pick a ratio or "No developer" before it saves, nothing is assumed.
- Blocking problems: no name, dye not a number / 0 / over 1 kg, a color without a name or with 0% / over 100%, colors not making exactly 100%, a color rounding to 0.0 g, no developer choice, a custom ratio outside 1:0.1 to 1:5, mixture over 1 kg. Only a warning: mixture over 700 g (little room for the bowl).
- Adding a color hands it whatever share is left. "Split evenly" uses the same largest remainder (33.34 / 33.33 / 33.33).
- Formulas started from a demo recipe stay tagged demo even after edits, they're still not validated.
- Developer strength (10/20/30/40 vol) is optional, record only.
- Saved formulas open in the same editor, so "recalculate for a different quantity" is just changing the dye amount and saving.
- Unsaved changes ask before leaving, reset asks before throwing edits away. Both are bottom sheets, not dialogs.
## Weighing (phase 4)

- Start weighing saves the formula first if it needs it, then a "Ready to weigh" sheet shows the order with running totals, asks for the developer check (the blueprint's "confirm the product-compatible ratio" step) and needs a connected scale.
- One bowl, zeroed once in the app (session zero), never tared again. Each step's target is the previous step's *actual* reading plus this step's planned amount, so an overshoot stays on that ingredient and the rest still get their full planned amounts. Nothing is ever rebalanced. Rules in `lib/features/weighing/weighing_state.dart`, pure, unit-tested.
- Zones: under, approaching (within 1 g or a tenth of the step), on target (within the tolerance, 0.3 g for now), over. Neutral / amber / green / red.
- A step only confirms on a steady, live, non-overloaded reading within tolerance. "Move on anyway" (short) and "Continue manually" (over) also need a steady reading and are recorded as manual, with the deviation.
- Previous only works while nothing has been poured on top of the step being reopened.
- Steady = readings over 800 ms within 0.2 g, smoothed with a 5-reading median (`stability_detector.dart`). Both numbers are settings, the real scale's noise decides them later.
- Stale: no reading for 1 s while connected, including a scale that connects and never sends anything. Nothing confirms while stale.
- Disconnects pause the session, the progress stays. After reconnecting, if the reading moved more than 1 g the screen says so.
- Actions within 0.6 s of the last step change are ignored. "Finish" and "Complete and save" sit in the same spot, a double tap used to skip the final check.
- Sessions save as they go: a row per session with planned amounts copied in, a row per step with target vs actual. Completed or cancelled at the end, an app killed mid-mix leaves it in progress and the next start marks it interrupted.
- Sounds and haptics on approaching, reached, over and disconnected, sounds follow the setting. Platforms without system sounds just don't play them.
- Screen kept on while the weighing screen is open (wakelock_plus, ignored where unsupported).
- Phones: the main action goes full width on top, Previous below it, and the steps table turns into two lines per step.

## Simulator

- `SimulatedScale` implements `ScaleDevice` like the real adapters will: 10 readings a second, ±0.04 g noise, 0.4 s to connect.
- Controls: place a 250 g bowl, clear, +0.1 / +1 / +5 / −1 g, hold to pour (5 g/s), unsteady readings (±1.2 g), freeze readings (connected, nothing sent), drop the connection, reconnect. In a session also "pour to target" and "pour 2 g too much".
- Timers and timestamps go through package:clock so tests run on fake time.

## Protocol

- Written ahead of the firmware in `docs/protocol.md`, with the Dart codec in `lib/core/bluetooth/esp32_protocol.dart` and its test vectors, so phase 5 and phase 6 code to the same bytes.

## Real Bluetooth (phase 6)

- `BleTransport` (`lib/core/bluetooth/ble_transport.dart`) is the handful of calls the app makes, with `UniversalBleTransport` as the real one. Tests use `test/fakes/fake_ble.dart`, a fake radio with a fake ESP32 that answers control writes like the firmware, so the adapter, the scan and the screens are all tested without a board. Every widget test gets the fake by default, the real plugin leaves platform timers behind.
- One `BleScaleDevice` for every BLE scale. It connects, looks at the services, and picks: our ESP32 service, the standard 0x181D weight scale, or neither (connected but unsupported, with a message). For the ESP32 it checks the three characteristics and their properties and reads the info text: anything but proto=1 is refused with a message saying the versions don't match.
- Frames: undecodable ones are counted and dropped, a sequence that isn't newer (allowing for the 16-bit wrap) is dropped, sensor-fault frames are dropped too so the weighing screen goes stale, and the scale screen says the sensor isn't answering. After a reconnect the sequence starts over, a restarted ESP32 counts from 1.
- A first connect that fails says so straight away. A link that drops after working is retried after 2, 4 and 8 s while the screens show "connecting", then gives up with a message. A disconnect the app asked for is never retried.
- Tare writes TARE and waits up to 4 s for the reply. Busy and no answer both come back as plain messages on the scale screen.
- Standard 0x181D scales work but are labelled experimental: they send a finished reading now and then, not a live weight, so the start sheet won't begin weighing with one.
- Scanning lists everything nearby but shows ColorMix scales first, other scales next, and folds the rest under "Show N other devices". Nameless devices aren't listed. A scan stops after 15 s or when a scale is picked. Bluetooth off, no Bluetooth, no permission and the browser preview each get their own message.
- The last scale that connected properly is remembered (settings), so the scale tab and the start sheet offer "Connect ColorMix Scale" without a scan. Forget clears it.
- Android permissions are in the app manifest (the plugin only declares the old ones): BLUETOOTH_SCAN with neverForLocation, BLUETOOTH_CONNECT, and location up to Android 11 where scanning still needs it.
- The web preview has no Bluetooth, web bluetooth needs a picker flow this app doesn't have. The simulator still runs everything there.
- Stream subscription `cancel()` futures aren't awaited anywhere. A broadcast subscription returns an already-done root-zone future: awaiting it gains nothing and hangs Flutter's fake-time tests.
- Not tried against real hardware yet, there's no board. The first real run goes through `docs/hardware_test.md`.

## History, settings, calibration (phase 7)

- History lives in the Formulas tab, Formulas | History, one search box for both (names and notes / formula and scale). It's a second view of saved work rather than a fifth tab: four tabs fit a 360 px phone, five don't.
- A session that's still "in progress" when the app starts was cut off by the app closing. `main()` marks those interrupted before the first frame. Their confirmed steps stay on the record.
- Sessions keep the tolerance they were weighed with (schema v2, the one migration so far). Older rows have none and are judged by today's setting. A past session shouldn't turn red because the setting moved later.
- Session detail: totals, then target / added / off by per step, the same table the end of weighing shows (`DeviationTable`). Manual moves keep their "Moved on" tag. A session can be deleted, the formula stays. Deleting a formula keeps its sessions, they just lose the link.
- The formula editor shows that formula's sessions under the result, newest three and "show all".
- Formula menu: Weigh (straight to the start sheet), Duplicate ("X (copy)", then "(copy 2)"... new ids, dated now, a demo stays a demo), Delete (confirm sheet, says history stays). No undo on delete, the sheet is the check.
- Settings: theme; sounds and auto-advance; tolerance as chips (0.1, 0.2, 0.3, 0.5, 1.0 g); steady threshold and settle time folded under Advanced with a way back to the defaults; starting dye amount in 5 g steps (10 to 300 g); the scale's status with Manage and Calibrate. Weighing settings apply from the next session, a running one keeps what it started with.
- Calibration wizard (`/calibrate`), ColorMix scale only: 1 empty the platform -> CAL_ZERO, 2 reference weight and its exact mass (10 g up to the scale's capacity) -> CAL_KNOWN_MASS, 3 check the live reading against the reference, or any other known weight, pass or fail against the tolerance. The scale answers after its 2 s average, so calibration commands wait 8 s rather than tare's 4. Busy, failed and old firmware each get a plain message and the step stays put. After it works the app reads the info text again (cal=1) and the "not calibrated" note goes.
- Calibrate is on the Scale tab (the stronger button while the scale still needs it), in Settings, and in the start sheet, which won't start weighing on an uncalibrated ColorMix scale. Its readings are only a rough default factor.
- A brand-new formula's editor makes its seed with a fresh id on every route rebuild, and coming back from weighing rebuilds it. The editor holds on to the seed it opened with. Before that, saving again after weighing made a second copy of the formula.
- Snackbars with an action stay up until tapped in this Flutter. "Formula saved · View all" and "Copied · Open" are only shortcuts, so they time out like the rest.

## Firmware (phase 5)

- `firmware/esp32_color_mix_scale`, PlatformIO, Arduino core 3.3 through the official espressif32 v8 platform. Details and wiring in its README.
- The parts with no hardware (frame encoding, control decoding, median / steady filters, calibration maths) live in `lib/scale_core` with no Arduino includes, and `pio test -e native` runs them on the PC with the same frame vectors as the Dart tests. Both sides are checked against the same bytes without a board.
- Nothing blocks the loop. The HX711 is only read when it says it has a sample, calibration averages the next 20 samples while frames keep going, control writes are queued from the BLE task and run in the loop.
- Calibration is two steps, zero then a known weight (at least 10 g), saved in NVS. The known-weight step needs a zero from the same power-up, and both fail if the reading moved while averaging. The app's wizard drives the same two steps over BLE (CAL_ZERO / CAL_KNOWN_MASS).
- Device tare isn't saved. The weighing screen doesn't use it.
- A dead HX711 still gets frames out every 100 ms with the sensor fault flag, so "board alive, sensor not" is something the app can show.
- No BLE pairing. Prototype on a bench, noted in the firmware README.
- Built, not run on hardware: there isn't a board here yet. `docs/hardware_test.md` is the sheet for the first real run (0 / 50 / 100 / 200 / 500 g, noise, drift, off-centre, BLE busy). Its numbers set the app's tolerance and steady threshold.

## Scale

- Every weight goes through `ScaleDevice` (`lib/core/bluetooth/scale_device.dart`), simulator included.
- The app decides "stable", not the firmware. Configurable threshold and dwell, same rule for every scale. Firmware's flag is diagnostic.
- Session zero is the stable reading with the empty bowl, kept in the app. Works the same on the simulator, the ESP32 and 0x181D scales that can't be tared remotely, and no risk of an in-flight pre-tare frame being read as zero. Firmware TARE stays for the scale screen.
- Overload is checked on the gross weight. Tare hides the bowl but the load cell still carries it.
- Calibration: the in-app wizard (CAL_ZERO + CAL_KNOWN_MASS), or the serial menu with a laptop plugged in.
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
