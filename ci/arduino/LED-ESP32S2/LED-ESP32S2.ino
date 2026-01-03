#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <Update.h>

const char* ap_ssid = "ESP32_AP";
const char* ap_password = "12345678";
const char* hostname = "my-esp32-device";

IPAddress apIP(10, 10, 10, 1);

WebServer mainServer(80);  // Main server for STA mode
WebServer apServer(80);    // AP server for configuration mode

Preferences preferences;

String wifiSSID = "";
String wifiPassword = "";

const int outputPin = 4;       // PWM output for brightness control
const int buttonPin = 5;
const int ledPin = 6;

int pwmValue = 0;              // Current brightness value (0-255)
bool pwmInitialized = false;

bool lastButtonState = HIGH;
unsigned long lastDebounceTime = 0;
const unsigned long debounceDelay = 50;
const unsigned long resetHoldTime = 10000; // 10 seconds button hold
unsigned long buttonPressTime = 0;
bool resetTriggered = false;

// LED blinking in AP mode
unsigned long lastLedToggle = 0;
const unsigned long ledInterval = 500; // 500ms
bool ledOn = false;

// Handle brightness setting via /led1/XX (XX = 0..100) or notFound
void handleLedValueParam() {
  String path = mainServer.uri(); // e.g. "/led1/50"
  int lastSlash = path.lastIndexOf('/');
  if (lastSlash == -1 || lastSlash == path.length() - 1) {
    mainServer.send(400, "text/plain", "Brightness value missing");
    return;
  }
  String valueStr = path.substring(lastSlash + 1);
  int value = valueStr.toInt();
  if (value < 0) value = 0;
  if (value > 100) value = 100;
  pwmValue = map(value, 0, 100, 0, 255);
  if (pwmInitialized) ledcWrite(outputPin, pwmValue);
  mainServer.send(200, "text/plain", "Brightness set: " + String(value));
  Serial.printf("Set PWM via path: %d%% -> PWM: %d\n", value, pwmValue);
}

// Handle current brightness request /led1/status
void handleLedStatus() {
  int statusValue = map(pwmValue, 0, 255, 0, 100);
  mainServer.send(200, "text/plain", String(statusValue));
}

// STA mode root page - show status and controls
void handleRootSTA() {
  String page = "<!DOCTYPE html><html><head>";
  page += "<title>ESP32 LED Control</title>";
  page += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  page += "<style>body{font-family:Arial;padding:20px;}";
  page += ".slider{max-width:300px;}</style></head><body>";
  page += "<h1>ESP32 LED Control</h1>";
  page += "<p>Status: " + String(pwmValue > 0 ? "ON" : "OFF") + "</p>";
  page += "<p>Current brightness: " + String(map(pwmValue, 0, 255, 0, 100)) + "%</p>";
  
  // Brightness slider
  page += "<h3>Brightness Control</h3>";
  page += "<input type='range' min='0' max='100' value='" + String(map(pwmValue, 0, 255, 0, 100)) + "' class='slider' ";
  page += "onchange='fetch(\"/led1/\"+this.value).then(()=>location.reload())'>";
  
  page += "<p><a href='/config'>WiFi Config</a> | <a href='/update'>Firmware Update</a></p>";
  page += "</body></html>";
  mainServer.send(200, "text/html", page);
}

// STA mode config page
void handleConfig() {
  String page = "<!DOCTYPE html><html><head>";
  page += "<title>WiFi Configuration</title>";
  page += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  page += "<style>body{font-family:Arial;padding:20px;} input{width:100%;padding:10px;margin:5px 0;}</style>";
  page += "</head><body><h1>WiFi Configuration</h1>";
  page += "<p>Current network: " + String(WiFi.SSID()) + "</p>";
  page += "<p>IP: " + WiFi.localIP().toString() + "</p>";
  page += "<form action='/save' method='POST'>";
  page += "SSID: <input type='text' name='ssid' value='" + String(wifiSSID) + "'><br>";
  page += "Password: <input type='password' name='password' value='" + String(wifiPassword) + "'><br>";
  page += "<input type='submit' value='Save & Reboot'>";
  page += "</form>";
  page += "<p><a href='/'>Main</a></p></body></html>";
  mainServer.send(200, "text/html", page);
}

// STA mode OTA page
void handleOTAUpdatePage() {
  String page = "<!DOCTYPE html><html><head><title>OTA Update</title>";
  page += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  page += "<style>body{font-family:Arial;padding:20px;} input{width:100%;padding:10px;margin:5px 0;}</style>";
  page += "</head><body><h1>Firmware Update</h1>";
  page += "<p>Current network: " + WiFi.SSID() + "</p>";
  page += "<p>IP: " + WiFi.localIP().toString() + "</p>";
  page += "<form method='POST' action='/update' enctype='multipart/form-data'>";
  page += "<input type='file' name='firmware' accept='.bin'>";
  page += "<input type='submit' value='Update Firmware'>";
  page += "</form>";
  page += "<p><a href='/'>Main</a></p></body></html>";
  mainServer.send(200, "text/html", page);
}

