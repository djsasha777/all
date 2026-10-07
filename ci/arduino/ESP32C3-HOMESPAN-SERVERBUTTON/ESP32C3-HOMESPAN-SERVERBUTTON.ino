#include "HomeSpan.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer webServer(8080);

// Состояния (теперь независимые)
bool toggleState = false;  
bool holdonState = false;  

// Таймеры
unsigned long lastToggleTime = 0;
bool buttonToggleActive = false;
const unsigned long TOGGLE_TIMEOUT = 500;

unsigned long lastHoldOnTime = 0;
bool buttonHoldOnActive = false;
const unsigned long HOLDON_TIMEOUT = 5000;

// Используем константу для пина
const uint8_t RELAY_PIN = 1; 

struct DEV_ToggleLED : Service::LightBulb {
  SpanCharacteristic *power;
  bool *statePtr;

  DEV_ToggleLED(bool *statePtr) : Service::LightBulb() {
    power = new Characteristic::On();
    this->statePtr = statePtr;
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, LOW); // Старт с 0В
  }

  boolean update() {
    bool newVal = power->getNewVal();
    *statePtr = newVal;
    
    if (newVal) {
      digitalWrite(RELAY_PIN, HIGH); // Включили: 3.3В
      lastToggleTime = millis();
    } else {
      digitalWrite(RELAY_PIN, LOW);  // Выключили: 0В
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
    // Пин уже настроен в DEV_ToggleLED
    digitalWrite(RELAY_PIN, LOW); 
  }

  boolean update() {
    bool newVal = power->getNewVal();
    *statePtr = newVal;

    if (newVal) {
      digitalWrite(RELAY_PIN, HIGH); // Включили: 3.3В
      lastHoldOnTime = millis();
    } else {
      digitalWrite(RELAY_PIN, LOW);  // Выключили: 0В
    }
    
    Serial.println("HoldOn HomeKit: " + String(newVal ? "ON" : "OFF"));
    return true;
  }
};

DEV_ToggleLED *toggleService;
DEV_HoldOnLED *holdonService;

void checkTimeouts() {
  unsigned long now = millis();
  
  // Toggle авто-OFF 0.5с
  if (toggleState && lastToggleTime && (now - lastToggleTime >= TOGGLE_TIMEOUT)) {
    digitalWrite(RELAY_PIN, LOW); // <--- Исправлено на LOW
    toggleState = false;
    if (toggleService) toggleService->power->setVal(false);
    lastToggleTime = 0;
    Serial.println("Toggle AUTO-OFF 0.5s");
  }
  
  // HoldOn авто-OFF 5с
  if (holdonState && lastHoldOnTime && (now - lastHoldOnTime >= HOLDON_TIMEOUT)) {
    digitalWrite(RELAY_PIN, LOW); // <--- Исправлено на LOW
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
    String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><meta http-equiv='refresh' content='1'><title>Relay Pin1</title></head><body>";
    html += "<h1>Pin 1: 2 Buttons / 2 HomeKit Lights</h1>";
    html += "<p>Physical: " + String(digitalRead(RELAY_PIN) ? "3.3V (HIGH)" : "0V (LOW)") + "</p>";
    
    if (buttonToggleActive) {
      html += "<p>Toggle: " + String((TOGGLE_TIMEOUT-(millis()-lastToggleTime))/1000.0,1) + "s</p><button disabled>1.Toggle 0.5s</button><br>";
    } else {
      html += "<a href='/toggle'><button>1.Toggle 0.5s</button></a><br>";
    }
    
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
    bool newState = !toggleState; 
    digitalWrite(RELAY_PIN, newState ? HIGH : LOW);
    toggleState = newState;
    // holdonState больше не трогаем принудительно!
    if (toggleService) toggleService->power->setVal(newState);
    if (newState) lastToggleTime = millis();
    buttonToggleActive = true;
    Serial.println("Web Toggle: " + String(newState ? "ON" : "OFF"));
    webServer.send(200, "text/html", "<script>location='/'</script>");
  });

  webServer.on("/holdon", HTTP_GET, []() {
    digitalWrite(RELAY_PIN, HIGH);
    holdonState = true;
    // toggleState больше не трогаем принудительно!
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

  new SpanAccessory();
  new Service::AccessoryInformation(); 
  new Characteristic::Identify();
  toggleService = new DEV_ToggleLED(&toggleState);

  new SpanAccessory();
  new Service::AccessoryInformation(); 
  new Characteristic::Identify();
  holdonService = new DEV_HoldOnLED(&holdonState);

  homeSpan.setWifiCallback(setupWeb);
}

void loop() {
  checkTimeouts();
  webServer.handleClient();
  homeSpan.poll();
}