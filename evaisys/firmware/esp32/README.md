# EvaISYS ESP32 VCU Düğümü (Firmware)

Elektrikli aracın üzerine takılan ESP32 tabanlı VCU düğümü. Telemetri gönderir ve uzaktan
komutları (kilit, immobilizer, alarm) uygular.

## Gereksinimler
- [PlatformIO](https://platformio.org/) (VS Code eklentisi veya CLI)
- ESP32 geliştirme kartı (esp32dev)

## Kurulum
1. `platformio.ini` → `build_flags` içinde şunları düzenleyin:
   - `WIFI_SSID`, `WIFI_PASS`
   - `BACKEND_URL` (backend sunucunuzun adresi, ör. `http://192.168.1.100:3000`)
   - `VEHICLE_ID` (her araç için benzersiz)
2. Derleyip yükleyin:
   ```bash
   pio run -t upload
   pio device monitor
   ```

## Pin Haritası (config.h)
| Pin | İşlev |
|---|---|
| GPIO26 | Immobilizer rölesi (motor kesme) |
| GPIO27 | Kilit rölesi |
| GPIO25 | Buzzer (alarm) |
| GPIO34 | Batarya voltajı (ADC, gerilim bölücü) |

> **Güvenlik:** Immobilizer ve kilit röleleri güç hattını anahtarlar; uygun röle/MOSFET ve
> koruma (flyback diyot, sigorta) kullanın. Pinleri kendi donanımınıza göre `config.h`'de güncelleyin.

## Notlar (MVP)
- Hız ve GPS şimdilik simüle edilir. Üretimde:
  - Hız/batarya değerlerini **CAN** üzerinden kontrolcü/BMS'ten okuyun.
  - GPS için `TinyGPSPlus` ile bir NEO-6M/NEO-M8N modülü bağlayın.
- Taşıma katmanı HTTP'dir; üretimde **MQTT + TLS** ve cihaz kimlik doğrulaması önerilir.
