# ColorMix Studio

Hair color formula + Bluetooth scale prototype. A Flutter app (Android first, Windows desktop, iOS later) and ESP32 + HX711 scale firmware in `firmware/`.

Pick a target color, set Color A/B/C percentages and a total, get exact gram amounts, then weigh them into one bowl on the scale with live readings, one ingredient on top of the other. Works offline, no account, no server.

Demo formulas are examples only, not product-validated. The color on screen is a target, not a promise of what the dye does on hair. Always follow the dye maker's mixing instructions.

## What's in it

- **Color Studio**: demo palette (labelled as demo), custom colors by picker, hex or RGB, the nearest demo shade for a custom color
- **Formula**: 1 to 3 colors by percentage, developer by weight ratio, exact gram amounts that always add up, plain messages for anything that doesn't
- **Weighing**: zero once with the bowl on, then each ingredient poured to a cumulative target. Live reading, remaining, progress, steady or not, amber close, green on target, red over. Overshoot is shown and recorded, never "fixed" by changing the other amounts
- **Scale**: the ColorMix scale over BLE, or a simulated scale that runs everything without hardware. Calibration wizard and a scale check (connection test, noise)
- **Saved**: formulas with search, duplicate, delete, and every weighing session with what was really poured
- **Settings**: theme, sounds, move on by itself, tolerance, steadiness, starting dye amount

## Setup

What I build it with (versions checked on 2026-10-26):

- Flutter 3.47.8 / Dart 3.13
- Android: SDK platform 36 + cmdline-tools, NDK 28.2.13676358, JDK 17. The phone needs Android 7 or newer with Bluetooth LE
- Windows: Visual Studio Build Tools 2022 (C++ desktop) and Windows Developer Mode on (Flutter symlinks the plugins)
- Firmware: PlatformIO Core (or the VS Code extension), see [firmware/esp32_color_mix_scale/README.md](firmware/esp32_color_mix_scale/README.md)

```
flutter pub get
dart run build_runner build
flutter test
flutter run -d <phone id>
flutter run -d windows
flutter build apk --release
```

- run `build_runner` again after touching `lib/core/database/tables.dart`, and add a step to the migration in `app_database.dart` with a schemaVersion bump
- Bluetooth only works on a real phone or Windows PC, not the Android emulator
- web is only for previewing screens, real Bluetooth never runs there. `web/sqlite3.wasm` and `web/drift_worker.js` come from the drift-2.35.3 GitHub release, update them together with drift
- Kotlin incremental builds are off in `android/gradle.properties`: the project on D: and the pub cache on C: break them

## Dependencies

| Package | For |
|---|---|
| flutter_riverpod 3 | state, no codegen |
| go_router 18 | routes, the four tabs keep their own stacks |
| drift + drift_flutter | SQLite on every platform, typed queries, migrations |
| universal_ble 3 | Bluetooth LE on Android and Windows (BSD-3). Picked over flutter_blue_plus, whose licence needs paying for commercial use |
| flex_color_picker 4 | the custom color picker |
| wakelock_plus | screen stays on while weighing |
| intl | dates |
| uuid | ids |
| clock | time that tests can control |
| drift_dev, build_runner, fake_async, flutter_lints | dev only |

## Using a scale

**Simulated scale**: Scale tab, Use simulated scale (or the same button on the "Ready to weigh" sheet). It has buttons to place a bowl, pour, overshoot, shake and drop the connection.

**The ColorMix scale**:

1. Wire and flash it: [firmware README](firmware/esp32_color_mix_scale/README.md) (parts, wiring table, `pio run -t upload`)
2. Switch it on, Scale tab, Scan, Connect on "ColorMix Scale". Android asks for Nearby devices (Android 12+) or location (11 and older), that's only for the scan. After the first time, "Connect ColorMix Scale" reconnects without scanning
3. First time only, calibrate: Scale tab, Calibrate. Empty platform, then a reference weight you know (200 g or more is best, 10 g at least) and its exact mass, then a check against it and any other known weight. The scale keeps it in its own flash. The app won't start weighing on an uncalibrated ColorMix scale
4. Scale check (Scale tab, Show) tests the connection and measures noise for 10 s, and says whether the steady and tolerance settings suit this scale

A standard Bluetooth weight scale (0x181D) connects too but is marked experimental: it only sends a reading now and then, so it can't guide pouring.

## Tests

