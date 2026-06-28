# EvaMania — Sürüş Kaydı (Strava-vari) Modülü

GPS ile sürüş kaydeden; rotayı **hız renkli** harita üzerinde gösteren; mesafe,
ortalama/maks hız, süre, tırmanış ve (telemetri bağlarsan) Ah/km tüketim
çıkaran; her sürüşü **JSON + CSV** (yol + adres bilgisiyle) olarak saklayan,
kendi içinde çalışan bir Flutter modülü. Opsiyonel **3D araç görseli** içerir.

> Bu modül `evamania-releases` (OTA kanalı) reposunda **referans** olarak durur.
> Kodu kendi private uygulama reponun `lib/` ağacına kopyalayıp kullan.

## Kurulum

1. `lib/features/ride_tracking/` klasörünü uygulamanın `lib/`'ine kopyala.
2. `pubspec-snippet.yaml` içindeki bağımlılıkları `pubspec.yaml`'a ekle → `flutter pub get`.
3. İzinler (çoğu zaten EvaMania'da var):
   - **Android** `AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
     (arka planda kayıt istersen `ACCESS_BACKGROUND_LOCATION` + foreground service).
   - **iOS** `Info.plist`: `NSLocationWhenInUseUsageDescription`
     (arka plan için `NSLocationAlwaysAndWhenInUseUsageDescription` + background mode).
4. 3D istiyorsan bir `.glb`'yi `assets/models/vehicle.glb` olarak ekle
   (Karluna'daki gibi). İstemiyorsan `model_viewer_plus`'ı ve
   `vehicleModelAsset` parametresini atla.

## Veri sistemi — ne tutuluyor?

Her örnek (`TrackPoint`) bir anlık **tam telemetri görüntüsü**:

- **GPS:** konum, yükseklik, GPS hız, yön
- **Araç:** hız (km/s), RPM, sürüş modu, gaz %
- **Elektrik:** voltaj, akım, güç (W = V·A)
- **Batarya/BMS:** SOC %, kalan/harcanan Ah, paket voltajı, hücre min/maks mV, hücre farkı, döngü
- **Sıcaklık:** motor, sürücü (kontrolcü), batarya °C
- **Arızalar:** o an aktif hata kodları (ör. çözülmüş FarDriver bitleri)

Tüm araç alanları opsiyonel — hangi kontrolcü ne veriyorsa onu besle, istatistik
katmanı eksiklerle başa çıkar. Bir sürüşün (`Ride`) türettiği istatistikler:
mesafe, hareket süresi, ort/maks/hareket-ort hız, tırmanış/iniş, **enerji (Wh)**,
**geri kazanım (Wh)**, harcanan Ah, **verim (Wh/km, Ah/km)**, maks güç/akım,
min voltaj, maks motor/sürücü/batarya sıcaklığı, maks hücre farkı, SOC kullanımı,
tahmini menzil, görülen arızalar.

## Kullanım

```dart
import 'package:<app>/features/ride_tracking/ride_tracking.dart';

// 1) Kayda başla (sabit aralıkla örnekler; GPS + telemetriyi birleştirir)
final recorder = RideRecorder(sampleInterval: const Duration(seconds: 1));
await recorder.start(vehicleId: 'FarDriver');

// 2) Mevcut BLE veri callback'lerinden telemetri besle (ne varsa)
recorder.updateTelemetry(
  vehicleSpeedKmh: speed, rpm: rpm, voltage: v, current: i, soc: soc,
  remainingAh: remAh, consumedAh: usedAh, motorTempC: mt, controllerTempC: ct,
  cellMinMv: cMin, cellMaxMv: cMax, mode: 'ECO', faults: activeFaults,
);

// 3) Canlı haritayı göster
StreamBuilder<Ride>(
  stream: recorder.rideStream,
  builder: (_, snap) => snap.hasData
      ? LiveRideMap(points: snap.data!.points)
      : const SizedBox(),
);

// 4) Bitir, adres çöz, kaydet (JSON+CSV), özet aç
final ride = await recorder.stop();
if (ride != null) {
  await const RideGeocoder(localeIdentifier: 'tr_TR').annotate(ride);
  await RideStore().save(ride); // <docs>/rides/<id>.json + .csv
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => RideSummaryPage(
      ride: ride,
      vehicleModelAsset: 'assets/models/vehicle.glb', // veya null
      onShareCsv: (path) {/* share_plus: Share.shareXFiles([XFile(path)]) */},
    ),
  ));
}

// Geçmiş liste:
Navigator.push(context, MaterialPageRoute(builder: (_) => const RideListPage()));
```

## CSV / JSON çıktısı

Her sürüş iki dosya olarak `<app-documents>/rides/` altına yazılır:

- **`<id>.json`** — kaynak doğruluk: tüm noktalar + tüm istatistik özeti + adresler.
- **`<id>.csv`** — nokta başına bir satır (Excel/Sheets uyumlu):

  ```
  index,timestamp,lat,lng,altitude_m,gps_speed_kmh,speed_kmh,rpm,mode,
  throttle_pct,voltage_v,current_a,power_w,soc_pct,remaining_ah,consumed_ah,
  motor_temp_c,controller_temp_c,battery_temp_c,cell_min_mv,cell_max_mv,
  cell_delta_mv,faults,address
  ```

  Boş hücreler = o kontrolcüden o veri gelmedi. `address` sütunu ilk satıra
  başlangıç, son satıra varış adresini yazar; `faults` `|` ile ayrılır.

## Dosya haritası

| Dosya | Görev |
|---|---|
| `models/track_point.dart` | Tek anlık tam telemetri görüntüsü (GPS + araç/BMS) |
| `models/ride.dart` | Sürüş + tüm istatistikler (mesafe/hız/enerji/verim/ısı/SOC) + JSON/CSV |
| `services/ride_recorder.dart` | GPS + telemetri füzyonu, sabit aralıkla örnekleme |
| `services/ride_geocoder.dart` | Başlangıç/varış adresi (reverse geocoding) |
| `services/ride_store.dart` | JSON+CSV kaydet/yükle/sil/paylaş yolu |
| `ui/ride_map_view.dart` | Hız renkli rota + canlı harita (flutter_map/OSM) |
| `ui/ride_stats_chart.dart` | Hız/yükseklik profili (bağımlılıksız CustomPainter) |
| `ui/vehicle_3d_view.dart` | 3D araç görseli (model_viewer_plus) |
| `ui/ride_summary_page.dart` | Strava-vari özet ekranı |
| `ui/ride_list_page.dart` | Sürüş geçmişi listesi |

## i18n

UI metinleri şimdilik Türkçe gömülü (hızlı önizleme için). Mevcut
TR/EN i18n sisteminize taşımak için string'leri kendi çeviri anahtarlarınızla
değiştirin (EvaMania'da i18n zaten tamam — v1.16.3 notlarına göre).

## Sonraki adım: tam 3D animasyonlu replay

Şu an "2D harita + 3D araç rozeti" (en sağlam). Aracın yol boyunca hareket
ettiği tam 3D sahne istersen ayrı bir iş kalemi — Mapbox 3D terrain veya bir
3D motoru gerekir; performans/efor maliyeti yüksek. İstersen onu ayrıca
planlayalım.
