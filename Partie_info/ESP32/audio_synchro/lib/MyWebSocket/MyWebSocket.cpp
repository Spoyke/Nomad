#include "MyWebSocket.h"

WebSocketsClient webSocket;
#define SERVER_IP "10.42.0.1"
#define SERVER_PORT 8765

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



void WS_init(void (*fct)(WStype_t type, uint8_t * payload, size_t length)){
  webSocket.begin(SERVER_IP, SERVER_PORT, "/");
  webSocket.onEvent(fct);   
  webSocket.setReconnectInterval(1000);
}

void WS_loop(){
  webSocket.loop();
}