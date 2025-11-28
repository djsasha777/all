#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <Update.h>

const char* ap_ssid = "ESP32_AP";
const char* ap_password = "12345678";
const char* hostname = "my-esp32-device";

IPAddress apIP(10,10,10,1);

WebServer mainServer(80);  // основной веб-сервер в режиме STA
WebServer apServer(80);    // вспомогательный веб-сервер в режиме AP

Preferences preferences;

String wifiSSID = "";
String wifiPassword = "";

bool shouldConnectToWiFi = false;

const int outputPin = 4;       // PWM вывод для регулирования яркости
const int buttonPin = 5;
const int ledPin = 6;

int pwmValue = 0;              // Текущее значение яркости (0-255)

bool lastButtonState = HIGH;
unsigned long lastDebounceTime = 0;
const unsigned long debounceDelay = 50;
const unsigned long resetHoldTime = 10000; // 10 секунд удержания кнопки
unsigned long buttonPressTime = 0;
bool resetTriggered = false;

// Мигание светодиода в AP режиме
unsigned long lastLedToggle = 0;
const unsigned long ledInterval = 500; // 500 мс
bool ledOn = false;

// Обработчик установки яркости через /led1/XX (XX в 0..100)
void handleLedValueParam() {
  String path = mainServer.uri(); // например "/led1/50"
  int lastSlash = path.lastIndexOf('/');
  if (lastSlash == -1 || lastSlash == path.length() - 1) {
    mainServer.send(400, "text/plain", "Значение яркости отсутствует");
    return;
  }
  String valueStr = path.substring(lastSlash + 1);
  int value = valueStr.toInt();
  if (value < 0) value = 0;
  if (value > 100) value = 100;
  pwmValue = map(value, 0, 100, 0, 255);
  ledcWrite(0, pwmValue);
  mainServer.send(200, "text/plain", "Яркость установлена: " + String(value));
  Serial.printf("Set PWM via path: %d%% -> PWM: %d\n", value, pwmValue);
}

// Обработчик запроса текущей яркости /led1/status
void handleLedStatus() {
  int statusValue = map(pwmValue, 0, 255, 0, 100);
  if (mainServer.method() == HTTP_GET) {
    mainServer.send(200, "text/plain", String(statusValue));
  } else {
    mainServer.send(405, "text/plain", "Метод не поддерживается");
  }
}

// Вспомогательный сервер AP — корневая страница с возможностью включения/выключения
void handleRoot() {
  String page = "<!DOCTYPE html><html><head><title>Управление пином</title></head><body>";
  page += "<h2>Управление яркостью LED</h2>";
  page += "<form action=\"/toggle\" method=\"POST\">";
  page += "<input type=\"submit\" value=\"" + String(pwmValue > 0 ? "Выключить" : "Включить") + "\">";
  page += "</form></body></html>";
  apServer.send(200, "text/html", page);
}

// Переключает яркость на максимум или выкл
void handleToggle() {
  if (apServer.method() == HTTP_POST) {
    pwmValue = (pwmValue > 0) ? 0 : 255;
    ledcWrite(0, pwmValue);
    apServer.sendHeader("Location", "/");
    apServer.send(303);
  } else {
    apServer.send(405, "text/plain", "Метод не поддерживается");
  }
}

// Возвращает ON если яркость > 0, иначе OFF
void handleState() {
  apServer.send(200, "text/plain", pwmValue > 0 ? "ON" : "OFF");
}

// Сохраняет WiFi параметры
void handleSave() {
  if (apServer.method() == HTTP_POST) {
    wifiSSID = apServer.arg("ssid");
    wifiPassword = apServer.arg("password");
    preferences.begin("wifi-creds", false);
    preferences.putString("ssid", wifiSSID);
    preferences.putString("password", wifiPassword);
    preferences.end();
    String response = "<!DOCTYPE html><html><head><title>Сохранено</title></head><body>";
    response += "<h2>Данные сохранены!</h2>";
    response += "<p>ESP теперь попытается подключиться к сети: " + wifiSSID + "</p>";
    response += "</body></html>";
    apServer.send(200, "text/html", response);
    shouldConnectToWiFi = true;
  } else {
    apServer.send(405, "text/plain", "Метод не поддерживается");
  }
}

