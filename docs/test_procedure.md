# Test procedure

How I check ColorMix Studio works: the automated tests, then the blueprint's end-to-end scenario (section 19) by hand, once on the simulated scale and once on the real one. The scale's own accuracy checks are in [hardware_test.md](hardware_test.md).

## 1. Automated

From the project folder:

```
flutter analyze
flutter test
```

All of it runs on the PC, no phone, no board. What it covers:

| Area | Files |
|---|---|
| formula maths: percentages, developer by weight, rounding to exact totals, bad inputs, rescaling a saved formula | `formula_math_test`, `formula_editor_test` |
| color: CIELAB / CIEDE2000, nearest demo shade, hex input | `color_science_test`, `color_studio_test`, `demo_catalog_test` |
| storage: formulas, sessions, history, interrupted sessions, duplicate names, opening v1, v2 and v3 databases, settings | `formula_repository_test`, `session_repository_test`, `migration_test`, `settings_repository_test` |
| product form: cream / liquid / powder saved, duplicated and kept in history, slow-down band per form, the editor's form menu at 360 px, pour hints while weighing | `product_form_test`, `product_form_ui_test` |
| units: g / oz / mL / fl oz conversions and typing, the mix density for a typed volume, density errors, switching units never moves the grams, the unit and densities saved, duplicated, backed up and remembered, the editor, list and start sheet in each unit at 360 px | `measure_unit_test`, `measure_unit_ui_test` |
| camera color: the card's correction under warm, cold, dim and bright light, white paper and gray card, portrait and landscape stills, shine and gaps between strands left out, stray strands over the card, shadow, washed out, too dark, no card, no hair; the screen from Color Studio to the target at 360 px with a fake camera, a bad photo then a good one, the card remembered, no camera allowed, a real PNG decoded and scaled | `camera_reading_test`, `camera_screen_test` |
| backup: everything round trips, a restore only adds, damaged / foreign / newer files refused with the reason, the Settings card from save to restore on a fresh install | `backup_test` |
| weighing rules: bowl zero, cumulative targets, zones, overshoot, manual moves, stale readings, drift after a reconnect, the simulator | `weighing_state_test`, `stability_detector_test`, `weighing_flow_test`, `simulated_scale_test` |
| BLE: frame bytes, sequence wrap, scan, connect, refuse the wrong device or protocol, reconnect after a drop, tare, calibration commands, connection test, missed frames | `esp32_protocol_test`, `ble_scale_device_test`, `ble_scan_test`, `scale_screen_test` |
| screens: shell and tabs, saved formulas, history, settings, calibration wizard, scale check and its noise numbers, 360 px phones | `widget_test`, `saved_formulas_test`, `settings_screen_test`, `calibration_test`, `scale_check_test`, `reading_stats_test` |
| **section 19 end to end**, all 16 steps through the real screens: simulated scale on a 360 px phone, and the ColorMix scale over a fake radio fed like the firmware feeds it | `e2e_rose_gold_test` |

The fake radio (`test/fakes/fake_ble.dart`) answers the way the firmware does, byte for byte from `docs/protocol.md`. It proves the app and the protocol agree. It doesn't prove the board works, that's section 3.

Firmware, from `firmware/esp32_color_mix_scale` (needs a gcc on PATH, msys64 ucrt64 here):

```
pio test -e native
pio run -e esp32dev
```

The native tests check the frame bytes against the same vectors as the Dart tests, the filters, the calibration maths and the noise numbers.

## 2. Section 19 on the simulated scale

Any build: Android phone, Windows, or the web preview (`flutter build web`, then serve `build/web`). Start from a fresh install or clear the app's data.

| # | Do | Expect |
|---|---|---|
| 1 | open the app | dashboard: New color formula, Connect scale, no saved formulas |
| 2 | Colors, Rose Gold | Rose Gold target with its hex, "Demo shade" |
| 3 | look at the recipe (phones: Details) | "Demo recipe", "Demo only", Color A 50%, Color B 30%, Color C 20%, developer 1:1 by weight |
| 4 | Create formula, dye amount 60 | the field takes 60 |
| 5 | | Color A 30.0 g, Color B 18.0 g, Color C 12.0 g, developer 60.0 g, mixture 120.0 g, total 100% |
| 6 | Save formula, Start weighing | "Ready to weigh" with the order and running totals 30 / 48 / 60 / 120 g. Tick the developer ratio check |
| 7 | Use simulated scale | "Simulated scale · Connected" |
| 8 | Start weighing | big live reading, Steady |
| 9 | simulator: Place bowl, then Zero with bowl | 250.0 g, then "Check it reads about 0.0 g" |
| 10 | Start with Color A, Hold to pour or +5 g | the number climbs, remaining and progress follow, amber when close |
| 11 | pour to 30.0 g | green, "On target", Steady, Next ingredient lights up |
| 12 | Color B then Color C | targets "of 48.0 g", "of 60.0 g" on top of what's in, never tared between |
| 13 | developer | target "of 120.0 g" (or 120.x if an earlier step was a touch over) |
| 14 | Finish | "Check the mixture": planned vs on the scale, each step's target, added, off by |
| 15 | Complete and save | "Mixture complete", "Saved to this device" |
| 16 | back, Formulas, the formula's ⋮, Weigh | the start sheet again with the same amounts. History shows the session as Completed, its detail shows 4 of 4 on target |

