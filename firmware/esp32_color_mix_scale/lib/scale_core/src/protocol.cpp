#include "protocol.h"

#include <cstdio>

namespace proto {

void encodeWeightFrame(uint8_t out[kWeightFrameLen], int32_t milligrams,
                       uint16_t sequence, uint8_t flags) {
  const uint32_t mg = static_cast<uint32_t>(milligrams);
  out[0] = kVersion;
  out[1] = flags;
  out[2] = static_cast<uint8_t>(sequence & 0xFF);
  out[3] = static_cast<uint8_t>(sequence >> 8);
  out[4] = static_cast<uint8_t>(mg & 0xFF);
  out[5] = static_cast<uint8_t>((mg >> 8) & 0xFF);
  out[6] = static_cast<uint8_t>((mg >> 16) & 0xFF);
  out[7] = static_cast<uint8_t>((mg >> 24) & 0xFF);
}

ControlCommand decodeControl(const uint8_t* data, size_t len) {
  ControlCommand cmd;
  if (data == nullptr || len == 0) return cmd;
  cmd.op = data[0];

  switch (cmd.op) {
    case op::kTare:
    case op::kGetStatus:
    case op::kCalZero:
      cmd.known = true;
      cmd.valid = len == 1;
      break;
    case op::kCalKnownMass:
      cmd.known = true;
      cmd.valid = len == 5;
      if (cmd.valid) {
        const uint32_t v = static_cast<uint32_t>(data[1]) |
                           (static_cast<uint32_t>(data[2]) << 8) |
                           (static_cast<uint32_t>(data[3]) << 16) |
                           (static_cast<uint32_t>(data[4]) << 24);
        cmd.payload = static_cast<int32_t>(v);
      }
      break;
    default:
      cmd.known = false;
      cmd.valid = false;
  }
  return cmd;
}

void encodeReply(uint8_t out[2], uint8_t opcode, uint8_t res) {
  out[0] = opcode | op::kReplyBit;
  out[1] = res;
}

int formatInfo(char* out, size_t size, const char* fw, uint32_t capacityG,
               bool calibrated) {
  return std::snprintf(out, size, "fw=%s;proto=%u;cap_g=%lu;cal=%d", fw,
                       static_cast<unsigned>(kVersion),
                       static_cast<unsigned long>(capacityG),
                       calibrated ? 1 : 0);
}

}  // namespace proto
