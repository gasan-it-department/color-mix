#pragma once

#include <cstddef>
#include <cstdint>

#include "protocol.h"

// the gatt service from docs/protocol.md on NimBLE. control writes arrive
// on the ble task and are queued, the main loop runs them so nothing slow
// happens inside a ble callback
namespace ble_link {

void begin(const char* infoText);

void setInfo(const char* infoText);

uint8_t connections();

// no-op when nobody is connected
void notifyWeight(const uint8_t frame[proto::kWeightFrameLen]);
void sendReply(uint8_t op, uint8_t result);

// next control command from the app, false when there's none
bool takeCommand(proto::ControlCommand& out);

const char* address();

}  // namespace ble_link
