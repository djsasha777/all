#include <Arduino.h>
#include "HomeSpan.h"
#include <WiFi.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>

constexpr uint8_t IR_PIN = 10;

IRsend irsend(IR_PIN);

SpanCharacteristic *acChar = nullptr;

void sendACSignal() {
  // ВАЖНО:
  // 0x0220E004 — временный пример 32-битного кода.
  // Замените его на настоящий код вашего кондиционера.
  irsend.sendPanasonicAC32(
    0x0220E004,
    32
  );

  Serial.println("IR: Panasonic AC signal sent");
}

struct ACService : Service::Switch {
  ACService() : Service::Switch() {
    acChar = new Characteristic::On();
    new Characteristic::Name("Кондиционер");
  }

  boolean update() {
    bool power = acChar->getNewVal();

    sendACSignal();

    Serial.printf(
      "HomeKit: AC=%s\n",
      power ? "ON" : "OFF"
    );

    return true;
  }
};

ACService *acService = nullptr;

void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println();
  Serial.println("Starting ESP32-S2 HomeSpan IR controller");

  irsend.begin();

  homeSpan.begin(
    Category::Bridges,
    "IR Controller"
  );

  new SpanAccessory();

  new Service::AccessoryInformation();
  new Characteristic::Name("IR Controller");
  new Characteristic::Identify();

  acService = new ACService();

  Serial.println("Setup completed");
}

void loop() {
  homeSpan.poll();
}