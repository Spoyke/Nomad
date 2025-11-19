#ifndef CHRONO_H
#define CHRONO_H
#include "Arduino.h"

class Chrono{
    public:
        Chrono();
        void start();
        unsigned long getTime();


    private:
        unsigned long _tempsDebut;
        unsigned long _tempsActuel;
        unsigned long _tempsEcoule;
};




#endif // CHRONO_H