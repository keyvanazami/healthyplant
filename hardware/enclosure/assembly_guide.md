# Assembly Guide — HealthyPlant Sensor

## Parts Needed
- 3D printed: main body, lid, stake, battery tray
- ESP32-S3 DevKitC-1
- Capacitive Soil Moisture Sensor v2.0
- BH1750 light sensor module
- BME280 temperature/humidity/pressure module
- DS18B20 waterproof soil temperature probe
- 18650 battery + TP4056 charger (outdoor version)
- 4.7k ohm resistor
- Jumper wires / JST connectors
- (Optional) Mini solar panel 6V 1W

## Wiring Diagram

```
ESP32-S3 Pin    →  Component
─────────────────────────────────────
3.3V            →  BH1750 VCC, BME280 VCC, DS18B20 VCC
5V (VIN)        →  Capacitive soil sensor VCC
GND             →  All sensor GNDs
GPIO4           →  Capacitive soil sensor AOUT
GPIO5           →  DS18B20 DATA (+ 4.7k pull-up to 3.3V)
GPIO8 (SDA)     →  BH1750 SDA + BME280 SDA
GPIO9 (SCL)     →  BH1750 SCL + BME280 SCL
```

### Battery Power (outdoor version)
```
Solar panel (+) → TP4056 IN+
Solar panel (-) → TP4056 IN-
TP4056 BAT+     → 18650 (+) terminal
TP4056 BAT-     → 18650 (-) terminal
TP4056 OUT+     → ESP32 5V (VIN)
TP4056 OUT-     → ESP32 GND
```

## Assembly Steps

### Step 1: Wire the sensors
1. Solder headers or JST connectors to each sensor module
2. Connect BH1750 and BME280 to the shared I2C bus (GPIO8/GPIO9)
3. Connect capacitive soil sensor to GPIO4
4. Connect DS18B20 to GPIO5 with 4.7k pull-up resistor to 3.3V
5. Test on breadboard before final assembly

### Step 2: Flash the firmware
1. Connect ESP32 via USB-C
2. Open `firmware/healthyplant-sensor/` in Arduino IDE or PlatformIO
3. Upload the sketch
4. Monitor serial output to verify sensor readings

### Step 3: Assemble the enclosure
1. Place the **battery tray** (with 18650 + TP4056 if outdoor) into the main body
2. Mount the **ESP32** on top of the battery tray — USB-C port aligned with the opening
3. Place **BME280** and **BH1750** modules near the top of the box (they need air/light exposure through the lid vents)
4. Route soil sensor and DS18B20 cables out through the bottom stake mount hole

### Step 4: Attach the stake
1. Thread the **capacitive soil sensor** and **DS18B20 probe** through the stake's wire channel
2. Push the stake's top plug into the body's bottom mount tube — it should friction-fit
3. Secure with a dab of hot glue if loose

### Step 5: Close it up
1. Snap the **lid** onto the main body — clips should click into place
2. For outdoor use: apply silicone sealant around the USB-C port edge
3. (Optional) Clip the **solar panel** onto the lid mount holes with M2.5 screws

### Step 6: First-time setup
1. Power on (plug in USB-C or insert charged battery)
2. LED blinks — sensor is in AP mode
3. On your phone, connect to WiFi network "HealthyPlant-XXXXXX"
4. The setup page opens automatically — enter your home WiFi credentials and device token
5. Sensor restarts, connects to WiFi, and begins sending readings every 15 minutes

## Troubleshooting
- **LED blinks 3 times quickly**: WiFi connection failed — check credentials
- **LED blinks 5 times quickly**: API auth error — verify device token
- **No readings in app**: Check that sensor is paired to a plant profile in Settings > Sensors
- **Soil moisture always 0% or 100%**: Calibrate `SOIL_ADC_DRY` and `SOIL_ADC_WET` in `config.h`
