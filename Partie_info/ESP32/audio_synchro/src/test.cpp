#include <Arduino.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <WebSocketsClient.h>
#include "MyWebSocket.h"
#include "MyI2S.h"

// --- CONFIGURATION RÉSEAU ---
#define NETWORK 4
#if NETWORK == 4
  const char ssid[] = "MonHotspot";
  const char password[] = "axel1234";
#endif

const char url[] = "http://10.42.0.1:8000/streamright";

// --- CONFIGURATION UDP MULTICAST ---
WiFiUDP udp;
const unsigned int localUdpPort = 12345;
IPAddress multicastIP(239, 0, 0, 1); 
uint8_t packetBuffer[2048]; // Buffer large pour encaisser les paquets de 1280 octets

// --- VARIABLES DE SYNCHRO ---
uint32_t targetEpochMillis = 0;
bool hasTargetTime = false;

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
    switch(type) {
        case WStype_TEXT: {
            char target[8], command[16], content[32];
            if (!extractField((char*)payload, "target", target, sizeof(target))) return;
            if (strcmp(target, "esp32") == 0) {
                extractField((char*)payload, "command", command, sizeof(command));
                extractField((char*)payload, "content", content, sizeof(content));
                if (strcmp(command, "Sync") == 0) {
                    targetEpochMillis = atoll(content);
                    hasTargetTime = true;
                } else if (strcmp(command, "Stop") == 0) {
                    stopAudio();
                } else if (strcmp(command, "Volume") == 0) {
                    setVolumeLevel(atoi(content));
                }
            }
        } break;
        default: break;
    }
}

void setup() {
    Serial.begin(115200);
    // 1. Connexion WiFi
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    // --- CRITIQUE : Désactive l'économie d'énergie pour l'audio temps réel ---
    WiFi.setSleep(false); 
    Serial.println("\nWiFi OK - Mode Performance activé");
    // 2. Initialisation Audio
    Audio_init();
    // 3. Services
    WS_init(webSocketEvent);  
    if (udp.beginMulticast(multicastIP, localUdpPort)) {
        Serial.println("Multicast rejoint.");
    }
}

void loop() {
    WS_loop();     
    Audio_loop();  
    while (int packetSize = udp.parsePacket()) {
        int len = udp.read(packetBuffer, 2048); 
        
        if (len > 0) {
            if (len >= 5 && memcmp(packetBuffer, "salut", 5) == 0) {
                Serial.println(">>> Mode MICRO (16kHz Multicast)");
                stopAudio(); 
                i2s_stop(I2S_NUM_0);
                i2s_set_clk(I2S_NUM_0, 16000, I2S_BITS_PER_SAMPLE_16BIT, I2S_CHANNEL_STEREO);
                i2s_zero_dma_buffer(I2S_NUM_0);
                i2s_start(I2S_NUM_0);
            } 
            else if (!audio.isRunning()) {
                if (len % 4 == 0) {
                    playUdpChunk(packetBuffer, len);
                }
            }
        }
    }

    if (hasTargetTime) {
        startAudio(url);
        hasTargetTime = false;
    }
}