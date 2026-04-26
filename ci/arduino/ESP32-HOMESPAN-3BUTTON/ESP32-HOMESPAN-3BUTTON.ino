#include "HomeSpan.h"
#include "DEV_LED.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer webServer(8080);

bool state33 = false;
bool state21 = false;
bool state32 = false;

struct DEV_LED *led33;
struct DEV_LED *led21;
struct DEV_LED *led32;

void syncStates() {
  digitalWrite(33, state33);
  digitalWrite(21, state21);
  digitalWrite(32, state32);

  if (led33) led33->power->setVal(state33);
  if (led21) led21->power->setVal(state21);
  if (led32) led32->power->setVal(state32);
}

String makePage() {
  String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Relay</title></head><body>";
  html += "<h1>Relay Control</h1>";

  html += "<p>GPIO 33: <strong>" + String(state33 ? "ON" : "OFF") + "</strong> ";
  html += "<a href='/toggle33'><button style='padding:20px;font-size:20px;'>Toggle 33</button></a></p>";

  html += "<p>GPIO 21: <strong>" + String(state21 ? "ON" : "OFF") + "</strong> ";
  html += "<a href='/toggle21'><button style='padding:20px;font-size:20px;'>Toggle 21</button></a></p>";

  html += "<p>GPIO 32: <strong>" + String(state32 ? "ON" : "OFF") + "</strong> ";
  html += "<a href='/toggle32'><button style='padding:20px;font-size:20px;'>Toggle 32</button></a></p>";

  html += "</body></html>";
  return html;
}

void setupWeb() {
  Serial.print("WebServer: http://");
  Serial.print(WiFi.localIP());
  Serial.println(":8080");

  webServer.on("/", []() {
    webServer.send(200, "text/html", makePage());
  });

  webServer.on("/toggle33", []() {
    state33 = !state33;
    syncStates();
    webServer.send(200, "text/html", makePage());
  });

  webServer.on("/toggle21", []() {
    state21 = !state21;
    syncStates();
    webServer.send(200, "text/html", makePage());
  });

  webServer.on("/toggle32", []() {
    state32 = !state32;
    syncStates();
    webServer.send(200, "text/html", makePage());
  });

  webServer.on("/status33", []() {
    webServer.send(200, "text/plain", state33 ? "ON" : "OFF");
  });

  webServer.on("/status21", []() {
    webServer.send(200, "text/plain", state21 ? "ON" : "OFF");
  });

  webServer.on("/status32", []() {
    webServer.send(200, "text/plain", state32 ? "ON" : "OFF");
  });

  webServer.begin();
}

void setup() {
  Serial.begin(115200);

  pinMode(33, OUTPUT);
  pinMode(21, OUTPUT);
  pinMode(32, OUTPUT);

  homeSpan.begin(Category::Lighting, "HomeSpan LED");
  homeSpan.setWifiCallback(setupWeb);

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
    led33 = new DEV_LED(33);

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
    led21 = new DEV_LED(21);

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
    led32 = new DEV_LED(32);
}

void loop() {
  webServer.handleClient();
  homeSpan.poll();
}