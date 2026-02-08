#ifndef MYWEBSOCKET_H
#define MYWEBSOCKET_H

#include <Arduino.h>
#include <WiFi.h>
#include <WebSocketsClient.h>

bool extractField(const char* json, const char* key, char* buffer, size_t maxLen);
void WS_init(void (*fct)(WStype_t type, uint8_t * payload, size_t length));
void WS_loop();

#endif // MYWEBSOCKET_H