# ColorMix Studio

Hair color formula + Bluetooth scale prototype. Flutter app (Android first, Windows desktop, iOS later) plus ESP32 + HX711 scale firmware (firmware not started yet).

Pick a target color, set Color A/B/C percentages and a total, get exact gram amounts, then weigh them into one bowl on the scale with live readings. Works offline, no account.

Demo formulas are examples only. The color on screen is a target, not a promise of what the dye does on hair.

## Running it

```
flutter pub get
dart run build_runner build
flutter test
flutter run -d windows
flutter run -d <phone id>
```

- run `build_runner` again after touching `lib/core/database/tables.dart`
- Windows builds need Developer Mode on (Flutter symlinks the plugins)
- Bluetooth only works on a real phone, not the emulator
- web is only for previewing screens, real Bluetooth never runs there. `web/sqlite3.wasm` and `web/drift_worker.js` come from the drift-2.35.3 GitHub release, update them together with drift

## Layout

```
lib/
  app/        app, router, shell, theme
  core/       constants, database (drift), bluetooth (scale interface), utils, widgets
  features/   dashboard, color_studio, formulation, scale, weighing, saved_formulas, settings
  shared/     models + widgets used by more than one feature
firmware/     esp32 scale firmware, PlatformIO
docs/         decisions, ble protocol, hardware test sheet
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
- [ ] 7 session history, settings, calibration ui
- [ ] 8 end-to-end runs, hardware checks, docs
