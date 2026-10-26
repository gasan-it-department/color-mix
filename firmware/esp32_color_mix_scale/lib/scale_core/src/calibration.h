#pragma once

// raw hx711 counts -> milligrams, and working out the factor from a known
// weight. no arduino in here

#include <cstdint>

struct Calibration {
  // raw reading with nothing on the platform
  int32_t zeroRaw = 0;
  // hx711 counts per gram, negative when the cell is wired the other way
  float countsPerGram = 1000.0f;
  bool calibrated = false;
};

// rough guess for an uncalibrated 1 kg cell at 3.3 V, frames carry the
// uncalibrated flag until a real factor is saved
constexpr float kDefaultCountsPerGram = 1000.0f;

// the hx711 is 24-bit, it pins at these when overdriven or disconnected
constexpr int32_t kRawMax = 0x7FFFFF;
constexpr int32_t kRawMin = -0x800000;

// smallest reference weight the calibration accepts, 10 g
constexpr int32_t kMinKnownMassMg = 10000;

// a factor this small means nothing was on the platform or the cell isn't
// wired, a real 1 kg cell gives hundreds to a few thousand
constexpr float kMinCountsPerGram = 50.0f;

// rounded to the nearest milligram
int32_t rawToMilligrams(int32_t raw, const Calibration& cal);

bool isRawAtRail(int32_t raw);

enum class CalError { kNone, kTooLight, kBadFactor };

struct CalResult {
  float countsPerGram = 0;
  CalError error = CalError::kNone;
};

CalResult factorFromKnownMass(int32_t raw, int32_t zeroRaw, int32_t knownMg);

const char* calErrorText(CalError e);
