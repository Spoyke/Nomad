#include <WiFi.h>
#include <Audio.h>
#include <WebSocketsClient.h>

// ==============================
// Configuration WiFi
// ==============================
#define NETWORK 4
#if NETWORK == 1
  const char ssid[] PROGMEM = "wifi-ensea";
  const char password[] PROGMEM = "";
#elif NETWORK == 2
  const char ssid[] PROGMEM = "Livebox-AE90";
  const char password[] PROGMEM = "qnrVTnqJk2odnwnupj";
#elif NETWORK == 3
  const char ssid[] PROGMEM = "Nomad";
  const char password[] PROGMEM = "axel1234";
#elif NETWORK == 4
  const char ssid[] PROGMEM = "MonHotspot";
  const char password[] PROGMEM = "axel1234";
#endif

#ifdef DEBUG
  #define Log(x) Serial.println(x)
#else
  #define Log(x)
#endif

#define SERVER_IP "10.42.0.1"
#define SERVER_PORT 8765

// ==============================
// Configuration audio et I2S
// ==============================
const char url[] PROGMEM = "http://10.42.0.1:8000/stream.mp3";

#define SD_PIN 5
#define I2S_BCLK 26
#define I2S_LRC 25
#define I2S_DOUT 22

Audio audio;
bool synced = false; // indique si la lecture a commencé

uint32_t targetEpochMillis = 0; 
bool hasTargetTime = false;

uint32_t baseEpoch = 0;
unsigned long baseMillis = 0;

// 0 = gauche, 1 = droite, 2 = stéréo
int forceChannel = 0;

void rtcSetTime(uint32_t epochMillis) {
  baseEpoch = epochMillis;
  baseMillis = millis();
}

uint32_t rtcGetEpochMillis() {
  uint32_t elapsed = millis() - baseMillis;
  return baseEpoch + elapsed;
}

// ==============================
// Audio callback pour forcer canal
// ==============================
void audioOutputCallback(int16_t* buffer, size_t len) {
  for (size_t i = 0; i < len; i += 2) {
    int16_t left = buffer[i];
    int16_t right = buffer[i+1];

    if (forceChannel == 0) right = 0;       // uniquement gauche
    else if (forceChannel == 1) left = 0;   // uniquement droite

    buffer[i] = left;
    buffer[i+1] = right;
  }
}

// ==============================
// JSON simplifié
// ==============================
bool extractField(const char* json, const char* key, char* buffer, size_t maxLen) {
  const char* p = strstr(json, key);
  if (!p) return false;
  p += strlen(key);
  while (*p && *p != ':') p++;
  if (!*p) return false;
  p++;
  while (*p == ' ' || *p == '\t' || *p == '"') p++;
  size_t i = 0;
  while (*p && *p != '"' && *p != ',' && i < maxLen - 1) buffer[i++] = *p++;
  buffer[i] = '\0';
  return (i > 0);
}

// ==============================
// Fonctions audio
// ==============================
void startAudio(const char* url) {
  Log(F("Connexion au flux audio..."));
  audio.setVolume(3);
  audio.connecttohost(url);
  digitalWrite(SD_PIN, HIGH);
  Log(F("Lecture audio démarrée !"));
}

void stopAudio() {
  Log(F("Arrêt du flux audio..."));
  audio.stopSong();
  digitalWrite(SD_PIN, LOW);
  synced = false;
  Log(F("Lecture arrêtée."));
}

// ==============================
// WebSocket
// ==============================
WebSocketsClient webSocket;

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED: Log(F("WebSocket déconnecté !")); break;
    case WStype_CONNECTED: Log(F("WebSocket connecté !")); break;
    case WStype_TEXT: {
      char target[8], command[16], content[32];
      if (!extractField((char*)payload, "target", target, sizeof(target))) return;
      Log(F((char*)payload));
      if (strcmp(target, "esp32") != 0) return;
      extractField((char*)payload, "command", command, sizeof(command));
      extractField((char*)payload, "content", content, sizeof(content));

      if (strcmp(command, "Sync") == 0) {
        targetEpochMillis = atoll(content);
        hasTargetTime = true;
      } else if (strcmp(command, "Stop") == 0) stopAudio();
      else if (strcmp(command, "Volume") == 0) audio.setVolume(atoi(content));
      else if (strcmp(command, "SetTime") == 0) rtcSetTime(atoll(content));
      else if (strcmp(command, "Channel") == 0) forceChannel = atoi(content); // 0=gauche,1=droite,2=stéréo
    }
    break;
    default: break;
  }
}

// ==============================
// Setup
// ==============================
void setup() {
  Serial.begin(115200);
  pinMode(SD_PIN, OUTPUT);
  digitalWrite(SD_PIN, LOW);

  Log(F("Connexion WiFi"));
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Log(F("."));
  }
  Log(F("\nWiFi connecté !"));

  audio.setPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);

  webSocket.begin(SERVER_IP, SERVER_PORT, "/");
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(1000);
}

// ==============================
// Loop
// ==============================
void loop() {
  webSocket.loop();
  audio.loop();

  if (hasTargetTime) {
    uint32_t currentEpochMillis = rtcGetEpochMillis();
    if (currentEpochMillis >= targetEpochMillis) {
      Log((char*)"Play");
      startAudio(url);
      hasTargetTime = false;
      targetEpochMillis = 0;
    }
  }
}
