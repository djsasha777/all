#include "HomeSpan.h"
#include <WiFi.h>
#include <HardwareSerial.h>

// ================= UART к MCU обогревателя =================
#define TUYA_RX_PIN 35   // ESP32 RX <- TX обогревателя
#define TUYA_TX_PIN 37   // ESP32 TX -> RX обогревателя
#define TUYA_BAUD 9600

HardwareSerial heaterSerial(1);

// ================= Подтверждённые DPID =================
#define DP_POWER            1    // bool: питание
#define DP_TARGET_TEMP      2    // value: целевая температура
#define DP_CURRENT_TEMP     3    // value: текущая температура
#define DP_MODE             4    // enum: 0, 1, 2
#define DP_UNKNOWN_BOOL_5   5    // bool: функция пока неизвестна
#define DP_UNKNOWN_RAW_12   12   // raw: функция пока неизвестна
#define DP_UNKNOWN_BOOL_101 101  // bool: служебный статус
#define DP_UNKNOWN_BOOL_102 102  // bool: служебный статус

// ================= HomeKit =================
SpanCharacteristic *currentTempChar;
SpanCharacteristic *targetTempChar;
SpanCharacteristic *stateChar;

// Forward declarations
void tuyaSendFrame(uint8_t cmd, const uint8_t *payload, size_t payloadLen);
void tuyaSendBool(uint8_t dpid, bool value);
void tuyaSendValue(uint8_t dpid, int32_t value);
void tuyaSendEnum(uint8_t dpid, uint8_t value);

// ================= HomeKit Service =================
struct Heater : Service::Thermostat {
  Heater() : Service::Thermostat() {

    currentTempChar = new Characteristic::CurrentTemperature(20);

    targetTempChar = new Characteristic::TargetTemperature(22);
    targetTempChar->setRange(5, 28, 1);

    // 0 = Off, 1 = Heat, 2 = Cool, 3 = Auto
    stateChar = new Characteristic::TargetHeatingCoolingState(0);

    new Characteristic::TemperatureDisplayUnits(0); // Celsius
    new Characteristic::CurrentHeatingCoolingState(0);
  }

  boolean update() {
    int homeKitState = stateChar->getNewVal();
    float targetTemp = targetTempChar->getNewVal();

    Serial.printf("HomeKit: state=%d, target=%.1f\n",
                  homeKitState,
                  targetTemp);

    switch (homeKitState) {
      case 0: // Off
        tuyaSendBool(DP_POWER, false);
        break;

      case 1: // Heat -> режим 2
        tuyaSendBool(DP_POWER, true);
        tuyaSendEnum(DP_MODE, 2);
        tuyaSendValue(DP_TARGET_TEMP, (int)targetTemp);
        break;

      case 2: // Cool -> режим 1
        tuyaSendBool(DP_POWER, true);
        tuyaSendEnum(DP_MODE, 1);
        tuyaSendValue(DP_TARGET_TEMP, (int)targetTemp);
        break;

      case 3: // Auto -> включён, режим 0, управление только температурой
        tuyaSendBool(DP_POWER, true);
        tuyaSendEnum(DP_MODE, 0);
        tuyaSendValue(DP_TARGET_TEMP, (int)targetTemp);
        break;
    }

    return true;
  }
};

Heater *heater;

// ================= Tuya MCU protocol =================
uint8_t rxBuffer[256];
size_t rxLen = 0;

uint8_t tuyaChecksum(const uint8_t *data, size_t len) {
  uint8_t sum = 0;

  for (size_t i = 0; i < len; i++) {
    sum += data[i];
  }

  return sum;
}

void tuyaSendFrame(uint8_t cmd, const uint8_t *payload, size_t payloadLen) {
  if (payloadLen > 200) {
    return;
  }

  uint8_t frame[256];
  size_t i = 0;

  frame[i++] = 0x55;
  frame[i++] = 0xAA;
  frame[i++] = 0x00; // version
  frame[i++] = cmd;

  frame[i++] = (payloadLen >> 8) & 0xFF;
  frame[i++] = payloadLen & 0xFF;

  for (size_t n = 0; n < payloadLen; n++) {
    frame[i++] = payload[n];
  }

  frame[i++] = tuyaChecksum(frame, i);

  heaterSerial.write(frame, i);
  heaterSerial.flush();

  Serial.print("TUYA TX [0x");
  Serial.print(cmd, HEX);
  Serial.print("]: ");

  for (size_t n = 0; n < i; n++) {
    Serial.printf("%02X ", frame[n]);
  }

  Serial.println();
}