`flutter test` runs everything on the PC, including the blueprint's 16-step scenario on the simulated scale and on a fake ESP32. `pio test -e native` in the firmware folder runs the firmware's maths and protocol tests. The by-hand procedure, on the simulator and on the real scale, is in [docs/test_procedure.md](docs/test_procedure.md).

## Docs

- [docs/decisions.md](docs/decisions.md): why things are the way they are, phase by phase
- [docs/protocol.md](docs/protocol.md): the BLE service, byte for byte
- [docs/test_procedure.md](docs/test_procedure.md): automated tests and the end-to-end runs
- [docs/hardware_test.md](docs/hardware_test.md): the sheet for the first real scale, accuracy, noise, drift, off-centre
- [firmware/esp32_color_mix_scale/README.md](firmware/esp32_color_mix_scale/README.md): parts, wiring, flashing, serial menu, calibration

## Known limitations

- **No hardware run yet.** The firmware builds and its PC tests pass, the app is tested against a fake radio that answers like the firmware. Nothing has been on a real ESP32, HX711 or load cell. The first run is [docs/hardware_test.md](docs/hardware_test.md)
- **Accuracy is unknown until then.** 0.1 g on screen isn't 0.1 g accuracy. A cheap 1 kg cell is more like ±0.2 g. The 0.3 g tolerance and 0.2 g steady threshold are guesses until the hardware sheet says otherwise
- **Demo recipes are demos.** The percentages and colors are for trying the app, not tested dye formulas. Screen color isn't hair color
- **Windows build not tried.** It needs Developer Mode, which was off on this PC. Windows BLE through universal_ble should work but hasn't been run
- **iOS not set up**, no Info.plist Bluetooth strings yet
- **Web preview has no Bluetooth**, the simulator only
- **No BLE pairing or encryption.** Anyone nearby with a BLE app could read the weight or send a tare. Fine on a salon bench for a prototype, not for anything more
- **One phone per scale** is the plan, nothing enforces it
- **Temperature drift isn't compensated**, re-zero or recalibrate after moving the scale somewhere warmer or colder
- **No backup or sync.** Formulas and sessions live on the device only. Uninstalling the app loses them
- Developer ratio and volume are recorded as entered, the app doesn't check them against any product

## Layout

```
lib/
  app/        app, router, shell, theme
  core/       constants, database (drift), bluetooth (scale interface, adapters, simulator), utils, widgets
  features/   dashboard, color_studio, formulation, scale, weighing, saved_formulas, history, settings
  shared/     models + widgets used by more than one feature
test/         unit, widget and end-to-end tests, fakes/ has the fake radio
firmware/     esp32 scale firmware, PlatformIO
docs/         decisions, ble protocol, test procedure, hardware test sheet
```

Shell: bottom bar under 600 px, icon rail up to 1100 px, labelled sidebar above that. Settings is in the app bar on phones and at the bottom of the rail/sidebar.

## Units

No doubles in the formula maths.

- weights: int decigrams (`dg`, 0.1 g)
- scale readings: int milligrams (`mg`)
- percentages: int hundredths of a percent (10000 = 100%)
- colors: int `0xRRGGBB`

## Phases

- [x] 0 setup: Flutter 3.47, Android cmdline-tools + NDK 28.2, PlatformIO, git
- [x] 1 foundation: routing, theme, dashboard, responsive shell, drift db, settings
- [x] 2 color studio: demo palette, custom picker, labelled demo recipes, nearest demo shade
- [x] 3 formula calculator: 1-3 colors, exact weights, developer by weight, validation, save and edit
- [x] 4 simulated weighing: simulator, bowl zero, live display, cumulative targets, overshoot, disconnects, sessions saved, `docs/protocol.md`
- [x] 5 esp32 firmware: HX711, calibration in NVS, BLE service, tare, serial menu. Builds and PC tests pass, not run on a board yet
- [x] 6 real bluetooth: scan, permissions, ESP32 adapter with checks, auto-reconnect, last scale remembered, 0x181D scales as experimental. Tested against a fake radio, not a board yet
- [x] 7 session history and detail, interrupted sessions, settings (tolerance, steadiness, sounds, auto-advance, starting dye), calibration wizard, saved formulas search / duplicate / delete. Calibration tested against the fake radio, not a board yet
- [x] 8 integration: the 16-step scenario automated on the simulator and a fake ESP32 and run by hand in the preview, scale check (connection test, noise) in the app and `n` in the firmware, test procedure, final docs. The hardware run is still to do
