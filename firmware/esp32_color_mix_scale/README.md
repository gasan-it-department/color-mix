# ColorMix scale firmware

ESP32 + HX711 + 1 kg load cell. Sends the weight over BLE about 10 times a second in the format from [../../docs/protocol.md](../../docs/protocol.md), takes TARE / GET_STATUS / calibration commands, keeps the calibration in flash, and has a serial menu for checking everything by hand.

Arduino framework on PlatformIO, NimBLE-Arduino 2.5 for BLE, RobTillaart/HX711 for the load cell.

## Parts

- ESP32-WROOM-32 dev board (esp32dev)
- HX711 module that runs on 3.3 V. Most green ones do, check yours
- 1 kg single-point load cell, 4 wires
- USB cable and a 5 V USB supply
- a base and a platform, wood or 3D printed, plus M4/M5 bolts and spacers for the cell

## Wiring

| HX711 | ESP32 |
|---|---|
| VCC | 3V3 |
| GND | GND |
| DT / DOUT | GPIO 18 |
| SCK / CLK | GPIO 19 |

| Load cell wire (usual colours) | HX711 |
|---|---|
| red | E+ |
| black | E− |
| green | A+ |
| white | A− |

- Wire colours aren't standard. Check the cell's datasheet. If the reading goes down when you press, swap A+ and A−, or just calibrate: a negative factor works fine.
- Power the HX711 from 3V3, not 5V. A 5 V HX711 drives DT at 5 V into the ESP32, which isn't 5 V tolerant.
- Leave the HX711's RATE pin on 10 SPS (tied to GND, which is how most modules ship). 80 SPS is noisier and the firmware only sends 10 frames a second anyway.
- Pins are in `include/config.h` if you need others.

Mechanics matter more than code for accuracy:

- bolt one end of the cell to the base and the other end to the platform, with spacers so the middle can bend freely
- the arrow on the cell points the way the load pushes (down)
- the platform shouldn't touch anything but the cell
- tie the cell's cable down so it doesn't pull on the cell

## Build and flash

PlatformIO Core is in `~\.platformio\penv\Scripts`, or use the PlatformIO tab in VS Code.

```
pio run -e esp32dev
pio run -e esp32dev -t upload
pio device monitor
```

If upload hangs on "Connecting...", hold the board's BOOT button until it starts writing.

Tests for the protocol, filters and calibration maths run on the PC, no board needed. They need a gcc on PATH (msys64 ucrt64 here):

```
pio test -e native
```

## Serial menu

115200 baud. Type a letter and press enter.

| Command | What it does |
|---|---|
| `s` | status: raw counts, gross / net grams, tare, steady, overload, sensor, calibration, BLE |
| `w` | stream the weight on/off |
| `r` | stream raw HX711 counts on/off |
| `t` | tare |
| `z` | calibration step 1, platform empty |
| `k <grams>` | calibration step 2, reference weight on, e.g. `k 200` |
| `c` | cancel a calibration step |
| `f <n>` | set counts per gram by hand |
| `x` | clear the calibration |
| `n [secs]` | noise check, 10 s unless you say: mean, min, max, swing, standard deviation and drift of the net reading. `n 1800` for a half-hour drift test. Frames keep going meanwhile |
| `h` | help |

## Calibration

Needs a known weight of at least 10 g. 200 g or more is better, a 500 g kitchen-scale reference weight or a sealed bottle weighed on a good scale both work.

1. Power up, let it warm up for a few minutes (the cell drifts while it warms)
2. Platform empty, wait for `s` to say steady, then `z`. It averages 2 s and saves the zero
3. Put the reference weight in the middle of the platform, wait for steady, then `k 200` (its real mass in grams). It averages 2 s, works out the counts per gram and saves it
4. Check with one or two other weights (`w` to watch the reading), and `n` with the platform still to see how noisy it is. See [../../docs/hardware_test.md](../../docs/hardware_test.md) for the full check
5. `x` and start again if it's off

The same two steps work over BLE (CAL_ZERO, CAL_KNOWN_MASS), that's what the app's calibration screen does: Scale tab, Calibrate. It walks through both steps and then checks the reading against known weights.

Until it's calibrated, frames carry the uncalibrated flag and grams use a rough default factor.

## BLE

- Advertises as `ColorMix Scale` with the service UUID in the advert, the name in the scan response
- Weight frames go out as each HX711 sample comes in (about 10 a second). If the HX711 stops answering for 0.5 s, frames keep going every 100 ms with the sensor fault flag set
- Control writes are queued and run in the main loop, the reply comes back as a notify on the control characteristic: `81 00` = tare ok, `81 01` = busy (reading not steady)
- Calibration replies come when the 2 s average is done, not straight away
- Advertising restarts by itself after a disconnect
- No pairing or encryption. It's a prototype on a salon bench, anyone nearby with a BLE app can read the weight or send a tare

In the app: Scale tab, Scan, Connect on "ColorMix Scale". It checks the service and the protocol version before it trusts the scale. To look underneath, nRF Connect on a phone works too: connect to ColorMix Scale, enable notifications on `7a3e0002…` and watch the 8-byte frames, write `01` to `7a3e0004…` to tare.

## Code

```
include/config.h        pins, UUIDs, timings
lib/scale_core/         no arduino in here, tested on the pc
  protocol.*            frames, control commands, replies, info text
  filter.*              median of 5, steady window
  calibration.*         raw counts -> mg, factor from a known weight
  noise.*               numbers for `n`: mean, swing, sd, drift, no heap
src/
  scale_input.*         hx711 sampling without blocking, tare, averaging
  cal_store.*           calibration in nvs (Preferences)
  ble_link.*            the gatt service on NimBLE
  app.*                 the loop: frames, commands, calibration steps
  serial_menu.*         the serial commands
test/test_core/         unity tests for lib/scale_core
```

Nothing in the loop blocks: no `delay()` apart from a 1 ms yield, the HX711 is only read when it has a sample, calibration averages over the next 20 samples while frames keep going.

## Known limits

- Not tested on hardware yet, it builds and the PC tests pass. First power-up checks are in the hardware test sheet
- 0.1 g on the display isn't 0.1 g accuracy. Expect around ±0.2 g on a cheap 1 kg cell, the hardware test will say
- Tare isn't saved, it resets on power-up. The app doesn't use it while weighing anyway, it zeroes the bowl itself
- Temperature drift isn't compensated. Zero again (`z` then `k`, or just tare) if it's been moved somewhere warmer or colder
- One phone at a time is the plan. NimBLE allows a few connections, nothing stops a second phone
