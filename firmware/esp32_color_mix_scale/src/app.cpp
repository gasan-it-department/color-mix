#include "app.h"

#include <cmath>

#include "ble_link.h"
#include "cal_store.h"
#include "config.h"
#include "protocol.h"

namespace {

// frames follow fresh samples, but never closer than this. an 80 SPS
// hx711 module still only sends about 12 a second
constexpr uint32_t kMinFrameGapMs = 80;

double grams(int32_t mg) { return mg / 1000.0; }

}  // namespace

void App::begin() {
  Serial.begin(115200);
  delay(200);  // usb serial settling, once at boot

  Serial.printf("\nColorMix Scale, firmware %s\n", FW_VERSION);

  const Calibration cal = cal_store::load();
  scale_.begin(kHxDataPin, kHxClockPin);
  scale_.setCalibration(cal);
  if (cal.calibrated) {
    Serial.printf("[cal] %.2f counts/g, zero at %ld\n", cal.countsPerGram,
                  static_cast<long>(cal.zeroRaw));
  } else {
    Serial.println("[cal] not calibrated yet, grams are only a rough guess");
  }

  proto::formatInfo(info_, sizeof info_, FW_VERSION, kCapacityG,
                    cal.calibrated);
  ble_link::begin(info_);
  Serial.printf("[ble] advertising as \"%s\", %s\n", kDeviceName,
                ble_link::address());

  printHelp(Serial);
}

void App::loop() {
  const uint32_t now = millis();

  if (scale_.poll(now)) onSample(now);
  if (scale_.captureReady()) finishCalibration();
  if (noiseRunning_ && now - noiseStartMs_ >= noiseMs_) finishNoiseCheck();
  runBleCommands();
  menu_.poll(*this);

  // a dead hx711 sends no samples: keep frames going with the fault flag so
  // the app knows the board is alive but the sensor isn't
  if (scale_.sensorFault(now) && now - lastFrameMs_ >= kNotifyIntervalMs) {
    sendFrame(now);
  }

  // let the idle task and ble run, 1 ms is nothing at 10 samples a second
  vTaskDelay(1);
}

// ── frames ─────────────────────────────────────────────────

void App::onSample(uint32_t nowMs) {
  if (noiseRunning_) noise_.push(scale_.netMg());
  if (streamRaw_) {
    Serial.printf("raw %ld  median %ld\n", static_cast<long>(scale_.lastRaw()),
                  static_cast<long>(scale_.smoothedRaw()));
  }
  if (streamWeight_) {
    Serial.printf("%10.3f g  %s%s\n", grams(scale_.netMg()),
                  scale_.stable() ? "steady" : "moving",
                  scale_.overload() ? "  OVERLOAD" : "");
  }
  if (nowMs - lastFrameMs_ >= kMinFrameGapMs) sendFrame(nowMs);
}

uint8_t App::frameFlags(uint32_t nowMs) const {
  uint8_t f = 0;
  if (scale_.stable()) f |= proto::flag::kStable;
  if (scale_.overload()) f |= proto::flag::kOverload;
  if (!scale_.calibration().calibrated) f |= proto::flag::kUncalibrated;
  if (scale_.sensorFault(nowMs)) f |= proto::flag::kSensorFault;
  return f;
}

void App::sendFrame(uint32_t nowMs) {
  lastFrameMs_ = nowMs;
  seq_++;
  uint8_t frame[proto::kWeightFrameLen];
  proto::encodeWeightFrame(frame, scale_.netMg(), seq_, frameFlags(nowMs));
  ble_link::notifyWeight(frame);
}

// ── commands from the app ──────────────────────────────────

void App::runBleCommands() {
  proto::ControlCommand cmd;
  while (ble_link::takeCommand(cmd)) {
    if (!cmd.known) {
      Serial.printf("[ble] unknown opcode 0x%02X\n", cmd.op);
      ble_link::sendReply(cmd.op, proto::result::kUnknownOp);
      continue;
    }
    if (!cmd.valid) {
      Serial.printf("[ble] bad length for opcode 0x%02X\n", cmd.op);
      ble_link::sendReply(cmd.op, proto::result::kFailed);
      continue;
    }
    switch (cmd.op) {
      case proto::op::kTare:
        tare(Source::kBle);
        break;
      case proto::op::kGetStatus:
        refreshInfo();
        ble_link::sendReply(cmd.op, proto::result::kOk);
        break;
      case proto::op::kCalZero:
        startCalZero(Source::kBle);
        break;
      case proto::op::kCalKnownMass:
        startCalKnownMass(cmd.payload, Source::kBle);
        break;
    }
  }
}

