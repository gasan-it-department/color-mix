#include "noise.h"

#include <cmath>

void NoiseStats::reset() { *this = NoiseStats(); }

void NoiseStats::push(int32_t mg) {
  if (count_ == 0) {
    min_ = mg;
    max_ = mg;
  } else {
    if (mg < min_) min_ = mg;
    if (mg > max_) max_ = mg;
  }
  count_++;

  // welford, so a long run doesn't lose precision
  const double delta = mg - mean_;
  mean_ += delta / count_;
  m2_ += delta * (mg - mean_);

  if (count_ <= kEdge) firstSum_ += mg;
  last_[lastHead_] = mg;
  lastHead_ = (lastHead_ + 1) % kEdge;
}

double NoiseStats::stdDevMg() const {
  if (count_ < 2) return 0;
  return std::sqrt(m2_ / (count_ - 1));
}

double NoiseStats::driftMg() const {
  if (count_ < 2u * kEdge) return 0;
  int64_t lastSum = 0;
  for (int32_t v : last_) lastSum += v;
  return (static_cast<double>(lastSum) - static_cast<double>(firstSum_)) /
         kEdge;
}