Product forms: before step 6, set Color A to Liquid in its name field's menu and the developer to Liquid. The sheet shows the form under each name. Weighing Color A says "Pour slowly, it runs fast.", and turns amber about 4.5 g before 30 g instead of 3 g, with "A few drops at a time now". A cream says "Squeeze it in steadily.", a powder "Spoon it in.".

Units: in the editor, the dye field's "g ▾" menu. oz shows 2.12 and 1.06 / 0.63 / 0.42 oz, with "120.0 g on the scale" under the mixture. Back to g is 60 again, not 60.1. mL shows 60 and a Density card. Set Color A to Powder: the field stays 60 mL, Color A becomes 40.0 mL (20 g), mixture 100.0 mL ("80.0 g on the scale", the developer ratio is still by weight). The start sheet says "add 40.0 mL" with "Powder · 20.0 g" under the name, the weighing screen "of 20.0 g · 40.0 mL". The saved list says "60.0 mL dye". A new formula starts in the last unit picked.

Camera, on a phone (the web preview only has whatever webcam the PC has): Colors, Camera, Open camera, allow it. Lay a hair swatch, or anything solid colored, on plain white paper by a window, no flash. Hair fills the middle square, paper shows in the four small ones, Read color. Then the same swatch under a warm lamp: the "Straight from the camera" color moves a lot, the reading should move much less. Pull the paper away so a small square shows the table: it refuses with "Part of the card is covered or in shadow". Use this color: it's the custom target, "Last reading, now the target" in the panel, Fine-tune opens Custom color on it. Worth a check against something of known color, a printed swatch or a paint chip, to see how far off this phone is.

Backup, on a phone: Settings, Save backup, save it to Downloads. Uninstall the app, install it again, Settings, Restore, pick that file: the formulas and History are back.

Worth trying on the way: Pour 2 g too much (red, Over by, Continue manually, "Moved on" on the record), Drop connection (paused, Reconnect, carries on), Freeze readings (Waiting for readings, nothing confirms).

## 3. Section 19 on the ColorMix scale

Android phone with Bluetooth, the scale flashed, calibrated and checked with [hardware_test.md](hardware_test.md) first. Same table as section 2 except:

| # | Do | Expect |
|---|---|---|
| 7 | Start weighing sheet: Find a scale, Scan, Connect on ColorMix Scale (or "Connect ColorMix Scale" if it's been used before) | "ColorMix Scale · Connected", "Firmware 0.1.0 · calibrated". An uncalibrated scale is refused here with a Calibrate button |
| 8 | Scale tab, Scale check, Test connection | answers in well under a second, about 10 readings a second, 0 missed |
| 9 | real bowl on, Zero with bowl | about 0.0 g with the bowl on |
| 10-13 | pour from the real bottles (water works for a dry run) | the reading follows within a fraction of a second, settles to Steady within about a second of stopping |
| 14 | | measured total within a few tenths of a gram of the sum of the steps |
| extra | switch the scale off mid-step, then on | "Scale disconnected", progress kept, Reconnect, carries on, a note if the bowl moved more than 1 g |

## 4. Runs so far

| Date | What | Result |
|---|---|---|
| 2026-10-27 | `flutter analyze`, `flutter test` | clean, 181 pass |
| 2026-10-27 | `pio test -e native`, `pio run -e esp32dev` | 9 pass, builds (62% flash, 11% RAM) |
| 2026-10-27 | `flutter build apk --debug`, `flutter build web` | build |
| 2026-10-27 | section 2 by hand in the web preview at desktop width, history and settings screens also at 360 px | pass. Found and fixed on the way: progress said 100.1% at 30.0 g, and -0.0% at the start of a step on web |
| 2026-10-27 | section 19 automated, simulator on a 360 px phone and fake ESP32 | pass |
| 2026-10-30 | units: `flutter analyze`, `flutter test`, the units run above in the web preview at 360 px | clean, 231 pass. 9 fail, all in the uncommitted redesign's own tests (`redesign_layout_test`, 2 history tests in `saved_formulas_test`), failing the same before units. Found and fixed on the way: the density fields' "g/mL" only showed once typed in |
| | section 3 on the real scale | not yet, no board |
