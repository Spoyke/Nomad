#include "mqtt.h"

WiFiClient espClient;
PubSubClient client(espClient);

// ==============================
// Configuration MQTT
// ==============================
const char* mqtt_server = "test.mosquitto.org";
const int mqtt_port = 1883;
const char* sendTopic = "Nomad/esp32/send";
const char* receiveTopic = "Nomad/esp32/receive";

// ==============================
// Variables globales
// ==============================
static String lastReceivedMsg = "";  // Message reçu

// ==============================
// Callback MQTT
// ==============================
void mqttSend(const char* msg) {
  client.publish(sendTopic, msg);
}

void callback(char* topic, byte* payload, unsigned int length) {
  payload[length] = '\0';
  lastReceivedMsg = String((char*)payload);  // on sauvegarde le message reçu
}

// ==============================
// Fonctions utilitaires
// ==============================
String mqttGetMessage() {
  return lastReceivedMsg;
}

void mqttCleanMessage() {
  lastReceivedMsg = "";
}

// ==============================
// Initialisation MQTT
// ==============================
void mqttReconnect() {
  while (!client.connected()) {
    Serial.print("Connexion au broker MQTT...");

    // Génère un identifiant unique basé sur l'adresse MAC
    String clientId = "ESP32AudioClient_" + String(WiFi.macAddress());

    if (client.connect(clientId.c_str())) {
      Serial.println("Connecté !");
      client.subscribe(receiveTopic);
      Serial.println("Abonné au topic : " + String(receiveTopic));
    } else {
      Serial.print("Échec, rc=");
      Serial.print(client.state());
      Serial.println(" => Reconnexion dans 2s");
      delay(2000);
    }
  }
}

void MqttInit() {
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

// ==============================
// Loop MQTT
// ==============================
void MqttLoop() {
  if (!client.connected()) mqttReconnect();
  client.loop();
}
