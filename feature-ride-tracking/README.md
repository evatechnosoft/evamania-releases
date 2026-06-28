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

## Kullanım

```dart
import 'package:<app>/features/ride_tracking/ride_tracking.dart';

// 1) Kayda başla
final recorder = RideRecorder();
await recorder.start();

// 2) (Opsiyonel) BLE telemetri besle — mevcut FarDriver/Votol/JK handler'ından
recorder.attachTelemetry(current: lastCurrentA, batteryAh: consumedAh);

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

- **`<id>.json`** — kaynak doğruluk: tüm noktalar + istatistik özeti + adresler.
- **`<id>.csv`** — nokta başına bir satır (Excel/Sheets uyumlu):

  ```
  index,timestamp,lat,lng,altitude_m,speed_kmh,current_a,battery_ah,address
  0,2026-06-28T10:00:01.000,41.012345,28.976543,34.0,0.0,,,"Bağdat Cd., Kadıköy, İstanbul"
  ...
  ```

  `address` sütunu ilk satıra başlangıç, son satıra varış adresini yazar.

## Dosya haritası

| Dosya | Görev |
|---|---|
| `models/track_point.dart` | Tek GPS örneği (+opsiyonel akım/Ah telemetri) |
| `models/ride.dart` | Sürüş + haversine mesafe, hız, tırmanış, tüketim + JSON/CSV |
| `services/ride_recorder.dart` | Canlı GPS kaydı (geolocator), telemetri bağlama |
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
