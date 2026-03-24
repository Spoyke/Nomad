#include <Arduino.h>
#include <Wire.h>
#include <esp32-hal-ledc.h>

// put function declarations here:
int AI1 = 6; // GPIO pin for AI1 (pin 5)
int AI2 = 7; // GPIO pin for AI2 (pin 6)
int pwmPin = 5; // GPIO pin for PWM
int pwmChannel = 0;  // LEDC channel (0-15)
int pwmFreq = 20000; // Frequency in Hz
int pwmResolution = 8; // Resolution in bits (0-255 for 8 bit res)
int pinC1 = 20; // GPIO pin for encoder channel 1
int pinC2 = 19; // GPIO pin for encoder channel 2
int prevState = 0;
int encoderPosition = 0; // Position of the encoder

// Quadrature transition table: index = (prevState << 2) | state
// +1 = clockwise, -1 = counterclockwise, 0 = no move/invalid
const int8_t transitionTable[16] = {
  0,  -1,  1,   0,
  1,   0,   0,  -1,
  -1,  0,   0,   1,
  0,   1,  -1,   0
};

void setup() {
  Serial.begin(115200);
  pinMode(AI1, OUTPUT);
  pinMode(AI2, OUTPUT);
  pinMode(pinC1, INPUT_PULLUP);
  pinMode(pinC2, INPUT_PULLUP);

  ledcSetup(pwmChannel, pwmFreq, pwmResolution); // channel, freq, resolution
  ledcAttachPin(pwmPin, pwmChannel); // attach GPIO pin to LEDC channel

  ledcWrite(pwmChannel, 255);

  digitalWrite(AI1, LOW);
  digitalWrite(AI2, HIGH); // Setting to spin in one direction

  prevState = (digitalRead(pinC1) << 1) | digitalRead(pinC2);
  Serial.println("Setup finished.");
}

void loop() {
  int c1 = digitalRead(pinC1);
  int c2 = digitalRead(pinC2);
  int state = (c1 << 1) | c2;

  if (state != prevState) {
    int index = (prevState << 2) | state;
    int8_t delta = transitionTable[index];
    if (delta == 1) {
      encoderPosition++;
      //Serial.println("Encoder turned clockwise");
    } else if (delta == -1) {
      encoderPosition--;
      //Serial.println("Encoder turned counterclockwise");
    }
    prevState = state;
  }

  static unsigned long lastPrint = 0;
  if (millis() - lastPrint >= 200) {
    lastPrint = millis();
    Serial.printf("Encoder pos: %d\n", encoderPosition);
  }
}
