#include "cal_store.h"

#include <Preferences.h>

#include <cmath>

namespace cal_store {

namespace {
constexpr char kNamespace[] = "colormix";
constexpr char kZero[] = "zero";
constexpr char kFactor[] = "cpg";
constexpr char kCalibrated[] = "cal";
}  // namespace

Calibration load() {
  Calibration cal;
  Preferences prefs;
  // read-write so a fresh chip creates the namespace instead of logging
  // an nvs NOT_FOUND error on every boot
  if (!prefs.begin(kNamespace, false)) return cal;

  cal.zeroRaw = prefs.getInt(kZero, 0);
  cal.countsPerGram = prefs.getFloat(kFactor, kDefaultCountsPerGram);
  cal.calibrated = prefs.getBool(kCalibrated, false);
  prefs.end();

  if (!std::isfinite(cal.countsPerGram) ||
      std::fabs(cal.countsPerGram) < kMinCountsPerGram) {
    cal.countsPerGram = kDefaultCountsPerGram;
    cal.calibrated = false;
  }
  return cal;
}

bool save(const Calibration& cal) {
  Preferences prefs;
  if (!prefs.begin(kNamespace, false)) return false;
  const bool ok = prefs.putInt(kZero, cal.zeroRaw) > 0 &&
                  prefs.putFloat(kFactor, cal.countsPerGram) > 0 &&
                  prefs.putBool(kCalibrated, cal.calibrated) > 0;
  prefs.end();
  return ok;
}

void clear() {
  Preferences prefs;
  if (!prefs.begin(kNamespace, false)) return;
  prefs.clear();
  prefs.end();
}

}  // namespace cal_store
