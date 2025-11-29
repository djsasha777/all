#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <EEPROM.h>
#include <Updater.h>
#ifndef D4
#define D4 2
#endif

const int output = D4;
const int ledPin = LED_BUILTIN;

ESP8266WebServer server(80);

String wifiSSID = "";
String wifiPassword = "";

void saveWiFiCredentials(const String& ssid, const String& pass) {
  EEPROM.begin(512);
  for (int i = 0; i < 32; i++) EEPROM.write(i, 0);
  for (int i = 0; i < 64; i++) EEPROM.write(100 + i, 0);
  for (int i = 0; i < ssid.length() && i < 31; i++) EEPROM.write(i, ssid[i]);
  EEPROM.write(ssid.length(), 0);
  for (int i = 0; i < pass.length() && i < 63; i++) EEPROM.write(100 + i, pass[i]);
  EEPROM.write(100 + pass.length(), 0);
  EEPROM.commit();
  Serial.println("WiFi credentials saved");
}

void loadWiFiCredentials() {
  char ssid[32];
  char pass[64];
  EEPROM.begin(512);
  for (int i = 0; i < 31; i++) {
    ssid[i] = EEPROM.read(i);
    if (ssid[i] == 0) break;
  }
  ssid[31] = 0;
  for (int i = 0; i < 63; i++) {
    pass[i] = EEPROM.read(100 + i);
    if (pass[i] == 0) break;
  }
  pass[63] = 0;
  wifiSSID = String(ssid);
  wifiPassword = String(pass);
}

// Регистрируем маршруты основного сервера в режиме STA, сохраняя логику управления пином
void setupSTAWebRoutes() {
  server.on("/button1/on", []() {
    digitalWrite(output, HIGH);
    delay(200);
    digitalWrite(output, LOW);
    Serial.println("Pin D4 pulse 200ms ON");
    server.send(200, "text/html", "OK");
  });

  server.on("/button2/long", []() {
    digitalWrite(output, HIGH);
    delay(5000);
    digitalWrite(output, LOW);
    Serial.println("Pin D4 long pulse 5s ON");
    server.send(200, "text/html", "OK");
  });

  // Корневая страница просто для отображения ссылок (можно изменить по запросу)
  server.on("/", []() {
    String page =
      "<!DOCTYPE html><html><head><title>ESP8266 Control</title></head><body>"
      "<h1>ESP8266 KVM</h1>"
      "<p><a href=\"/button1/on\"><button>POWER ON</button></a></p>"
      "<p><a href=\"/button2/long\"><button>LONG PRESS</button></a></p>"
      "</body></html>";
    server.send(200, "text/html", page);
  });
}

// Вспомогательные маршруты для AP - WiFi конфигурация и OTA
void setupAPWebRoutes() {
  server.on("/", []() {
    String page = "<html><body><h1>Configure WiFi</h1>";
    page += "<form action='/save' method='POST'>";
    page += "SSID:<br><input name='ssid' length=32><br>";
    page += "Password:<br><input name='password' type='password' length=64><br>";
    page += "<input type='submit' value='Save'>";
    page += "</form></body></html>";
    server.send(200, "text/html", page);
  });

  server.on("/save", HTTP_POST, []() {
    wifiSSID = server.arg("ssid");
    wifiPassword = server.arg("password");
    saveWiFiCredentials(wifiSSID, wifiPassword);
    server.send(200, "text/html", "<html><body><h1>Saved! Rebooting...</h1></body></html>");
    delay(2000);
    ESP.restart();
  });

  server.on("/update", HTTP_GET, []() {
    String page = "<html><body><h1>OTA Update</h1>";
    page += "<form method='POST' action='/update' enctype='multipart/form-data'>";
    page += "<input type='file' name='update'><br>";
    page += "<input type='submit' value='Update'>";
    page += "</form></body></html>";
    server.send(200, "text/html", page);
  });

  server.on("/update", HTTP_POST, []() {
    server.sendHeader("Connection", "close");
    server.send(200, "text/plain", (Update.hasError()) ? "Update Failed" : "Update Success. Restarting...");
    ESP.restart();
  }, []() {
    HTTPUpload& upload = server.upload();
    if (upload.status == UPLOAD_FILE_START) {
      Serial.printf("Update Start: %s\n", upload.filename.c_str());
      if (!Update.begin(upload.totalSize)) {
        Update.printError(Serial);
      }
    } else if (upload.status == UPLOAD_FILE_WRITE) {
      if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
        Update.printError(Serial);
      }
    } else if (upload.status == UPLOAD_FILE_END) {
      if (Update.end(true)) {
        Serial.println("Update Completed.");
      } else {
        Update.printError(Serial);
      }
    }
  });
}

void startAP() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP("ESP8266_AP", "12345678");
  IPAddress apIP(10, 10, 10, 1);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255, 255, 255, 0));

  Serial.print("Access Point started. IP: ");
  Serial.println(WiFi.softAPIP());

  server.stop();
  setupAPWebRoutes();
  server.begin();
}

void connectSTA() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());

  Serial.print("Connecting to WiFi ");
  Serial.println(wifiSSID);

  unsigned long startAttemptTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 10000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("Connected to WiFi.");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    server.stop();
    setupSTAWebRoutes();
    server.begin();
  } else {
    Serial.println("Failed to connect; starting AP.");
    startAP();
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(output, OUTPUT);
  digitalWrite(output, LOW);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);

  loadWiFiCredentials();

  if (wifiSSID.length() > 0 && wifiPassword.length() > 0) {
    connectSTA();
  } else {
    startAP();
  }
}

void loop() {
  server.handleClient();
}