// ESP32 работает как Wi-Fi-модуль:
// 0x06 = передать DP-команду MCU обогревателя
void tuyaSendBool(uint8_t dpid, bool value) {
  uint8_t payload[] = {
    dpid,
    0x01,       // bool
    0x00, 0x01,
    value ? 0x01 : 0x00
  };

  tuyaSendFrame(0x06, payload, sizeof(payload));
}

void tuyaSendValue(uint8_t dpid, int32_t value) {
  uint8_t payload[] = {
    dpid,
    0x02,       // value
    0x00, 0x04,
    (uint8_t)((value >> 24) & 0xFF),
    (uint8_t)((value >> 16) & 0xFF),
    (uint8_t)((value >> 8) & 0xFF),
    (uint8_t)(value & 0xFF)
  };

  tuyaSendFrame(0x06, payload, sizeof(payload));
}

void tuyaSendEnum(uint8_t dpid, uint8_t value) {
  uint8_t payload[] = {
    dpid,
    0x04,       // enum
    0x00, 0x01,
    value
  };

  tuyaSendFrame(0x06, payload, sizeof(payload));
}

void handleTuyaFrame() {
  if (rxLen < 6) {
    return;
  }

  if (rxBuffer[0] != 0x55 || rxBuffer[1] != 0xAA) {
    Serial.println("TUYA RX: bad header");
    rxLen = 0;
    return;
  }

  uint8_t cmd = rxBuffer[3];

  uint16_t dataLen =
    ((uint16_t)rxBuffer[4] << 8) |
    rxBuffer[5];

  if (rxLen < 7 + dataLen) {
    return;
  }

  uint8_t expectedChecksum = rxBuffer[6 + dataLen];
  uint8_t actualChecksum = tuyaChecksum(rxBuffer, 6 + dataLen);

  Serial.print("TUYA RX [0x");
  Serial.print(cmd, HEX);
  Serial.print("], len=");
  Serial.print(dataLen);
  Serial.print(": ");

  for (size_t i = 0; i < rxLen; i++) {
    Serial.printf("%02X ", rxBuffer[i]);
  }

  Serial.println();

  if (expectedChecksum != actualChecksum) {
    Serial.println("TUYA RX: checksum error");
    rxLen = 0;
    return;
  }

  uint8_t *data = rxBuffer + 6;

  switch (cmd) {
    case 0x00: // heartbeat от MCU
      tuyaSendFrame(0x00, nullptr, 0);
      break;

    case 0x01: // запрос product info
      {
        const char *productInfo =
          "{\"p\":\"YOUR_PRODUCT_ID\",\"v\":\"1.0.0\"}";

        tuyaSendFrame(
          0x01,
          (const uint8_t *)productInfo,
          strlen(productInfo)
        );
      }
      break;

    case 0x02: // запрос конфигурации модуля
      tuyaSendFrame(0x02, nullptr, 0);
      break;

    case 0x08: // MCU запросил текущее состояние
      tuyaSendValue(DP_TARGET_TEMP, (int)targetTempChar->getVal());
      break;

    // MCU сообщает статус DP
    case 0x07:
      {
        size_t pos = 0;

        while (pos + 4 <= dataLen) {
          uint8_t dpid = data[pos];
          uint8_t type = data[pos + 1];

          uint16_t len =
            ((uint16_t)data[pos + 2] << 8) |
            data[pos + 3];

          if (pos + 4 + len > dataLen) {
            break;
          }

          uint8_t *value = data + pos + 4;

          Serial.printf("TUYA status: dpid=%u type=0x%02X len=%u value=",
                        dpid,
                        type,
                        len);

          for (uint16_t i = 0; i < len; i++) {
            Serial.printf("%02X ", value[i]);
          }

          Serial.println();

          switch (dpid) {
            case DP_POWER:
              if (type == 0x01 && len == 1) {
                bool power = value[0] != 0;

                // Если выключили с кнопки — HomeKit тоже Off
                if (!power) {
                  stateChar->setVal(0);
                }

                Serial.printf("Heater power: %s\n",
                              power ? "ON" : "OFF");
              }
              break;

            case DP_TARGET_TEMP:
              if (type == 0x02 && len == 4) {
                int32_t raw =
                  ((int32_t)value[0] << 24) |
                  ((int32_t)value[1] << 16) |
                  ((int32_t)value[2] << 8) |
                  (int32_t)value[3];

                targetTempChar->setVal(raw);

                Serial.printf("Heater target temp: %d C\n", raw);
              }
              break;

            case DP_CURRENT_TEMP:
              if (type == 0x02 && len == 4) {
                int32_t raw =
                  ((int32_t)value[0] << 24) |
                  ((int32_t)value[1] << 16) |
                  ((int32_t)value[2] << 8) |
                  (int32_t)value[3];

                currentTempChar->setVal(raw);

                Serial.printf("Heater current temp: %d C\n", raw);
              }
              break;

            case DP_MODE:
              if (type == 0x04 && len == 1) {
                uint8_t mode = value[0];

                int homeKitState;

                if (mode == 0) {
                  homeKitState = 3; // Auto
                } else if (mode == 1) {
                  homeKitState = 2; // Cool
                } else {
                  homeKitState = 1; // Heat
                }

                stateChar->setVal(homeKitState);

                Serial.printf("Heater mode: %u -> HomeKit state %d\n",
                              mode,
                              homeKitState);
              }
              break;

            case DP_UNKNOWN_BOOL_5:
              if (type == 0x01 && len == 1) {
                Serial.printf("Heater DP5 bool: %s\n",
                              value[0] ? "ON" : "OFF");
              }
              break;

            case DP_UNKNOWN_RAW_12:
              Serial.printf("Heater DP12 raw: 0x%02X\n",
                            len > 0 ? value[0] : 0);
              break;

            case DP_UNKNOWN_BOOL_101:
              if (type == 0x01 && len == 1) {
                Serial.printf("Heater DP101 bool: %s\n",
                              value[0] ? "ON" : "OFF");
              }
              break;

            case DP_UNKNOWN_BOOL_102:
              if (type == 0x01 && len == 1) {
                Serial.printf("Heater DP102 bool: %s\n",
                              value[0] ? "ON" : "OFF");
              }
              break;

            default:
              Serial.printf("Unhandled status DPID: %u\n", dpid);
              break;
          }

          pos += 4 + len;
        }
      }
      break;

    default:
      Serial.printf("TUYA RX: unhandled command 0x%02X\n", cmd);
      break;
  }

  rxLen = 0;
}

