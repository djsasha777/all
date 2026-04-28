#include "HomeSpan.h"
#include <WiFi.h>
#include <WebServer.h>


WebServer webServer(8080);

// Состояния трёх пинов (логика: true = включен)
bool ledState21 = false;
bool ledState32 = false;
bool ledState33 = false;

// Каждый LED → свой DEV_LED
struct DEV_LED : Service::LightBulb {
  int ledPin;
  SpanCharacteristic *power;
  bool *ledStatePtr;

  DEV_LED(int pin, bool *state) : Service::LightBulb() {
    ledPin = pin;
    ledStatePtr = state;
    power = new Characteristic::On();
    pinMode(ledPin, OUTPUT);
  }

  int getPin() { return ledPin; }

  boolean update() {
    *ledStatePtr = power->getNewVal();

    // Инвертируем только для пина 33 (реле включается при LOW)
    if (ledPin == 33) {
      digitalWrite(ledPin, !(*ledStatePtr));
    } else {
      digitalWrite(ledPin, *ledStatePtr);
    }

    Serial.printf("[HomeSpan] Update: pin=%d -> %s (state=%d)\n",
                  ledPin,
                  *ledStatePtr ? "ON" : "OFF",
                  *ledStatePtr);
    return true;
  }
};

DEV_LED *led21 = nullptr;
DEV_LED *led32 = nullptr;
DEV_LED *led33 = nullptr;

void setupWeb() {
  Serial.print("WebServer: http://");
  Serial.print(WiFi.localIP());
  Serial.println(":8080");

  webServer.on("/", []() {
    String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Relays</title></head><body>";
    html += "<h1>Relay Control</h1>";

    html += "<p><strong>Pin 21:</strong> ";
    html += ledState21 ? "ON" : "OFF";
    html += " <a href='/toggle21'><button style='padding:10px;margin:5px;'>Toggle 21</button></a></p>";

    html += "<p><strong>Pin 32:</strong> ";
    html += ledState32 ? "ON" : "OFF";
    html += " <a href='/toggle32'><button style='padding:10px;margin:5px;'>Toggle 32</button></a></p>";

    html += "<p><strong>Pin 33 (inverted):</strong> ";
    html += ledState33 ? "ON" : "OFF";
    html += " <a href='/toggle33'><button style='padding:10px;margin:5px;'>Toggle 33</button></a></p>";

    html += "</body></html>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/toggle21", []() {
    Serial.println("[WEB] Toggle 21 (web)");
    ledState21 = !ledState21;
    digitalWrite(21, ledState21);              // нет инверсии
    if (led21) {
      led21->power->setVal(ledState21);        // синхронизируем с HomeKit
    }

    String html = "<h1>Toggled Pin 21!</h1>";
    html += "<p>Pin 21: <strong>" + String(ledState21 ? "ON" : "OFF") + "</strong></p>";
    html += "<a href='/'><button>Back</button></a>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/toggle32", []() {
    Serial.println("[WEB] Toggle 32 (web)");
    ledState32 = !ledState32;
    digitalWrite(32, ledState32);              // нет инверсии
    if (led32) {
      led32->power->setVal(ledState32);
    }

    String html = "<h1>Toggled Pin 32!</h1>";
    html += "<p>Pin 32: <strong>" + String(ledState32 ? "ON" : "OFF") + "</strong></p>";
    html += "<a href='/'><button>Back</button></a>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/toggle33", []() {
    Serial.println("[WEB] Toggle 33 (web)");
    ledState33 = !ledState33;

    // !! инвертируем для пина 33 (реле включается при LOW)
    digitalWrite(33, !ledState33);

    if (led33) {
      led33->power->setVal(ledState33);
    }

    String html = "<h1>Toggled Pin 33!</h1>";
    html += "<p>Pin 33 (inverted): <strong>" + String(ledState33 ? "ON" : "OFF") + "</strong></p>";
    html += "<a href='/'><button>Back</button></a>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/status", []() {
    String json = "{\"relays\":[";
    json += "{\"pin\":21,\"state\":" + String(ledState21 ? "true" : "false") + "},";
    json += "{\"pin\":32,\"state\":" + String(ledState32 ? "true" : "false") + "},";
    json += "{\"pin\":33,\"state\":" + String(ledState33 ? "true" : "false") + "}";
    json += "]}";
    webServer.send(200, "application/json", json);
  });

  webServer.begin();
}

void setup() {
  Serial.begin(115200);
  Serial.println("setup started");

  homeSpan.begin(Category::Lighting, "HomeSpan Relays");
  homeSpan.setWifiCallback(setupWeb);

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();

    led21 = new DEV_LED(21, &ledState21);
    led32 = new DEV_LED(32, &ledState32);
    led33 = new DEV_LED(33, &ledState33);

  // Синхронизируем стартовое состояние
  ledState21 = led21->power->getVal();
  ledState32 = led32->power->getVal();
  ledState33 = led33->power->getVal();

  digitalWrite(21, ledState21);
  digitalWrite(32, ledState32);
  digitalWrite(33, !ledState33);   // инверсия при старте для пина 33

  Serial.println("HomeSpan and web server started.");
  Serial.println("Open: http://" + WiFi.localIP().toString() + ":8080");
}

void loop() {
  webServer.handleClient();
  homeSpan.poll();   // homeSpan.poll() ОБЯЗАН вызываться каждый цикл
}