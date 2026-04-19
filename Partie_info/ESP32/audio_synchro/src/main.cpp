#include <Arduino.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <WebSocketsClient.h>
#include "MyWebSocket.h"
#include "AudioLogger.h"
#include "SnapClient.h"
#include <WebSocketsClient.h>
#include <Audio.h>

// --- VARIABLES DE SYNCHRO ---
uint32_t targetEpochMillis = 0;
bool hasTargetTime = false;
const char url[] = "http://10.42.0.1:8000/streamleft";
// Pins pour gérer l'I2S
int _bck = 17, _ws = 18, _data = 16;    
int volume = 3;
const char *ssid = "MonHotspot";
const char *password = "axel1234";
bool isIcecast = true;
I2SStream out; 
WiFiClient wifi;
CopyDecoder decoder; 
SnapClient client(wifi, out, decoder);
Audio audio;
bool i2sInitialized = false; // Flag pour savoir si on doit désinstaller
void releaseI2S() {
    Serial.println("Libération des ressources I2S...");
    
    // On n'arrête que si cela a déjà été lancé
    if (i2sInitialized) {
        // On arrête les flux logiciels d'abord
        audio.stopSong(); 
        out.end();
        
        // On désinstalle le driver hardware proprement
        i2s_driver_uninstall((i2s_port_t)0); 
        i2sInitialized = false;
        delay(100); // Petite pause pour laisser le hardware respirer
    }
}

void init_I2S_SnapCast(){ 
  releaseI2S();
  
  auto cfg = out.defaultConfig(TX_MODE);
  cfg.pin_bck = _bck;
  cfg.pin_ws = _ws;
  cfg.pin_data = _data;
  cfg.sample_rate = 44100;
  cfg.channels = 2;
  cfg.bits_per_sample = 16;
  client.setVolumeFactor(.25);
  
  out.begin(cfg);
  client.begin();
  
  i2sInitialized = true; // On marque comme initialisé
  isIcecast = false;
}

void init_I2S_Icecast(){
  releaseI2S();
  
  audio.setPinout(_bck, _ws, _data);
  audio.setVolume(volume);
  
  i2sInitialized = true; // On marque comme initialisé
  isIcecast = true;
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
    switch(type) {
        case WStype_TEXT: {
            char target[8], command[16], content[32];
            if (!extractField((char*)payload, "target", target, sizeof(target))) return;            
            if (strcmp(target, "esp32") == 0) {
                extractField((char*)payload, "command", command, sizeof(command));
                extractField((char*)payload, "content", content, sizeof(content));

                if (strcmp(command, "Sync") == 0) {   
                  //  init_I2S_Icecast();                 
                    init_I2S_Icecast();
                    targetEpochMillis = atoll(content);
                    hasTargetTime = true;
                } else if (strcmp(command, "Stop") == 0) {
                    if(audio.isRunning()){
                        audio.stopSong();
                        Serial.println("Lecture arrêtée.");
                    }
                    init_I2S_SnapCast();
                } else if (strcmp(command, "Volume") == 0) {
                    volume = atoi(content);
                    audio.setVolume(volume);
                }
            }
        } break;
        case WStype_DISCONNECTED: Serial.println("WS Déconnecté"); break;
        case WStype_CONNECTED: Serial.println("WS Connecté"); break;
        default: break;
    }
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connecté !");
  
  WS_init(webSocketEvent); 
}

void loop() {
  WS_loop();  
  if(isIcecast){
    audio.loop();
    if (hasTargetTime) {
      audio.setVolume(volume);
      audio.connecttohost(url);
      hasTargetTime = false;
    }
  }
  else{
    client.doLoop();
  }

  
}