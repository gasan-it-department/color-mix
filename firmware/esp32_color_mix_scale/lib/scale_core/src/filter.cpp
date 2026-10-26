#include "filter.h"

void Median5::push(int32_t v) {
  buf_[head_] = v;
  head_ = (head_ + 1) % 5;
  if (count_ < 5) count_++;
}

void Median5::reset() {
  count_ = 0;
  head_ = 0;
}

int32_t Median5::value() const {
  if (count_ == 0) return 0;
  // insertion sort of at most 5, cheap enough every sample
  int32_t sorted[5];
  for (uint8_t i = 0; i < count_; i++) {
    const int32_t v = buf_[i];
    int8_t j = static_cast<int8_t>(i) - 1;
    while (j >= 0 && sorted[j] > v) {
      sorted[j + 1] = sorted[j];
      j--;
    }
    sorted[j + 1] = v;
  }
  return sorted[count_ / 2];
}

StabilityWindow::StabilityWindow(int32_t thresholdMg, uint8_t samples)
    : thresholdMg_(thresholdMg),
      size_(samples == 0 ? 1 : (samples > kMax ? kMax : samples)) {}

void StabilityWindow::push(int32_t mg) {
  buf_[head_] = mg;
  head_ = (head_ + 1) % size_;
  if (count_ < size_) count_++;
}

void StabilityWindow::reset() {
  count_ = 0;
  head_ = 0;
}

int32_t StabilityWindow::spread() const {
  if (count_ == 0) return 0;
  int32_t lo = buf_[0];
  int32_t hi = buf_[0];
  for (uint8_t i = 1; i < count_; i++) {
    if (buf_[i] < lo) lo = buf_[i];
    if (buf_[i] > hi) hi = buf_[i];
  }
  return hi - lo;
}

bool StabilityWindow::stable() const {
  return count_ == size_ && spread() <= thresholdMg_;
}
