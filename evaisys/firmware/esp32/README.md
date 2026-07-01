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
| GPIO16/17 | GPS UART (RX/TX) — NEO-6M/M8N |
| GPIO21/22 | CAN/TWAI (TX/RX) — SN65HVD230 vb. transceiver üzerinden |

## Kimlik doğrulama (cihaz token)
Backend, telemetri/komut uçlarını **cihaz token** ile korur. İlk çalıştırmada backend loguna
her araç için bir token yazılır (`[seed] cihaz token'ı EVA-001: ...`). Bu değeri
`platformio.ini` içindeki `DEVICE_TOKEN` flag'ine yazın.

## Gerçek CAN / GPS
- **CAN:** `src/can_bus.cpp` içindeki `CAN_ID_CONTROLLER` / `CAN_ID_BMS` ID'leri ve byte
  çözümleri **örnektir** — kendi kontrolcü/BMS CAN dokümanınıza göre güncelleyin. TWAI 250kbps
  varsayılıdır (gerekirse `TWAI_TIMING_CONFIG_500KBITS`).
- **GPS:** TinyGPSPlus ile Serial2 üzerinden okunur; geçerli fix yoksa son bilinen konum korunur.
- CAN/GPS bulunamazsa firmware **ADC + simülasyon** ile çalışmaya devam eder (MVP kolaylığı).

> **Güvenlik:** Immobilizer ve kilit röleleri güç hattını anahtarlar; uygun röle/MOSFET ve
> koruma (flyback diyot, sigorta) kullanın. Pinleri kendi donanımınıza göre `config.h`'de güncelleyin.

## Notlar (MVP)
- Hız ve GPS şimdilik simüle edilir. Üretimde:
  - Hız/batarya değerlerini **CAN** üzerinden kontrolcü/BMS'ten okuyun.
  - GPS için `TinyGPSPlus` ile bir NEO-6M/NEO-M8N modülü bağlayın.
- Taşıma katmanı HTTP'dir; üretimde **MQTT + TLS** ve cihaz kimlik doğrulaması önerilir.
