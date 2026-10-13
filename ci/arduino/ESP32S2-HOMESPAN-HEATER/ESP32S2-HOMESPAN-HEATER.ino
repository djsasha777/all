#include "HomeSpan.h"
#include <WiFi.h>
#include <HardwareSerial.h>

// ================= UART =================
#define TUYA_RX_PIN 35
#define TUYA_TX_PIN 37
#define TUYA_BAUD 9600

HardwareSerial heaterSerial(1);

// ================= Tuya DP =================
#define DP_POWER 1
#define DP_TARGET_TEMP 2
#define DP_CURRENT_TEMP 3
#define DP_MODE 4
#define DP_UNKNOWN_BOOL_5 5
#define DP_UNKNOWN_RAW_12 12
#define DP_UNKNOWN_BOOL_101 101
#define DP_UNKNOWN_BOOL_102 102

// ================= Tuya modes =================
#define MODE_IDLE 2        // холостой ход, без нагрева
#define MODE_HALF_HEAT 1   // половинный нагрев
#define MODE_FULL_HEAT 0   // полный нагрев

// ================= HomeKit states =================
#define HK_OFF 0
#define HK_HEAT 1
#define HK_COOL 2
#define HK_AUTO 3

// ================= HomeKit =================
SpanCharacteristic *currentTempChar;
SpanCharacteristic *targetTempChar;
SpanCharacteristic *stateChar;
SpanCharacteristic *currentHeaterStateChar;

// ================= State =================
int lastHomeKitState = HK_OFF;
int lastSentTemp = -999;

unsigned long lastResendTime = 0;
const unsigned long RESEND_INTERVAL = 10000;

// ================= Tuya RX =================
uint8_t rxBuffer[256];
size_t rxLen = 0;

// ============================================================
// Tuya protocol
// ============================================================
uint8_t tuyaChecksum(uint8_t *data, size_t len) {
  uint8_t sum = 0;

  for (size_t i = 0; i < len; i++) {
    sum += data[i];
  }

  return sum;
}

