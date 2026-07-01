# EvaISYS — Bağlantılı Araç / VCU Telemetri Platformu (MVP)

EvaISYS, elektrikli iki tekerlekli araçlar için **kendi VCU + telemetri + uzaktan kontrol** yığınıdır.
SIAECOSYS **SIAVM20** VCU Smart Cloud System ürününe **açık, kendi markanızda** bir alternatif olarak
tasarlanmıştır (bkz. [`docs/burdaki-vcu-fizibilite.md`](docs/burdaki-vcu-fizibilite.md)).

> **Durum:** MVP iskeleti. Uçtan uca akış çalışır durumda (ESP32 → Backend → Web/Flutter).
> Donanım pinleri ve kimlik doğrulama gibi üretim detayları basitleştirilmiştir.

## Bileşenler

| Klasör | Bileşen | Teknoloji | Rol |
|---|---|---|---|
| [`firmware/esp32`](firmware/esp32) | Araç düğümü (VCU) | ESP32 / Arduino (PlatformIO) | Telemetri toplar, komut uygular (immobilizer, alarm) |
| [`backend`](backend) | Bulut/API | Node.js (Express + ws + SQLite) | Auth (JWT + cihaz token), telemetri, komut kuyruğu, kalıcı depo, gerçek zamanlı yayın |
| [`web`](web) | İzleme paneli | Vanilla HTML/JS + Leaflet | Canlı harita, araç durumu, uzaktan kontrol |
| [`app`](app/evaisys_app) | Mobil uygulama | Flutter | Araç listesi/detay, telemetri, uzaktan komut |
| [`docs`](docs) | Dokümanlar | Markdown | Fizibilite, veri sözleşmesi |

## Mimari

```
        CAN/sensör                 4G/WiFi (HTTP+JSON)              WebSocket
[Araç: motor/batarya] → [ESP32 VCU] ───────────────→ [Backend] ──────────────→ [Web Panel]
                              ↑                          │  ↑                        
                              └──── komut (poll) ────────┘  └──── REST/WS ───→ [Flutter App]
```

- **Telemetri:** ESP32 her birkaç saniyede bir `POST /api/telemetry` ile durum gönderir.
- **Komut:** Web/App `POST /api/vehicles/:id/command` çağırır; ESP32 `GET /api/vehicles/:id/commands`
  ile bekleyen komutları çeker ve uygular (kilit/aç, immobilize, alarm).
- **Gerçek zamanlı:** Backend, telemetri ve komut olaylarını WebSocket ile panellere yayınlar.

Ortak JSON veri sözleşmesi: [`docs/veri-sozlesmesi.md`](docs/veri-sozlesmesi.md).

## Hızlı Başlangıç

```bash
# 1) Backend (Node 18+; native better-sqlite3 derler)
cd backend
npm install
npm start            # http://localhost:3000  (web panel bu adreste sunulur)
#    İlk çalıştırmada admin kullanıcısı ve cihaz token'ları oluşturulur (loga yazılır).
#    Varsayılan giriş:  admin / admin123   (ADMIN_USER/ADMIN_PASS env ile değiştirin)

# 2) Simüle araç (donanım olmadan uçtan uca test) — cihaz token'ını otomatik hesaplar
node sim/vehicle-sim.js EVA-001

# 3) Web panel
#    Tarayıcıda http://localhost:3000 açın, admin / admin123 ile giriş yapın

# 4) Flutter app
cd ../app/evaisys_app
flutter pub get
flutter run          # API_BASE'i backend adresinize göre ayarlayın (--dart-define=API_BASE=...)

# 5) ESP32
#    firmware/esp32 -> platformio.ini içinde WiFi, BACKEND_URL ve DEVICE_TOKEN ayarlayın
#    (DEVICE_TOKEN backend seed logundan alınır), derleyip yükleyin
```

## Güvenlik / kimlik doğrulama
- **Kullanıcı:** `POST /api/auth/login` → JWT. Tüm izleme/komut uçları `Authorization: Bearer <jwt>` ister.
- **Cihaz (ESP32):** telemetri/komut çekme uçları `X-Device-Token` ister; token yalnızca kendi aracına yetkilidir.
- **WebSocket:** `ws://host/ws?token=<jwt>` — token yoksa bağlantı reddedilir (4001).
- Üretim için: `JWT_SECRET`, `ADMIN_PASS` env değerlerini değiştirin; HTTPS/WSS ve MQTT+TLS kullanın.

## Yol Haritası (MVP sonrası)
- Kimlik doğrulama (JWT) ve cihaz eşleştirme (device provisioning)
- MQTT/TLS taşıma, kalıcı veritabanı (şu an bellek içi)
- Gerçek CAN entegrasyonu (kontrolcü/BMS mesaj çözümleme)
- KVKK uyumlu veri saklama ve konum geçmişi
- OTA firmware güncelleme (EvaMania OTA kanalıyla hizalı)

Ayrıntılı iş gerekçesi ve al-veya-yap kararı için: [`docs/burdaki-vcu-fizibilite.md`](docs/burdaki-vcu-fizibilite.md).
