#ifndef MYI2S_H
#define MYI2S_H

#include <Arduino.h>
#include <WiFi.h>
#include <WebSocketsClient.h>
#include <Audio.h>

extern Audio audio;

void Audio_init();
void Audio_loop();
void playUdpChunk(uint8_t* data, size_t len);
void startAudio(const char* url);
void stopAudio();
void setVolumeLevel(int vol);
#endif // MYI2S_H