#include "HomeSpan.h"
#include <WebServer.h>

WebServer webServer(8080);


// Фейковая температура
float fakeTemp = 22.0;

unsigned long lastFakeUpdate = 0;
const unsigned long FAKE_UPDATE_INTERVAL = 5000;  // 5 сек


// Одно аксессуарное устройство: Switch + TemperatureSensor
struct FakeSwitchAndSensor : Service::AccessoryInformation,
  Service::Switch,
  Service::TemperatureSensor
{
  SpanCharacteristic *on;
  SpanCharacteristic *temp;

  FakeSwitchAndSensor() : Service::AccessoryInformation(),
    Service::Switch(),
    Service::TemperatureSensor()
  {
    // Switch
    on = new Characteristic::On();

    // Temperature
    temp = new Characteristic::CurrentTemperature(22.0);
    temp->setRange(-50, 100);        // HomeKit: -50 .. 100 °C
  }

  bool update() override {
    bool val = on->getNewVal();
    Serial.println("Switch: " + String(val ? "ON" : "OFF"));
    return true;
  }

  void loop() override {
    unsigned long now = millis();
    if (now - lastFakeUpdate >= FAKE_UPDATE_INTERVAL) {
      lastFakeUpdate = now;

      fakeTemp = 22.0 + 3.0 * sinf(now / 15000.0);
      fakeTemp = constrain(fakeTemp, -50.0, 100.0);

      temp->setVal(fakeTemp, 1);

      Serial.printf("Fake Temp (from Switch+Sensor): T=%.1f\n", fakeTemp);
    }
  }
};


// Веб‑сайт с фейковой температурой
void handleHome() {
  String html = R"=====(
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>ESP32 Temp + Switch</title>
  <meta http-equiv="refresh" content="3">
  <style>
    body { font-family: Verdana; font-size: 14px; margin: 20px; }
    table { border-collapse: collapse; margin-top: 10px; }
    td, th { border: 1px solid #ccc; padding: 6px 10px; }
  </style>
</head>
<body>
  <h1>ESP32 Fake Temp + Switch Device</h1>
  <table>
    <tr><th>Параметр</th><th>Значение</th></tr>
    <tr><td>Температура</td><td>)=====";

  html += String(fakeTemp, 1) + " °C</td></tr>";
  html += "</table>";

  html += "<p>Wi‑Fi IP: " + WiFi.localIP().toString() + "</p>";
  html += "<p>Откройте в браузере: http://" + WiFi.localIP().toString() + ":8080</p>";
  html += "</body></html>";

  webServer.send(200, "text/html", html);
}


void setupWeb() {
  Serial.println("Web: http://" + WiFi.localIP().toString() + ":8080");
  webServer.on("/", HTTP_GET, handleHome);
  webServer.begin();
}


void setup() {
  Serial.begin(115200);

  // HomeSpan сам управляет Wi‑Fi
  homeSpan.begin(Category::Switches, "ESP32 Fake Temp + Switch");

  new SpanAccessory();
  new Service::AccessoryInformation();
  new Characteristic::Identify();
  new Characteristic::Name("Fake Temp + Switch");
  new FakeSwitchAndSensor();

  // Запуск веб‑сервера после установки Wi‑Fi
  homeSpan.setWifiCallback(setupWeb);
}


void loop() {
  webServer.handleClient();
  homeSpan.poll();
}