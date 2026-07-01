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

// Telemetri gönderim / komut çekme periyodu (ms)
#define TELEMETRY_PERIOD_MS 2000

// --- GPIO pin haritası (kendi donanımınıza göre ayarlayın) ---
#define PIN_IMMOBILIZER 26  // motor/kontrolcü kesme rölesi (HIGH = motor kesik)
#define PIN_LOCK        27  // seat/steering kilit rölesi
#define PIN_BUZZER      25  // anti-hırsızlık sesli alarm
#define PIN_VBAT_ADC    34  // batarya voltajı ölçümü (gerilim bölücü üzerinden)

// Batarya ölçeği (gerilim bölücü oranı) — MVP varsayılanı
#define VBAT_SCALE 20.0f
