#ifndef UTILITY_H
#include "Arduino.h"

#define DEBUG true

void debugPrint(char txt);
void debugPrint(String txt);
void debugPrintln(String txt);
void debugPrint(const char* txt);
void debugPrintln(const char* txt);



#endif // UTILITY_H