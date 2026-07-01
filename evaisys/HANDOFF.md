# EvaISYS — Handoff (Devir) Notu

Bu belge, EvaISYS bağlantılı araç platformunun mevcut durumunu, kanıtlanan işlevleri ve sıradaki
adımları özetler. Amaç: bir sonraki geliştiricinin (siz) hiç bağlam kaybetmeden devam edebilmesi.

Son güncelleme: 2026-07-01 • Branch: `claude/burdaki-system-feasibility-aks7jn` • Konum: `evaisys/`

---

## 1. Ne durumda? (özet)

Uçtan uca çalışan bir MVP: **ESP32 (VCU) → Backend (auth + SQLite + realtime) → Web & Flutter**.
Backend tarafı gerçek çalıştırma ile **kanıtlandı** (9/9 test). Web/Flutter/ESP32 kod olarak tamam;
bu ortamda derleyici olmadığı için Flutter ve ESP32 statik olarak hazır (aşağıda "kanıt durumu").

---

## 2. Yapıldı (Done) — kanıt durumuyla

| Bileşen | İçerik | Kanıt |
|---|---|---|
| Backend REST+WS | telemetri, araç listesi/detay, komut kuyruğu, geçmiş | ✅ çalıştırıldı |
| JWT auth | login, korunmuş uçlar, WS token | ✅ 401/200/4001 doğrulandı |
| Cihaz token | ESP32 uçları `X-Device-Token`, araç eşleşme kontrolü | ✅ 401/403/200 doğrulandı |
| SQLite persistans | araçlar + telemetri geçmişi + komut + kullanıcı/cihaz | ✅ restart sonrası veri korundu |
| Komut akışı | web/app → backend → cihaz çekişi → uygulama | ✅ immobilize → hız 0 |
| Web panel | login, canlı kartlar, Leaflet harita, kontrol, çıkış | ✅ WS auth + statik servis |
| Flutter app | login → filo → detay + komut, token'lı REST | 🟡 kod tam, derlenmedi (SDK yok) |
| ESP32 firmware | WiFi, telemetri, komut, immobilizer/kilit/alarm, **gerçek GPS + CAN(TWAI)**, cihaz token | 🟡 kod tam, derlenmedi (toolchain yok) |
| Repo taşıma | `scripts/migrate-to-standalone-repo.sh` + `MIGRATION.md` | ✅ scratchpad'e taşıma test edildi |
| Fizibilite | SIAVM20 al-veya-yap analizi | ✅ `docs/burdaki-vcu-fizibilite.md` |

**Son doğrulama çıktısı (backend):** 9/9 test geçti — tokensiz red, login, hatalı parola red,
kötü/doğru cihaz token, yanlış araç id red, JWT listeleme, komut çekişi, kalıcı geçmiş.

---

## 3. Nasıl çalıştırılır (yerelde)

```bash
cd evaisys/backend && npm install && npm start      # http://localhost:3000
# Giriş: admin / admin123  (ilk çalıştırmada cihaz token'ları loga yazılır)

node sim/vehicle-sim.js EVA-001                      # donanımsız araç simülatörü
node sim/vehicle-sim.js EVA-002                      # ikinci araç

# Web:    http://localhost:3000  (admin/admin123)
# Flutter: cd ../app/evaisys_app && flutter pub get && flutter run
# ESP32:   firmware/esp32 -> platformio.ini (WiFi/BACKEND_URL/DEVICE_TOKEN) -> pio run -t upload
```

Varsayılan cihaz token'ı (seed): `sha256("<VEHICLE_ID>|evaisys-seed")` ilk 32 karakter.
Örn. EVA-001 → `b4378b1cb12019daf2d43b9e135d5873`. Simülatör bunu otomatik hesaplar.

---

## 4. Yapılacaklar (Next) — öncelik sırası

1. **Flutter'ı gerçek cihazda derle/çalıştır** (`flutter create .` ile platform klasörleri, sonra `flutter run`).
   Token'ı kalıcı saklamak için `shared_preferences` ekle (şu an bellek içi).
2. **ESP32'yi gerçek donanımda doğrula:** CAN ID'lerini (`src/can_bus.cpp`) kendi kontrolcü/BMS
   dokümanınıza göre güncelle; GPS modülünü bağla; röle/buzzer pinlerini kalibre et.
3. **Güvenlik sertleştirme:** `JWT_SECRET` ve `ADMIN_PASS` env ile; HTTPS/WSS; cihaz provisioning
   (token'ları seed yerine üretim akışında üret); rate-limit.
4. **Taşıma katmanı:** HTTP yerine **MQTT + TLS** (ESP32 ↔ backend) — pil/veri verimliliği.
5. **Veritabanı:** SQLite → PostgreSQL/TimescaleDB (telemetri zaman serisi); konum geçmişi & KVKK
   uyumlu saklama/silme politikaları.
6. **OTA:** ESP32 firmware OTA güncelleme; EvaMania OTA kanalıyla hizalama.
7. **Panel/rapor:** geçmiş grafik (batarya/hız trendi), coğrafi çit (geofence), alarm bildirimleri.
8. **Repoyu bağımsızlaştır:** `MIGRATION.md` adımlarıyla `evatechnosoft/evaisys` deposuna taşı
   (bu oturumun izni yeni repo açmaya yetmedi — 403).

---

## 5. Bilinen sınırlamalar / notlar

- **Repo konumu:** İzin kapsamı nedeniyle `evaisys/` bu depo (`evamania-releases`) altında. Bağımsız
  repo elle açılıp `scripts/migrate-to-standalone-repo.sh` ile taşınabilir.
- **Auth basit:** Tek admin kullanıcı (seed). Rol/çoklu kullanıcı, yenileme token'ı yok.
- **Bellek/DB:** `evaisys.db` (WAL) commit'lenmez (`.gitignore`); her ortam kendi verisini üretir.
- **ESP32 CAN/GPS:** ID'ler ve ölçekler örnektir; gerçek araç dokümanı ile değiştirilmeli. Donanım
  yoksa firmware ADC+simülasyon ile çalışır.
- **Test ortamı:** Flutter/PlatformIO SDK'ları bu ortamda yok; ilgili kod statik doğrulandı.

---

## 6. Dosya haritası

```
evaisys/
├── README.md                    # genel bakış + hızlı başlangıç + güvenlik
├── HANDOFF.md                   # bu belge
├── MIGRATION.md                 # bağımsız repoya taşıma
├── docs/                        # veri sözleşmesi + fizibilite
├── backend/                     # Node.js: server.js, auth.js, db.js, store.js, sim/
├── web/                         # index.html, app.js, style.css (login + panel)
├── app/evaisys_app/            # Flutter: lib/{main,config,models,services}
├── firmware/esp32/             # PlatformIO: src/{main.cpp, can_bus.*, config.h}
└── scripts/                     # migrate-to-standalone-repo.sh
```

Devam ederken bu dosyadan başlayın; "Yapılacaklar" listesi öncelik sırasıyla hazırdır.
