#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <Update.h>

const char* ap_ssid = "ESP32_AP";
const char* ap_password = "12345678";
const char* default_hostname = "my-esp32-device";

IPAddress apIP(10,10,10,1);

WebServer mainServer(80);  // главный веб-сервер в STA режиме
WebServer apServer(80);    // вспомогательный веб-сервер в AP режиме

Preferences preferences;

String wifiSSID = "";
String wifiPassword = "";
String wifiHostname = "";

bool shouldConnectToWiFi = false;

const int outputPin = 4;
const int buttonPin = 5;
const int ledPin = 15;

bool outputState = false;
bool lastButtonState = HIGH;

unsigned long lastDebounceTime = 0;
const unsigned long debounceDelay = 50;

const unsigned long resetHoldTime = 10000; // 10 секунд удержания кнопки
unsigned long buttonPressTime = 0;
bool resetTriggered = false;

unsigned long lastLedToggle = 0;
const unsigned long ledInterval = 500; // 500 мс
bool ledOn = false;

// ======= Обработчики кнопок Main Server (API) =======

// Включить пин
void handleButtonOn() {
  if (mainServer.method() == HTTP_GET) {
    outputState = true;
    digitalWrite(outputPin, HIGH);
    updateLed();
    mainServer.send(200, "text/plain", "Button 1 ON");
  } else {
    mainServer.send(405, "text/plain", "Method not allowed");
  }
}

// Выключить пин
void handleButtonOff() {
  if (mainServer.method() == HTTP_GET) {
    outputState = false;
    digitalWrite(outputPin, LOW);
    updateLed();
    mainServer.send(200, "text/plain", "Button 1 OFF");
  } else {
    mainServer.send(405, "text/plain", "Method not allowed");
  }
}

// Статус пина
void handleButtonStatus() {
  if (mainServer.method() == HTTP_GET) {
    String stateString = outputState ? "ON" : "OFF";
    mainServer.send(200, "text/plain", stateString);
  } else {
    mainServer.send(405, "text/plain", "Method not allowed");
  }
}

// ======= Страницы управления =======

// Главная страница: кнопка переключения пина и кнопка перехода в настройки (/config)
void handleRoot() {
  String page = "<!DOCTYPE html><html><head><title>ESP32 Control</title></head><body>";
  page += "<h2>Pin Control</h2>";
  page += "<p>Current pin state: " + String(outputState ? "ON" : "OFF") + "</p>";
  page += "<form action='/toggle' method='POST'>";
  page += "<input type='submit' value='" + String(outputState ? "Turn OFF" : "Turn ON") + "'>";
  page += "</form><br>";
  page += "<form action='/config' method='GET'>";
  page += "<input type='submit' value='Go to Configuration'>";
  page += "</form>";
  page += "</body></html>";
  mainServer.send(200, "text/html", page);
}

// Переключение пина по кнопке на главной странице
void handleTogglePin() {
  outputState = !outputState;
  digitalWrite(outputPin, outputState ? HIGH : LOW);
  updateLed();

  String page = "<!DOCTYPE html><html><head><title>Pin Toggle</title></head><body>";
  page += "<h2>Pin state changed to " + String(outputState ? "ON" : "OFF") + "</h2>";
  page += "<a href='/'>Back</a>";
  page += "</body></html>";
  mainServer.send(200, "text/html", page);
}

// Страница настроек по маршруту /config (доступна и в AP и в STA)
void handleConfig() {
  String page = "<!DOCTYPE html><html><head><title>ESP32 Configuration</title></head><body>";
  page += "<h2>Setup WiFi and Hostname</h2>";
  page += "<form action=\"/save\" method=\"POST\">";
  page += "SSID: <input type=\"text\" name=\"ssid\" value=\"" + wifiSSID + "\"><br>";
  page += "Password: <input type=\"password\" name=\"password\" value=\"" + wifiPassword + "\"><br>";
  page += "Hostname: <input type=\"text\" name=\"hostname\" value=\"" + wifiHostname + "\"><br>";
  page += "<input type=\"submit\" value=\"Save\">";
  page += "</form>";
  page += "<h3>Firmware Update</h3>";
  page += "<form action=\"/update\" method=\"GET\">";
  page += "<input type=\"submit\" value=\"Go to OTA Update\">";
  page += "</form>";
  page += "<hr><a href='/'>Back to Control</a>";
  page += "</body></html>";

  if (apServer.client())
    apServer.send(200, "text/html", page);
  else
    mainServer.send(200, "text/html", page);
}

// Сохраняем настройки WiFi и hostname
void handleSave() {
  String ssid = "";
  String password = "";
  String hostname = "";

  if (apServer.client()) {
    if (apServer.method() != HTTP_POST) {
      apServer.send(405, "text/plain", "Method not allowed");
      return;
    }
    ssid = apServer.arg("ssid");
    password = apServer.arg("password");
    hostname = apServer.arg("hostname");
  } else if (mainServer.client()) {
    if (mainServer.method() != HTTP_POST) {
      mainServer.send(405, "text/plain", "Method not allowed");
      return;
    }
    ssid = mainServer.arg("ssid");
    password = mainServer.arg("password");
    hostname = mainServer.arg("hostname");
  }

  wifiSSID = ssid;
  wifiPassword = password;
  wifiHostname = hostname;

  preferences.begin("wifi-creds", false);
  preferences.putString("ssid", wifiSSID);
  preferences.putString("password", wifiPassword);
  preferences.putString("hostname", wifiHostname);
  preferences.end();

  String response = "<!DOCTYPE html><html><head><title>Saved</title></head><body>";
  response += "<h2>Data saved!</h2>";
  response += "<p>ESP will now try to connect to network: " + wifiSSID + "</p>";
  response += "<p>New hostname: " + wifiHostname + "</p>";
  response += "<a href='/config'>Back to Configuration</a>";
  response += "</body></html>";

  if (apServer.client()) {
    apServer.send(200, "text/html", response);
  } else {
    mainServer.send(200, "text/html", response);
  }

  shouldConnectToWiFi = true;
}