void pollTuyaUart() {
  while (heaterSerial.available()) {
    if (rxLen >= sizeof(rxBuffer)) {
      rxLen = 0;
      Serial.println("TUYA RX: buffer overflow");
      continue;
    }

    rxBuffer[rxLen++] = heaterSerial.read();

    if (rxLen >= 6) {
      uint16_t dataLen =
        ((uint16_t)rxBuffer[4] << 8) |
        rxBuffer[5];

      size_t fullLen = 6 + dataLen + 1;

      if (
        rxBuffer[0] == 0x55 &&
        rxBuffer[1] == 0xAA &&
        rxLen == fullLen
      ) {
        handleTuyaFrame();
      }
    }
  }
}

// ================= Arduino =================
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("ESP32-S2 -> Tuya heater UART bridge");

  heaterSerial.begin(
    TUYA_BAUD,
    SERIAL_8N1,
    TUYA_RX_PIN,
    TUYA_TX_PIN
  );

  WiFi.setTxPower(WIFI_POWER_8_5dBm);

  homeSpan.begin(Category::Thermostats, "Tuya Heater");

  new SpanAccessory();

  new Service::AccessoryInformation();
  new Characteristic::Name("Tuya Heater");
  new Characteristic::Identify();

  heater = new Heater();

  // При включении ничего не отправляем.
}

void loop() {
  homeSpan.poll();
  pollTuyaUart();
}