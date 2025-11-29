#include <WiFi.h>
#include <WebServer.h>
#include <Update.h>
#include <Preferences.h>

const char* ap_ssid = "ESP32_AP";
const char* ap_password = "12345678";
const char* hostname = "esp32-switch";

IPAddress apIP(10, 10, 10, 1);

WebServer server(80);
Preferences preferences;

int outputPin1 = 33; 
int outputPin2 = 21;
int outputPin3 = 32;

String wifiSSID = "";
String wifiPassword = "";

bool shouldConnectToWiFi = false;
unsigned long previousMillis = 0;
const unsigned long interval = 30000;

void handleRoot() {
  String page = "<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width, initial-scale=1'>";
  page += "<style>html { font-family: Helvetica; text-align: center; } ";
  page += ".button { background-color: #195B6A; border: none; color: white; padding: 16px 40px; font-size: 30px; margin: 2px; cursor: pointer;}</style>";
  page += "</head><body><h1>SPONGO SWITCH</h1>";
  page += "<p><a href='/button1/on'><button class='button'>POWER ON</button></a></p>";
  page += "<p><a href='/button1/off'><button class='button'>POWER OFF</button></a></p>";
  page += "<p><a href='/button2/on'><button class='button'>1 POWER ON</button></a></p>";
  page += "<p><a href='/button2/off'><button class='button'>1 POWER OFF</button></a></p>";
  page += "<p><a href='/button3/on'><button class='button'>2 POWER ON</button></a></p>";
  page += "<p><a href='/button3/off'><button class='button'>2 POWER OFF</button></a></p>";
  page += "</body></html>";
  server.send(200, "text/html", page);
}

void handleButton1On() {
  digitalWrite(outputPin1, LOW);
  server.send(200, "text/html", "Button1 ON done");
}

void handleButton1Off() {
  digitalWrite(outputPin1, HIGH);
  server.send(200, "text/html", "Button1 OFF done");
}

void handleButton2On() {
  digitalWrite(outputPin2, HIGH);
  server.send(200, "text/html", "Button2 ON done");
}

void handleButton2Off() {
  digitalWrite(outputPin2, LOW);
  server.send(200, "text/html", "Button2 OFF done");
}

void handleButton3On() {
  digitalWrite(outputPin3, HIGH);
  server.send(200, "text/html", "Button3 ON done");
}

void handleButton3Off() {
  digitalWrite(outputPin3, LOW);
  server.send(200, "text/html", "Button3 OFF done");
}

// Дополнительные обработчики состояния
void handleButton1Status() {
  String state = digitalRead(outputPin1) == LOW ? "ON" : "OFF";
  server.send(200, "text/plain", state);
}

void handleButton2Status() {
  String state = digitalRead(outputPin2) == HIGH ? "ON" : "OFF";
  server.send(200, "text/plain", state);
}

void handleButton3Status() {
  String state = digitalRead(outputPin3) == HIGH ? "ON" : "OFF";
  server.send(200, "text/plain", state);
}

void handleSave() {
  if (server.method() == HTTP_POST) {
    wifiSSID = server.arg("ssid");
    wifiPassword = server.arg("password");
    preferences.begin("wifi-creds", false);
    preferences.putString("ssid", wifiSSID);
    preferences.putString("password", wifiPassword);
    preferences.end();
    server.send(200, "text/html", "<html><body><h2>Credentials saved. Rebooting...</h2></body></html>");
    delay(2000);
    ESP.restart();
  } else {
    server.send(405, "text/plain", "Method Not Allowed");
  }
}

void handleOTAPage() {
  String page = "<html><body><h1>OTA Update</h1>";
  page += "<form method='POST' action='/update' enctype='multipart/form-data'>";
  page += "<input type='file' name='update'><br>";
  page += "<input type='submit' value='Update'>";
  page += "</form></body></html>";
  server.send(200, "text/html", page);
}

void handleOTAUpload() {
  HTTPUpload& upload = server.upload();
  if (upload.status == UPLOAD_FILE_START) {
    Serial.printf("OTA Update Start: %s\n", upload.filename.c_str());
    if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (Update.end(true)) {
      Serial.printf("OTA Update Ended: %u bytes\n", upload.totalSize);
      server.send(200, "text/plain", "Update Success. Rebooting...");
      delay(1000);
      ESP.restart();
    } else {
      Update.printError(Serial);
      server.send(500, "text/plain", "Update Failed");
    }
  }
}

void startAccessPoint() {
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255, 255, 255, 0));
  WiFi.softAP(ap_ssid, ap_password);
  Serial.println("Access Point started: " + String(ap_ssid));
  Serial.println("IP: " + WiFi.softAPIP().toString());

  // Настройка маршрутов вспомогательного сервера (AP режим)
  server.on("/", HTTP_GET, []() {
    String page = "<html><body><h1>Configure WiFi</h1>";
    page += "<form action='/save' method='POST'>";
    page += "SSID: <input name='ssid' length=32><br>";
    page += "Password: <input name='password' type='password' length=64><br>";
    page += "<input type='submit' value='Save'>";
    page += "</form></body></html>";
    server.send(200, "text/html", page);
  });

  server.on("/save", HTTP_POST, handleSave);
  server.on("/update", HTTP_GET, handleOTAPage);
  server.on("/update", HTTP_POST, []() { server.sendHeader("Connection", "close"); server.send(200); }, handleOTAUpload);

  server.begin();
}

void connectToWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());
  Serial.println("Connecting to WiFi: " + wifiSSID);

  unsigned long startAttemptTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 10000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("Connected.");
    Serial.print("IP: "); Serial.println(WiFi.localIP());

    // Настройка маршрутов основного сервера (STA режим)
    server.on("/", HTTP_GET, handleRoot);
    server.on("/button1/on", HTTP_GET, handleButton1On);
    server.on("/button1/off", HTTP_GET, handleButton1Off);
    server.on("/button1/status", HTTP_GET, handleButton1Status);
    server.on("/button2/on", HTTP_GET, handleButton2On);
    server.on("/button2/off", HTTP_GET, handleButton2Off);
    server.on("/button2/status", HTTP_GET, handleButton2Status);
    server.on("/button3/on", HTTP_GET, handleButton3On);
    server.on("/button3/off", HTTP_GET, handleButton3Off);
    server.on("/button3/status", HTTP_GET, handleButton3Status);

    server.begin();
  } else {
    Serial.println("Failed to connect. Starting AP.");
    startAccessPoint();
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(outputPin1, OUTPUT);
  pinMode(outputPin2, OUTPUT);
  pinMode(outputPin3, OUTPUT);

  digitalWrite(outputPin1, HIGH);
  digitalWrite(outputPin2, LOW);
  digitalWrite(outputPin3, LOW);

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
  unsigned long currentMillis = millis();
  if (WiFi.status() != WL_CONNECTED && currentMillis - previousMillis >= interval) {
    Serial.println("Reconnecting to WiFi...");
    WiFi.disconnect();
    WiFi.reconnect();
    previousMillis = currentMillis;
  }
  server.handleClient();
}
