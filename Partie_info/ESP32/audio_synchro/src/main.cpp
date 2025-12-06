#include <driver/i2s.h>
#include <Arduino.h>
#include <WiFi.h>
#include <WebSocketsClient.h>
#include <Audio.h>

#define DEBUG
#ifdef DEBUG
  #define Log(x) Serial.println(x)
#else
  #define Log(x)
#endif

// ==============================
// Connexion Internet
// ==============================
// WiFi + WebSocket utilisés pour recevoir les commandes du serveur
// et pour lancer la lecture audio au bon moment.

const char ssid[] PROGMEM = "MonHotspot";
const char password[] PROGMEM = "axel1234";
const char url[] PROGMEM = "http://10.42.0.1:8000/streamleft";

WebSocketsClient webSocket;
int volume = 12;
// ==============================
// Configuration audio / I2S
// ==============================
// Sortie audio I2S vers ampli / DAC externe.

#define I2S_NUM         I2S_NUM_0
#define I2S_SAMPLE_RATE 44100
#define I2S_BCK_IO      10     // BCLK
#define I2S_WS_IO       11     // LRCLK
#define I2S_DO_IO       12     // Data out
#define SD_PIN          5      // Activation de l’ampli

// ==============================
// Gestion du flux audio
// ==============================
#define SERVER_IP "10.42.0.1"
#define SERVER_PORT 8765

Audio audio;

// ==============================
// Synchronisation temporelle
// ==============================
// Système de pseudo RTC basé sur millis().
// Le serveur envoie une heure cible à laquelle
// l’ESP doit démarrer la lecture audio.

bool synced = false;
uint32_t targetEpochMillis = 0;
bool hasTargetTime = false;

uint32_t baseEpoch = 0;   // timestamp de référence
unsigned long baseMillis = 0; // millis() au moment de la référence

// Enregistre un temps absolu envoyé par le serveur.
void rtcSetTime(uint32_t epochMillis) {
  baseEpoch = epochMillis;
  baseMillis = millis();
}

// Renvoie l’heure courante basée sur la référence connue.
uint32_t rtcGetEpochMillis() {
  uint32_t elapsed = millis() - baseMillis;
  return baseEpoch + elapsed;
}

// ==============================
// Extraction JSON minimaliste
// ==============================
// Extraction très simple d’un champ JSON sans dépendances externes.

bool extractField(const char* json, const char* key, char* buffer, size_t maxLen) {
  const char* p = strstr(json, key);
  if (!p) return false;
  p += strlen(key);

  while (*p && *p != ':') p++;
  if (!*p) return false;
  p++;

  while (*p == ' ' || *p == '\t' || *p == '"') p++;

  size_t i = 0;
  while (*p && *p != '"' && *p != ',' && i < maxLen - 1)
    buffer[i++] = *p++;

  buffer[i] = '\0';
  return (i > 0);
}

// ==============================
// Fonctions Audio
// ==============================

// Démarre la lecture du flux audio
void startAudio(const char* url) {
  Log(F("Connexion au flux audio..."));
  audio.setVolume(volume);
  audio.connecttohost(url);
  digitalWrite(SD_PIN, HIGH);
  Log(F("Lecture audio démarrée."));
}

// Arrête la lecture audio
void stopAudio() {
  Log(F("Arrêt du flux audio..."));
  audio.stopSong();
  digitalWrite(SD_PIN, LOW);
  synced = false;
  Log(F("Lecture arrêtée."));
}

// ==============================
// Gestion WebSocket
// ==============================
// Réception des commandes :
// - Sync : programmation d’une heure de lecture
// - Stop : arrêt du son
// - Volume : réglage volume
// - SetTime : correction du temps interne de l’ESP

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {

    case WStype_DISCONNECTED:
      Log(F("WebSocket déconnecté."));
      break;

    case WStype_CONNECTED:
      Log(F("WebSocket connecté."));
      break;

    case WStype_TEXT: {
      char target[8], command[16], content[32];

      if (!extractField((char*)payload, "target", target, sizeof(target)))
        return;

      Log(F((char*)payload));

      if (strcmp(target, "esp32") != 0)
        return;

      extractField((char*)payload, "command", command, sizeof(command));
      extractField((char*)payload, "content", content, sizeof(content));

      if (strcmp(command, "Sync") == 0) {
        targetEpochMillis = atoll(content);
        hasTargetTime = true;

      } else if (strcmp(command, "Stop") == 0) {
        stopAudio();

      } else if (strcmp(command, "Volume") == 0) {
        volume = atoi(content);
        audio.setVolume(volume);

      } else if (strcmp(command, "SetTime") == 0) {
        rtcSetTime(atoll(content));
      }
    }
    break;

    default:
      break;
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(SD_PIN, OUTPUT);
  digitalWrite(SD_PIN, LOW);

  Log(F("Connexion au WiFi..."));
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Log(F("."));
  }

  Log(F("WiFi connecté."));

  audio.setPinout(I2S_BCK_IO, I2S_WS_IO, I2S_DO_IO);

  // Connexion au serveur WebSocket
  webSocket.begin(SERVER_IP, SERVER_PORT, "/");
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(1000);
}


void loop() {
  webSocket.loop();
  audio.loop();

  if (hasTargetTime) {
    uint32_t now = rtcGetEpochMillis();

    if (now >= targetEpochMillis) {
      Log((char*)"Play");
      startAudio(url);
      hasTargetTime = false;
      targetEpochMillis = 0;
    }
  }
}
