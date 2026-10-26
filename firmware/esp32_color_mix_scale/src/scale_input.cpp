#include "scale_input.h"

#include <cmath>

void ScaleInput::begin(uint8_t dataPin, uint8_t clockPin) {
  // fastProcessor: the esp32 toggles the clock faster than the hx711's
  // 0.2 us minimum without the library's extra delay
  hx_.begin(dataPin, clockPin, true);
  hx_.set_gain(HX711_CHANNEL_A_GAIN_128);
}

bool ScaleInput::poll(uint32_t nowMs) {
  // read() would block until the next conversion, only ask when it's there
  if (!hx_.is_ready()) return false;

  const int32_t raw = static_cast<int32_t>(std::lround(hx_.read()));
  lastRaw_ = raw;
  lastSampleMs_ = nowMs;
  everSampled_ = true;

  median_.push(raw);
  stability_.push(grossMg());

  if (capturing()) {
    capSum_ += raw;
    capGot_++;
  }
  return true;
}

bool ScaleInput::overload() const {
  return isRawAtRail(lastRaw_) || grossMg() >= kCapacityMg;
}

bool ScaleInput::sensorFault(uint32_t nowMs) const {
  if (!everSampled_) return nowMs > kSensorTimeoutMs * 4;  // grace at boot
  return nowMs - lastSampleMs_ > kSensorTimeoutMs;
}

void ScaleInput::setCalibration(const Calibration& cal) {
  cal_ = cal;
  // old readings were in the old units
  stability_.reset();
}

void ScaleInput::startCapture(uint8_t samples) {
  capSum_ = 0;
  capGot_ = 0;
  capWanted_ = samples == 0 ? 1 : samples;
}

int32_t ScaleInput::takeCapture() {
  const int32_t avg =
      capGot_ == 0 ? lastRaw_
                   : static_cast<int32_t>(std::llround(
                         static_cast<double>(capSum_) / capGot_));
  capWanted_ = 0;
  capGot_ = 0;
  capSum_ = 0;
  return avg;
}
