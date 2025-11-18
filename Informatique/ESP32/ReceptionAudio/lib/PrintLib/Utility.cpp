#include <Utility.h>

void debugPrint(char txt){
  #if DEBUG
    Serial.print(txt);
  #endif
}

void debugPrint(String txt){
  #if DEBUG
    Serial.print(txt);
  #endif
}

void debugPrintln(String txt){
  #if DEBUG
    Serial.print(txt);
  #endif
}

void debugPrint(const char* txt){
  #if DEBUG
    Serial.print(txt);
  #endif
}

void debugPrintln(const char* txt){
  #if DEBUG
    Serial.println(txt);
  #endif
}