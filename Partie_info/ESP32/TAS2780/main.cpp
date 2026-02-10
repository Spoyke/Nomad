#include <Arduino.h>
#include <Wire.h>

#define TAS2780_ADDR 0x38

#define SDZ 1 // ! à changer pour le vrai code    
#define I2C_SDA 48
#define I2C_SCL 47

#define TDM_CFG0 0x09
#define TDM_CFG1 0x02
#define TDM_CFG2 0x10

void writeRegister(uint8_t addr, uint8_t reg, uint8_t val) {
  Wire.beginTransmission(addr);
  Wire.write(reg);
  Wire.write(val);

  uint8_t error = Wire.endTransmission(); 

  switch(error) {
    case 0:
      return;
      break;
    case 1:
      Serial.println("data too long to fit in transmit buffer.");
      break;
    case 2:
      Serial.println("received NACK on transmit of address.");
      break;
    case 3:
      Serial.println("received NACK on transmit of data.");
      break;
    case 4:
      Serial.println("other error.");
      break;
    case 5:
      Serial.println("Timeout");
  }

  Serial.println(reg, HEX);
}

void checkI2CConnection() {
  Wire.beginTransmission(TAS2780_ADDR);
  byte error = Wire.endTransmission();

  if (error == 0) {
    Serial.println("SUCCÈS : TAS2780 détecté à l'adresse 0x38 !");
  } else if (error == 2) {
    Serial.println("ERREUR : Adresse introuvable (Vérifiez câblage SDA/SCL et SDZ)");
  } else {
    Serial.print("ERREUR : Code d'erreur inconnu : ");
    Serial.println(error);
  }
}


void setup() {
  Serial.begin(115200);
  Wire.begin(I2C_SDA, I2C_SCL);
  delay(2000);

  Serial.println("Preconfiguration du TAS2780...");

  // --- Séquence d'initialisation "Magique" (Book 0 / Page 0 & FD) ---
  writeRegister(TAS2780_ADDR, 0x00, 0x01); // Page 1
  writeRegister(TAS2780_ADDR, 0x37, 0x3A);
  
  writeRegister(TAS2780_ADDR, 0x00, 0xFD); // Page FD
  writeRegister(TAS2780_ADDR, 0x0D, 0x0D);
  writeRegister(TAS2780_ADDR, 0x06, 0xC1);

  writeRegister(TAS2780_ADDR, 0x00, 0x01); // Page 1
  writeRegister(TAS2780_ADDR, 0x19, 0xC0);
  
  writeRegister(TAS2780_ADDR, 0x00, 0xFD); // Page FD
  writeRegister(TAS2780_ADDR, 0x0D, 0x0D);
  writeRegister(TAS2780_ADDR, 0x06, 0xD5);

  // --- Software Reset ---
  writeRegister(TAS2780_ADDR, 0x00, 0x00); // Page 0
  writeRegister(TAS2780_ADDR, 0x7F, 0x00); // Book 0
  writeRegister(TAS2780_ADDR, 0x01, 0x01); // SW Reset
  delay(2); // Un peu plus de marge (2ms)

  // --- Re-application de la configuration après Reset ---
  writeRegister(TAS2780_ADDR, 0x00, 0x01); // Page 1
  writeRegister(TAS2780_ADDR, 0x37, 0x3A);

  writeRegister(TAS2780_ADDR, 0x00, 0xFD); // Page FD
  writeRegister(TAS2780_ADDR, 0x0D, 0x0D);
  // writeRegister(TAS2780_ADDR, 0x06, 0xC1); // Ligne supprimée (inutile car écrasée juste après)
  writeRegister(TAS2780_ADDR, 0x06, 0xD5);

  // --- Configuration Alimentation (ACTUELLEMENT : PWR_MODE2) ---
  Serial.println("Config Alimentation (PWR_MODE2 - LDO Interne ACTIF)");
  writeRegister(TAS2780_ADDR, 0x00, 0x00); // Page 0
  
  // TDM TX (Slots V/I) - Optionnel
  writeRegister(TAS2780_ADDR, 0x0E, 0x44);
  writeRegister(TAS2780_ADDR, 0x0F, 0x40);

  // Optimisations internes
  writeRegister(TAS2780_ADDR, 0x00, 0x01); // Page 1
  writeRegister(TAS2780_ADDR, 0x17, 0xC0);
  writeRegister(TAS2780_ADDR, 0x19, 0x00);
  writeRegister(TAS2780_ADDR, 0x21, 0x00);
  writeRegister(TAS2780_ADDR, 0x35, 0x74);

  writeRegister(TAS2780_ADDR, 0x00, 0xFD); // Page FD
  writeRegister(TAS2780_ADDR, 0x0D, 0x0D);
  writeRegister(TAS2780_ADDR, 0x3E, 0x4A);
  writeRegister(TAS2780_ADDR, 0x0D, 0x00);

  // Registres critiques d'alimentation
  writeRegister(TAS2780_ADDR, 0x00, 0x00); // Page 0
  writeRegister(TAS2780_ADDR, 0x03, 0xE8); // Gain 21dBV, Y-Bridge Low Power
  
  // A1 = LDO Interne activé (Bit 7=1). 
  // ATTENTION : Mettre 0x21 pour le futur PCB en PWR_MODE0 !
  writeRegister(TAS2780_ADDR, 0x04, 0xA1); 
  
  writeRegister(TAS2780_ADDR, 0x71, 0x0E); // UVLO

  // --- Configuration Audio I2S ---
  Serial.println("Config I2S (48kHz, 16-bit)");
  writeRegister(TAS2780_ADDR, 0x08, TDM_CFG0); // 0x09
  writeRegister(TAS2780_ADDR, 0x09, TDM_CFG1); // 0x02
  writeRegister(TAS2780_ADDR, 0x0A, TDM_CFG2); // 0x10

  // --- Activation Finale ---
  writeRegister(TAS2780_ADDR, 0x02, 0x00); // Active (0x00)
  
  Serial.println("Ampli demarre.");

  delay(100);
  checkI2CConnection();
}

void loop() {
}