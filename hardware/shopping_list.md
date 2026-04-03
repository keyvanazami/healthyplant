# Shopping List — HealthyPlant Sensor (1 Indoor + 1 Outdoor)

## Shared Components (both sensors)

| # | Item | Qty | ~Cost | Amazon |
|---|------|-----|-------|--------|
| 1 | HiLetgo ESP32 ESP-32D USB-C (3-pack) | 1 pack | $17 | [amazon.com/dp/B0CNYK7WT2](https://www.amazon.com/dp/B0CNYK7WT2) |
| 2 | Capacitive Soil Moisture Sensor v2.0 (2-pack) | 1 pack | $8 | [Gikfun 2-Pack](https://www.amazon.com/Gikfun-Capacitive-Corrosion-Resistant-Detection/dp/B07H3P1NRM) |
| 3 | BH1750 Light Sensor GY-302 (5-pack) | 1 pack | $9 | [DAOKI 5-Pack](https://www.amazon.com/DAOKI-GY-302-Intensity-BH1750FVI-Arduino/dp/B08PBJX9JP) |
| 4 | BME280 Temp/Humidity/Pressure (2-pack) | 1 pack | $10 | [ACEIRMC 2-Pack](https://www.amazon.com/Organizer-Temperature-Humidity-Atmospheric-Barometric/dp/B07V5CL3L8) |
| 5 | DS18B20 Waterproof Soil Temp Probe (5-pack) | 1 pack | $9 | [HiLetgo 5-Pack](https://www.amazon.com/HiLetgo-DS18B20-Temperature-Stainless-Waterproof/dp/B00M1PM55K) |
| 6 | Arduino Starter Kit (jumper wires, resistors incl. 4.7k, breadboard) | 1 | $13 | [Keywishbot Starter Kit](https://www.amazon.com/Keywish-Electronics-Breadboard-Resistors-Capacitor/dp/B071FR41WS) |

## Outdoor Sensor Only (battery + solar)

| # | Item | Qty | ~Cost | Amazon |
|---|------|-----|-------|--------|
| 7 | TP4056 USB-C LiPo Charger (3-pack) | 1 pack | $8 | [HiLetgo TP4056 3-Pack](https://www.amazon.com/HiLetgo-Lithium-Charging-Protection-Functions/dp/B07PKND8KG) |
| 8 | 6V 1W Mini Solar Panel (3-pack) | 1 pack | $9 | [uxcell 6V 1W 3-Pack](https://www.amazon.com/Uxcell-a16051700ux0984-Rectangle-Energy-Charger/dp/B01KABA1TI) |
| 9 | 18650 Battery 3000mAh+ | 1 | $5-8 | Search "18650 3000mah battery" (EBL, PKCELL) |

## 3D Printing

| # | Item | Qty | ~Cost | Amazon |
|---|------|-----|-------|--------|
| 10 | PETG Filament 1.75mm (1kg spool) | 1 | $18-22 | Search "PETG filament 1.75mm" (Hatchbox, eSUN, Overture) |

---

## Cost Summary

| Build | Items | Estimated Total |
|-------|-------|-----------------|
| Indoor sensor only | 1-6 | ~$55 |
| Outdoor sensor only | 1-9 | ~$75 |
| **Both (1 indoor + 1 outdoor)** | **1-9** | **~$75** |
| + 3D printing filament | 1-10 | ~$95 |

Most packs include 2-5 units, so you'll have spares for building more sensors later.

## Alternative Board

If you prefer the ESP32-S3 instead of the HiLetgo ESP32-D:

| Item | Amazon |
|------|--------|
| Espressif ESP32-S3-DevKitC-1 (N8R2) | [amazon.com/dp/B09D3S7T3M](https://www.amazon.com/Espressif-ESP32-S3-DevKitC-1-N8R2-Development-Board/dp/B09D3S7T3M) |

See `firmware/healthyplant-sensor/config.h` to switch between board configs.
See `hardware/wiring_diagram_esp32.svg` or `hardware/wiring_diagram_esp32s3.svg` for the matching wiring diagram.