// OTA Update страница
void handleOTAPage() {
  String page = "<!DOCTYPE html><html><head><title>OTA Update</title></head><body>";
  page += "<h1>OTA Firmware Update</h1>";
  page += "<form method='POST' action='/update' enctype='multipart/form-data'>";
  page += "<input type='file' name='firmware'>";
  page += "<input type='submit' value='Update'>";
  page += "</form></body></html>";

  if (apServer.client())
    apServer.send(200, "text/html", page);
  else
    mainServer.send(200, "text/html", page);
}

// OTA Update загрузка
void handleOTAUpload() {
  HTTPUpload& upload = (apServer.client()) ? apServer.upload() : mainServer.upload();

  if (upload.status == UPLOAD_FILE_START) {
    Serial.printf("Start uploading file: %s\n", upload.filename.c_str());
    if (!Update.begin()) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (Update.end(true)) {
      Serial.printf("Firmware update complete: %u bytes\n", upload.totalSize);
      if (apServer.client())
        apServer.send(200, "text/plain", "OK, restarting...");
      else
        mainServer.send(200, "text/plain", "OK, restarting...");
      delay(1000);
      ESP.restart();
    } else {
      Update.printError(Serial);
      if (apServer.client())
        apServer.send(500, "text/plain", "Update error");
      else
        mainServer.send(500, "text/plain", "Update error");
    }
  }
}

// Общие функции
void updateLed() {
  if (WiFi.getMode() == WIFI_AP) {
    digitalWrite(ledPin, LOW);
  } else {
    digitalWrite(ledPin, outputState ? HIGH : LOW);
  }
}

void startAccessPoint() {
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255,255,255,0));
  WiFi.softAP(ap_ssid, ap_password);

  apServer.on("/", []() {
    // Главная страница AP: кнопки включения/выключения пина и перехода в настройки
    String page = "<!DOCTYPE html><html><head><title>ESP32 AP Control</title></head><body>";
    page += "<h2>Pin Control (AP)</h2>";
    page += "<p>Current pin state: " + String(outputState ? "ON" : "OFF") + "</p>";
    page += "<form action='/toggle' method='POST'>";
    page += "<input type='submit' value='" + String(outputState ? "Turn OFF" : "Turn ON") + "'>";
    page += "</form><br>";
    page += "<form action='/config' method='GET'>";
    page += "<input type='submit' value='Go to Configuration'>";
    page += "</form></body></html>";
    apServer.send(200, "text/html", page);
  });

  apServer.on("/toggle", []() {
    if (apServer.method() == HTTP_POST) {
      outputState = !outputState;
      digitalWrite(outputPin, outputState ? HIGH : LOW);
      updateLed();
      apServer.sendHeader("Location", "/");
      apServer.send(303);
    } else {
      apServer.send(405, "text/plain", "Method not allowed");
    }
  });

  apServer.on("/save", HTTP_POST, handleSave);
  apServer.on("/config", handleConfig);
  apServer.on("/update", HTTP_GET, handleOTAPage);
  apServer.on("/update", HTTP_POST, []() { apServer.sendHeader("Connection", "close"); }, handleOTAUpload);

  apServer.begin();
  Serial.println("Access point started: " + String(ap_ssid));
  Serial.println("IP: " + WiFi.softAPIP().toString());

  ledOn = false;
  lastLedToggle = millis();
}

void connectToWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.setHostname(wifiHostname.length() ? wifiHostname.c_str() : default_hostname);
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());
  Serial.println("Connecting to WiFi: " + wifiSSID);

  unsigned long startAttemptTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 10000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("Connected to WiFi: " + wifiSSID);
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    // Обработчики главного сервера
    mainServer.on("/", handleRoot);
    mainServer.on("/toggle", HTTP_POST, handleTogglePin);
    mainServer.on("/config", handleConfig);
    mainServer.on("/save", HTTP_POST, handleSave);
    mainServer.on("/update", HTTP_GET, handleOTAPage);
    mainServer.on("/update", HTTP_POST, []() { mainServer.sendHeader("Connection", "close"); }, handleOTAUpload);

    // Возвращаем API-обработчики для button1 и status
    mainServer.on("/button1/on", handleButtonOn);
    mainServer.on("/button1/off", handleButtonOff);
    mainServer.on("/button1/status", handleButtonStatus);

    mainServer.begin();
    updateLed();
  } else {
    Serial.println("Failed to connect to WiFi");
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
  wifiHostname = preferences.getString("hostname", default_hostname);
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
          Serial.println("WiFi credentials cleared, restarting...");
          resetTriggered = true;
          delay(1000);
          ESP.restart();
        }
      }
    } else if (reading == HIGH) {
      if (!resetTriggered && buttonPressTime != 0) {
        outputState = !outputState;
        digitalWrite(outputPin, outputState ? HIGH : LOW);
        updateLed();
        Serial.println("Physical button pressed, pin 4 state changed to " + String(outputState ? "ON" : "OFF"));
      }
      buttonPressTime = 0;
      resetTriggered = false;
    }
  }
  lastButtonState = reading;

  if (shouldConnectToWiFi) {
    shouldConnectToWiFi = false;
    WiFi.disconnect(true);
    delay(1000);
    connectToWiFi();
  }
}
