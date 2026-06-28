# EvaMania — Bakım Hatırlatıcı (km bazlı)

Lastik, fren, kayış/zincir, genel bakım gibi km bazlı servis aralıklarını takip
eder; kalan km'yi ilerleme çubuğuyla gösterir, gecikenleri kırmızı işaretler ve
tek dokunuşla "Servis yapıldı" ile sıfırlar.

## Kurulum
1. `lib/features/maintenance/`'i uygulamanın `lib/`'ine kopyala.
2. `pubspec-snippet.yaml` → `path_provider` (varsa tekrarlama) → `flutter pub get`.

## Kullanım
```dart
import 'package:<app>/features/maintenance/maintenance.dart';

// currentOdoKm: kontrolcünün odometresi VEYA sürüş modülünün toplam mesafesi
// (RideAggregates.totalDistanceKm).
Navigator.push(context, MaterialPageRoute(
  builder: (_) => MaintenancePage(currentOdoKm: odoKm),
));
```

İlk açılışta makul varsayılanlar gelir (lastik 8000, fren 6000, kayış 5000,
genel 10000 km). Kullanıcı ekleyip düzenleyebilir.

## Dosya haritası
| Dosya | Görev |
|---|---|
| `models/maintenance_item.dart` | Bakım öğesi + kalan/ilerleme/gecikme + JSON + varsayılanlar |
| `services/maintenance_store.dart` | JSON kalıcılık (ilk açılışta varsayılanları yazar) |
| `ui/maintenance_page.dart` | Liste + ilerleme + "servis yapıldı" + ekle/düzenle/sil |

## Not
Odometre kaynağını uygulama sağlar. Kontrolcüden gerçek odo okunabiliyorsa onu
ver; yoksa sürüş kayıtlarının toplam mesafesini kullan (yalnızca uygulamayla
gidilen mesafeyi sayar).