// STA mode OTA upload handler
void handleOTAUploadSTA() {
  HTTPUpload& upload = mainServer.upload();
  if (upload.status == UPLOAD_FILE_START) {
    Serial.printf("STA OTA start: %s\n", upload.filename.c_str());
    if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (Update.end(true)) {
      Serial.printf("STA OTA complete: %u bytes\n", upload.totalSize);
      mainServer.send(200, "text/plain", "OK, rebooting...");
      delay(1000);
      ESP.restart();
    } else {
      Update.printError(Serial);
      mainServer.send(500, "text/plain", "Update failed");
    }
  }
  yield();
}

// NotFound for STA mode - parse /led1/XX
void handleNotFound() {
  String path = mainServer.uri();
  if (path.startsWith("/led1/")) {
    handleLedValueParam();
  } else if (path == "/status") {
    handleLedStatus();
  } else {
    mainServer.send(404, "text/plain", "Route not found");
  }
}

// AP server root page
void handleRoot() {
  String page = "<!DOCTYPE html><html><head><title>ESP32 Config</title>";
  page += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  page += "<style>body{font-family:Arial;padding:20px;} input{width:100%;padding:10px;margin:5px 0;}</style>";
  page += "</head><body><h1>ESP32 Configuration</h1>";
  page += "<p>Mode: Access Point</p>";
  page += "<p>Status: " + String(pwmValue > 0 ? "ON" : "OFF") + "</p>";
  
  page += "<h3>LED Control</h3>";
  page += "<form action='/toggle' method='POST'>";
  page += "<input type='submit' value='" + String(pwmValue > 0 ? "Turn OFF" : "Turn ON") + "'>";
  page += "</form>";
  
  page += "<h3>WiFi Settings</h3>";
  page += "<form action='/save' method='POST'>";
  page += "SSID: <input type='text' name='ssid'><br>";
  page += "Password: <input type='password' name='password'><br>";
  page += "<input type='submit' value='Save & Reboot'>";
  page += "</form>";
  
  page += "<h3>OTA Update</h3>";
  page += "<a href='/update'>Update Firmware</a>";
  page += "</body></html>";
  apServer.send(200, "text/html", page);
}

// Toggle brightness (full on/off)
void handleToggle() {
  if (apServer.method() == HTTP_POST) {
    pwmValue = (pwmValue > 0) ? 0 : 255;
    if (pwmInitialized) ledcWrite(outputPin, pwmValue);
    apServer.sendHeader("Location", "/");
    apServer.send(303);
  } else {
    apServer.send(405, "text/plain", "Method not allowed");
  }
}

// AP state endpoint
void handleState() {
  apServer.send(200, "text/plain", pwmValue > 0 ? "ON" : "OFF");
}

// Save WiFi credentials
void handleSaveSTA() {
  if (mainServer.method() == HTTP_POST) {
    wifiSSID = mainServer.arg("ssid");
    wifiPassword = mainServer.arg("password");
    preferences.begin("wifi-creds", false);
    preferences.putString("ssid", wifiSSID);
    preferences.putString("password", wifiPassword);
    preferences.end();
    
    String response = "<h1>WiFi Saved!</h1>";
    response += "<p>SSID: " + wifiSSID + "</p>";
    response += "<p>Rebooting in 3 seconds...</p>";
    response += "<script>setTimeout(function(){window.location.href='/';}, 3000);</script>";
    mainServer.send(200, "text/html", response);
    Serial.println("WiFi saved: " + wifiSSID);
    delay(3000);
    ESP.restart();
  } else {
    mainServer.send(405, "text/plain", "Method not allowed");
  }
}

void handleSaveAP() {
  if (apServer.method() == HTTP_POST) {
    wifiSSID = apServer.arg("ssid");
    wifiPassword = apServer.arg("password");
    preferences.begin("wifi-creds", false);
    preferences.putString("ssid", wifiSSID);
    preferences.putString("password", wifiPassword);
    preferences.end();
    
    String response = "<h1>WiFi Saved!</h1>";
    response += "<p>SSID: " + wifiSSID + "</p>";
    response += "<p>Rebooting in 3 seconds...</p>";
    response += "<script>setTimeout(function(){window.location.href='/';}, 3000);</script>";
    apServer.send(200, "text/html", response);
    Serial.println("WiFi saved: " + wifiSSID);
    delay(3000);
    ESP.restart();
  } else {
    apServer.send(405, "text/plain", "Method not allowed");
  }
}

