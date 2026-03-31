/*
 * HealthyPlant Sensor — ESP32-S3 Firmware
 *
 * Reads soil moisture, light, temperature, humidity, and soil temperature.
 * Sends readings to the HealthyPlant API via WiFi every 15 minutes.
 * First-run: starts a WiFi AP with captive portal for provisioning.
 *
 * Hardware:
 *   - ESP32-S3 DevKitC-1 (USB-C)
 *   - Capacitive Soil Moisture Sensor v2.0 (GPIO4)
 *   - BH1750 Light Sensor (I2C)
 *   - BME280 Temp/Humidity/Pressure (I2C)
 *   - DS18B20 Waterproof Soil Temp Probe (GPIO5)
 */

#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include "config.h"
#include "sensor_reader.h"
#include "api_client.h"

// ──────────────────────────────────────────────
// Globals
// ──────────────────────────────────────────────

Preferences prefs;
SensorReader sensors;
ApiClient api;
WebServer server(80);

String storedSSID;
String storedPass;
String storedToken;
String storedApiUrl;

// ──────────────────────────────────────────────
// NVS helpers
// ──────────────────────────────────────────────

void loadSettings() {
  prefs.begin(NVS_NAMESPACE, true);
  storedSSID   = prefs.getString(NVS_WIFI_SSID, "");
  storedPass   = prefs.getString(NVS_WIFI_PASS, "");
  storedToken  = prefs.getString(NVS_DEVICE_TOKEN, "");
  storedApiUrl = prefs.getString(NVS_API_URL, API_DEFAULT_URL);
  prefs.end();
}

void saveSettings(const String& ssid, const String& pass,
                  const String& token, const String& apiUrl) {
  prefs.begin(NVS_NAMESPACE, false);
  prefs.putString(NVS_WIFI_SSID, ssid);
  prefs.putString(NVS_WIFI_PASS, pass);
  prefs.putString(NVS_DEVICE_TOKEN, token);
  prefs.putString(NVS_API_URL, apiUrl);
  prefs.end();

  storedSSID = ssid;
  storedPass = pass;
  storedToken = token;
  storedApiUrl = apiUrl;
}

// ──────────────────────────────────────────────
// WiFi connection
// ──────────────────────────────────────────────

bool connectWiFi() {
  Serial.printf("[WiFi] Connecting to %s...\n", storedSSID.c_str());
  WiFi.mode(WIFI_STA);
  WiFi.begin(storedSSID.c_str(), storedPass.c_str());

  int elapsed = 0;
  while (WiFi.status() != WL_CONNECTED && elapsed < WIFI_TIMEOUT_SEC) {
    delay(1000);
    elapsed++;
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("[WiFi] Connected! IP: %s\n", WiFi.localIP().toString().c_str());
    return true;
  }

  Serial.println("[WiFi] Connection failed");
  return false;
}

// ──────────────────────────────────────────────
// Captive portal (first-run provisioning)
// ──────────────────────────────────────────────

