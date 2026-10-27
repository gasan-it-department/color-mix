#pragma once

#include <Arduino.h>

#include "noise.h"
#include "scale_input.h"
#include "serial_menu.h"

enum class Source : uint8_t { kSerial, kBle };

// everything the scale does, run from loop() without blocking
class App {
 public:
  void begin();
  void loop();

  // shared by the serial menu and the app's control writes. return a
  // proto::result code. calibration steps finish later, when enough
  // samples are in, and reply then
  uint8_t tare(Source src);
  uint8_t startCalZero(Source src);
  uint8_t startCalKnownMass(int32_t knownMg, Source src);
  void cancelCalibration();
  void clearCalibration();
  bool setFactor(float countsPerGram);

  void toggleWeightStream();
  void toggleRawStream();

  // collects net readings for [seconds], then prints mean, swing, standard
  // deviation and drift. frames keep going meanwhile
  void startNoiseCheck(uint32_t seconds);

  void printStatus(Print& out);
  void printHelp(Print& out) const;

 private:
  enum class CalStep : uint8_t { kIdle, kZero, kKnownMass };

  void onSample(uint32_t nowMs);
  void sendFrame(uint32_t nowMs);
  uint8_t frameFlags(uint32_t nowMs) const;
  void runBleCommands();
  void finishCalibration();
  void applyCalibration(const Calibration& cal);
  void refreshInfo();
  void finishNoiseCheck();
  void done(Source src, uint8_t op, uint8_t result, const char* message);

  ScaleInput scale_;
  SerialMenu menu_;

  uint16_t seq_ = 0;
  uint32_t lastFrameMs_ = 0;
  bool streamWeight_ = false;
  bool streamRaw_ = false;

  CalStep calStep_ = CalStep::kIdle;
  Source calSource_ = Source::kSerial;
  int32_t calKnownMg_ = 0;
  // the known-mass step needs a zero from this power-up, not an old one
  bool zeroedThisBoot_ = false;

  NoiseStats noise_;
  bool noiseRunning_ = false;
  uint32_t noiseStartMs_ = 0;
  uint32_t noiseMs_ = 0;

  char info_[64] = {};
};
