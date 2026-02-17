#include <Arduino.h>
#include <Wire.h>
#include <esp32-hal-ledc.h>


// put function declarations here:
int AI1 = 26;
int AI2 = 27;


int pwmPin  = 25;
int pwmChannel = 0;  // LEDC channel (0-15)
int pwmFreq = 20000; // Frequency in Hz
int pwmResolution = 6; // Resolution in bits (0-255 for 8 bit res)



void setup() {
  Serial.begin(9600);
  gpio_set_direction((gpio_num_t)AI1, GPIO_MODE_OUTPUT);
  gpio_set_direction((gpio_num_t)AI2, GPIO_MODE_OUTPUT);
  
  ledcSetup(pwmChannel, pwmFreq, pwmResolution); // channel, freq, resolution
  ledcAttachPin(pwmPin, pwmChannel); // attach GPIO pin to LEDC channel

  ledcWrite(pwmChannel, 255); // channel, duty cycle (0-255 for 8 bit resolution) 255 is full speed, 0 is lowest/stopped


  Serial.println("Setup finished.");
}

void loop() {
  // put your main code here, to run repeatedly:
  digitalWrite(AI1, HIGH);
  digitalWrite(AI2, LOW); // Setting to spin in one direction


}