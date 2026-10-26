// pc-side tests for the parts with no hardware in them.
// the frame vectors are the same ones as docs/protocol.md and the app's
// test/esp32_protocol_test.dart

#include <unity.h>

#include <cstring>
#include <initializer_list>

#include "calibration.h"
#include "filter.h"
#include "protocol.h"

void setUp() {}
void tearDown() {}

static void expectFrame(int32_t mg, uint16_t seq, uint8_t flags,
                        const uint8_t (&want)[8]) {
  uint8_t got[8];
  proto::encodeWeightFrame(got, mg, seq, flags);
  TEST_ASSERT_EQUAL_HEX8_ARRAY(want, got, 8);
}

void test_weight_frame_vectors() {
  using namespace proto::flag;
  expectFrame(30000, 42, kStable, {0x01, 0x01, 0x2A, 0x00, 0x30, 0x75, 0x00, 0x00});
  expectFrame(-12, 65535, 0, {0x01, 0x00, 0xFF, 0xFF, 0xF4, 0xFF, 0xFF, 0xFF});
  expectFrame(1000000, 256, kOverload, {0x01, 0x02, 0x00, 0x01, 0x40, 0x42, 0x0F, 0x00});
  expectFrame(0, 5, kUncalibrated, {0x01, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00});
  expectFrame(1000, 7, kStable | kSensorFault, {0x01, 0x09, 0x07, 0x00, 0xE8, 0x03, 0x00, 0x00});
}

void test_control_decode() {
  const uint8_t tare[] = {0x01};
  auto c = proto::decodeControl(tare, 1);
  TEST_ASSERT_TRUE(c.valid);
  TEST_ASSERT_EQUAL_HEX8(proto::op::kTare, c.op);

  // 100 g, same bytes the app's encodeControl test expects
  const uint8_t known[] = {0x11, 0xA0, 0x86, 0x01, 0x00};
  c = proto::decodeControl(known, 5);
  TEST_ASSERT_TRUE(c.valid);
  TEST_ASSERT_EQUAL_INT32(100000, c.payload);

  // wrong lengths and unknown opcodes
  TEST_ASSERT_FALSE(proto::decodeControl(known, 3).valid);
  const uint8_t tareWithJunk[] = {0x01, 0x00};
  TEST_ASSERT_FALSE(proto::decodeControl(tareWithJunk, 2).valid);
  const uint8_t unknown[] = {0x42};
  c = proto::decodeControl(unknown, 1);
  TEST_ASSERT_FALSE(c.known);
  TEST_ASSERT_FALSE(proto::decodeControl(nullptr, 0).valid);
}

void test_reply_and_info() {
  uint8_t reply[2];
  proto::encodeReply(reply, proto::op::kCalZero, proto::result::kBusy);
  TEST_ASSERT_EQUAL_HEX8(0x90, reply[0]);
  TEST_ASSERT_EQUAL_HEX8(0x01, reply[1]);

  char info[64];
  proto::formatInfo(info, sizeof info, "0.1.0", 1000, true);
  TEST_ASSERT_EQUAL_STRING("fw=0.1.0;proto=1;cap_g=1000;cal=1", info);
}

void test_median_ignores_one_spike() {
  Median5 m;
  for (int32_t v : {1000, 1002, 9999, 998, 1001}) m.push(v);
  TEST_ASSERT_EQUAL_INT32(1001, m.value());
  m.reset();
  TEST_ASSERT_TRUE(m.empty());
  m.push(5);
  TEST_ASSERT_EQUAL_INT32(5, m.value());
}

void test_stability_window() {
  StabilityWindow w(150, 8);
  for (int i = 0; i < 7; i++) w.push(30000 + (i % 2) * 50);
  TEST_ASSERT_FALSE(w.stable());  // not full yet
  w.push(30020);
  TEST_ASSERT_TRUE(w.stable());
  w.push(31000);  // someone pours
  TEST_ASSERT_FALSE(w.stable());
  TEST_ASSERT_EQUAL_INT32(1000, w.spread());
}

void test_raw_to_milligrams() {
  Calibration cal;
  cal.zeroRaw = 8000;
  cal.countsPerGram = 1400.0f;
  cal.calibrated = true;
  TEST_ASSERT_EQUAL_INT32(0, rawToMilligrams(8000, cal));
  TEST_ASSERT_EQUAL_INT32(30000, rawToMilligrams(8000 + 1400 * 30, cal));
  // signed, below zero
  TEST_ASSERT_EQUAL_INT32(-1000, rawToMilligrams(8000 - 1400, cal));
  // rounds to the nearest mg
  TEST_ASSERT_EQUAL_INT32(1, rawToMilligrams(8000 + 1, cal));

  // reversed wiring, negative factor still reads positive grams
  cal.countsPerGram = -1400.0f;
  TEST_ASSERT_EQUAL_INT32(30000, rawToMilligrams(8000 - 1400 * 30, cal));
}

void test_factor_from_known_mass() {
  auto r = factorFromKnownMass(8000 + 280000, 8000, 200000);
  TEST_ASSERT_TRUE(r.error == CalError::kNone);
  TEST_ASSERT_FLOAT_WITHIN(0.01f, 1400.0f, r.countsPerGram);

  TEST_ASSERT_TRUE(factorFromKnownMass(9000, 8000, 5000).error == CalError::kTooLight);
  // nothing actually on the platform
  TEST_ASSERT_TRUE(factorFromKnownMass(8100, 8000, 100000).error == CalError::kBadFactor);
}

void test_rails() {
  TEST_ASSERT_TRUE(isRawAtRail(0x7FFFFF));
  TEST_ASSERT_TRUE(isRawAtRail(-0x800000));
  TEST_ASSERT_FALSE(isRawAtRail(123456));
}

int main() {
  UNITY_BEGIN();
  RUN_TEST(test_weight_frame_vectors);
  RUN_TEST(test_control_decode);
  RUN_TEST(test_reply_and_info);
  RUN_TEST(test_median_ignores_one_spike);
  RUN_TEST(test_stability_window);
  RUN_TEST(test_raw_to_milligrams);
  RUN_TEST(test_factor_from_known_mass);
  RUN_TEST(test_rails);
  return UNITY_END();
}
