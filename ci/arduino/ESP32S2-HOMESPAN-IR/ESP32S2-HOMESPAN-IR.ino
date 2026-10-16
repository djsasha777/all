#include <Arduino.h>
#include "HomeSpan.h"
#include <WiFi.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ir_Midea.h>

// GPIO, к которому подключён ИК-светодиод
constexpr uint8_t IR_PIN = 16;

// Объект для отправки команд по протоколу Midea
IRMideaAC mideaAC(IR_PIN);

// Указатель на характеристику включения/выключения
SpanCharacteristic *acChar = nullptr;

// Отправка команды кондиционеру
void sendACPower(bool on) {
  Serial.printf(
    "sendACPower() called: %s\n",
    on ? "ON" : "OFF"
  );

  // Сбрасываем состояние перед формированием новой команды
  mideaAC.stateReset();

  // Работаем в градусах Цельсия
  mideaAC.setUseCelsius(true);

  if (on) {
    mideaAC.setPower(true);
  } else {
    mideaAC.setPower(false);             // Выключение
  }

  // Отправляем ИК-команду
  mideaAC.send();

  Serial.printf(
    "IR: Midea/Comfee AC %s sent\n",
    on ? "ON (Dry 23C Auto)" : "OFF"
  );
}

// HomeKit-сервис: обычный переключатель
struct ACService : Service::Switch {
  ACService() : Service::Switch() {
    // Характеристика On: true = включено, false = выключено
    acChar = new Characteristic::On();

    // Имя, которое будет видно в приложении «Дом»
    new Characteristic::Name("Кондиционер");

    Serial.println("ACService created");
  }

  // Вызывается HomeSpan, когда iOS меняет состояние переключателя
  boolean update() override {
    // Новое значение из HomeKit:
    // true  -> пользователь включил кондиционер
    // false -> пользователь выключил кондиционер
    bool power = acChar->getNewVal();

    Serial.printf(
      "HomeKit update received: AC=%s\n",
      power ? "ON" : "OFF"
    );

    // Отправляем соответствующую ИК-команду
    sendACPower(power);

    // Сообщаем HomeSpan, что команда принята успешно
    return true;
  }
};

ACService *acService = nullptr;

void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println();
  Serial.println("Starting ESP32-S2 HomeSpan IR Switch (Midea)");

  // Инициализация ИК-передатчика
  mideaAC.begin();
  mideaAC.stateReset();

  // Запуск HomeSpan
  homeSpan.begin(
    Category::Switches,
    "AC IR Switch"
  );

  // Создаём аксессуар
  new SpanAccessory();

  // Обязательная информация об аксессуаре
  new Service::AccessoryInformation();
  new Characteristic::Name("Кондиционер");
  new Characteristic::Identify();

  // Добавляем переключатель кондиционера
  acService = new ACService();

  Serial.println("Setup completed");
}

void loop() {
  // Обработка HomeKit-соединений и команд
  homeSpan.poll();
}