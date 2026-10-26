#pragma once

#include "calibration.h"

// calibration kept in nvs so it survives power cycles and reflashing the
// same partition layout
namespace cal_store {

// defaults (uncalibrated) when nothing valid is saved
Calibration load();
bool save(const Calibration& cal);
void clear();

}  // namespace cal_store
