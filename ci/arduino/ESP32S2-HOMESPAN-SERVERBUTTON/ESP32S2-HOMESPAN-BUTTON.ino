#include "HomeSpan.h"        
#include <WiFi.h>
#include <WebServer.h>

WebServer webServer(8080);
bool ledState = false;
struct DEV_LED *ledService;

void setupWeb() {
  Serial.print("WebServer: http://");
  Serial.print(WiFi.localIP());
  Serial.println(":8080");
  
  webServer.on("/", []() {
    String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Relay</title></head><body>";
    html += "<h1>Relay Control</h1>";
    html += "<p>Status: <strong>" + String(ledState ? "ON" : "OFF") + "</strong></p>";
    html += "<a href='/toggle'><button style='padding:20px;font-size:20px;'>Toggle</button></a>";
    html += "</body></html>";
    webServer.send(200, "text/html", html);
  });

  webServer.on("/toggle", []() {
    ledState = !ledState;
    digitalWrite(4, ledState);
    
    if (ledService) {
      ledService->power->setVal(ledState);
    }
    
    String html = "<h1>Toggled!</h1>";
    html += "<p>Relay: <strong>" + String(ledState ? "ON" : "OFF") + "</strong></p>";
    html += "<a href='/'><button>Back</button></a>";
    webServer.send(200, "text/html", html);
  });
  
  webServer.begin();
}

void setup() {
  Serial.begin(115200);
  homeSpan.begin(Category::Lighting, "HomeSpan LED");
  homeSpan.setWifiCallback(setupWeb);
  
  new SpanAccessory(); 
    new Service::AccessoryInformation(); 
      new Characteristic::Identify();                
    ledService = new DEV_LED(4);
}

void loop() {
  webServer.handleClient();
  homeSpan.poll();
}

// structs
struct DEV_LED : Service::LightBulb {               // First we create a derived class from the HomeSpan LightBulb Service

  int ledPin;                                       // this variable stores the pin number defined for this LED
  SpanCharacteristic *power;                        // here we create a generic pointer to a SpanCharacteristic named "power" that we will use below

  DEV_LED(int ledPin) : Service::LightBulb(){

    power=new Characteristic::On();                 // this is where we create the On Characterstic we had previously defined in setup().  Save this in the pointer created above, for use below
    this->ledPin=ledPin;                            // don't forget to store ledPin...
    pinMode(ledPin,OUTPUT);                         // ...and set the mode for ledPin to be an OUTPUT (standard Arduino function)
    
  } // end constructor

  boolean update(){            

    digitalWrite(ledPin,power->getNewVal());        // use a standard Arduino function to turn on/off ledPin based on the return of a call to power->getNewVal() (see below for more info)
   
    return(true);                                   // return true to indicate the update was successful (otherwise create code to return false if some reason you could not turn on the LED)
  
  } // update
};