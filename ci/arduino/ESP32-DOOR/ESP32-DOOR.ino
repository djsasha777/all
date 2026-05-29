#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include "esp_sleep.h"
#include "esp_system.h"

// --- Настройки ---
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASS";
const char* SERVER_IP = "192.168.1.1";
const int SERVER_PORT = 80;

// Пин геркона (толькоGPIO с возможностью wakeup: 32–39 для ext0)
const int GERKON_PIN = 34;  // GPIO34 - только ввод, подходит для wakeup

// Логика:
// Замыкание геркона -> пробуждение -> считаем это "открытием двери" -> true
// Если через 5 сек геркон разомкнут -> false
bool readDoorState() {
  int val = digitalRead(GERKON_PIN);
  // Подстрой под свою схему:
  // Если при замкнутом герконе GPIO = LOW ->Opened = LOW
  return (val == LOW);  // true = замкнут (открыто)
}

void sendHttpRequest(const char* value) {
  HTTPClient http;
  String url = "http://" + String(SERVER_IP) + "/sensor1/" + String(value);

  http.begin(url);
  int httpCode = http.GET();
  if (httpCode > 0) {
    // Успех
    // Serial.printf("HTTP response: %d\n", httpCode);
  } else {
    // Ошибка
    // Serial.printf("HTTP error: %s\n", http.errorToString(httpCode).c_str());
  }
  http.end();
}

void goToSleep() {
  Serial.println("Entering deep sleep, waiting for gerkon closure...");
  // Включаем пробуждение по одному GPIO (ext0)
  // GPIO должен быть из списка: 32–39
  esp_sleep_enable_ext0_wakeup((gpio_num_t)GERKON_PIN, 0);  // 0 = пробуждение при LOW

  esp_deep_sleep_start();
}

void setup() {
  Serial.begin(115200);
  delay(100);

  pinMode(GERKON_PIN, INPUT);  // или INPUT_PULLUP, если нужна подтяжка

  // Определяем, было ли пробуждение из deep sleep
  esp_sleep_wakeup_cause_t wakeup_reason = esp_sleep_get_wakeup_cause();

  if (wakeup_reason == ESP_SLEEP_WAKEUP_EXT0) {
    Serial.println("Woke up from deep sleep by GPIO (gerkon)");
  } else {
    Serial.println("Booting normally (first power or reset)");
  }

  // Подключение к Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  Serial.println();

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi connection failed, going to sleep");
    goToSleep();
    return;
  }

  // При пробуждении считаем, что дверь открылась (геркон замкнулся)
  bool doorOpen = true;
  Serial.println("Door opened (gerkon closed), sending true");
  sendHttpRequest("true");

  // Ждём 5 секунд
  Serial.println("Waiting 5 seconds before recheck...");
  delay(5000);

  bool stateAfter5s = readDoorState();
  Serial.printf("Recheck gerkon state: %s\n", stateAfter5s ? "CLOSED (open)" : "OPEN (closed)");

  if (!stateAfter5s) {
    // Через 5 сек геркон разомкнулся → дверь закрылась
    Serial.println("Door closed after 5s, sending false");
    sendHttpRequest("false");
  } else {
    Serial.println("Gerkon still closed, no second event");
  }

  WiFi.disconnect(true);
  goToSleep();
}

void loop() {
  // Пустой, всегда уходим в deep sleep
}