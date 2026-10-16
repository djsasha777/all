#include "HomeSpan.h"
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include "Adafruit_BME680.h"
#include <WiFi.h>


struct BME68xHub : Service::TemperatureSensor {
  SpanCharacteristic *temp, *hum;
  Service::HumiditySensor *humService;

  unsigned long lastUpdate;
  float temperature, humidity;
  float pressure_mmHg, gas_resistance;
  Adafruit_BME680 bme;
  bool bmeOk;

  BME68xHub() : Service::TemperatureSensor() {
    temp = new Characteristic::CurrentTemperature(22.0);
    temp->setRange(-50, 100);
    new Characteristic::Name("Температура");

    humService = new Service::HumiditySensor();
    hum = new Characteristic::CurrentRelativeHumidity(50.0);
    hum->setRange(0, 100);
    new Characteristic::Name("Влажность");

    lastUpdate = 0;
    temperature = 0;
    humidity = 0;
    pressure_mmHg = 0;
    gas_resistance = 0;
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

    if (!bmeOk || now - lastUpdate <= 5000)
      return;

    lastUpdate = now;
    bme.setGasHeater(320, 150);

    if (!bme.performReading()) {
      LOG1("Error reading BME680\n");
      return;
    }

    temperature = bme.temperature - 6.0f;
    humidity = bme.humidity + 13.0f;
    humidity = constrain(humidity, 0.0f, 100.0f);

    pressure_mmHg = bme.pressure / 133.322f;
    gas_resistance = bme.gas_resistance / 1000.0f;

    temp->setVal(temperature);
    hum->setVal(humidity);

    LOG1("T%0.1f C  H%0.1f %%  P%0.1f mmHg  G%0.0f kOhm\n",
         temperature, humidity, pressure_mmHg, gas_resistance);
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