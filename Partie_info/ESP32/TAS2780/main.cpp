#include <Arduino.h>
#include <Wire.h>

#define TAS2780_ADDR 0x38

#define SDZ 1 // ! à changer pour le vrai code    
#define I2C_SDA 48
#define I2C_SCL 47

#define TDM_CFG0 0x09 // Détéction auto de la fréquence + Fréquence d'échantillonnage (44.1/48 kHz) + Activation sur les transitions bas->haut
#define TDM_CFG1 0x02 // Offset de 1 de la communication (propre à l'I2S)
#define TDM_CFG2 0x10 // Mots de 16 bits 

void writeRegister(uint8_t addr, uint8_t reg, uint8_t val) {
  Wire.beginTransmission(addr);
  Wire.write(reg);
  Wire.write(val);

  uint8_t error = Wire.endTransmission(); 

  switch(error) {
    case 0:
      return;
    case 1:
      Serial.println("data too long to fit in transmit buffer.");
      break;
    case 2:
      Serial.println("received NACK on transmit of address.");
      break;
    case 3:
      Serial.println("received NACK on transmit of data.");
      break;
    case 5:
      Serial.println("Timeout");
      break;
    default:
      Serial.println("other error.");
      break;
  }

  Serial.print("0x");
  Serial.println(reg, HEX);
}


void setup() {
  Serial.begin(115200);
  Wire.begin(I2C_SDA, I2C_SCL);
  delay(2000);

  Serial.println("Preconfiguration du TAS2780...");
  // Séquence de préconfiguration indiquée dans la datasheet
  writeRegister(TAS2780_ADDR, 0x00, 0x01);
  writeRegister(TAS2780_ADDR, 0x37, 0x3A);
  
  writeRegister(TAS2780_ADDR, 0x00, 0xFD);
  writeRegister(TAS2780_ADDR, 0x0D, 0x0D);
  writeRegister(TAS2780_ADDR, 0x06, 0xC1);

  writeRegister(TAS2780_ADDR, 0x00, 0x01);
  writeRegister(TAS2780_ADDR, 0x19, 0xC0);
  
  writeRegister(TAS2780_ADDR, 0x00, 0xFD);
  writeRegister(TAS2780_ADDR, 0x0D, 0x0D);
  writeRegister(TAS2780_ADDR, 0x06, 0xD5);

  writeRegister(TAS2780_ADDR, 0x00, 0x00);
  writeRegister(TAS2780_ADDR, 0x7F, 0x00);
  writeRegister(TAS2780_ADDR, 0x01, 0x01);
  delay(2);

  writeRegister(TAS2780_ADDR, 0x00, 0x01);
  writeRegister(TAS2780_ADDR, 0x37, 0x3A);

  writeRegister(TAS2780_ADDR, 0x00, 0xFD);
  writeRegister(TAS2780_ADDR, 0x0D, 0x0D);
  writeRegister(TAS2780_ADDR, 0x06, 0xC1);
  writeRegister(TAS2780_ADDR, 0x06, 0xD5);

  Serial.println("Configuration de l'Alimentation en PWR_MODE2");
  // Séquence de configuration donnée par la datasheet pour le PWR_MODE2 (! à changer pour le futur PCB)
  writeRegister(TAS2780_ADDR, 0x00, 0x00);
  writeRegister(TAS2780_ADDR, 0x0E, 0x44);
  writeRegister(TAS2780_ADDR, 0x0F, 0x40);

  writeRegister(TAS2780_ADDR, 0x00, 0x01);
  writeRegister(TAS2780_ADDR, 0x17, 0xC0);
  writeRegister(TAS2780_ADDR, 0x19, 0x00);
  writeRegister(TAS2780_ADDR, 0x21, 0x00);
  writeRegister(TAS2780_ADDR, 0x35, 0x74);

  writeRegister(TAS2780_ADDR, 0x00, 0xFD);
  writeRegister(TAS2780_ADDR, 0x0D, 0x0D);
  writeRegister(TAS2780_ADDR, 0x3E, 0x4A);
  writeRegister(TAS2780_ADDR, 0x0D, 0x00);

  writeRegister(TAS2780_ADDR, 0x00, 0x00);
  writeRegister(TAS2780_ADDR, 0x03, 0xE8); // Gain 21dBV, Y-Bridge Low Power
  writeRegister(TAS2780_ADDR, 0x04, 0xA1); 
  writeRegister(TAS2780_ADDR, 0x71, 0x0E);

  Serial.println("Configuration de l'amplificateur pour utiliser l'I2S");
  writeRegister(TAS2780_ADDR, 0x08, TDM_CFG0);
  writeRegister(TAS2780_ADDR, 0x09, TDM_CFG1);
  writeRegister(TAS2780_ADDR, 0x0A, TDM_CFG2);

  // Démarrage de du TAS2780
  writeRegister(TAS2780_ADDR, 0x02, 0x00); // Active (0x00)

  delay(100);
  Serial.println("Fin de la configuration de lu TAS2780");
}

void loop() {
}