#include <WiFi.h>
#include <WiFiUdp.h>

#define Network 2

#if Network == 1
const char* ssid = "wifi-ensea";
const char* password = "";
#elif Network == 2
const char* ssid = "Livebox-AE90";
const char* password = "qnrVTnqJk2odnwnupj";
#endif


WiFiUDP udp;
#define UDP_PORT 12345
#define BUFFER_SIZE 512

uint8_t buffer[BUFFER_SIZE];

void setup() { 
  Serial.begin(115200); 
  WiFi.begin(ssid, password); 
  while (WiFi.status() != WL_CONNECTED) { 
    delay(500); Serial.print("."); 
  }
  Serial.println("\nWiFi connecté !"); 
  Serial.print("IP ESP32 : "); 
  Serial.println(WiFi.localIP()); 
  udp.begin(UDP_PORT); }

void loop() {
  int packetSize = udp.parsePacket();
  if (packetSize > 0) {
    int len = udp.read(buffer, min(packetSize, BUFFER_SIZE));
    for (int i = 0; i < len; i++) {
      Serial.print(buffer[i]);   // affiche en décimal
      Serial.print(' ');         // espace entre chaque octet
    }
  Serial.println();
  }
}
