#ifndef CONFIG_H
#define CONFIG_H

// ──────────────────────────────────────────────
// Pin assignments (ESP32-S3 DevKitC-1)
// ──────────────────────────────────────────────
#define PIN_SOIL_MOISTURE   4   // Capacitive sensor analog (ADC1_CH3)
#define PIN_DS18B20         5   // OneWire data (4.7k pull-up to 3.3V)
#define PIN_I2C_SDA         8   // Shared I2C bus (BH1750 + BME280)
#define PIN_I2C_SCL         9   // Shared I2C bus
#define PIN_STATUS_LED      2   // Onboard or external LED

// ──────────────────────────────────────────────
// Soil moisture calibration (12-bit ADC)
// Adjust these after testing your specific sensor
// ──────────────────────────────────────────────
#define SOIL_ADC_DRY        3500  // ADC reading in air (0% moisture)
#define SOIL_ADC_WET        1500  // ADC reading in water (100% moisture)

// ──────────────────────────────────────────────
// Timing
// ──────────────────────────────────────────────
#define READING_INTERVAL_MIN  15    // Minutes between readings
#define WIFI_TIMEOUT_SEC      15    // Max seconds to wait for WiFi
#define HTTP_TIMEOUT_SEC      10    // Max seconds for HTTP POST
#define SENSOR_SAMPLES        3     // Number of samples to average

// ──────────────────────────────────────────────
// API
// ──────────────────────────────────────────────
#define API_DEFAULT_URL  "https://healthyplant-api-prod-236276754022.us-central1.run.app"
#define API_READINGS_PATH  "/api/v1/sensors/readings"

// ──────────────────────────────────────────────
// WiFi AP (provisioning mode)
// ──────────────────────────────────────────────
#define AP_PASSWORD  "plantcare"  // Password for setup AP

// ──────────────────────────────────────────────
// NVS keys (non-volatile storage)
// ──────────────────────────────────────────────
#define NVS_NAMESPACE      "hplant"
#define NVS_WIFI_SSID      "wifi_ssid"
#define NVS_WIFI_PASS      "wifi_pass"
#define NVS_DEVICE_TOKEN   "dev_token"
#define NVS_API_URL        "api_url"

#endif // CONFIG_H
