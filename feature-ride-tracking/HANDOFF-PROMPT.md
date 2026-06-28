# PC'deki Claude Code için görev (EvaMania private repo)

> Bu dosyayı/aşağıdaki promptu, **private EvaMania uygulama reposunun** açık
> olduğu Claude Code oturumuna ver. Amaç: hazır sürüş-kaydı modülünü uygulamaya
> entegre etmek ve **OTA APK** çıkarmak.

---

## PROMPT (kopyala-yapıştır)

EvaMania (Flutter + Shorebird) uygulamasına, ayrı bir repoda hazırladığım
**sürüş kaydı (Strava-vari) veri sistemi** modülünü entegre et ve bir **OTA
sürümü** (APK + version.json release asset) çıkar.

### 1. Modülü getir
- Kaynak: `evatechnosoft/evamania-releases` reposu, branch
  `claude/karluna-apk-analysis-f03p5b`, klasör `feature-ride-tracking/`.
- `feature-ride-tracking/lib/features/ride_tracking/` klasörünü olduğu gibi bu
  uygulamanın `lib/features/ride_tracking/` altına kopyala.
- `feature-ride-tracking/README.md` ve `pubspec-snippet.yaml` entegrasyon
  rehberidir; oku.

### 2. Bağımlılıklar
`pubspec.yaml`'a ekle (zaten varsa atla, sürümleri projeyle uyumlu tut):
`geolocator`, `geocoding`, `flutter_map`, `latlong2`, `path_provider`,
`model_viewer_plus` (3D istemiyorsan bunu ve `vehicle_3d_view.dart`'ı + ilgili
parametreyi çıkar). Sonra `flutter pub get`.

### 3. İzinler
- Android `AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
  (mevcut değilse). Arka planda kayıt isteniyorsa `ACCESS_BACKGROUND_LOCATION`
  + foreground service.
- iOS `Info.plist`: `NSLocationWhenInUseUsageDescription`.

### 4. BLE telemetrisini bağla (EN ÖNEMLİ ADIM)
Modül `RideRecorder.updateTelemetry(...)` ile besleniyor. Uygulamadaki mevcut
kontrolcü/BMS okuma kodunu (FarDriver / Votol / JK / Daly / ANT / Wooliis BLE
handler'ları) bul ve **gerçek değişkenleri** bu çağrıya bağla. İmza:

```dart
recorder.updateTelemetry({
  double? vehicleSpeedKmh, double? rpm, String? mode, double? throttlePct,
  double? voltage, double? current, double? soc, double? remainingAh,
  double? consumedAh, double? packVoltage, double? batteryCurrent,
  int? cellMinMv, int? cellMaxMv, int? cycles,
  double? motorTempC, double? controllerTempC, double? batteryTempC,
  List<String>? faults,
});
```
Sadece elindeki alanları geç; gerisi null kalabilir. `faults` için mevcut
FarDriver arıza-bitmask çözümünün ürettiği etiket listesini ver.

### 5. UI giriş noktası
Mevcut navigasyona/menüye bir giriş ekle:
- "Sürüşlerim" → `RideListPage()`
- Kayıt başlat/bitir butonu: `RideRecorder` örneği oluştur, `start()` /
  `stop()`; bitince `RideGeocoder(localeIdentifier: <aktif dil>).annotate(ride)`,
  sonra `RideStore().save(ride)` ve `RideSummaryPage(ride: ...)`.
- **3D Replay** dahildir: `RideSummaryPage` içindeki "3D Replay" butonu
  `Ride3DReplay(ride: ...)`'i açar (takip kameralı animasyonlu replay, oynat/
  sürgü/hız + telemetri HUD; bağımlılıksız `CustomPainter`).
Tek import: `import 'package:<app_paket>/features/ride_tracking/ride_tracking.dart';`

### 6. i18n
Modüldeki UI metinleri şimdilik Türkçe gömülü. EvaMania'nın mevcut TR/EN i18n
sistemine taşı (string'leri çeviri anahtarlarıyla değiştir). Gerekirse DE de ekle.

### 7. Doğrula
- `flutter analyze` (sıfır hata).
- Mümkünse cihaz/emülatörde: kayıt başlat → hareket → bitir → harita + istatistik
  + CSV/JSON dosyalarının `<docs>/rides/` altına yazıldığını gör.

### 8. OTA sürümü çıkar
- Sürüm numarasını bir artır (mevcut desen `vMAJOR.MINOR.PATCH+BUILD`,
  en son `v1.16.5+71`). `pubspec.yaml` version'ı güncelle.
- Projenin mevcut OTA/Shorebird sürüm akışını uygula (önceki release'lerin nasıl
  üretildiğine bak — Shorebird patch + APK-OTA iki katman aktif, bkz. v1.16.1+55
  notu). Release script'i/CI varsa onu kullan.
- `evatechnosoft/evamania-releases` reposuna yeni release: **APK + version.json**
  asset olarak (dosya adında build no, OTA indirme sorununu önlemek için —
  bkz. v1.16.5+68 notu).
- Release notuna sürüş-kaydı özelliğini ekle.

### 9. Ek kolaylık modülleri (entegre et)
Aynı branch'te iki ek modül var; bunları da entegre et:

**a) Otomatik sürüş kaydı** — `feature-ride-tracking` içinde
`services/auto_trip_controller.dart` (aynı `ride_tracking` modülünün parçası).
`AutoTripController` ile sürüş bağlanınca/hareket edince **otomatik** başlar,
durunca biter + geocode + kaydeder. Manuel `RideRecorder` yerine bunu kullan:
```dart
final auto = AutoTripController(onTripSaved: (ride) => listeyiYenile());
auto.setConnected(bleConnected);
// telemetri döngüsünde:
auto.tick(speedKmh: speed);
auto.updateTelemetry(voltage: v, current: i, soc: soc, motorTempC: mt, ...);
```

**b) Sesli asistan + alarm motoru** — `feature-rider-assist/lib/features/rider_assist/`
klasörünü uygulamanın `lib/`'ine kopyala. `pubspec`'e `flutter_tts: ^4.2.0` ekle.
Eşik tabanlı sesli (TTS) uyarı + titreşim + periyodik durum anonsu.
```dart
import 'package:<app>/features/rider_assist/rider_assist.dart';
final assist = VoiceAssistant(announceStatus: true)..start();
// telemetri döngüsünde:
assist.update(RiderTelemetry(speedKmh: s, soc: soc, motorTempC: mt,
    cellMinMv: cMin, cellMaxMv: cMax, faults: activeFaults));
```
Ayarlar ekranına alarm eşiklerini düzenleme + sesi aç/kapat (`assist.muted`)
ekle. Kurallar `AlarmRule.toJson/fromJson` ile saklanabilir.
`feature-rider-assist/README.md`'yi oku.

**c) Tuning preset yöneticisi** — `feature-tuning-presets/lib/features/tuning_presets/`
klasörünü kopyala. `pubspec`'e `path_provider`, `qr_flutter`, `mobile_scanner`
ekle. Ayar profillerini kaydet/tek dokunuşla uygula/QR paylaş-tara. EN ÖNEMLİ:
`PresetListPage(onApply: ...)` callback'inde `preset.params`'i kontrolcüye BLE
ile yaz (uygulamadaki mevcut parametre-yazma koduna bağla); aralık/limit
doğrulamasını uygulama tarafında yap. `knownKeys`'e kontrolcünün gerçek parametre
anahtarlarını ver. `feature-tuning-presets/README.md`'yi oku.

**d) Kaza algılama + SOS** — `feature-crash-sos/lib/features/crash_sos/`
klasörünü kopyala. `pubspec`'e `sensors_plus`, `geolocator`, `url_launcher`,
`path_provider` ekle. `CrashSosController`'ı başlat, `controller.setSpeed(hız)`
besle, uygulama köküne `CrashSosListener` koy, ayarlar ekranına
`CrashSosSettingsPage`. Varsayılan gönderim cihazın SMS uygulamasını açar;
dokunmasız otomatik gönderim için kendi `SosSender`'ını enjekte et.
`feature-crash-sos/README.md`'yi oku. (Güvenlik: kaza algılama garanti değildir.)

### Notlar
- Uygulama kodu private; modüller `evamania-releases`'te sadece referans olarak duruyor.
- Modül `flutter analyze`'dan geçecek şekilde yazıldı ama hazırlandığı ortamda
  Flutter SDK yoktu; ilk `analyze`'da küçük uyum düzeltmeleri gerekebilir.
- **3D animasyonlu replay dahil** (`ride_replay_3d.dart`) — ekstra paket/token
  gerektirmez; sadece `flutter analyze` ile uyumunu doğrula.
- Karluna analizinden çıkan ek fikirler `feature-ride-tracking/KARLUNA-ANALYSIS.md`'de
  (EV şarj istasyonu haritası, planlı şarj, BLE yanıt-kod tablosu) — bu görevin
  kapsamı dışında, sonraki sürümlere bırakılabilir.
