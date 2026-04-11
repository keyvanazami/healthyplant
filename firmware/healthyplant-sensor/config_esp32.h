#ifndef CONFIG_ESP32_H
#define CONFIG_ESP32_H

// ──────────────────────────────────────────────
// Board: HiLetgo ESP32 ESP-32D (38-pin, USB-C)
// ──────────────────────────────────────────────
// Product: amazon.com/dp/B0CNYK7WT2
// Chip:    ESP32-D (dual-core Xtensa LX6, 240MHz)
// Flash:   4MB  |  SRAM: 520KB
// USB:     USB-C via CP2102 UART bridge
// ──────────────────────────────────────────────

// ── Pin Assignments ─────────────────────────────
//
//  ESP32 Pin       Sensor              Notes
//  ──────────      ──────              ─────
//  GPIO34          Soil Moisture AOUT  ADC1_CH6, input-only pin (perfect for ADC)
//  GPIO4           DS18B20 DATA        OneWire, 4.7k pull-up to 3.3V
//  GPIO21          I2C SDA             BH1750 + BME280 (shared bus) — ESP32 default
//  GPIO22          I2C SCL             BH1750 + BME280 (shared bus) — ESP32 default
//  GPIO2           Status LED          Onboard blue LED
//
// IMPORTANT: On the original ESP32, ADC2 (GPIO0,2,4,12-15,25-27)
// cannot be used while WiFi is active. Use ADC1 pins (GPIO32-39) only.
//
#define PIN_SOIL_MOISTURE   34
#define PIN_DS18B20         4
#define PIN_I2C_SDA         21
#define PIN_I2C_SCL         22
#define PIN_STATUS_LED      2

// ── Soil Moisture Calibration (12-bit ADC) ──────
// Test your sensor: hold in air → note ADC value (dry)
//                   dip in water → note ADC value (wet)
#define SOIL_ADC_DRY        3500  // ADC reading in air (0% moisture)
#define SOIL_ADC_WET        1500  // ADC reading in water (100% moisture)

// ── Timing ──────────────────────────────────────
#define READING_INTERVAL_MIN  15    // Minutes between readings
#define WIFI_TIMEOUT_SEC      15    // Max seconds to wait for WiFi
#define HTTP_TIMEOUT_SEC      10    // Max seconds for HTTP POST
#define SENSOR_SAMPLES        3     // Number of samples to average

// ── API ─────────────────────────────────────────
#define API_DEFAULT_URL  "https://healthyplant-api-prod-fajtqt5o2a-uc.a.run.app"
#define API_READINGS_PATH  "/api/v1/sensors/readings"

// ── WiFi AP (provisioning mode) ─────────────────
#define AP_PASSWORD  "plantcare"

// ── NVS Keys ────────────────────────────────────
#define NVS_NAMESPACE      "hplant"
#define NVS_WIFI_SSID      "wifi_ssid"
#define NVS_WIFI_PASS      "wifi_pass"
#define NVS_DEVICE_TOKEN   "dev_token"
#define NVS_API_URL        "api_url"

#endif // CONFIG_ESP32_H
