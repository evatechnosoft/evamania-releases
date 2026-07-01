// EvaISYS — ESP32 TWAI (CAN) okuma implementasyonu.
#include <Arduino.h>
#include "driver/twai.h"
#include "can_bus.h"
#include "config.h"

// --- Örnek CAN mesaj ID'leri (kendi araç dokümanınıza göre değiştirin) ---
#define CAN_ID_CONTROLLER 0x0CF11E05  // hız/RPM taşıyan kontrolcü çerçevesi (örnek)
#define CAN_ID_BMS        0x18FF50E5  // batarya SOC/voltaj taşıyan BMS çerçevesi (örnek)

bool canBegin() {
  twai_general_config_t g = TWAI_GENERAL_CONFIG_DEFAULT(
      (gpio_num_t)PIN_CAN_TX, (gpio_num_t)PIN_CAN_RX, TWAI_MODE_NORMAL);
  twai_timing_config_t t = TWAI_TIMING_CONFIG_250KBITS(); // yaygın: 250k/500k
  twai_filter_config_t f = TWAI_FILTER_CONFIG_ACCEPT_ALL();

  if (twai_driver_install(&g, &t, &f) != ESP_OK) return false;
  if (twai_start() != ESP_OK) return false;
  return true;
}

bool canPoll(CanData& out) {
  twai_message_t msg;
  bool got = false;
  // Kuyruktaki tüm çerçeveleri boşalt (bloklamadan).
  while (twai_receive(&msg, 0) == ESP_OK) {
    switch (msg.identifier) {
      case CAN_ID_CONTROLLER: {
        // Örnek: byte0-1 = hız*10 (little-endian). Kendi ölçeğinize göre uyarlayın.
        uint16_t raw = msg.data[0] | (msg.data[1] << 8);
        out.speedKph = raw / 10.0f;
        out.haveSpeed = true;
        got = true;
        break;
      }
      case CAN_ID_BMS: {
        // Örnek: byte0 = SOC(%), byte1-2 = voltaj*10 (little-endian).
        out.batteryPct = msg.data[0];
        uint16_t v = msg.data[1] | (msg.data[2] << 8);
        out.voltage = v / 10.0f;
        out.haveBattery = true;
        got = true;
        break;
      }
      default:
        break; // ilgilenmediğimiz çerçeveler
    }
  }
  return got;
}
