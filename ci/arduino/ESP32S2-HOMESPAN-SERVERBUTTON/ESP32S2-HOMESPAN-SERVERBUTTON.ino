#include "HomeSpan.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer webServer(8080);
bool ledState = false;

// Таймеры
unsigned long lastToggleTime = 0;
bool buttonToggleActive = false;
const unsigned long TOGGLE_TIMEOUT = 500;

unsigned long lastPulseTime = 0;
bool buttonPulseActive = false;
const unsigned long PULSE_TIMEOUT = 5000;

unsigned long lastHomeKitOnTime = 0;
const unsigned long HOMEKIT_TIMEOUT = 500;

struct DEV_LED : Service::LightBulb {
  int ledPin;
  SpanCharacteristic *power;

  DEV_LED(int ledPin) : Service::LightBulb(){
    power = new Characteristic::On();
    this->ledPin = ledPin;
    pinMode(ledPin, OUTPUT);
  }

  int getPin() { return ledPin; }

  boolean update() {
    bool newVal = power->getNewVal();
    
    digitalWrite(ledPin, newVal);
    ledState = newVal;
    
    if (newVal) {
      lastHomeKitOnTime = millis();
    } else {
      lastHomeKitOnTime = 0;
    }
    
    Serial.println("HomeKit update: " + String(newVal ? "ON" : "OFF"));
    return true;
  }
};

DEV_LED *ledService;

void checkTimeouts() {
  unsigned long now = millis();
  
  // HomeKit авто-OFF
  if (lastHomeKitOnTime && (now - lastHomeKitOnTime >= HOMEKIT_TIMEOUT)) {
    digitalWrite(4, LOW);
    if (ledService) ledService->power->setVal(false);
    ledState = false;
    lastHomeKitOnTime = 0;
    Serial.println("HomeKit AUTO-OFF");
  }
  
  // Web Toggle
  if (buttonToggleActive && (now - lastToggleTime >= TOGGLE_TIMEOUT)) {
    buttonToggleActive = false;
    Serial.println("Web Toggle timeout");
  }
  
  // Web Pulse
  if (buttonPulseActive && (now - lastPulseTime >= PULSE_TIMEOUT)) {
    buttonPulseActive = false;
    Serial.println("Web Pulse timeout");
  }
}

void setupWeb() {
  Serial.print("Web: http://");
  Serial.println(WiFi.localIP());

  webServer.on("/", []() {
    checkTimeouts();
    
    String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><meta http-equiv='refresh' content='1'><title>Relay</title></head><body>";
    html += "<h1>Pin 4 Control</h1>";
    html += "<p>Physical: " + String(digitalRead(4) ? "HIGH" : "LOW") + "</p>";
    html += "<p>HomeKit: " + String(ledState ? "ON" : "OFF") + "</p>";
    
    if (buttonToggleActive) {
      html += "<p>Toggle: OFF (" + String((TOGGLE_TIMEOUT - (millis() - lastToggleTime))/1000.0,1) + "s)</p>";
      html += "<button disabled>Toggle</button>";
    } else {
      html += "<a href='/toggle'><button>Toggle (0.5s)</button></a>";
    }
    
    if (buttonPulseActive) {
      html += "<p>Pulse: OFF (" + String((PULSE_TIMEOUT - (millis() - lastPulseTime))/1000.0,1) + "s)</p>";
      html += "<button disabled>Pulse</button>";
    } else {
      html += "<a href='/pulse'><button>Pulse (5s)</button></a>";
    }
    
    html += "</body></html>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/toggle", []() {
    bool newState = !digitalRead(4);
    digitalWrite(4, newState);
    ledState = newState;
    if (ledService) ledService->power->setVal(newState);
    
    buttonToggleActive = true;
    lastToggleTime = millis();
    
    Serial.println("Web Toggle: " + String(newState ? "ON" : "OFF"));
    
    webServer.send(200, "text/html", 
      "<h1>Toggle OK</h1><script>setTimeout(()=>{window.location='/'},600);</script>");
  });

  webServer.on("/pulse", []() {
    digitalWrite(4, HIGH);
    for(int i=0; i<2000; i++); // ~50ms
    digitalWrite(4, LOW);
    
    ledState = false;
    if (ledService) ledService->power->setVal(false);
    
    buttonPulseActive = true;
    lastPulseTime = millis();
    
    Serial.println("Web Pulse");
    
    webServer.send(200, "text/html", 
      "<h1>Pulse OK</h1><script>setTimeout(()=>{window.location='/'},100);</script>");
  });

  webServer.begin();
}

void setup() {
  Serial.begin(115200);
  homeSpan.begin(Category::Lighting, "Relay");
  homeSpan.setWifiCallback(setupWeb);

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
    ledService = new DEV_LED(4);
}

void loop() {
  checkTimeouts();
  webServer.handleClient();
  homeSpan.poll();
}