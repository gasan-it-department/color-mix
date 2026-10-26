// ColorMix scale: ESP32 + HX711 + 1 kg load cell, weight over BLE.
// protocol in docs/protocol.md, wiring and calibration in README.md

#include <Arduino.h>

#include "app.h"

namespace {
App app;
}

void setup() { app.begin(); }

void loop() { app.loop(); }