void App::done(Source src, uint8_t op, uint8_t result, const char* message) {
  if (src == Source::kBle) ble_link::sendReply(op, result);
  Serial.printf("[%s] %s\n", src == Source::kBle ? "ble" : "cmd", message);
}

// ── tare ───────────────────────────────────────────────────

uint8_t App::tare(Source src) {
  if (!scale_.hasSample() || !scale_.stable()) {
    done(src, proto::op::kTare, proto::result::kBusy,
         "not steady, tare again once the reading settles");
    return proto::result::kBusy;
  }
  scale_.tare();
  done(src, proto::op::kTare, proto::result::kOk, "tared");
  return proto::result::kOk;
}

// ── calibration ────────────────────────────────────────────

uint8_t App::startCalZero(Source src) {
  if (calStep_ != CalStep::kIdle) {
    done(src, proto::op::kCalZero, proto::result::kBusy,
         "calibration already running");
    return proto::result::kBusy;
  }
  if (!scale_.stable()) {
    done(src, proto::op::kCalZero, proto::result::kBusy,
         "wait for a steady reading with the platform empty");
    return proto::result::kBusy;
  }
  calStep_ = CalStep::kZero;
  calSource_ = src;
  scale_.startCapture(kCalSamples);
  Serial.println("[cal] zeroing, keep the platform empty for 2 s...");
  return proto::result::kOk;
}

uint8_t App::startCalKnownMass(int32_t knownMg, Source src) {
  if (calStep_ != CalStep::kIdle) {
    done(src, proto::op::kCalKnownMass, proto::result::kBusy,
         "calibration already running");
    return proto::result::kBusy;
  }
  if (!zeroedThisBoot_) {
    done(src, proto::op::kCalKnownMass, proto::result::kFailed,
         "zero first with the platform empty ('z')");
    return proto::result::kFailed;
  }
  if (knownMg < kMinKnownMassMg) {
    done(src, proto::op::kCalKnownMass, proto::result::kFailed,
         calErrorText(CalError::kTooLight));
    return proto::result::kFailed;
  }
  if (!scale_.stable()) {
    done(src, proto::op::kCalKnownMass, proto::result::kBusy,
         "wait for a steady reading with the weight on");
    return proto::result::kBusy;
  }
  calStep_ = CalStep::kKnownMass;
  calSource_ = src;
  calKnownMg_ = knownMg;
  scale_.startCapture(kCalSamples);
  Serial.printf("[cal] measuring %.3f g, keep still for 2 s...\n",
                grams(knownMg));
  return proto::result::kOk;
}

void App::finishCalibration() {
  const int32_t avg = scale_.takeCapture();
  const CalStep step = calStep_;
  calStep_ = CalStep::kIdle;
  const uint8_t op = step == CalStep::kZero ? proto::op::kCalZero
                                            : proto::op::kCalKnownMass;

  // someone bumped it while we averaged
  if (!scale_.stable()) {
    done(calSource_, op, proto::result::kFailed,
         "reading moved while measuring, try that step again");
    return;
  }

  Calibration cal = scale_.calibration();
  if (step == CalStep::kZero) {
    cal.zeroRaw = avg;
    zeroedThisBoot_ = true;
    applyCalibration(cal);
    done(calSource_, op, proto::result::kOk,
         "zero saved. put the reference weight on, then 'k <grams>'");
    return;
  }

  const CalResult r = factorFromKnownMass(avg, cal.zeroRaw, calKnownMg_);
  if (r.error != CalError::kNone) {
    done(calSource_, op, proto::result::kFailed, calErrorText(r.error));
    return;
  }
  cal.countsPerGram = r.countsPerGram;
  cal.calibrated = true;
  applyCalibration(cal);
  Serial.printf("[cal] %.2f counts/g\n", cal.countsPerGram);
  done(calSource_, op, proto::result::kOk,
       "calibrated. check it with one or two other known weights");
}

void App::cancelCalibration() {
  scale_.cancelCapture();
  calStep_ = CalStep::kIdle;
  Serial.println("[cal] cancelled");
}

