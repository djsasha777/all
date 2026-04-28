#include "HomeSpan.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer webServer(8080);
int brightness = 50;
const int ledPin = 37;
SpanCharacteristic *powerChar;
SpanCharacteristic *brightnessChar;

struct DimmableLED : Service::LightBulb {
  DimmableLED() : Service::LightBulb() {
    powerChar = new Characteristic::On();
    brightnessChar = new Characteristic::Brightness(1);
    brightnessChar->setRange(0, 100, 1);
  }
  
  boolean update() {
    bool power = powerChar->getNewVal();
    brightness = brightnessChar->getNewVal();
    
    int pwm = power ? brightness : 0;
    analogWrite(ledPin, map(pwm, 0, 100, 0, 255));
    
    Serial.printf("HomeKit: power=%s, brightness=%d PWM=%d\n", 
                  power?"ON":"OFF", brightness, map(pwm, 0, 100, 0, 255));
    return true;
  }
};

DimmableLED *myLED;

String makePage() {
  return R"rawliteral(
<!DOCTYPE html>
<html><head><meta charset='utf-8'><title>LED</title>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<style>body{font-family:Arial;margin:20px;background:#222;color:#fff;text-align:center;}
.slider{width:80%;height:50px;-webkit-appearance:none;background:#333;border-radius:25px;}
.slider::-webkit-slider-thumb{width:50px;height:50px;background:#4CAF50;border-radius:50%;cursor:pointer;}
.brightness{font-size:28px;color:#4CAF50;}
button{padding:15px 30px;font-size:20px;margin:10px;border:none;border-radius:25px;background:#4CAF50;color:white;cursor:pointer;}
button.off{background:#f44336;}
#status{padding:15px;background:#333;margin:10px;border-radius:10px;}
</style></head><body>
<h1>LED GPIO 37</h1>
<div class='brightness'>Яркость: <span id='val'>)rawliteral" + String(brightness) + R"rawliteral(</span>%</div>
<input type='range' min='0' max='100' value='")rawliteral" + String(brightness) + R"rawliteral("' class='slider' id='slider'>
<button onclick='setB(100)'>100%</button><button onclick='setB(50)'>50%</button><button class='off' onclick='setB(0)'>ВЫКЛ</button>
<div id='status'>Готов</div>
<script>
let s=document.getElementById('slider'),v=document.getElementById('val'),st=document.getElementById('status');
s.oninput=function(){v.textContent=this.value;setB(this.value);};
function setB(b){st.textContent='...';st.style.background='#ff9800';
fetch('/b?val='+b).then(r=>r.text()).then(d=>{st.textContent=b+'%';st.style.background='#4CAF50';if(b==0){s.value=0;v.textContent='0';}}).catch(e=>{st.textContent='ERR';st.style.background='#f44336';});}
</script></body></html>)rawliteral";
}

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  analogWrite(ledPin, 0);
  
  homeSpan.begin(Category::Lighting, "LED Strip");
  
  new SpanAccessory();
  new Service::AccessoryInformation();
  new Characteristic::Name("LED Dimmer");
  new Characteristic::Identify();
  
  myLED = new DimmableLED();
  
  homeSpan.setWifiCallback([]() {
    Serial.printf("Web: http://%s:8080\n", WiFi.localIP().toString().c_str());
    
    webServer.on("/", []() { webServer.send(200, "text/html", makePage()); });
    webServer.on("/b", []() {
      if (webServer.hasArg("val")) {
        int val = constrain(webServer.arg("val").toInt(), 0, 100);
        brightnessChar->setVal(val);
        powerChar->setVal(val > 0);
        analogWrite(ledPin, map(val, 0, 100, 0, 255));
        Serial.printf("Web: %d%% PWM=%d\n", val, map(val, 0, 100, 0, 255));
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