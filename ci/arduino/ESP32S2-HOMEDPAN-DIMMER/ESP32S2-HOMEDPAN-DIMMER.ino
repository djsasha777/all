#include "HomeSpan.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer webServer(80);
int brightness = 50;  // 0-100
const int ledPin = 37;

struct MyDimmableLED : Service::Lightbulb {
  SpanCharacteristic *power;
  SpanCharacteristic *level;
  
  MyDimmableLED() : Service::Lightbulb() {
    power = new Characteristic::On();
    level = new Characteristic::Brightness();
    level->setRange(0, 100, 1);  // ✅ 0-100% без ограничений!
  }
  
  boolean update() {
    brightness = level->getNewVal();
    bool isOn = power->getNewVal();
    
    if (isOn) {
      analogWrite(ledPin, map(brightness, 0, 100, 0, 255));
    } else {
      analogWrite(ledPin, 0);  // ✅ Полное выкл!
    }
    
    Serial.printf("HomeKit: power=%s, brightness=%d -> PWM=%d\n", isOn?"ON":"OFF", brightness, map(brightness, 0, 100, 0, 255));
    return true;
  }
};

MyDimmableLED *myLED;

String makePage() {
  String html = R"rawliteral(
<!DOCTYPE html><html><head><meta charset='utf-8'><title>LED Strip</title>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<style>body{font-family:Arial;margin:40px;background:#222;color:#fff;text-align:center;}
h1{color:#4CAF50;}.slider-container{margin:40px 0;}
input[type=range]{width:80%;height:40px;-webkit-appearance:none;background:#333;border-radius:20px;}
input[type=range]::-webkit-slider-thumb{width:40px;height:40px;background:#4CAF50;border-radius:50%;cursor:pointer;}
.brightness{font-size:24px;font-weight:bold;color:#4CAF50;margin:20px 0;}
button{padding:15px 30px;font-size:18px;margin:10px;border:none;border-radius:25px;background:#4CAF50;color:white;cursor:pointer;}
button.off{background:#f44336;}button.off:hover{background:#d32f2f;}
.status{padding:10px;background:#333;margin:10px;border-radius:5px;}</style></head><body>
<h1>LED Лента GPIO 37</h1>
<div class='brightness'>Яркость: <span id='brightnessValue)">)rawliteral" + String(brightness) + R"rawliteral(</span>%</div>
<div class='slider-container'><input type='range' min='0' max='100' value=')rawliteral" + String(brightness) + R"rawliteral(' id='brightnessSlider'></div>
<button onclick='setB(100)'>100%</button><button onclick='setB(50)'>50%</button><button class='off' onclick='setOff()'>🚫 ВЫКЛ</button>
<a href='/status'><button>Статус</button></a><div class='status' id='status'>Готов</div>
<script>
let s=document.getElementById('brightnessSlider'),v=document.getElementById('brightnessValue'),st=document.getElementById('status');
s.oninput=function(){v.textContent=this.value;setB(this.value);};
function setB(val){st.textContent='Установка...';st.style.background='#ff9800';fetch('/b?val='+val).then(r=>r.text()).then(d=>{st.textContent='OK '+val+'% ✅';st.style.background='#4CAF50';}).catch(e=>{st.textContent='Ошибка!';st.style.background='#f44336';});}
function setOff(){st.textContent='Выкл...';st.style.background='#ff9800';fetch('/off').then(r=>r.text()).then(d=>{st.textContent='Выкл ✅';st.style.background='#4CAF50';v.textContent='0';s.value='0';}).catch(e=>{st.textContent='Ошибка!';st.style.background='#f44336';});}
</script></body></html>)rawliteral";
  return html;
}

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  analogWrite(ledPin, 0);
  
  homeSpan.begin(Category::Lighting, "LED Strip");
  homeSpan.setWifiCallback([]() {
    Serial.print("Web: http://"); Serial.println(WiFi.localIP());
    
    webServer.on("/", []() { webServer.send(200, "text/html", makePage()); });
    webServer.on("/b", []() {
      if (webServer.hasArg("val")) {
        brightness = constrain(webServer.arg("val").toInt(), 0, 100);
        myLED->level->setVal(brightness);
        myLED->power->setVal(brightness > 0);
        analogWrite(ledPin, map(brightness, 0, 100, 0, 255));
        Serial.printf("Web: %d%% PWM=%d\n", brightness, map(brightness, 0, 100, 0, 255));
      }
      webServer.send(200, "text/plain", "OK");
    });
    webServer.on("/off", []() {
      brightness = 0;
      myLED->level->setVal(0);
      myLED->power->setVal(false);
      analogWrite(ledPin, 0);
      Serial.println("Web: FULL OFF!");
      webServer.send(200, "text/plain", "OFF");
    });
    webServer.on("/status", []() {
      webServer.send(200, "application/json", "{\"brightness\":" + String(brightness) + ",\"pwm\":" + String(map(brightness, 0, 100, 0, 255)) + "}");
    });
    webServer.begin();
  });
  
  new Service::AccessoryInformation();
  myLED = new MyDimmableLED();
}

void loop() {
  homeSpan.poll();
  webServer.handleClient();
}