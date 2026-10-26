# Hardware test sheet

What the blueprint asks for before trusting the scale: reference masses at about 0 / 50 / 100 / 200 / 500 g, plus noise, drift, off-centre loading and repeatability. Fill this in with the real scale, then set the app's tolerance and stability numbers from it.

Board: ______  Cell: ______  HX711 module: ______  Firmware: ______  Date: ______

Reference weights used and how their mass was known: ______________________

## 1. First power-up

- [ ] serial shows the banner, `[cal] not calibrated yet`, `[ble] advertising`
- [ ] `s` shows raw counts changing a little, sensor ok
- [ ] pressing the platform moves the raw counts (either direction is fine)
- [ ] nRF Connect sees `ColorMix Scale` and gets 8-byte frames on the weight characteristic
- [ ] writing `01` to the control characteristic gives `81 00` (or `81 01` while it's moving)

## 2. Calibration

- [ ] `z` with the platform empty: `zero saved`
- [ ] `k <grams>` with the reference on: counts per gram = ________
- [ ] power off and on: `s` still shows the same factor (it's in flash)
- [ ] `x` to clear it, then calibrate again from the app (Scale tab, Calibrate): both steps go through, the scale tab says calibrated, step 3 reads the reference within tolerance
- [ ] in the app, Zero the scale with something moving on the platform: it says the reading isn't steady and stays on step 1

## 3. Accuracy

Weight in the middle, wait for steady, read the net grams (`w`). Three times each, taking the weight off in between.

| Reference (g) | Read 1 | Read 2 | Read 3 | Worst error (g) |
|---|---|---|---|---|
| 0 | | | | |
| 50 | | | | |
| 100 | | | | |
| 200 | | | | |
| 500 | | | | |

## 4. Noise

Platform empty, `w` on for 30 s.

- biggest swing between readings: ______ g
- `s` spread while steady: ______ g

The app's "steady" threshold (0.2 g over 0.8 s) should sit a bit above the swing. The on-target tolerance (0.3 g) should be at least twice it.

## 5. Drift

Tare, leave the platform empty.

| After | Reading (g) |
|---|---|
| 0 min | 0.0 |
| 5 min | |
| 15 min | |
| 30 min | |

Same again with 200 g left on.

## 6. Off-centre loading

200 g in the middle, then near each corner.

| Position | Reading (g) |
|---|---|
| middle | |
| front left | |
| front right | |
| back left | |
| back right | |

More than about 0.5 g between them means the cell mounting or the platform needs work, not the code.

## 7. With BLE busy

App (or nRF Connect) connected and receiving the whole time.

- [ ] noise from step 4 isn't worse while connected
- [ ] unplug and replug the scale while the app's weighing screen is open: the app says disconnected, Reconnect picks it up again once the scale is advertising, and the session carries on

## Result

Tolerance to use in the app: ______ g  Steady threshold: ______ g over ______ ms

Notes:
