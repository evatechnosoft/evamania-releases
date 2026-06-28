# Karluna APK/XAPK Analizi (referans)

> Amaç: Karluna uygulamasının özellik setini ve mimarisini anlayıp EvaMania'ya
> **uyarlanabilir fikirleri** çıkarmak. Karluna'nın özel/şifreli protokolü birebir
> kopyalanmaz; mimari desenler referans alınır.

## Uygulama kimliği
- **Tip:** Flutter (Dart **3.5.3** stable), paket `karluna_ktm` (KTM ortak dev sürümü)
- **Dağıtım:** Google Play App Bundle (base + `config.arm64_v8a` + dil/dpi split'leri)
- **Sunucu uçları:** `memapi.karluna.com.tr` (üyelik), `vhcapi.karluna.com.tr` (araç)

## Teknoloji yığını
flutter_blue_plus (BLE) · Eclipse Paho **MQTT** (gerçek-zamanlı) · firebase
(analytics/crashlytics/**messaging**) · geolocator + flutter_map + **Mapbox** ·
**model_viewer** (3D `.glb`) · background_service · camera/file_picker (QR/belge) ·
encrypt/crypto · hive (yerel db) · secure_storage · dio.

## Mimari (libapp.so paket ağacından)
```
vehicle/   (23)  araç yönetimi, dashboard, şarj, EV istasyon, anahtar, takip
core/      (21)  encryption, hive local-db, secure_storage, connectivity, i18n
ui/        (18)  ortak bileşenler
bluetooth/ (12)  BLE protokol katmanı (aşağıda)
user/      (11)  hesap, profil, kimlik
support/    (6)  destek/SSS/şikayet
settings/   (6)
notification/(5) push + araç bildirimleri
friend/     (5)  arkadaş + QR ekleme
```

## BLE / CAN protokol yapısı
- `bluetooth/data/factory/message_factory.dart` — `MessageFactory`, `MessageModel.parseMessage`
- `CommandBuilderVisitor` — komut paketleyici
- Komut enum'ları: `CommandTypes`, `ManagementCommandIds`, `ParameterCommandIds`
- Modeller: `bt_request`, `bt_message_model`, `bt_result_model`, `bt_event_notification_model`, `bt_parameter_model`, `bt_management_model`
- `core/encryption/service/encryption_service.dart` — mesajlar **şifreli** (AES)
- **CAN köprüsü:** `vehicle/data/model/can_command.dart`, `vehicle_can_dashboard.dart`
  → BLE modülü araç CAN bus'ına köprü; telemetri (batteryLevel/current/range...) CAN'den.

**Özel BLE UUID'leri:**
- `0000fff5-0000-1000-8000-00805f9b34fb`
- `00002902-...` (CCCD / notify descriptor)
- `8df6edae-328f-fc93-9e4f-79ba79e92a93`
- `d3b5a130-9e23-4b3a-8be4-6b1ee5f980a3`

> Komut ID integer değerleri ve byte düzeni derlenmiş kodda (object pool) — düz
> string taramasıyla çıkmaz; tam `blutter` disassembly gerekir. Ancak bu protokol
> Karluna'nın **kendi KTM/CAN donanımına** özel; EvaMania'nın hedef kontrolcüleriyle
> (FarDriver/Votol/JK) **alakasız**, dolayısıyla pratik getirisi düşük + telif/etik
> açıdan kopyalanmamalı.

## BLE yanıt kodları (dil dosyasından — UX deseni olarak alınabilir)
0 Success · 1 Invalid command · 2 Unexpected command · 3 Invalid parameter ·
4 Incorrect payload · 5 Length error · 6 Format error · 7 Value error ·
8 Cancelled · 9 Not authorized · 10 No permission · 11 Too many attempts ·
12 Device outside range · 13 Module not ready · 14 Module busy · 15 Internal error ·
16 Incorrect vehicle state · 17 Permission expired · 18 Timeout · 19 Time error ·
20 Requires two keyfobs · 21 No keyfob response · 22 Keyfob not connected ·
23 Device already verified

## Özellik seti (731 i18n anahtarından)
Hesap/2FA/SSO · **Dijital anahtar** (zaman sınırlı, paylaşım, keyfob 1/2) ·
**Pasif erişim** (Passive Entry/Start/Exit + **BLE RSSI sinyal kalibrasyonu**) ·
Uzaktan kumanda (kilit, far, korna, flaşör, **iklim ısıtıcı/soğutucu**, buğu çözücü) ·
Sürüş modları (Normal/Eco/Düşük Hız/Düşük Enerji) · **Şarj** (planlı, geçmiş,
**EV istasyon haritası**, soket/güç/fiyat, ödeme) · Geofence (daire/dikdörtgen/rota) ·
Canlı konum takibi + geçmiş · Departman/unvan (kurumsal filo) · Arkadaş + QR ·
3D araç modeli · Push bildirim · Belge yönetimi · Destek/SSS.

> **Karluna'da Strava-vari sürüş kaydı YOK** (sadece canlı `tracking_screen`).
> EvaMania'daki ride-tracking modülü bu yüzden farklılaştırıcı.

## EvaMania'ya uyarlanabilir (öncelik sırası)
1. **Sürüş kaydı (Strava-vari)** — bu repodaki `feature-ride-tracking/` ile ✅ yapıldı.
2. **BLE yanıt-kod → mesaj tablosu** (yukarıdaki 24 kod) — UX deseni.
3. **EV şarj istasyonu haritası** (flutter_map + geolocator).
4. **Planlı şarj / menzil-tüketim kartı**.
5. **3D araç görseli** dashboard'da (model_viewer).
6. **Push bildirim** (Firebase Messaging) + gerçek-zamanlı veri (MQTT).
