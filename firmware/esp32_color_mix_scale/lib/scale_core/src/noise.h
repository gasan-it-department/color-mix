#pragma once

// numbers for the noise check (serial `n`): mean, swing, standard deviation
// and drift, without keeping every sample. no heap

#include <cstdint>

class NoiseStats {
 public:
  // drift compares the average of the first and last this many samples
  static constexpr uint8_t kEdge = 10;

  void reset();
  void push(int32_t mg);

  uint32_t count() const { return count_; }
  int32_t minMg() const { return min_; }
  int32_t maxMg() const { return max_; }
  int32_t swingMg() const { return count_ == 0 ? 0 : max_ - min_; }
  double meanMg() const { return mean_; }

  // sample standard deviation, 0 under two samples
  double stdDevMg() const;

  // average of the last kEdge samples minus the first kEdge. needs at least
  // two edges' worth, 0 before that
  double driftMg() const;

 private:
  uint32_t count_ = 0;
  int32_t min_ = 0;
  int32_t max_ = 0;
  double mean_ = 0;
  double m2_ = 0;  // welford's running sum of squares

  int64_t firstSum_ = 0;
  int32_t last_[kEdge] = {};
  uint8_t lastHead_ = 0;
};