void App::clearCalibration() {
  cancelCalibration();
  cal_store::clear();
  scale_.setCalibration(Calibration{});
  scale_.clearTare();
  zeroedThisBoot_ = false;
  refreshInfo();
  Serial.println("[cal] cleared, back to the rough default");
}

bool App::setFactor(float countsPerGram) {
  if (!(std::fabs(countsPerGram) >= kMinCountsPerGram)) {
    Serial.println("[cal] that factor is too small to be real");
    return false;
  }
  Calibration cal = scale_.calibration();
  cal.countsPerGram = countsPerGram;
  cal.calibrated = true;
  applyCalibration(cal);
  Serial.printf("[cal] factor set to %.2f counts/g\n", countsPerGram);
  return true;
}

void App::applyCalibration(const Calibration& cal) {
  scale_.setCalibration(cal);
  scale_.clearTare();
  if (!cal_store::save(cal)) Serial.println("[cal] couldn't write to nvs");
  refreshInfo();
}

void App::refreshInfo() {
  proto::formatInfo(info_, sizeof info_, FW_VERSION, kCapacityG,
                    scale_.calibration().calibrated);
  ble_link::setInfo(info_);
}

// ── serial output ──────────────────────────────────────────

void App::toggleWeightStream() {
  streamWeight_ = !streamWeight_;
  Serial.printf("weight stream %s\n", streamWeight_ ? "on" : "off");
}

void App::toggleRawStream() {
  streamRaw_ = !streamRaw_;
  Serial.printf("raw stream %s\n", streamRaw_ ? "on" : "off");
}

// ── noise check ────────────────────────────────────────────

void App::startNoiseCheck(uint32_t seconds) {
  noise_.reset();
  noiseStartMs_ = millis();
  noiseMs_ = seconds * 1000;
  noiseRunning_ = true;
  Serial.printf("[noise] measuring for %lu s, keep the platform still...\n",
                static_cast<unsigned long>(seconds));
}

void App::finishNoiseCheck() {
  noiseRunning_ = false;
  if (noise_.count() < 2) {
    Serial.println("[noise] not enough samples, is the hx711 answering? (s)");
    return;
  }
  Serial.printf("[noise] %lu samples over %lu s\n",
                static_cast<unsigned long>(noise_.count()),
                static_cast<unsigned long>(noiseMs_ / 1000));
  Serial.printf("[noise] mean %.3f g  min %.3f g  max %.3f g\n",
                noise_.meanMg() / 1000.0, grams(noise_.minMg()),
                grams(noise_.maxMg()));
  Serial.printf("[noise] swing %.3f g  sd %.3f g  drift %+.3f g\n",
                grams(noise_.swingMg()), noise_.stdDevMg() / 1000.0,
                noise_.driftMg() / 1000.0);
}

void App::printStatus(Print& out) {
  const uint32_t now = millis();
  const Calibration& cal = scale_.calibration();
  out.printf("raw %ld (median %ld)\n", static_cast<long>(scale_.lastRaw()),
             static_cast<long>(scale_.smoothedRaw()));
  out.printf("gross %.3f g  net %.3f g  tare %.3f g\n", grams(scale_.grossMg()),
             grams(scale_.netMg()), grams(scale_.tareMg()));
  out.printf("steady %s (spread %.3f g)  overload %s  sensor %s\n",
             scale_.stable() ? "yes" : "no", grams(scale_.spreadMg()),
             scale_.overload() ? "YES" : "no",
             scale_.sensorFault(now) ? "NOT ANSWERING" : "ok");
  out.printf("calibration %s, %.2f counts/g, zero %ld\n",
             cal.calibrated ? "saved" : "NOT DONE", cal.countsPerGram,
             static_cast<long>(cal.zeroRaw));
  out.printf("ble %u connected, frame %u, %s\n", ble_link::connections(),
             seq_, ble_link::address());
  out.printf("info \"%s\"\n", info_);
}

void App::printHelp(Print& out) const {
  out.println(
      "commands (then enter):\n"
      "  s          status\n"
      "  w          stream weight on/off\n"
      "  r          stream raw hx711 counts on/off\n"
      "  t          tare\n"
      "  z          calibrate step 1: zero, platform empty\n"
      "  k <grams>  calibrate step 2: known weight on, e.g. k 200\n"
      "  c          cancel a calibration step\n"
      "  f <n>      set counts per gram by hand\n"
      "  x          clear calibration\n"
      "  n [secs]   noise check, default 10 s, e.g. n 300 for drift\n"
      "  h          this help");
}
