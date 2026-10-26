#pragma once

#include <cstdint>

class App;

// one-letter commands over usb serial at 115200, see App::printHelp
class SerialMenu {
 public:
  // reads whatever has arrived, runs complete lines
  void poll(App& app);

 private:
  void run(App& app, char* line);

  char buf_[48] = {};
  uint8_t len_ = 0;
};
