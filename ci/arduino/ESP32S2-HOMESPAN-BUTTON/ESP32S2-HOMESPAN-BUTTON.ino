#include "HomeSpan.h"
#include <WiFi.h>

struct DEV_LED : Service::LightBulb {
  int ledPin;
  SpanCharacteristic *power;

  DEV_LED(int ledPin) : Service::LightBulb() {
    power = new Characteristic::On();
    this->ledPin = ledPin;
    pinMode(ledPin, OUTPUT);
    digitalWrite(ledPin, HIGH); // реле выключено при активном LOW
  }

  boolean update() {
    digitalWrite(ledPin, !power->getNewVal()); // инверсия для активного LOW
    return true;
  }
};

DEV_LED *ledService;

void setup() {
  Serial.begin(115200);
  homeSpan.begin(Category::Lighting, "HomeSpan LED");

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
    ledService = new DEV_LED(37);
}

void loop() {
  homeSpan.poll();
}