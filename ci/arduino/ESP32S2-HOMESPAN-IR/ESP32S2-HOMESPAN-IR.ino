#include <Arduino.h>

#include "HomeSpan.h"

#include <WiFi.h>
#include <WebServer.h>

#include <IRremoteESP8266.h>
#include <IRsend.h>


// =========================
// Настройки
// =========================

constexpr uint8_t IR_PIN = 10;
constexpr uint16_t WEB_PORT = 8080;


// =========================
// Объекты
// =========================

WebServer webServer(WEB_PORT);
IRsend irsend(IR_PIN);


// =========================
// Состояние устройств
// =========================

bool acPower = false;
bool heaterPower = false;
bool tvPower = false;

SpanCharacteristic *acChar = nullptr;
SpanCharacteristic *heaterChar = nullptr;
SpanCharacteristic *tvChar = nullptr;


// =========================
// Отправка ИК-команд
// =========================

// ВАЖНО:
// 0x0220E004 — временный пример 32-битного кода.
// Замените его на настоящий код вашего устройства.
void sendACSignal() {
  irsend.sendPanasonicAC32(
    0x0220E004,
    32
  );

  Serial.println("IR: Panasonic AC signal sent");
}


void sendHeaterSignal() {
  // Пример LG, 28 бит.
  // Замените код на код вашего обогревателя.
  irsend.sendLG(
    0x088C0051,
    28
  );

  Serial.println("IR: Heater signal sent");
}


void sendTVSignal() {
  // Пример Samsung, 32 бита.
  // Замените код на код вашего телевизора.
  irsend.sendSAMSUNG(
    0xE0E09966,
    32
  );

  Serial.println("IR: TV signal sent");
}


// =========================
// HomeKit-сервисы
// =========================

struct ACService : Service::Switch {
  ACService() : Service::Switch() {
    acChar = new Characteristic::On();
    new Characteristic::Name("Кондиционер");
  }

  boolean update() {
    bool power = acChar->getNewVal();

    // Отправляем ИК-команду при любом изменении состояния.
    sendACSignal();

    acPower = power;

    Serial.printf(
      "HomeKit: AC=%s\n",
      power ? "ON" : "OFF"
    );

    return true;
  }
};


struct HeaterService : Service::Switch {
  HeaterService() : Service::Switch() {
    heaterChar = new Characteristic::On();
    new Characteristic::Name("Обогреватель");
  }

  boolean update() {
    bool power = heaterChar->getNewVal();

    sendHeaterSignal();

    heaterPower = power;

    Serial.printf(
      "HomeKit: Heater=%s\n",
      power ? "ON" : "OFF"
    );

    return true;
  }
};


struct TVService : Service::Switch {
  TVService() : Service::Switch() {
    tvChar = new Characteristic::On();
    new Characteristic::Name("Телевизор");
  }

  boolean update() {
    bool power = tvChar->getNewVal();

    sendTVSignal();

    tvPower = power;

    Serial.printf(
      "HomeKit: TV=%s\n",
      power ? "ON" : "OFF"
    );

    return true;
  }
};


ACService *acService = nullptr;
HeaterService *heaterService = nullptr;
TVService *tvService = nullptr;


// =========================
// Web-интерфейс
// =========================

String makePage() {
  return R"rawliteral(
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>IR Control</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
      background: #222;
      color: #fff;
      text-align: center;
    }

    h1 {
      margin-bottom: 30px;
    }

    button {
      padding: 20px 40px;
      font-size: 22px;
      margin: 15px;
      border: none;
      border-radius: 25px;
      color: white;
      cursor: pointer;
      width: 240px;
    }

    button:active {
      transform: scale(0.95);
    }

    .ac {
      background: #2196F3;
    }

    .heater {
      background: #FF5722;
    }

    .tv {
      background: #9C27B0;
    }

    #status {
      padding: 15px;
      background: #333;
      margin: 20px auto;
      border-radius: 10px;
      font-size: 18px;
      max-width: 500px;
    }
  </style>
