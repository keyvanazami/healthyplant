#ifndef API_CLIENT_H
#define API_CLIENT_H

#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include "config.h"
#include "sensor_reader.h"

class ApiClient {
public:
  // Returns HTTP status code, or -1 on error
  int postReading(const String& apiUrl, const String& deviceToken, const SensorData& data) {
    WiFiClientSecure client;
    client.setInsecure();  // Skip cert verification (Cloud Run uses valid certs)

    HTTPClient http;
    String url = apiUrl + API_READINGS_PATH;

    http.begin(client, url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-Token", deviceToken);
    http.setTimeout(HTTP_TIMEOUT_SEC * 1000);

    // Build JSON payload
    String json = "{";
    json += "\"soilMoisture\":" + String(data.soilMoisture, 1);
    json += ",\"lightLux\":" + String(data.lightLux, 0);
    json += ",\"temperature\":" + String(data.temperature, 1);
    json += ",\"humidity\":" + String(data.humidity, 1);
    json += ",\"pressure\":" + String(data.pressure, 1);
    if (data.hasSoilTemp) {
      json += ",\"soilTemperature\":" + String(data.soilTemperature, 1);
    }
    // Battery percent (read from ADC if using battery, placeholder for now)
    // json += ",\"batteryPercent\":" + String(getBatteryPercent());
    json += "}";

    Serial.printf("[API] POST %s\n", url.c_str());
    Serial.printf("[API] Body: %s\n", json.c_str());

    int httpCode = http.POST(json);

    if (httpCode > 0) {
      String response = http.getString();
      Serial.printf("[API] Response %d: %s\n", httpCode, response.c_str());
    } else {
      Serial.printf("[API] Error: %s\n", http.errorToString(httpCode).c_str());
    }

    http.end();
    return httpCode;
  }
};

#endif // API_CLIENT_H