void tuyaSendFrame(uint8_t cmd, uint8_t *payload, size_t payloadLen) {
  uint8_t frame[256];
  size_t i = 0;

  frame[i++] = 0x55;
  frame[i++] = 0xAA;
  frame[i++] = 0x00;
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

void tuyaSendBool(uint8_t dpid, bool value) {
  uint8_t payload[5];

  payload[0] = dpid;
  payload[1] = 0x01;
  payload[2] = 0x00;
  payload[3] = 0x01;
  payload[4] = value ? 0x01 : 0x00;

  tuyaSendFrame(0x06, payload, 5);
}

void tuyaSendValue(uint8_t dpid, int32_t value) {
  uint8_t payload[8];

  payload[0] = dpid;
  payload[1] = 0x02;
  payload[2] = 0x00;
  payload[3] = 0x04;
  payload[4] = (value >> 24) & 0xFF;
  payload[5] = (value >> 16) & 0xFF;
  payload[6] = (value >> 8) & 0xFF;
  payload[7] = value & 0xFF;

  tuyaSendFrame(0x06, payload, 8);
}

void tuyaSendEnum(uint8_t dpid, uint8_t value) {
  uint8_t payload[5];

  payload[0] = dpid;
  payload[1] = 0x04;
  payload[2] = 0x00;
  payload[3] = 0x01;
  payload[4] = value;

  tuyaSendFrame(0x06, payload, 5);
}

// ============================================================
// Heater commands
// ============================================================
void heaterPower(bool on) {
  tuyaSendBool(DP_POWER, on);
}

void heaterMode(uint8_t mode) {
  tuyaSendEnum(DP_MODE, mode);
}

void heaterTargetTemp(int temp) {
  tuyaSendValue(DP_TARGET_TEMP, temp);
}

// ============================================================
// Resend current HomeKit state every 10 seconds
// ============================================================
void resendCurrentState() {
  int state = stateChar->getVal();

  Serial.printf("Resend state: %d\n", state);

  if (state == HK_AUTO) {
    heaterPower(true);
    delay(30);
    heaterMode(MODE_IDLE);
  }

  if (state == HK_COOL) {
    heaterPower(true);
    delay(30);
    heaterMode(MODE_HALF_HEAT);
  }

  if (state == HK_HEAT) {
    heaterPower(true);
    delay(30);
    heaterMode(MODE_FULL_HEAT);
  }

  // HK_OFF не повторяем,
  // чтобы не выключать обогреватель, включённый кнопкой на корпусе.
}

// ============================================================
// Tuya frame handler
// ============================================================
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

  uint16_t dataLen = (rxBuffer[4] << 8) | rxBuffer[5];

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

  if (cmd == 0x00) {
    tuyaSendFrame(0x00, nullptr, 0);
  }

  if (cmd == 0x01) {
    const char *productInfo = "{\"p\":\"YOUR_PRODUCT_ID\",\"v\":\"1.0.0\"}";
    tuyaSendFrame(0x01, (uint8_t *)productInfo, strlen(productInfo));
  }

  if (cmd == 0x02) {
    tuyaSendFrame(0x02, nullptr, 0);
  }

  if (cmd == 0x08) {
    resendCurrentState();
  }

  if (cmd == 0x07) {
    size_t pos = 0;

    while (pos + 4 <= dataLen) {

      uint8_t dpid = data[pos];
      uint8_t type = data[pos + 1];

      uint16_t len = (data[pos + 2] << 8) | data[pos + 3];

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

      // ---------------- POWER ----------------
      if (dpid == DP_POWER && type == 0x01 && len == 1) {

        bool power = value[0] != 0;

        Serial.printf("Heater power: %s\n", power ? "ON" : "OFF");

        if (!power) {
          stateChar->setVal(HK_OFF);
          lastHomeKitState = HK_OFF;
        }
      }

      // ---------------- TARGET TEMP ----------------
      if (dpid == DP_TARGET_TEMP && type == 0x02 && len == 4) {

        int32_t raw =
          (value[0] << 24) |
          (value[1] << 16) |
          (value[2] << 8) |
          value[3];

        targetTempChar->setVal(raw);
        lastSentTemp = raw;

        Serial.printf("Heater target temp: %d C\n", raw);
      }

      // ---------------- CURRENT TEMP ----------------
      if (dpid == DP_CURRENT_TEMP && type == 0x02 && len == 4) {

        int32_t raw =
          (value[0] << 24) |
          (value[1] << 16) |
          (value[2] << 8) |
          value[3];

        currentTempChar->setVal(raw);

        Serial.printf("Heater current temp: %d C\n", raw);
      }

      // ---------------- MODE ----------------
      if (dpid == DP_MODE && type == 0x04 && len == 1) {

        uint8_t mode = value[0];

        int hkState = HK_AUTO;

        if (mode == MODE_HALF_HEAT) {
          hkState = HK_COOL;
        }

        if (mode == MODE_FULL_HEAT) {
          hkState = HK_HEAT;
        }

        if (mode == MODE_IDLE) {
          hkState = HK_AUTO;
        }

        if (stateChar->getVal() != hkState) {
          stateChar->setVal(hkState);
          lastHomeKitState = hkState;
        }

        Serial.printf("Heater mode: %u -> HomeKit state %d\n",
                      mode,
                      hkState);
      }

      // ---------------- HEATING STATUS ----------------
      if (dpid == DP_UNKNOWN_RAW_12 && len > 0) {

        uint8_t workState = value[0];

        Serial.printf("Heater DP12 raw: 0x%02X\n", workState);

        if (workState == 0x00) {
          currentHeaterStateChar->setVal(0);
        } else {
          currentHeaterStateChar->setVal(1);
        }
      }

      // ---------------- UNKNOWN ----------------
      if (dpid == DP_UNKNOWN_BOOL_5 && type == 0x01 && len == 1) {
        Serial.printf("Heater DP5 bool: %s\n",
                      value[0] ? "ON" : "OFF");
      }

      if (dpid == DP_UNKNOWN_BOOL_101 && type == 0x01 && len == 1) {
        Serial.printf("Heater DP101 bool: %s\n",
                      value[0] ? "ON" : "OFF");
      }

      if (dpid == DP_UNKNOWN_BOOL_102 && type == 0x01 && len == 1) {
        Serial.printf("Heater DP102 bool: %s\n",
                      value[0] ? "ON" : "OFF");
      }

      pos += 4 + len;
    }
  }

  rxLen = 0;
}