const char SETUP_HTML[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>HealthyPlant Sensor Setup</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #000; color: #fff;
           max-width: 400px; margin: 0 auto; padding: 20px; }
    h1 { color: #00C853; font-size: 22px; }
    label { display: block; margin-top: 16px; color: #aaa; font-size: 14px; }
    input { width: 100%; padding: 12px; margin-top: 4px; border: 1px solid #333;
            border-radius: 8px; background: #111; color: #fff; font-size: 16px;
            box-sizing: border-box; }
    button { width: 100%; padding: 14px; margin-top: 24px; border: none;
             border-radius: 10px; background: #00C853; color: #000;
             font-size: 16px; font-weight: 600; cursor: pointer; }
    .id { color: #00C853; font-family: monospace; font-size: 18px; margin: 8px 0; }
    .note { color: #888; font-size: 12px; margin-top: 8px; }
  </style>
</head>
<body>
  <h1>HealthyPlant Sensor</h1>
  <p>Sensor ID:</p>
  <p class="id">%SENSOR_ID%</p>
  <p class="note">Enter this ID in the HealthyPlant app to pair this sensor.</p>
  <form method="POST" action="/setup">
    <label>WiFi Network Name</label>
    <input name="ssid" required placeholder="Your WiFi SSID">
    <label>WiFi Password</label>
    <input name="pass" type="password" placeholder="WiFi password">
    <label>Device Token</label>
    <input name="token" required placeholder="From HealthyPlant app">
    <label>API URL (optional)</label>
    <input name="api" value="%API_URL%" placeholder="Leave default for production">
    <button type="submit">Save & Connect</button>
  </form>
</body>
</html>
)rawliteral";

String getSensorId() {
  uint8_t mac[6];
  WiFi.macAddress(mac);
  char id[20];
  snprintf(id, sizeof(id), "HP-%02X%02X%02X", mac[3], mac[4], mac[5]);
  return String(id);
}

void handleRoot() {
  String html = String(SETUP_HTML);
  html.replace("%SENSOR_ID%", getSensorId());
  html.replace("%API_URL%", API_DEFAULT_URL);
  server.send(200, "text/html", html);
}

void handleSetup() {
  String ssid  = server.arg("ssid");
  String pass  = server.arg("pass");
  String token = server.arg("token");
  String apiUrl = server.arg("api");

  if (ssid.isEmpty() || token.isEmpty()) {
    server.send(400, "text/plain", "SSID and Token are required");
    return;
  }

  if (apiUrl.isEmpty()) apiUrl = API_DEFAULT_URL;

  saveSettings(ssid, pass, token, apiUrl);

  server.send(200, "text/html",
    "<html><body style='background:#000;color:#fff;font-family:sans-serif;"
    "text-align:center;padding:40px;'>"
    "<h2 style='color:#00C853;'>Setup Complete!</h2>"
    "<p>Connecting to WiFi and starting sensor readings.</p>"
    "<p>You can close this page.</p></body></html>"
  );

  delay(2000);
  ESP.restart();
}

void startProvisioningAP() {
  String apName = "HealthyPlant-" + getSensorId().substring(3);
  Serial.printf("[AP] Starting provisioning AP: %s\n", apName.c_str());

  WiFi.mode(WIFI_AP);
  WiFi.softAP(apName.c_str(), AP_PASSWORD);

  Serial.printf("[AP] IP: %s\n", WiFi.softAPIP().toString().c_str());

  server.on("/", handleRoot);
  server.on("/setup", HTTP_POST, handleSetup);
  server.onNotFound(handleRoot);  // Captive portal redirect
  server.begin();

  // Blink LED to indicate AP mode
  pinMode(PIN_STATUS_LED, OUTPUT);
  Serial.println("[AP] Waiting for setup via http://192.168.4.1 ...");

  while (true) {
    server.handleClient();
    digitalWrite(PIN_STATUS_LED, (millis() / 500) % 2);  // Blink
    delay(10);
  }
}

// ──────────────────────────────────────────────
// Deep sleep
// ──────────────────────────────────────────────

void enterDeepSleep() {
  uint64_t sleepUs = (uint64_t)READING_INTERVAL_MIN * 60 * 1000000;
  Serial.printf("[Sleep] Sleeping for %d minutes...\n", READING_INTERVAL_MIN);
  Serial.flush();
  esp_sleep_enable_timer_wakeup(sleepUs);
  esp_deep_sleep_start();
}

// ──────────────────────────────────────────────
// LED status
// ──────────────────────────────────────────────

void blinkLED(int count, int onMs, int offMs) {
  pinMode(PIN_STATUS_LED, OUTPUT);
  for (int i = 0; i < count; i++) {
    digitalWrite(PIN_STATUS_LED, HIGH);
    delay(onMs);
    digitalWrite(PIN_STATUS_LED, LOW);
    if (i < count - 1) delay(offMs);
  }
}

// ──────────────────────────────────────────────
// Main
// ──────────────────────────────────────────────

void setup() {
  Serial.begin(115200);
  delay(100);

  Serial.println("\n========================================");
  Serial.println("  HealthyPlant Sensor v1.0.0");
  Serial.printf("  Sensor ID: %s\n", getSensorId().c_str());
  Serial.println("========================================\n");

  // Load saved settings
  loadSettings();

  // If no WiFi configured, start provisioning AP
  if (storedSSID.isEmpty() || storedToken.isEmpty()) {
    Serial.println("[Setup] No WiFi/token configured — starting AP...");
    startProvisioningAP();
    // Never returns — runs AP server loop
  }

  // Connect to WiFi
  if (!connectWiFi()) {
    Serial.println("[Error] WiFi failed — going back to sleep");
    blinkLED(3, 100, 100);  // Quick red blinks = error
    enterDeepSleep();
    return;
  }

  // Initialize sensors
  sensors.begin();

  // Read all sensors
  Serial.println("[Sensors] Reading...");
  SensorData data = sensors.read();

  Serial.printf("  Soil Moisture: %.1f%%\n", data.soilMoisture);
  Serial.printf("  Light:         %.0f lux\n", data.lightLux);
  Serial.printf("  Temperature:   %.1f°C\n", data.temperature);
  Serial.printf("  Humidity:      %.1f%%\n", data.humidity);
  Serial.printf("  Pressure:      %.1f hPa\n", data.pressure);
  if (data.hasSoilTemp) {
    Serial.printf("  Soil Temp:     %.1f°C\n", data.soilTemperature);
  }

  // POST to API
  int httpCode = api.postReading(storedApiUrl, storedToken, data);

  if (httpCode == 201) {
    Serial.println("[OK] Reading submitted successfully");
    blinkLED(2, 200, 100);  // 2 blinks = success
  } else if (httpCode == 401) {
    Serial.println("[Error] Invalid token — clear settings to re-provision");
    blinkLED(5, 100, 100);  // 5 quick blinks = auth error
  } else {
    Serial.printf("[Error] HTTP %d — will retry next cycle\n", httpCode);
    blinkLED(3, 100, 100);  // 3 blinks = general error
  }

  // Disconnect WiFi and sleep
  WiFi.disconnect(true);
  enterDeepSleep();
}

void loop() {
  // Never reached — setup() ends with deep sleep
}