</head>

<body>
  <h1>ИК-управление</h1>

  <button class="ac" onclick="sendCmd('ac')">
    🌡️ Кондиционер
  </button>

  <br>

  <button class="heater" onclick="sendCmd('heater')">
    🔥 Обогреватель
  </button>

  <br>

  <button class="tv" onclick="sendCmd('tv')">
    📺 Телевизор
  </button>

  <div id="status">Готов</div>

  <script>
    const statusElement = document.getElementById('status');

    function sendCmd(device) {
      statusElement.textContent = 'Отправка...';
      statusElement.style.background = '#ff9800';

      fetch('/cmd?dev=' + encodeURIComponent(device))
        .then(response => {
          if (!response.ok) {
            throw new Error('HTTP ' + response.status);
          }

          return response.text();
        })
        .then(result => {
          statusElement.textContent = 'OK: ' + device;
          statusElement.style.background = '#4CAF50';
        })
        .catch(error => {
          console.error(error);
          statusElement.textContent = 'Ошибка';
          statusElement.style.background = '#f44336';
        });
    }
  </script>
</body>
</html>
)rawliteral";
}


void setupWebServer() {
  webServer.on("/", HTTP_GET, []() {
    webServer.send(
      200,
      "text/html; charset=utf-8",
      makePage()
    );
  });


  webServer.on("/cmd", HTTP_GET, []() {
    if (!webServer.hasArg("dev")) {
      webServer.send(
        400,
        "text/plain; charset=utf-8",
        "Missing dev argument"
      );

      return;
    }

    String device = webServer.arg("dev");

    if (device == "ac") {
      sendACSignal();

      acPower = !acPower;

      if (acChar != nullptr) {
        acChar->setVal(acPower);
      }
    }
    else if (device == "heater") {
      sendHeaterSignal();

      heaterPower = !heaterPower;

      if (heaterChar != nullptr) {
        heaterChar->setVal(heaterPower);
      }
    }
    else if (device == "tv") {
      sendTVSignal();

      tvPower = !tvPower;

      if (tvChar != nullptr) {
        tvChar->setVal(tvPower);
      }
    }
    else {
      webServer.send(
        400,
        "text/plain; charset=utf-8",
        "Unknown device"
      );

      return;
    }

    Serial.printf(
      "Web: command=%s\n",
      device.c_str()
    );

    webServer.send(
      200,
      "text/plain; charset=utf-8",
      "OK"
    );
  });

  webServer.begin();

  Serial.printf(
    "Web server started: http://%s:%u\n",
    WiFi.localIP().toString().c_str(),
    WEB_PORT
  );
}


// =========================
// setup()
// =========================

void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println();
  Serial.println("Starting ESP32-S2 HomeSpan IR controller");

  irsend.begin();

  homeSpan.begin(
    Category::Bridges,
    "IR Controller"
  );

  // Accessory Information
  new SpanAccessory();

  new Service::AccessoryInformation();
  new Characteristic::Name("IR Controller");
  new Characteristic::Identify();


  // HomeKit-сервисы
  acService = new ACService();
  heaterService = new HeaterService();
  tvService = new TVService();


  // Web-сервер запускаем после подключения HomeSpan к Wi-Fi
  homeSpan.setWifiCallback([]() {
    Serial.printf(
      "Wi-Fi connected: %s\n",
      WiFi.localIP().toString().c_str()
    );

    static bool webServerStarted = false;

    if (!webServerStarted) {
      setupWebServer();
      webServerStarted = true;
    }
  });

  Serial.println("Setup completed");
}


// =========================
// loop()
// =========================

void loop() {
  homeSpan.poll();

  static uint32_t lastWebCheck = 0;
  uint32_t now = millis();

  if (now - lastWebCheck >= 20) {
    webServer.handleClient();
    lastWebCheck = now;
  }
}