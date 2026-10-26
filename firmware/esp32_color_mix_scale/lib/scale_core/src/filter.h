#pragma once

// small fixed-size filters, no heap

#include <cstdint>

// median of the last 5 samples (fewer while it fills). kills single spikes
// without lagging much at 10 samples a second
class Median5 {
 public:
  void push(int32_t v);
  void reset();
  bool empty() const { return count_ == 0; }
  int32_t value() const;

 private:
  int32_t buf_[5] = {};
  uint8_t count_ = 0;
  uint8_t head_ = 0;
};

// steady when the window is full and everything in it sits within the
// threshold. the app has its own rule, this one is for the stable flag and
// for refusing to tare or calibrate on a moving reading
class StabilityWindow {
 public:
  static constexpr uint8_t kMax = 16;

  StabilityWindow(int32_t thresholdMg, uint8_t samples);
  void push(int32_t mg);
  void reset();
  bool stable() const;
  int32_t spread() const;

 private:
  int32_t thresholdMg_;
  uint8_t size_;
  int32_t buf_[kMax] = {};
  uint8_t count_ = 0;
  uint8_t head_ = 0;
};
