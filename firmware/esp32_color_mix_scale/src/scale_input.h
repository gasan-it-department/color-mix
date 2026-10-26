#pragma once

#include <HX711.h>

#include "calibration.h"
#include "config.h"
#include "filter.h"

// the hx711 side: non-blocking sampling, smoothing, steady, tare, and
// averaging a few seconds of samples for calibration without stalling the
// loop (ble keeps notifying while it collects)
class ScaleInput {
 public:
  void begin(uint8_t dataPin, uint8_t clockPin);

  // call every loop. true when a new sample came in
  bool poll(uint32_t nowMs);

  int32_t lastRaw() const { return lastRaw_; }
  int32_t smoothedRaw() const { return median_.value(); }
  bool hasSample() const { return !median_.empty(); }

  // before tare. overload is judged on this, the bowl is still on the cell
  int32_t grossMg() const { return rawToMilligrams(median_.value(), cal_); }
  int32_t netMg() const { return grossMg() - tareMg_; }
  int32_t tareMg() const { return tareMg_; }

  bool stable() const { return stability_.stable(); }
  int32_t spreadMg() const { return stability_.spread(); }
  bool overload() const;
  bool sensorFault(uint32_t nowMs) const;

  const Calibration& calibration() const { return cal_; }
  void setCalibration(const Calibration& cal);

  void tare() { tareMg_ = grossMg(); }
  void clearTare() { tareMg_ = 0; }

  // average of the next [samples] raw readings
  void startCapture(uint8_t samples);
  void cancelCapture() { capWanted_ = 0; }
  bool capturing() const { return capWanted_ > 0 && capGot_ < capWanted_; }
  bool captureReady() const { return capWanted_ > 0 && capGot_ >= capWanted_; }
  // the average, and ends the capture
  int32_t takeCapture();

 private:
  HX711 hx_;
  Median5 median_;
  StabilityWindow stability_{kStableThresholdMg, kStableSamples};
  Calibration cal_;
  int32_t tareMg_ = 0;
  int32_t lastRaw_ = 0;
  uint32_t lastSampleMs_ = 0;
  bool everSampled_ = false;

  int64_t capSum_ = 0;
  uint8_t capWanted_ = 0;
  uint8_t capGot_ = 0;
};
