#pragma once

// the ble protocol, byte for byte the same as docs/protocol.md and
// lib/core/bluetooth/esp32_protocol.dart in the app. no arduino in here so
// the native tests can run it.

#include <cstddef>
#include <cstdint>

namespace proto {

constexpr uint8_t kVersion = 1;
constexpr size_t kWeightFrameLen = 8;

namespace flag {
constexpr uint8_t kStable = 0x01;
constexpr uint8_t kOverload = 0x02;
constexpr uint8_t kUncalibrated = 0x04;
constexpr uint8_t kSensorFault = 0x08;
}  // namespace flag

namespace op {
constexpr uint8_t kTare = 0x01;
constexpr uint8_t kGetStatus = 0x02;
constexpr uint8_t kCalZero = 0x10;
constexpr uint8_t kCalKnownMass = 0x11;
constexpr uint8_t kReplyBit = 0x80;
}  // namespace op

namespace result {
constexpr uint8_t kOk = 0;
constexpr uint8_t kBusy = 1;
constexpr uint8_t kFailed = 2;
constexpr uint8_t kUnknownOp = 3;
}  // namespace result

// [0] version, [1] flags, [2-3] uint16 sequence, [4-7] int32 mg, little endian
void encodeWeightFrame(uint8_t out[kWeightFrameLen], int32_t milligrams,
                       uint16_t sequence, uint8_t flags);

struct ControlCommand {
  uint8_t op = 0;
  int32_t payload = 0;
  // false when the length doesn't fit the opcode
  bool valid = false;
  bool known = false;
};

// one opcode byte, plus an int32 for CAL_KNOWN_MASS
ControlCommand decodeControl(const uint8_t* data, size_t len);

// reply notified on the control characteristic: [op | 0x80, result]
void encodeReply(uint8_t out[2], uint8_t op, uint8_t result);

// 'fw=0.1.0;proto=1;cap_g=1000;cal=1', returns what snprintf returns
int formatInfo(char* out, size_t size, const char* fw, uint32_t capacityG,
               bool calibrated);

}  // namespace proto
