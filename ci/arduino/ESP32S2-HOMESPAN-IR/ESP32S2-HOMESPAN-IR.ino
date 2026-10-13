#include <Arduino.h>
#include "HomeSpan.h"
#include <WiFi.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ir_Coolix.h>

constexpr uint8_t IR_PIN = 10;

IRsend irsend(IR_PIN);
IRCoolixAC coolixAC(IR_PIN);

SpanCharacteristic *acChar = nullptr;

void sendACPower(bool on) {
  coolixAC.begin();

  if (on) {
    coolixAC.setPower(true);
    coolixAC.setMode(kCoolixCool);
    coolixAC.setTemp(24);
    coolixAC.setFan(kCoolixFanAuto);
  } else {
    coolixAC.setPower(false);
  }

  coolixAC.send();

  Serial.printf(
    "IR: Comfee/Coolix AC %s sent\n",
    on ? "ON (Cool 24C Auto)" : "OFF"
  );
}

struct ACService : Service::Switch {
  ACService() : Service::Switch() {
    acChar = new Characteristic::On();
    new Characteristic::Name("Кондиционер");
  }

  boolean update() override {
    bool power = acChar->getNewVal();

    sendACPower(power);

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
  Serial.println("Starting ESP32-S2 HomeSpan IR Switch");

  irsend.begin();
  coolixAC.begin();

  homeSpan.begin(
    Category::Switches,
    "AC IR Switch"
  );

  new SpanAccessory();

  new Service::AccessoryInformation();
  new Characteristic::Name("Кондиционер");
  new Characteristic::Identify();

  acService = new ACService();

  Serial.println("Setup completed");
}

void loop() {
  homeSpan.poll();
}