#include "ble_link.h"

#include <Arduino.h>
#include <NimBLEDevice.h>

#include <string>

#include "config.h"

namespace ble_link {

namespace {

NimBLEServer* server = nullptr;
NimBLECharacteristic* weightChr = nullptr;
NimBLECharacteristic* infoChr = nullptr;
NimBLECharacteristic* controlChr = nullptr;
QueueHandle_t commands = nullptr;
std::string addressText;

class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* s, NimBLEConnInfo& info) override {
    Serial.printf("[ble] connected %s (%u now)\n",
                  info.getAddress().toString().c_str(),
                  s->getConnectedCount());
  }

  void onDisconnect(NimBLEServer* s, NimBLEConnInfo& info,
                    int reason) override {
    // advertiseOnDisconnect puts the scale back on air by itself
    Serial.printf("[ble] disconnected, reason %d (%u left)\n", reason,
                  s->getConnectedCount());
  }
};

class ControlCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* c, NimBLEConnInfo& info) override {
    const NimBLEAttValue value = c->getValue();
    const proto::ControlCommand cmd =
        proto::decodeControl(value.data(), value.length());
    // a full queue drops it, the app sees no reply and can try again
    if (commands != nullptr) xQueueSend(commands, &cmd, 0);
  }
};

// static, no heap: they live as long as the firmware does
ServerCallbacks serverCallbacks;
ControlCallbacks controlCallbacks;

}  // namespace

void begin(const char* infoText) {
  commands = xQueueCreate(4, sizeof(proto::ControlCommand));

  NimBLEDevice::init(kDeviceName);
  server = NimBLEDevice::createServer();
  server->setCallbacks(&serverCallbacks, false);
  server->advertiseOnDisconnect(true);

  NimBLEService* service = server->createService(kServiceUuid);
  weightChr = service->createCharacteristic(kWeightUuid, NIMBLE_PROPERTY::NOTIFY);
  infoChr = service->createCharacteristic(kInfoUuid, NIMBLE_PROPERTY::READ);
  controlChr = service->createCharacteristic(
      kControlUuid, NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY);
  controlChr->setCallbacks(&controlCallbacks);
  infoChr->setValue(infoText);
  // no service->start() in NimBLE 2, advertising starts the gatt server

  // the 128-bit service uuid and the name don't both fit in 31 bytes:
  // uuid in the advert so the app can filter its scan, name in the scan
  // response
  NimBLEAdvertisementData advert;
  advert.setFlags(BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP);
  advert.addServiceUUID(NimBLEUUID(kServiceUuid));
  NimBLEAdvertisementData scanResponse;
  scanResponse.setName(kDeviceName);

  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  adv->setAdvertisementData(advert);
  adv->setScanResponseData(scanResponse);
  adv->enableScanResponse(true);
  adv->start();

  addressText = NimBLEDevice::getAddress().toString();
}

void setInfo(const char* infoText) {
  if (infoChr != nullptr) infoChr->setValue(infoText);
}

uint8_t connections() {
  return server == nullptr ? 0 : server->getConnectedCount();
}

void notifyWeight(const uint8_t frame[proto::kWeightFrameLen]) {
  if (weightChr == nullptr || connections() == 0) return;
  weightChr->notify(frame, proto::kWeightFrameLen);
}

void sendReply(uint8_t op, uint8_t result) {
  if (controlChr == nullptr || connections() == 0) return;
  uint8_t reply[2];
  proto::encodeReply(reply, op, result);
  controlChr->notify(reply, sizeof reply);
}

bool takeCommand(proto::ControlCommand& out) {
  return commands != nullptr && xQueueReceive(commands, &out, 0) == pdTRUE;
}

const char* address() { return addressText.c_str(); }

}  // namespace ble_link
