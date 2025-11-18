#include "Chrono.h"

Chrono::Chrono(){
    _tempsDebut  = 0;
    _tempsActuel = 0;
}

void Chrono::start(){
    _tempsDebut = millis();
}

unsigned long Chrono::getTime(){
    _tempsActuel = millis();
    return _tempsActuel - _tempsDebut;
}



