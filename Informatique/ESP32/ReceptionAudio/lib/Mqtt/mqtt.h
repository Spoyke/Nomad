#ifndef MQTT_H
#include "Arduino.h"
#include <WiFi.h>
#include <PubSubClient.h>


void mqttSend(const char* msg);
void callback(char* topic, byte* payload, unsigned int length);
String mqttGetMessage();
void mqttCleanMessage();
void mqttReconnect();
void MqttInit();
void MqttLoop();

#endif // MQTT_H