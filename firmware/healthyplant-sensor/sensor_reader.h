#ifndef SENSOR_READER_H
#define SENSOR_READER_H

#include <Wire.h>
#include <BH1750.h>
#include <Adafruit_BME280.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include "config.h"

struct SensorData {
  float soilMoisture;      // 0-100%
  float lightLux;          // 0-65535
  float temperature;       // °C (air)
  float humidity;          // 0-100%
  float soilTemperature;   // °C (soil)
  float pressure;          // hPa
  bool  hasSoilTemp;       // DS18B20 present?
};

class SensorReader {
public:
  void begin() {
    // I2C bus
    Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);

    // BH1750 light sensor
    _lightOk = _bh1750.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);
    Serial.printf("[Sensors] BH1750: %s\n", _lightOk ? "OK" : "NOT FOUND");

    // BME280 temp/humidity/pressure
    _bmeOk = _bme.begin(0x76, &Wire);
    if (!_bmeOk) _bmeOk = _bme.begin(0x77, &Wire);  // Try alt address
    Serial.printf("[Sensors] BME280: %s\n", _bmeOk ? "OK" : "NOT FOUND");

    // DS18B20 soil temperature
    _oneWire = new OneWire(PIN_DS18B20);
    _ds18b20 = new DallasTemperature(_oneWire);
    _ds18b20->begin();
    _ds18b20Ok = _ds18b20->getDeviceCount() > 0;
    Serial.printf("[Sensors] DS18B20: %s\n", _ds18b20Ok ? "OK" : "NOT FOUND");

    // Soil moisture ADC
    analogReadResolution(12);
    pinMode(PIN_SOIL_MOISTURE, INPUT);
  }

  SensorData read() {
    SensorData data = {};

    // Average multiple samples
    float soilSum = 0, luxSum = 0, tempSum = 0, humSum = 0, pressSum = 0;

    for (int i = 0; i < SENSOR_SAMPLES; i++) {
      // Soil moisture (capacitive, analog)
      int raw = analogRead(PIN_SOIL_MOISTURE);
      float pct = mapFloat(raw, SOIL_ADC_DRY, SOIL_ADC_WET, 0.0, 100.0);
      soilSum += constrain(pct, 0.0, 100.0);

      // Light (BH1750)
      if (_lightOk) {
        luxSum += _bh1750.readLightLevel();
      }

      // Temp + Humidity + Pressure (BME280)
      if (_bmeOk) {
        tempSum += _bme.readTemperature();
        humSum += _bme.readHumidity();
        pressSum += _bme.readPressure() / 100.0;  // Pa → hPa
      }

      if (i < SENSOR_SAMPLES - 1) delay(100);
    }

    data.soilMoisture = soilSum / SENSOR_SAMPLES;
    data.lightLux = _lightOk ? (luxSum / SENSOR_SAMPLES) : 0;
    data.temperature = _bmeOk ? (tempSum / SENSOR_SAMPLES) : 0;
    data.humidity = _bmeOk ? (humSum / SENSOR_SAMPLES) : 0;
    data.pressure = _bmeOk ? (pressSum / SENSOR_SAMPLES) : 0;

    // Soil temperature (DS18B20)
    if (_ds18b20Ok) {
      _ds18b20->requestTemperatures();
      float soilTemp = _ds18b20->getTempCByIndex(0);
      if (soilTemp != DEVICE_DISCONNECTED_C) {
        data.soilTemperature = soilTemp;
        data.hasSoilTemp = true;
      }
    }

    return data;
  }

private:
  BH1750 _bh1750;
  Adafruit_BME280 _bme;
  OneWire* _oneWire;
  DallasTemperature* _ds18b20;
  bool _lightOk = false;
  bool _bmeOk = false;
  bool _ds18b20Ok = false;

  float mapFloat(float x, float inMin, float inMax, float outMin, float outMax) {
    return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }
};

#endif // SENSOR_READER_H
