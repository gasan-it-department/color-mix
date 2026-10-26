#include "calibration.h"

#include <cmath>

int32_t rawToMilligrams(int32_t raw, const Calibration& cal) {
  const float cpg = cal.countsPerGram == 0 ? kDefaultCountsPerGram
                                           : cal.countsPerGram;
  const double mg =
      (static_cast<double>(raw) - static_cast<double>(cal.zeroRaw)) * 1000.0 /
      static_cast<double>(cpg);
  return static_cast<int32_t>(std::lround(mg));
}

bool isRawAtRail(int32_t raw) { return raw >= kRawMax || raw <= kRawMin; }

CalResult factorFromKnownMass(int32_t raw, int32_t zeroRaw, int32_t knownMg) {
  CalResult r;
  if (knownMg < kMinKnownMassMg) {
    r.error = CalError::kTooLight;
    return r;
  }
  const double grams = static_cast<double>(knownMg) / 1000.0;
  r.countsPerGram = static_cast<float>(
      (static_cast<double>(raw) - static_cast<double>(zeroRaw)) / grams);
  if (std::fabs(r.countsPerGram) < kMinCountsPerGram) {
    r.error = CalError::kBadFactor;
  }
  return r;
}

const char* calErrorText(CalError e) {
  switch (e) {
    case CalError::kNone:
      return "ok";
    case CalError::kTooLight:
      return "reference weight must be at least 10 g";
    case CalError::kBadFactor:
      return "reading barely moved, is the weight on and the cell wired?";
  }
  return "unknown";
}