// Страница OTA обновления
void handleOTAPage() {
  String page = "<!DOCTYPE html><html><head><title>OTA Update</title></head><body>";
  page += "<h1>OTA обновление прошивки</h1>";
  page += "<form method='POST' action='/update' enctype='multipart/form-data'>";
  page += "<input type='file' name='firmware'>";
  page += "<input type='submit' value='Обновить'>";
  page += "</form></body></html>";
  apServer.send(200, "text/html", page);
}

// Обработка загрузки OTA прошивки
void handleOTAUpload() {
  HTTPUpload& upload = apServer.upload();
  if (upload.status == UPLOAD_FILE_START) {
    Serial.printf("Начало загрузки файла: %s\n", upload.filename.c_str());
    if (!Update.begin()) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (Update.end(true)) {
      Serial.printf("Загрузка прошивки завершена: %u байт\n", upload.totalSize);
      apServer.send(200, "text/plain", "OK, перезагрузка...");
      delay(1000);
      ESP.restart();
    } else {
      Update.printError(Serial);
      apServer.send(500, "text/plain", "Ошибка обновления");
    }
  }
}

void updateLed() {
  if (WiFi.getMode() == WIFI_AP) {
    digitalWrite(ledPin, LOW);
  } else {
    ledcWrite(0, pwmValue);
  }
}

void startAccessPoint() {
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255,255,255,0));
  WiFi.softAP(ap_ssid, ap_password);

  apServer.on("/", handleRoot);
  apServer.on("/toggle", HTTP_POST, handleToggle);
  apServer.on("/state", handleState);
  apServer.on("/save", HTTP_POST, handleSave);
  apServer.on("/update", HTTP_GET, handleOTAPage);
  apServer.on("/update", HTTP_POST, []() {
    apServer.sendHeader("Connection", "close");
  }, handleOTAUpload);

  apServer.begin();

  Serial.println("Точка доступа запущена: " + String(ap_ssid));
  Serial.println("IP: " + WiFi.softAPIP().toString());

  ledOn = false;
  lastLedToggle = millis();
}

void connectToWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.setHostname(hostname);
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());
  Serial.println("Подключение к WiFi: " + wifiSSID);

  unsigned long startAttemptTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 10000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("Подключено к WiFi: " + wifiSSID);
    Serial.print("IP адрес: ");
    Serial.println(WiFi.localIP());

    ledcSetup(0, 5000, 8);
    ledcAttachPin(outputPin, 0);
    updateLed();

    // Регистрируем маршрут с параметром в пути для установки яркости
    mainServer.on("^/led1/([0-9]{1,3})$", HTTP_GET, handleLedValueParam);

    // Статус яркости
    mainServer.on("/led1/status", HTTP_GET, handleLedStatus);

    mainServer.begin();
  } else {
    Serial.println("Не удалось подключиться к WiFi: запуск AP");
    startAccessPoint();
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(outputPin, OUTPUT);
  digitalWrite(outputPin, LOW);

  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);

  lastButtonState = digitalRead(buttonPin);

  preferences.begin("wifi-creds", true);
  wifiSSID = preferences.getString("ssid", "");
  wifiPassword = preferences.getString("password", "");
  preferences.end();

  if (wifiSSID.length() > 0 && wifiPassword.length() > 0) {
    connectToWiFi();
  } else {
    startAccessPoint();
  }
}

void loop() {
  if (WiFi.getMode() == WIFI_AP) {
    apServer.handleClient();

    unsigned long now = millis();
    if (now - lastLedToggle >= ledInterval) {
      ledOn = !ledOn;
      digitalWrite(ledPin, ledOn ? HIGH : LOW);
      lastLedToggle = now;
    }
  } else if (WiFi.getMode() == WIFI_STA) {
    mainServer.handleClient();
  }

  int reading = digitalRead(buttonPin);
  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading == LOW && !resetTriggered) {
      if (buttonPressTime == 0) {
        buttonPressTime = millis();
      } else {
        unsigned long held = millis() - buttonPressTime;
        if (held >= resetHoldTime) {
          preferences.begin("wifi-creds", false);
          preferences.clear();
          preferences.end();
          Serial.println("Сброс сохраненных WiFi данных. Перезагрузка...");
          resetTriggered = true;
          delay(1000);
          ESP.restart();
        }
      }
    } else if (reading == HIGH) {
      if (!resetTriggered && buttonPressTime != 0) {
        pwmValue = (pwmValue > 0) ? 0 : 255;
        updateLed();
        Serial.println("Физическая кнопка нажата, PWM изменено на " + String(pwmValue));
      }
      buttonPressTime = 0;
      resetTriggered = false;
    }
  }
  lastButtonState = reading;
}
