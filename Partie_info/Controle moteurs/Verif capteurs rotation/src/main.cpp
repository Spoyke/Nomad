#include <Arduino.h>
#include <Wire.h>
#include <esp32-hal-ledc.h>

// put function declarations here:
int AI1 = 5; // GPIO pin for AI1 (pin 5)
int AI2 = 6; // GPIO pin for AI2 (pin 6)
int pwmPin = 8; // GPIO pin for PWM (pin 12)
int pwmChannel = 0;  // LEDC channel (0-15)
int pwmFreq = 20000; // Frequency in Hz
int pwmResolution = 8; // Resolution in bits (0-255 for 8 bit res)
int pinC1 = 47; // GPIO pin for encoder channel 1
int pinC2 = 48; // GPIO pin for encoder channel 2
int prevState = 0;
int encoderPosition = 0; // Position of the encoder

int ledpins[] = {39, 38, 37, 36}; // GPIO pins for LEDs (pins 39, 38, 37, 36)

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

  pinMode(ledpins[0], OUTPUT);
  pinMode(ledpins[1], OUTPUT);
  pinMode(ledpins[2], OUTPUT);
  pinMode(ledpins[3], OUTPUT);
  digitalWrite(ledpins[0], HIGH);
  digitalWrite(ledpins[1], HIGH);
  digitalWrite(ledpins[2], HIGH);
  digitalWrite(ledpins[3], HIGH);

  ledcSetup(pwmChannel, pwmFreq, pwmResolution); // channel, freq, resolution
  ledcAttachPin(pwmPin, pwmChannel); // attach GPIO pin to LEDC channel

  

  digitalWrite(AI1, LOW);
  digitalWrite(AI2, HIGH); // Setting to spin in one direction

  prevState = (digitalRead(pinC1) << 1) | digitalRead(pinC2);
  Serial.println("Setup finished.");
}

void loop() {
  int c1 = digitalRead(pinC1);
  int c2 = digitalRead(pinC2);
  int state = (c1 << 1) | c2;

  ledcWrite(pwmChannel, 100);

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
    Serial.printf("Encoder pos: %d, AI1: %d, AI2: %d\n", encoderPosition, digitalRead(AI1), digitalRead(AI2));
    Serial.printf("PWM duty: %d\n", ledcRead(pwmChannel));
  }

}
