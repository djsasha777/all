#include "HomeSpan.h"
#include "Arduino.h"

// ==================== КОНФИГУРАЦИЯ ====================
#define DOOR_SENSOR_PIN     4                   // GPIO для геркона

// Порог времени для проверки состояния (мс)
#define DEBOUNCE_DELAY      50
#define STATE_CHECK_INTERVAL 100

// ==================== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ====================
bool lastDoorState = false;                     // false = закрыто, true = открыто
unsigned long lastStateChange = 0;
bool wifiConnected = false;

// ==================== СЕРВИС ДАТЧИКА КОНТАКТА ====================
struct ContactSensor : Service::ContactSensor {
    ContactState *contactState;
    uint8_t sensorPin;
    
    ContactSensor(uint8_t pin) : Service::ContactSensor() {
        sensorPin = pin;
        contactState = new ContactState();
        
        // Настраиваем GPIO с внутренним pull-up
        pinMode(sensorPin, INPUT_PULLUP);
        
        // Начальное состояние (инвертировано: LOW = закрыто = 0)
        bool initialState = digitalRead(sensorPin) == HIGH;
        contactState->setVal(initialState);
        lastDoorState = initialState;
        lastStateChange = millis();
        
        Serial.print("Initializing Contact Sensor (PIN ");
        Serial.print(sensorPin);
        Serial.println(")");
    }
    
    bool getDoorState() {
        // HIGH = дверь открыта, LOW = дверь закрыта (из-за pull-up)
        return digitalRead(sensorPin) == HIGH;
    }
    
    void updateSensor() {
        bool currentState = getDoorState();
        
        if (currentState != lastDoorState) {
            // Антидребезг
            delay(DEBOUNCE_DELAY);
            if (getDoorState() == currentState) {
                lastDoorState = currentState;
                contactState->setVal(currentState);
                lastStateChange = millis();
                
                Serial.print("Door state changed: ");
                Serial.println(currentState ? "OPEN" : "CLOSED");
            }
        }
    }
};

// ==================== ФУНКЦИЯ ГЛУБОКОГО СНА ====================
void enterDeepSleep() {
    Serial.println("Entering deep sleep...");
    Serial.flush();
    
    // Отключаем WiFi перед сном
    if (wifiConnected) {
        WiFi.disconnect(true);
        delay(100);
    }
    
    // Конфигурируем GPIO 4 для пробуждения по HIGH уровню
    // (геркон разомкнут = дверь открыта)
    esp_deep_sleep_enable_gpio_wakeup(1ULL << DOOR_SENSOR_PIN, ESP_GPIO_WAKEUP_GPIO_HIGH);
    
    // Отключаем pull-up перед сном для экономии энергии
    gpio_pullup_dis((gpio_num_t)DOOR_SENSOR_PIN);
    gpio_pulldown_en((gpio_num_t)DOOR_SENSOR_PIN);
    
    // Запускаем глубокий сон
    esp_deep_sleep_start();
}

// ==================== SETUP ====================
void setup() {
    Serial.begin(115200);
    
    Serial.println("\n=================================");
    Serial.println("ESP32-C3 Door Sensor - HomeSpan");
    Serial.println("=================================");
    
    // Проверяем причину пробуждения
    esp_sleep_wakeup_reason_t wakeupReason = esp_sleep_get_wakeup_cause();
    
    Serial.print("Wakeup reason: ");
    switch(wakeupReason) {
        case ESP_SLEEP_WAKEUP_UNDEFINED:
            Serial.println("Cold boot (first start)");
            break;
        case ESP_SLEEP_WAKEUP_GPIO:
            Serial.println("GPIO wakeup (door opened!)");
            break;
        default:
            Serial.println("Other wakeup source");
            break;
    }
    
    // Инициализируем HomeSpan с автоматической настройкой WiFi
    homeSpan.setLogLevel(1);
    
    // Включаем режим STA (клиент WiFi) для HomeSpan
    homeSpan.autoStartAP();
    
    // Создаем устройство
    new Span();
    
    new Accessory()
        .addService(new Service::AccessoryInformation())
            .set<Characteristic::Identify>(1)
            .set<Characteristic::Manufacturer>("ESP32-C3")
            .set<Characteristic::Model>("Door Sensor v1")
            .set<Characteristic::SerialNumber>("door-sensor-001")
            .set<Characteristic::FirmwareRevision>("1.0.0")
        .addService(new ContactSensor(DOOR_SENSOR_PIN));
    
    homeSpan.begin(Category::Sensors, "Door Sensor");
    
    Serial.println("HomeSpan initialized!");
    
    // Проверяем, подключен ли WiFi
    if (WiFi.status() == WL_CONNECTED) {
        wifiConnected = true;
        Serial.print("WiFi connected! IP: ");
        Serial.println(WiFi.localIP());
    } else {
        wifiConnected = false;
        Serial.println("WiFi not connected - will enter sleep");
    }
}

// ==================== MAIN LOOP ====================
void loop() {
    homeSpan.poll();
    
    // Проверяем статус WiFi
    if (WiFi.status() != WL_CONNECTED) {
        wifiConnected = false;
    } else if (!wifiConnected) {
        wifiConnected = true;
        Serial.print("WiFi connected! IP: ");
        Serial.println(WiFi.localIP());
    }
    
    // Получаем доступ к сервису датчика
    ContactSensor *sensor = (ContactSensor*)homeSpan.getService("ContactSensor");
    
    if (sensor) {
        sensor->updateSensor();
        
        // Если WiFi подключен и дверь закрыта уже более 2 секунд, уходим в сон
        if (wifiConnected && !lastDoorState && (millis() - lastStateChange > 2000)) {
            Serial.println("Door closed for 2+ seconds, entering deep sleep...");
            delay(500); // Даем время на отправку последнего состояния в HomeKit
            enterDeepSleep();
        }
    }
    
    delay(STATE_CHECK_INTERVAL);
}