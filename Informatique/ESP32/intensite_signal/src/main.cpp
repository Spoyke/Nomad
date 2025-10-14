#include <Arduino.h>
#include <WiFi.h>
#include <BLEDevice.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>

// Scan intervals (in seconds)
#define WIFI_SCAN_INTERVAL 5
#define BLE_SCAN_INTERVAL 5
#define BLE_SCAN_TIME 3

// Global variables
BLEScan* pBLEScan;

// Define a class to handle BLE scan callbacks
class MyBLECallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) {
    // Extract device details
    const char* deviceName = advertisedDevice.getName().c_str();
    const char* deviceAddress = advertisedDevice.getAddress().toString().c_str();
    int rssi = advertisedDevice.getRSSI();

    // Print BLE device details
    Serial.print("BLE Device: ");
    if (strlen(deviceName) > 0) {
      Serial.print("Name: ");
      Serial.print(deviceName);
      Serial.print(", ");
    }
    Serial.print("Address: ");
    Serial.print(deviceAddress);
    Serial.print(", RSSI: ");
    Serial.print(rssi);
    Serial.println(" dBm");

    // Basic proximity estimation based on RSSI
    if (rssi > -50) {
      Serial.println("  -> Strong signal (likely close)");
    } else if (rssi > -70) {
      Serial.println("  -> Moderate signal");
    } else {
      Serial.println("  -> Weak signal (likely far)");
    }
  }
};

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10); // Wait for Serial to be ready
  Serial.println("ESP32 Signal Scanner Starting...");

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  Serial.println("Wi-Fi initialized.");

  BLEDevice::init(""); 
  pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyBLECallbacks());
  pBLEScan->setActiveScan(true); 
  pBLEScan->setInterval(100); 
  pBLEScan->setWindow(99);   
  Serial.println("BLE initialized.");
}

void scanWiFi() {
  Serial.println("\n=== Starting Wi-Fi Scan ===");
  int networkCount = WiFi.scanNetworks();
  if (networkCount == 0) {
    Serial.println("No Wi-Fi networks found.");
  } else {
    Serial.print("Found ");
    Serial.print(networkCount);
    Serial.println(" Wi-Fi networks:");
    for (int i = 0; i < networkCount; ++i) {
      Serial.print("Wi-Fi Network: SSID: ");
      Serial.print(WiFi.SSID(i));
      Serial.print(", RSSI: ");
      Serial.print(WiFi.RSSI(i));
      Serial.print(" dBm, Channel: ");
      Serial.println(WiFi.channel(i));
      if (WiFi.RSSI(i) > -50) {
        Serial.println("  -> Strong signal (likely close)");
      } else if (WiFi.RSSI(i) > -70) {
        Serial.println("  -> Moderate signal");
      } else {
        Serial.println("  -> Weak signal (likely far)");
      }
    }
  }
  WiFi.scanDelete(); 
}

void scanBLE() {
  Serial.println("\n=== Starting BLE Scan ===");
  pBLEScan->start(BLE_SCAN_TIME, false);
  Serial.println("BLE Scan completed.");
  pBLEScan->clearResults(); 
}

void loop() {
  scanWiFi();
  delay(WIFI_SCAN_INTERVAL * 1000);

  scanBLE();
  delay(BLE_SCAN_INTERVAL * 1000);
}