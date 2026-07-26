#include "HomeSpan.h"
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include "Adafruit_BME680.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer server(8080);

// --- Глобальное состояние двери ---
bool doorOpen = false;  // true = открыта, false = закрыта

struct BME68xHub : Service::TemperatureSensor {
  SpanCharacteristic *temp, *hum;
  SpanCharacteristic *pressure; // Добавлено: указатель на характеристику давления
  SpanCharacteristic *gas;      // Добавлено: указатель на характеристику VOC
  Service::HumiditySensor *humService;

  unsigned long lastUpdate, fakeLastUpdate;
  float temperature, humidity;
  float pressure_mmHg, gas_resistance;
  Adafruit_BME680 bme;
  bool bmeOk;
  float fakeTemp, fakeHum, fakePress_mmHg, fakeGas;

  BME68xHub() : Service::TemperatureSensor() {
    temp = new Characteristic::CurrentTemperature(22.0);
    temp->setRange(-50,100);
    new Characteristic::Name("Температура");

    humService = new Service::HumiditySensor();
    hum = new Characteristic::CurrentRelativeHumidity(50.0);
    hum->setRange(0,100);
    new Characteristic::Name("Влажность");

    pressure = new Characteristic::CurrentAmbientLightLevel(760.0); 
    pressure->setRange(700, 800);
    new Characteristic::Name("Давление");

    gas = new Characteristic::CarbonDioxideLevel(100); 
    gas->setRange(0, 500);
    new Characteristic::Name("VOC (сопротивление)");

    lastUpdate = 0;
    fakeLastUpdate = 0;
    temperature = 0;
    humidity = 0;
    pressure_mmHg = 0;
    gas_resistance = 0;
    fakeTemp = 22.0;
    fakeHum = 50.0;
    fakePress_mmHg = 760.0;
    fakeGas = 100000.0;
    bmeOk = false;

    Wire.begin(8, 9); 
    
    if (!bme.begin(0x77, &Wire)) { 
      LOG1("BME680 not found\n");
      return;
    }
    bme.setTemperatureOversampling(BME680_OS_8X);
    bme.setHumidityOversampling(BME680_OS_2X);
    bme.setPressureOversampling(BME680_OS_4X);
    bme.setIIRFilterSize(BME680_FILTER_SIZE_3);
    bmeOk = true;
    LOG1("BME680 OK\n");
  }

  void loop() {
    unsigned long now = millis();
    if (bmeOk) {
      if (now - lastUpdate > 5000) {
        lastUpdate = now;
        
        bme.setGasHeater(320, 150); 

        if (!bme.performReading()) {
          LOG1("Error reading BME680\n");
          return;
        }

        temperature = bme.temperature;
        humidity = bme.humidity;
        pressure_mmHg = bme.pressure / 133.322f;
        gas_resistance = bme.gas_resistance / 1000.0f; 

        temp->setVal(temperature);
        hum->setVal(humidity);
        pressure->setVal(pressure_mmHg);
        gas->setVal(gas_resistance);

        LOG1("T%0.1f H%0.1f P%0.1f G%0.0fk\n", temperature, humidity, pressure_mmHg, gas_resistance);
      }
    } else {
      if (now - fakeLastUpdate > 10000) {
        fakeLastUpdate = now;
        fakeTemp += random(-50,51) / 100.0;
        fakeTemp = constrain(fakeTemp, 18.0, 28.0);
        fakeHum += random(-100,101) / 100.0;
        fakeHum = constrain(fakeHum, 30.0, 70.0);
        fakePress_mmHg += random(-20,21) / 10.0;
        fakePress_mmHg = constrain(fakePress_mmHg, 730.0, 790.0);
        fakeGas *= (0.98 + random(41) / 1000.0);
        fakeGas = constrain(fakeGas, 50000.0, 200000.0);

        temp->setVal(fakeTemp);
        hum->setVal(fakeHum);
      }
    }
  }
};

// --- Датчик открытия двери (Contact Sensor) ---
struct DoorContactSensor : Service::ContactSensor {
  SpanCharacteristic *contactState;

