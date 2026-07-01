#pragma once
// EvaISYS ESP32 yapılandırması.
// Değerler platformio.ini içindeki build_flags ile geçilir; burada varsayılanlar tanımlıdır.

#ifndef WIFI_SSID
#define WIFI_SSID "YOUR_WIFI"
#endif
#ifndef WIFI_PASS
#define WIFI_PASS "YOUR_PASS"
#endif
#ifndef BACKEND_URL
#define BACKEND_URL "http://192.168.1.100:3000"
#endif
#ifndef VEHICLE_ID
#define VEHICLE_ID "EVA-001"
#endif
#ifndef DEVICE_TOKEN
#define DEVICE_TOKEN "REPLACE_WITH_DEVICE_TOKEN"  // backend seed/provisioning ile verilir
#endif

// Telemetri gönderim / komut çekme periyodu (ms)
#define TELEMETRY_PERIOD_MS 2000

// --- GPS (UART) ---
#define PIN_GPS_RX 16   // ESP32 RX  <- GPS TX
#define PIN_GPS_TX 17   // ESP32 TX  -> GPS RX
#define GPS_BAUD   9600

// --- CAN / TWAI ---
#define PIN_CAN_TX 21
#define PIN_CAN_RX 22

// --- GPIO pin haritası (kendi donanımınıza göre ayarlayın) ---
#define PIN_IMMOBILIZER 26  // motor/kontrolcü kesme rölesi (HIGH = motor kesik)
#define PIN_LOCK        27  // seat/steering kilit rölesi
#define PIN_BUZZER      25  // anti-hırsızlık sesli alarm
#define PIN_VBAT_ADC    34  // batarya voltajı ölçümü (gerilim bölücü üzerinden)

// Batarya ölçeği (gerilim bölücü oranı) — MVP varsayılanı
#define VBAT_SCALE 20.0f
