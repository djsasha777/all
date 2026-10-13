#include "HomeSpan.h"

int brightness = 50;
const int ledPin = 4;
SpanCharacteristic *powerChar;
SpanCharacteristic *brightnessChar;

struct DimmableLED : Service::LightBulb {
  DimmableLED() : Service::LightBulb() {
    powerChar = new Characteristic::On();
    brightnessChar = new Characteristic::Brightness(1);
    brightnessChar->setRange(0, 100, 1);
  }

  boolean update() {
    bool power = powerChar->getNewVal();
    brightness = brightnessChar->getNewVal();

    int pwm = power ? brightness : 0;
    analogWrite(ledPin, map(pwm, 0, 100, 0, 255));

    Serial.printf("HomeKit: power=%s, brightness=%d PWM=%d\n",
                  power ? "ON" : "OFF", brightness, map(pwm, 0, 100, 0, 255));
    return true;
  }
};

DimmableLED *myLED;

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  analogWrite(ledPin, 0);

  homeSpan.begin(Category::Lighting, "LED Strip");

  new SpanAccessory();
  new Service::AccessoryInformation();
  new Characteristic::Name("LED Dimmer");
  new Characteristic::Identify();

  myLED = new DimmableLED();
}

void loop() {
  homeSpan.poll();
}