// AP OTA page
void handleOTAPage() {
  String page = "<!DOCTYPE html><html><head><title>OTA Update - AP</title>";
  page += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  page += "<style>body{font-family:Arial;padding:20px;} input{width:100%;padding:10px;margin:5px 0;}</style>";
  page += "</head><body><h1>Firmware Update (AP Mode)</h1>";
  page += "<p>AP IP: " + WiFi.softAPIP().toString() + "</p>";
  page += "<form method='POST' action='/update' enctype='multipart/form-data'>";
  page += "<input type='file' name='firmware' accept='.bin'>";
  page += "<input type='submit' value='Update Firmware'>";
  page += "</form>";
  page += "<p><a href='/'>Back to Config</a></p></body></html>";
  apServer.send(200, "text/html", page);
}

// AP OTA upload handler
void handleOTAUploadAP() {
  HTTPUpload& upload = apServer.upload();
  if (upload.status == UPLOAD_FILE_START) {
    Serial.printf("AP OTA start: %s\n", upload.filename.c_str());
    if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (Update.end(true)) {
      Serial.printf("AP OTA complete: %u bytes\n", upload.totalSize);
      apServer.send(200, "text/plain", "OK, rebooting...");
      delay(1000);
      ESP.restart();
    } else {
      Update.printError(Serial);
      apServer.send(500, "text/plain", "Update failed");
    }
  }
  yield();
}

void startAccessPoint() {
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255, 255, 255, 0));
  WiFi.softAP(ap_ssid, ap_password);

  apServer.on("/", handleRoot);
  apServer.on("/toggle", HTTP_POST, handleToggle);
  apServer.on("/state", handleState);
  apServer.on("/save", HTTP_POST, handleSaveAP);
  apServer.on("/update", HTTP_GET, handleOTAPage);
  apServer.on("/update", HTTP_POST, []() {
    apServer.sendHeader("Connection", "close");
    apServer.send(200, "text/plain", "OK");
  }, handleOTAUploadAP);

  apServer.begin();

  Serial.println("AP started: " + String(ap_ssid));
  Serial.println("AP IP: " + WiFi.softAPIP().toString());

  ledOn = false;
  lastLedToggle = millis();
}

void connectToWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.setHostname(hostname);
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());
  Serial.println("Connecting to: " + wifiSSID);

  unsigned long startAttemptTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 10000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("Connected! IP: " + WiFi.localIP().toString());

    // STA mode routes - including OTA
    mainServer.on("/", HTTP_GET, handleRootSTA);
    mainServer.on("/config", HTTP_GET, handleConfig);
    mainServer.on("/status", HTTP_GET, handleLedStatus);
    mainServer.on("/save", HTTP_POST, handleSaveSTA);
    mainServer.on("/update", HTTP_GET, handleOTAUpdatePage);
    mainServer.on("/update", HTTP_POST, []() {
      mainServer.sendHeader("Connection", "close");
      mainServer.send(200, "text/plain", "OK");
    }, handleOTAUploadSTA);
    mainServer.onNotFound(handleNotFound);
    mainServer.begin();
    Serial.println("STA server started on port 80");
  } else {
    Serial.println("WiFi failed, fallback to AP");
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

  // ESP32 3.0+ LEDC API
  ledcAttach(outputPin, 5000, 8);  // pin, freq, resolution
  pwmInitialized = true;
  ledcWrite(outputPin, pwmValue);  // Initial value 0

  preferences.begin("wifi-creds", true);
  wifiSSID = preferences.getString("ssid", "");
  wifiPassword = preferences.getString("password", "");
  preferences.end();

  if (wifiSSID.length() > 0) {
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

  // Button handling
  int reading = digitalRead(buttonPin);
  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading == LOW && !resetTriggered) {
      if (buttonPressTime == 0) {
        buttonPressTime = millis();
        Serial.println("Button pressed...");
      } else {
        unsigned long held = millis() - buttonPressTime;
        if (held >= resetHoldTime) {
          Serial.println("WiFi reset - 10s hold");
          preferences.begin("wifi-creds", false);
          preferences.clear();
          preferences.end();
          delay(1000);
          ESP.restart();
        }
      }
    } else if (reading == HIGH && buttonPressTime != 0 && !resetTriggered) {
      // Short press - toggle
      pwmValue = (pwmValue > 0) ? 0 : 255;
      ledcWrite(outputPin, pwmValue);
      Serial.println("Button: toggle PWM=" + String(pwmValue));
      buttonPressTime = 0;
    }
  }
  lastButtonState = reading;
}
