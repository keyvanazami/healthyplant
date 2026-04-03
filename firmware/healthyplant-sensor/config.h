#ifndef CONFIG_H
#define CONFIG_H

// ──────────────────────────────────────────────
// Board Selection
// ──────────────────────────────────────────────
// Uncomment ONE of the lines below to match your board:

#define BOARD_ESP32S3    // Espressif ESP32-S3 DevKitC-1 (N8R2)
// #define BOARD_ESP32   // HiLetgo ESP32 ESP-32D (amazon.com/dp/B0CNYK7WT2)

// ──────────────────────────────────────────────

#ifdef BOARD_ESP32S3
  #include "config_esp32s3.h"
#elif defined(BOARD_ESP32)
  #include "config_esp32.h"
#else
  #error "No board selected! Uncomment BOARD_ESP32S3 or BOARD_ESP32 in config.h"
#endif

#endif // CONFIG_H
