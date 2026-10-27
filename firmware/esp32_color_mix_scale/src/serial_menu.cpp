#include "serial_menu.h"

#include <Arduino.h>

#include <cctype>
#include <cmath>
#include <cstdlib>

#include "app.h"

void SerialMenu::poll(App& app) {
  while (Serial.available() > 0) {
    const char c = static_cast<char>(Serial.read());
    if (c == '\r' || c == '\n') {
      if (len_ > 0) {
        buf_[len_] = '\0';
        run(app, buf_);
        len_ = 0;
      }
      continue;
    }
    // overlong lines get cut, they're not commands anyway
    if (len_ < sizeof buf_ - 1) buf_[len_++] = c;
  }
}

void SerialMenu::run(App& app, char* line) {
  while (*line == ' ') line++;
  const char cmd = static_cast<char>(std::tolower(line[0]));
  const char* arg = line + 1;
  while (*arg == ' ') arg++;

  switch (cmd) {
    case 'h':
    case '?':
      app.printHelp(Serial);
      break;
    case 's':
      app.printStatus(Serial);
      break;
    case 'w':
      app.toggleWeightStream();
      break;
    case 'r':
      app.toggleRawStream();
      break;
    case 't':
      app.tare(Source::kSerial);
      break;
    case 'z':
      app.startCalZero(Source::kSerial);
      break;
    case 'k': {
      char* end = nullptr;
      const double g = std::strtod(arg, &end);
      if (end == arg || g <= 0) {
        Serial.println("usage: k <grams>, e.g. k 200");
        break;
      }
      app.startCalKnownMass(static_cast<int32_t>(std::lround(g * 1000.0)),
                            Source::kSerial);
      break;
    }
    case 'c':
      app.cancelCalibration();
      break;
    case 'f': {
      char* end = nullptr;
      const double f = std::strtod(arg, &end);
      if (end == arg) {
        Serial.println("usage: f <counts per gram>, e.g. f 1402.5");
        break;
      }
      app.setFactor(static_cast<float>(f));
      break;
    }
    case 'x':
      app.clearCalibration();
      break;
    case 'n': {
      char* end = nullptr;
      const long secs = std::strtol(arg, &end, 10);
      if (end == arg) {
        app.startNoiseCheck(10);
      } else if (secs < 1 || secs > 3600) {
        Serial.println("usage: n [seconds], 1 to 3600, e.g. n 30");
      } else {
        app.startNoiseCheck(static_cast<uint32_t>(secs));
      }
      break;
    }
    default:
      Serial.printf("unknown '%s', h for help\n", line);
  }
}
