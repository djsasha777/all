#include "HomeSpan.h"
#include "Arduino.h"
#include "esp_sleep.h"
#include "driver/rtc_io.h"

// ==================== КОНФИГУРАЦИЯ ====================
#define DOOR_SENSOR_PIN       4       // GPIO4, RTC GPIO на ESP32-S2
#define DEBOUNCE_DELAY        50      // мс
#define STATE_CHECK_INTERVAL  100     // мс
#define SLEEP_AFTER_MS        2000    // мс после закрытия двери

// ==================== СЕРВИС ДАТЧИКА ====================
struct DoorContactSensor : Service::ContactSensor {
  Characteristic::ContactSensorState *contactState;
  uint8_t sensorPin;
  bool lastDoorState;
  unsigned long lastStateChange;

  DoorContactSensor(uint8_t pin) : Service::ContactSensor() {
    sensorPin = pin;
    contactState = new Characteristic::ContactSensorState();

    pinMode(sensorPin, INPUT_PULLUP);
    delay(20);

    // HIGH = геркон разомкнут = дверь открыта
    // HomeKit: 0 = DETECTED (закрыто), 1 = NOT_DETECTED (открыто)
    bool isOpen = digitalRead(sensorPin) == HIGH;
    contactState->setVal(isOpen ? 1 : 0);

    lastDoorState = isOpen;
    lastStateChange = millis();

    Serial.printf("Contact sensor initialized on GPIO %d: %s\n",
                  sensorPin,
                  isOpen ? "OPEN" : "CLOSED");
  }

  bool getDoorState() {
    return digitalRead(sensorPin) == HIGH;
  }

  void updateSensor() {
    bool currentState = getDoorState();

    if (currentState != lastDoorState) {
      delay(DEBOUNCE_DELAY);

      // Подтверждаем состояние после антидребезга
      if (getDoorState() == currentState) {
        lastDoorState = currentState;
        contactState->setVal(currentState ? 1 : 0);
        lastStateChange = millis();

        Serial.printf("Door state changed: %s\n",
                      currentState ? "OPEN" : "CLOSED");
      }
    }
  }

  bool closedLongEnough() {
    return !lastDoorState &&
           (millis() - lastStateChange > SLEEP_AFTER_MS);
  }
};

// ==================== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ====================
DoorContactSensor *doorSensor = nullptr;
bool wifiConnected = false;

// ==================== DEEP SLEEP ====================
void enterDeepSleep() {
  Serial.println("Entering deep sleep...");
  Serial.flush();
  delay(100);

  if (wifiConnected) {
    WiFi.disconnect(true);
    delay(100);
  }

  const gpio_num_t wakePin = (gpio_num_t)DOOR_SENSOR_PIN;

  // Во время deep sleep геркон разомкнут, поэтому включаем RTC pull-up.
  // GPIO4 = HIGH => ESP32-S2 просыпается.
  rtc_gpio_pullup_en(wakePin);
  rtc_gpio_pulldown_dis(wakePin);
  rtc_gpio_set_direction(wakePin, RTC_GPIO_MODE_INPUT_ONLY);

  // EXT1 wakeup: любой выбранный пин в HIGH пробуждает ESP32-S2
  esp_sleep_enable_ext1_wakeup_io(
    1ULL << wakePin,
    ESP_EXT1_WAKEUP_ANY_HIGH
  );

  esp_deep_sleep_start();
}

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n=================================");
  Serial.println("ESP32-S2 Door Sensor - HomeSpan");
  Serial.println("=================================");

  esp_sleep_wakeup_cause_t wakeupReason = esp_sleep_get_wakeup_cause();

  switch (wakeupReason) {
    case ESP_SLEEP_WAKEUP_UNDEFINED:
      Serial.println("Wakeup: cold boot");
      break;

    case ESP_SLEEP_WAKEUP_EXT1:
      Serial.println("Wakeup: EXT1 GPIO (door opened)");
      break;

    default:
      Serial.println("Wakeup: other source");
      break;
  }

  homeSpan.setLogLevel(1);

  homeSpan.begin(Category::Sensors, "Door Sensor");

  // ==================== ACCESSORY ====================
  new SpanAccessory();

  new Service::AccessoryInformation();
  new Characteristic::Identify();
  new Characteristic::Manufacturer("ESP32-S2");
  new Characteristic::Model("Door Sensor v1");
  new Characteristic::SerialNumber("door-sensor-001");
  new Characteristic::FirmwareRevision("1.0.0");

  doorSensor = new DoorContactSensor(DOOR_SENSOR_PIN);

  Serial.println("HomeSpan initialized");
}

// ==================== LOOP ====================
void loop() {
  homeSpan.poll();

  if (WiFi.status() == WL_CONNECTED) {
    if (!wifiConnected) {
      wifiConnected = true;
      Serial.printf("WiFi connected, IP: %s\n",
                    WiFi.localIP().toString().c_str());
    }
  } else {
    wifiConnected = false;
  }

  if (doorSensor) {
    doorSensor->updateSensor();

    // Если дверь закрыта более 2 секунд, уходим в deep sleep
    if (wifiConnected && doorSensor->closedLongEnough()) {
      Serial.println("Door closed for 2+ seconds, entering deep sleep...");
      delay(500); // дать HomeSpan отправить финальное состояние
      enterDeepSleep();
    }
  }

  delay(STATE_CHECK_INTERVAL);
}