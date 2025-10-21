#include <Arduino.h>
#include <WiFi.h>
#include <BLEDevice.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>

// === CONFIGURATION ===
#define WIFI_SCAN_INTERVAL 5
#define BLE_SCAN_INTERVAL 5
#define BLE_SCAN_TIME 3

BLEScan* pBLEScan;

// === CLASSE CALLBACK BLE ===
class MyBLECallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) {
    const char* deviceName = advertisedDevice.getName().c_str();
    const char* deviceAddress = advertisedDevice.getAddress().toString().c_str();
    int rssi = advertisedDevice.getRSSI();

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

    if (rssi > -50)
      Serial.println("  -> Strong signal (likely close)");
    else if (rssi > -70)
      Serial.println("  -> Moderate signal");
    else
      Serial.println("  -> Weak signal (likely far)");
  }
};

// === SETUP ===
void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);
  Serial.println("\nESP32 WiFi + BLE Scanner with Connection");

  // Wi-Fi setup
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  Serial.println("Wi-Fi initialized.");

  // BLE setup
  btStop(); // stop Bluetooth classic to avoid I2S error
  BLEDevice::init("");
  pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyBLECallbacks());
  pBLEScan->setActiveScan(true);
  pBLEScan->setInterval(100);
  pBLEScan->setWindow(99);
  Serial.println("BLE initialized.");
}

// === SCAN Wi-Fi ===
void scanWiFi() {
  Serial.println("\n=== Starting Wi-Fi Scan ===");
  int networkCount = WiFi.scanNetworks();
  if (networkCount == 0) {
    Serial.println("No Wi-Fi networks found.");
    return;
  }

  Serial.printf("Found %d Wi-Fi networks:\n", networkCount);
  for (int i = 0; i < networkCount; ++i) {
    Serial.printf("[%d] SSID: %s | RSSI: %d dBm | Channel: %d\n",
                  i + 1, WiFi.SSID(i).c_str(), WiFi.RSSI(i), WiFi.channel(i));
  }

  Serial.println("\nEnter the number of the network you want to connect to (0 to skip):");
  while (!Serial.available()) delay(10);
  int choice = Serial.parseInt();

  if (choice <= 0 || choice > networkCount) {
    Serial.println("Skipping Wi-Fi connection...");
    WiFi.scanDelete();
    return;
  }

  String ssid = WiFi.SSID(choice - 1);
  Serial.print("You selected: ");
  Serial.println(ssid);

  Serial.println("Enter Wi-Fi password: ");
  while (!Serial.available()) delay(10);
  String password = Serial.readStringUntil('\n');
  password.trim();

  Serial.printf("Connecting to %s...\n", ssid.c_str());
  WiFi.begin(ssid.c_str(), password.c_str());

  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 15000) {
    Serial.print(".");
    delay(500);
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("✅ Wi-Fi connected successfully!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("❌ Failed to connect to Wi-Fi.");
  }

  WiFi.scanDelete();
}

// === SCAN BLE ===
void scanBLE() {
  Serial.println("\n=== Starting BLE Scan ===");
  pBLEScan->start(BLE_SCAN_TIME, false);
  Serial.println("BLE Scan completed.");
  pBLEScan->clearResults();
}

// === LOOP ===
void loop() {
  scanWiFi();
  delay(WIFI_SCAN_INTERVAL * 1000);

  scanBLE();
  delay(BLE_SCAN_INTERVAL * 1000);
}

