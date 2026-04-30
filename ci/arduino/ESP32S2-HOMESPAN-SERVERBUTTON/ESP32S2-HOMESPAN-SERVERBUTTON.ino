#include "HomeSpan.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer webServer(8080);

// Состояния двух логических ламп (оба пин 4)
bool toggleState = false;  // Лампа 1: Toggle
bool holdonState = false;  // Лампа 2: HoldOn 5с

// Таймеры
unsigned long lastToggleTime = 0;
bool buttonToggleActive = false;
const unsigned long TOGGLE_TIMEOUT = 500;

unsigned long lastHoldOnTime = 0;
bool buttonHoldOnActive = false;
const unsigned long HOLDON_TIMEOUT = 5000;

struct DEV_ToggleLED : Service::LightBulb {
  SpanCharacteristic *power;
  bool *statePtr;  // Указатель на toggleState

  DEV_ToggleLED(bool *statePtr) : Service::LightBulb() {
    power = new Characteristic::On();
    this->statePtr = statePtr;
    pinMode(4, OUTPUT);
    digitalWrite(4, LOW);
  }

  boolean update() {
    bool newVal = power->getNewVal();
    *statePtr = newVal;
    digitalWrite(4, newVal);
    Serial.println("Toggle HomeKit: " + String(newVal ? "ON" : "OFF"));
    lastToggleTime = millis();  // Авто-OFF 0.5с
    return true;
  }
};

struct DEV_HoldOnLED : Service::LightBulb {
  SpanCharacteristic *power;
  bool *statePtr;

  DEV_HoldOnLED(bool *statePtr) : Service::LightBulb() {
    power = new Characteristic::On();
    this->statePtr = statePtr;
  }

  boolean update() {
    bool newVal = power->getNewVal();
    *statePtr = newVal;
    digitalWrite(4, newVal);
    Serial.println("HoldOn HomeKit: " + String(newVal ? "ON" : "OFF"));
    lastHoldOnTime = millis();  // Авто-OFF 5с
    return true;
  }
};

DEV_ToggleLED *toggleService;
DEV_HoldOnLED *holdonService;

void checkTimeouts() {
  unsigned long now = millis();
  
  // Toggle авто-OFF 0.5с (для обеих ламп)
  if (lastToggleTime && (now - lastToggleTime >= TOGGLE_TIMEOUT)) {
    digitalWrite(4, LOW);
    toggleState = false;
    holdonState = false;
    if (toggleService) toggleService->power->setVal(false);
    if (holdonService) holdonService->power->setVal(false);
    lastToggleTime = 0;
    Serial.println("Toggle AUTO-OFF 0.5s");
  }
  
  // HoldOn авто-OFF 5с
  if (lastHoldOnTime && (now - lastHoldOnTime >= HOLDON_TIMEOUT)) {
    digitalWrite(4, LOW);
    holdonState = false;
    if (holdonService) holdonService->power->setVal(false);
    lastHoldOnTime = 0;
    Serial.println("HoldOn AUTO-OFF 5s");
  }
  
  // Кнопки веб разблокировка
  if (buttonToggleActive && (now - lastToggleTime >= TOGGLE_TIMEOUT)) {
    buttonToggleActive = false;
    Serial.println("Toggle button unlocked");
  }
  if (buttonHoldOnActive && (now - lastHoldOnTime >= HOLDON_TIMEOUT)) {
    buttonHoldOnActive = false;
    Serial.println("HoldOn button unlocked");
  }
}

void setupWeb() {
  Serial.print("Web: http://");
  Serial.println(WiFi.localIP().toString() + ":8080");

  webServer.on("/", HTTP_GET, []() {
    checkTimeouts();
    String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><meta http-equiv='refresh' content='1'><title>Relay Pin4</title></head><body>";
    html += "<h1>Pin 4: 2 Buttons / 2 HomeKit Lights</h1>";
    html += "<p>Physical: " + String(digitalRead(4) ? "HIGH" : "LOW") + "</p>";
    
    // Toggle кнопка (0.5с)
    if (buttonToggleActive) {
      html += "<p>Toggle: " + String((TOGGLE_TIMEOUT-(millis()-lastToggleTime))/1000.0,1) + "s</p><button disabled>1.Toggle 0.5s</button><br>";
    } else {
      html += "<a href='/toggle'><button>1.Toggle 0.5s</button></a><br>";
    }
    
    // HoldOn кнопка (5с)
    if (buttonHoldOnActive || lastHoldOnTime) {
      float t = (HOLDON_TIMEOUT-(millis()-lastHoldOnTime))/1000.0;
      html += "<p>HoldOn: " + String(t,1) + "s</p><button disabled>2.HoldOn 5s</button>";
    } else {
      html += "<a href='/holdon'><button>2.HoldOn 5s</button></a>";
    }
    
    html += "</body></html>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/toggle", HTTP_GET, []() {
    bool newState = !toggleState;  // Toggle реально переключает!
    digitalWrite(4, newState);
    toggleState = newState;
    holdonState = newState;
    if (toggleService) toggleService->power->setVal(newState);
    lastToggleTime = millis();
    buttonToggleActive = true;
    Serial.println("Web Toggle: " + String(newState ? "ON" : "OFF"));
    webServer.send(200, "text/html", "<script>location='/'</script>");
  });

  webServer.on("/holdon", HTTP_GET, []() {
    digitalWrite(4, HIGH);
    holdonState = true;
    toggleState = true;
    if (holdonService) holdonService->power->setVal(true);
    lastHoldOnTime = millis();
    buttonHoldOnActive = true;
    Serial.println("Web HoldOn ON");
    webServer.send(200, "text/html", "<script>location='/'</script>");
  });

  webServer.begin();
}

void setup() {
  Serial.begin(115200);
  homeSpan.begin(Category::Lighting, "Relay Dual");

  // Accessory 1: Toggle Light (0.5s auto-off)
  new SpanAccessory();
  new Service::AccessoryInformation(); new Characteristic::Identify();
  toggleService = new DEV_ToggleLED(&toggleState);

  // Accessory 2: HoldOn Light (5s auto-off)
  new SpanAccessory();
  new Service::AccessoryInformation(); new Characteristic::Identify();
  holdonService = new DEV_HoldOnLED(&holdonState);

  homeSpan.setWifiCallback(setupWeb);
}

void loop() {
  checkTimeouts();
  webServer.handleClient();
  homeSpan.poll();
}