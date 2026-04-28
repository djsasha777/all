#include "HomeSpan.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer webServer(8080);
bool ledState = false;

// Структура должна быть ОБЪЯВЛЕНА до setup() и setupWeb()
struct DEV_LED : Service::LightBulb {
  int ledPin;
  SpanCharacteristic *power;

  DEV_LED(int ledPin) : Service::LightBulb(){
    power = new Characteristic::On();
    this->ledPin = ledPin;
    pinMode(ledPin, OUTPUT);
  }

  int getPin() { return ledPin; }

  boolean update(){
    digitalWrite(ledPin, power->getNewVal());
    return true;
  }
};

DEV_LED *ledService;  // указатель, теперь тип полностью известен


void setupWeb() {
  Serial.print("WebServer: http://");
  Serial.print(WiFi.localIP());
  Serial.println(":8080");

  webServer.on("/", []() {
    String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Relay</title></head><body>";
    html += "<h1>Relay Control</h1>";
    html += "<p>Status: <strong>" + String(ledState ? "ON" : "OFF") + "</strong></p>";
    html += "<a href='/toggle'><button style='padding:20px;font-size:20px;'>Toggle</button></a>";
    html += "</body></html>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/toggle", []() {
    ledState = !ledState;
    digitalWrite(4, ledState);

    if (ledService) {
      ledService->power->setVal(ledState);
    }

    String html = "<h1>Toggled!</h1>";
    html += "<p>Relay: <strong>" + String(ledState ? "ON" : "OFF") + "</strong></p>";
    html += "<a href='/'><button>Back</button></a>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/status", []() {
    String json = "{\"relay\": \"" + String(ledState ? "ON" : "OFF") + "\", ";
    json += "\"pin\": " + String(ledService->getPin()) + ", ";
    json += "\"power\": " + String(ledService->power->getVal() ? "true" : "false") + "}";

    webServer.send(200, "application/json", json);
  });

  webServer.begin();
}

void setup() {
  Serial.begin(115200);
  homeSpan.begin(Category::Lighting, "HomeSpan LED");
  homeSpan.setWifiCallback(setupWeb);

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
    ledService = new DEV_LED(4);  // теперь тип DEV_LED полностью определён
}

void loop() {
  webServer.handleClient();
  homeSpan.poll();
}