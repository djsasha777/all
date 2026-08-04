#include "HomeSpan.h"
#include <WiFi.h>
#include <WebServer.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>

WebServer webServer(8080);
const int irPin = 4;  // GPIO для ИК-светодиода
IRsend irsend(irPin);

// Глобальные переменные для состояния устройств
bool acPower = false;
bool heaterPower = false;
bool tvPower = false;

SpanCharacteristic *acChar;
SpanCharacteristic *heaterChar;
SpanCharacteristic *tvChar;

// Функции отправки ИК-сигналов
void sendACSignal() {
  // Замените на коды вашего кондиционера
  // Пример для Panasonic:
  irsend.sendPANASONIC_AC(0x0220E004000000060200000000000000);
  Serial.println("IR: AC signal sent");
}

void sendHeaterSignal() {
  // Замените на коды вашего обогревателя
  // Пример для LG:
  irsend.sendLG(0x88C0051);
  Serial.println("IR: Heater signal sent");
}

void sendTVSignal() {
  // Замените на коды вашего телевизора
  // Пример для Samsung:
  irsend.sendSAMSUNG(0xE0E09966);
  Serial.println("IR: TV signal sent");
}

struct ACService : Service::Switch {
  ACService() : Service::Switch() {
    acChar = new Characteristic::On();
    new Characteristic::Name("Кондиционер");
  }
  
  boolean update() {
    bool power = acChar->getNewVal();
    if (power) {
      sendACSignal();
    }
    acPower = power;
    Serial.printf("HomeKit: AC=%s\n", power?"ON":"OFF");
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
    if (power) {
      sendHeaterSignal();
    }
    heaterPower = power;
    Serial.printf("HomeKit: Heater=%s\n", power?"ON":"OFF");
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
    if (power) {
      sendTVSignal();
    }
    tvPower = power;
    Serial.printf("HomeKit: TV=%s\n", power?"ON":"OFF");
    return true;
  }
};

ACService *acService;
HeaterService *heaterService;
TVService *tvService;

String makePage() {
  return R"rawliteral(
<!DOCTYPE html>
<html><head><meta charset='utf-8'><title>IR Control</title>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<style>
body{font-family:Arial;margin:20px;background:#222;color:#fff;text-align:center;}
button{padding:20px 40px;font-size:22px;margin:15px;border:none;border-radius:25px;color:white;cursor:pointer;width:200px;}
.ac{background:#2196F3;}
.heater{background:#FF5722;}
.tv{background:#9C27B0;}
button:active{transform:scale(0.95);}
#status{padding:15px;background:#333;margin:20px;border-radius:10px;font-size:18px;}
</style></head><body>
<h1>ИК Управление</h1>
<button class='ac' onclick='sendCmd("ac")'>🌡️ Кондиционер</button><br>
<button class='heater' onclick='sendCmd("heater")'>🔥 Обогреватель</button><br>
<button class='tv' onclick='sendCmd("tv")'>📺 Телевизор</button>
<div id='status'>Готов</div>
<script>
let st=document.getElementById('status');
function sendCmd(cmd){
  st.textContent='Отправка...';
  st.style.background='#ff9800';
  fetch('/cmd?dev='+cmd).then(r=>r.text()).then(d=>{
    st.textContent='OK: '+cmd;
    st.style.background='#4CAF50';
  }).catch(e=>{
    st.textContent='ERR';
    st.style.background='#f44336';
  });
}
</script></body></html>)rawliteral";
}

void setup() {
  Serial.begin(115200);
  irsend.begin();
  
  homeSpan.begin(Category::Bridges, "IR Controller");
  
  new SpanAccessory();
  new Service::AccessoryInformation();
  new Characteristic::Name("IR Controller");
  new Characteristic::Identify();
  
  acService = new ACService();
  heaterService = new HeaterService();
  tvService = new TVService();
  
  homeSpan.setWifiCallback([]() {
    Serial.printf("Web: http://%s:8080\n", WiFi.localIP().toString().c_str());
    
    webServer.on("/", []() { 
      webServer.send(200, "text/html", makePage()); 
    });
    
    webServer.on("/cmd", []() {
      if (webServer.hasArg("dev")) {
        String dev = webServer.arg("dev");
        if (dev == "ac") {
          sendACSignal();
          acChar->setVal(!acChar->getVal());
        } else if (dev == "heater") {
          sendHeaterSignal();
          heaterChar->setVal(!heaterChar->getVal());
        } else if (dev == "tv") {
          sendTVSignal();
          tvChar->setVal(!tvChar->getVal());
        }
        Serial.printf("Web: Command %s\n", dev.c_str());
      }
      webServer.send(200, "text/plain", "OK");
    });
    
    webServer.begin();
  });
}

void loop() {
  homeSpan.poll();
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck > 20) {
    webServer.handleClient();
    lastCheck = millis();
  }
}