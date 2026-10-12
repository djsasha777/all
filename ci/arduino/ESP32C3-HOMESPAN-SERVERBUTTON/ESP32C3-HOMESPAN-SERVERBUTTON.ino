#include "HomeSpan.h"
#include <WiFi.h>

// Состояния (независимые)
bool toggleState = false;
bool holdonState = false;

// Таймеры
unsigned long lastToggleTime = 0;
const unsigned long TOGGLE_TIMEOUT = 500;

unsigned long lastHoldOnTime = 0;
const unsigned long HOLDON_TIMEOUT = 5000;

const uint8_t RELAY_PIN = 1;

struct DEV_ToggleLED : Service::LightBulb {
  SpanCharacteristic *power;
  bool *statePtr;

  DEV_ToggleLED(bool *statePtr) : Service::LightBulb() {
    power = new Characteristic::On();
    this->statePtr = statePtr;
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, LOW);
  }

  boolean update() {
    bool newVal = power->getNewVal();
    *statePtr = newVal;

    if (newVal) {
      digitalWrite(RELAY_PIN, HIGH);
      lastToggleTime = millis();
    } else {
      digitalWrite(RELAY_PIN, LOW);
    }

    Serial.println("Toggle HomeKit: " + String(newVal ? "ON" : "OFF"));
    return true;
  }
};

struct DEV_HoldOnLED : Service::LightBulb {
  SpanCharacteristic *power;
  bool *statePtr;

  DEV_HoldOnLED(bool *statePtr) : Service::LightBulb() {
    power = new Characteristic::On();
    this->statePtr = statePtr;
    digitalWrite(RELAY_PIN, LOW);
  }

  boolean update() {
    bool newVal = power->getNewVal();
    *statePtr = newVal;

    if (newVal) {
      digitalWrite(RELAY_PIN, HIGH);
      lastHoldOnTime = millis();
    } else {
      digitalWrite(RELAY_PIN, LOW);
    }

    Serial.println("HoldOn HomeKit: " + String(newVal ? "ON" : "OFF"));
    return true;
  }
};

DEV_ToggleLED *toggleService;
DEV_HoldOnLED *holdonService;

void checkTimeouts() {
  unsigned long now = millis();

  if (toggleState && lastToggleTime && (now - lastToggleTime >= TOGGLE_TIMEOUT)) {
    digitalWrite(RELAY_PIN, LOW);
    toggleState = false;
    if (toggleService) toggleService->power->setVal(false);
    lastToggleTime = 0;
    Serial.println("Toggle AUTO-OFF 0.5s");
  }

  if (holdonState && lastHoldOnTime && (now - lastHoldOnTime >= HOLDON_TIMEOUT)) {
    digitalWrite(RELAY_PIN, LOW);
    holdonState = false;
    if (holdonService) holdonService->power->setVal(false);
    lastHoldOnTime = 0;
    Serial.println("HoldOn AUTO-OFF 5s");
  }
}

void setup() {
  Serial.begin(115200);
  homeSpan.begin(Category::Lighting, "Relay Dual");

  new SpanAccessory();
  new Service::AccessoryInformation();
  new Characteristic::Identify();
  toggleService = new DEV_ToggleLED(&toggleState);

  new SpanAccessory();
  new Service::AccessoryInformation();
  new Characteristic::Identify();
  holdonService = new DEV_HoldOnLED(&holdonState);
}

void loop() {
  checkTimeouts();
  homeSpan.poll();
}