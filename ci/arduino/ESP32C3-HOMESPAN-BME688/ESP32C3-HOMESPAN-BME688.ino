#include "HomeSpan.h"
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include "Adafruit_BME680.h"
#include <WiFi.h>

struct BME68xHub : Service::TemperatureSensor {
  SpanCharacteristic *temp, *hum;
  SpanCharacteristic *pressure;
  SpanCharacteristic *gas;
  Service::HumiditySensor *humService;

  unsigned long lastUpdate, fakeLastUpdate;
  float temperature, humidity;
  float pressure_mmHg, gas_resistance;
  Adafruit_BME680 bme;
  bool bmeOk;
  float fakeTemp, fakeHum, fakePress_mmHg, fakeGas;

  BME68xHub() : Service::TemperatureSensor() {
    temp = new Characteristic::CurrentTemperature(22.0);
    temp->setRange(-50, 100);
    new Characteristic::Name("Температура");

    humService = new Service::HumiditySensor();
    hum = new Characteristic::CurrentRelativeHumidity(50.0);
    hum->setRange(0, 100);
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

        fakeTemp += random(-50, 51) / 100.0;
        fakeTemp = constrain(fakeTemp, 18.0, 28.0);

        fakeHum += random(-100, 101) / 100.0;
        fakeHum = constrain(fakeHum, 30.0, 70.0);

        fakePress_mmHg += random(-20, 21) / 10.0;
        fakePress_mmHg = constrain(fakePress_mmHg, 730.0, 790.0);

        fakeGas *= (0.98 + random(41) / 1000.0);
        fakeGas = constrain(fakeGas, 50000.0, 200000.0);

        temp->setVal(fakeTemp);
        hum->setVal(fakeHum);
      }
    }
  }
};

BME68xHub *hub;

void setup() {
  Serial.begin(115200);
  homeSpan.setLogLevel(1);
  homeSpan.begin(Category::Sensors, "BME68x");

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Name("BME68x C3");

  hub = new BME68xHub();
}

void loop() {
  homeSpan.poll();
  hub->loop();
}