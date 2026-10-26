#pragma once

#include <cstdint>

#ifndef FW_VERSION
#define FW_VERSION "0.1.0"
#endif

// ── wiring, see README ─────────────────────────────────────

constexpr uint8_t kHxDataPin = 18;   // HX711 DOUT / DT
constexpr uint8_t kHxClockPin = 19;  // HX711 SCK / CLK

// ── ble, must match docs/protocol.md ───────────────────────

constexpr char kDeviceName[] = "ColorMix Scale";
constexpr char kServiceUuid[] = "7a3e0001-5c2d-4f1b-9c8e-0d6b2f4a1e90";
constexpr char kWeightUuid[] = "7a3e0002-5c2d-4f1b-9c8e-0d6b2f4a1e90";
constexpr char kInfoUuid[] = "7a3e0003-5c2d-4f1b-9c8e-0d6b2f4a1e90";
constexpr char kControlUuid[] = "7a3e0004-5c2d-4f1b-9c8e-0d6b2f4a1e90";

// ── scale ──────────────────────────────────────────────────

constexpr uint32_t kCapacityG = 1000;
constexpr int32_t kCapacityMg = static_cast<int32_t>(kCapacityG) * 1000;

// one frame per hx711 sample at 10 SPS, no faster
constexpr uint32_t kNotifyIntervalMs = 100;

// no sample for this long and the frames carry the sensor fault flag
constexpr uint32_t kSensorTimeoutMs = 500;

// device-side steady guess for the flag and for refusing to tare or
// calibrate on a moving reading. the app judges steady for itself
constexpr int32_t kStableThresholdMg = 150;
constexpr uint8_t kStableSamples = 8;  // 0.8 s at 10 SPS

// raw samples averaged for each calibration step, 2 s at 10 SPS
constexpr uint8_t kCalSamples = 20;