// ============================================================
// UART poll
// ============================================================
void pollTuyaUart() {
  while (heaterSerial.available()) {

    if (rxLen >= sizeof(rxBuffer)) {
      rxLen = 0;
      Serial.println("TUYA RX: buffer overflow");
      continue;
    }

    rxBuffer[rxLen++] = heaterSerial.read();

    if (rxLen >= 6) {

      uint16_t dataLen = (rxBuffer[4] << 8) | rxBuffer[5];
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

// ============================================================
// HomeKit thermostat
// ============================================================
struct HeaterService : Service::Thermostat {

  HeaterService() : Service::Thermostat() {

    currentTempChar = new Characteristic::CurrentTemperature(20);
    currentTempChar->setRange(-40, 100, 1);

    targetTempChar = new Characteristic::TargetTemperature(22);
    targetTempChar->setRange(5, 35, 1);

    stateChar = new Characteristic::TargetHeatingCoolingState(0);

    currentHeaterStateChar = new Characteristic::CurrentHeatingCoolingState(0);

    new Characteristic::TemperatureDisplayUnits(0);
  }

  boolean update() {

    int state = stateChar->getNewVal();
    int temp = (int)targetTempChar->getNewVal();

    Serial.printf("HomeKit update: state=%d, target=%d\n",
                  state,
                  temp);

    // ---------------- OFF ----------------
    if (state == HK_OFF) {
      heaterPower(false);

      lastSentTemp = temp;
      lastHomeKitState = HK_OFF;

      return true;
    }

    // ---------------- AUTO: холостой ход ----------------
    if (state == HK_AUTO) {

      heaterPower(true);
      delay(30);
      heaterMode(MODE_IDLE);

      // Температуру в Auto не отправляем:
      // это режим без нагрева и без регулировки.

      lastSentTemp = temp;
      lastHomeKitState = HK_AUTO;

      return true;
    }

    // ---------------- COOL: половинный нагрев ----------------
    if (state == HK_COOL) {

      heaterPower(true);
      delay(30);

      if (temp != lastSentTemp) {
        heaterTargetTemp(temp);
        delay(30);
      }

      heaterMode(MODE_HALF_HEAT);

      lastSentTemp = temp;
      lastHomeKitState = HK_COOL;

      return true;
    }

    // ---------------- HEAT: полный нагрев ----------------
    if (state == HK_HEAT) {

      heaterPower(true);
      delay(30);

      if (temp != lastSentTemp) {
        heaterTargetTemp(temp);
        delay(30);
      }

      heaterMode(MODE_FULL_HEAT);

      lastSentTemp = temp;
      lastHomeKitState = HK_HEAT;

      return true;
    }

    return true;
  }
};

HeaterService *heater;

// ============================================================
// Arduino setup / loop
// ============================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("ESP32-S2 -> Tuya Heater HomeKit bridge");

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

  heater = new HeaterService();
}

void loop() {
  homeSpan.poll();
  pollTuyaUart();

  unsigned long now = millis();

  if (now - lastResendTime >= RESEND_INTERVAL) {
    lastResendTime = now;
    resendCurrentState();
  }
}