  DoorContactSensor() : Service::ContactSensor() {
    contactState = new Characteristic::ContactSensorState(doorOpen ? 1 : 0);
    new Characteristic::Name("Дверь");
  }

  void updateDoorState(bool open) {
    doorOpen = open;
    contactState->setVal(doorOpen ? 1 : 0);
    LOG1("Door state: %s\n", doorOpen ? "OPEN" : "CLOSED");
  }

  void loop() {
    
  }
};

BME68xHub *hub;
DoorContactSensor *doorSensor;

void setupWebServer() {
  server.on("/", []() {
    String html = R"HTML(
<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width,initial-scale=1'>
<title>BME68x</title>
<style>
body{font-family:Arial;margin:40px;background:#f0f4f8;color:#333;}
.card{background:#fff;padding:20px;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.1);margin:10px 0;}
h1{text-align:center;color:#2c3e50;}
.val{font-size:24px;font-weight:bold;color:#27ae60;}
.mode{font-size:18px;padding:8px;border-radius:6px;display:inline-block;}
.REAL{background:#d4edda;color:#155724;}
.FAKE{background:#fff3cd;color:#856404;}
.OPEN{background:#f8d7da;color:#721c24;}
.CLOSED{background:#d4edda;color:#155724;}
.data-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:15px;}
@media(max-width:600px){.data-grid{grid-template-columns:1fr;}}
</style>
</head>
<body>
<h1>🌡️ BME68x ESP32-C3</h1>
<div class='data-grid'>
)HTML";

  html += "<div class='card'><b>Температура</b><br><span class='val'>";
  html += (hub->bmeOk ? String(hub->temperature, 1) : String(hub->fakeTemp, 1));
  html += " °C</span></div>";

  html += "<div class='card'><b>Влажность</b><br><span class='val'>";
  html += (hub->bmeOk ? String(hub->humidity, 1) : String(hub->fakeHum, 1));
  html += " %</span></div>";

  html += "<div class='card'><b>Давление</b><br><span class='val'>";
  html += (hub->bmeOk ? String(hub->pressure_mmHg, 1) : String(hub->fakePress_mmHg, 1));
  html += " мм рт.ст.</span></div>";

  html += "<div class='card'><b>VOC</b><br><span class='val'>";
  html += (hub->bmeOk ? String(hub->gas_resistance, 0) : String(hub->fakeGas / 1000.0, 0));
  html += " kΩ</span></div>";

  html += "<div class='card'><b>Дверь</b><br><span class='val ";
  html += doorOpen ? "OPEN" : "CLOSED";
  html += "'>";
  html += doorOpen ? "ОТКРЫТА" : "ЗАКРЫТА";
  html += "</span></div>";

  html += "<div class='card'><b>Режим</b><br><span class='mode ";
  html += (hub->bmeOk ? "REAL" : "FAKE");
  html += "'>";
  html += (hub->bmeOk ? "REAL" : "FAKE");
  html += "</span></div>";

  html += R"HTML(
</div>
<p style='text-align:center;color:#666;font-size:14px;'>Auto-refresh 10s</p>
<script>setTimeout(()=>location.reload(),10000);</script>
</body>
</html>
)HTML";

    server.send(200, "text/html", html);
  });

  server.on("/sensor1/true", []() {
    doorSensor->updateDoorState(true);  
    server.send(200, "application/json", "{\"ok\":true,\"door\":\"open\"}");
  });

  server.on("/sensor1/false", []() {
    doorSensor->updateDoorState(false);  
    server.send(200, "application/json", "{\"ok\":true,\"door\":\"closed\"}");
  });

  server.begin();
}

void setup() {
  Serial.begin(115200);
  homeSpan.setLogLevel(1);
  homeSpan.begin(Category::Sensors, "BME68x");

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Name("BME68x C3");

  hub = new BME68xHub();
  doorSensor = new DoorContactSensor();

  setupWebServer();
}

void loop() {
  homeSpan.poll();
  server.handleClient();
  hub->loop();
  doorSensor->loop();
}