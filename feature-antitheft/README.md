# EvaMania — Hareket Alarmı (Anti-Theft)

Park halinde **korumaya al**; ivmeölçer ile kurcalama veya GPS ile çekme
(towing) algılayınca önce **uyarı** (giriş gecikmesi, titreşimli) verir,
iptal edilmezse **siren + titreşim** çalar ve istenirse **SOS bildirir**.

## Kurulum
1. `lib/features/antitheft/`'i uygulamanın `lib/`'ine kopyala.
2. `pubspec-snippet.yaml` → `sensors_plus`, `geolocator`, `audioplayers`,
   `path_provider` (varsa tekrarlama) → `flutter pub get`.
3. Siren sesi: bir `assets/sounds/siren.mp3` ekle (pubspec assets'e tanımla).
   Ses istemezsen `NoopSiren` kullan (sadece titreşim).
4. İzinler: konum (geolocator). Arka planda çalışması için foreground service +
   `ACCESS_BACKGROUND_LOCATION` önerilir (uygulama kapalıyken de korusun).

## Kullanım
```dart
import 'package:<app>/features/antitheft/antitheft.dart';

final store = AntiTheftConfigStore();
final config = await store.load();
config.sirenAsset = 'sounds/siren.mp3'; // audioplayers: 'assets/' OLMADAN

final controller = AntiTheftController(
  config: config,
  onAlarm: (event) async {
    // Tam alarmda: konum gönder / push / crash-sos SosSender'ı çağır
    // örn: await mySosSender.send(...);
  },
);

// Ayar/kur ekranı:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => AntiTheftPage(
    controller: controller, config: config, store: store),
));

// Park edince koru, kullanırken kapat (BLE bağlanınca otomatik de yapılabilir):
controller.arm();
controller.disarm();
```

İpucu: kontrolcüye BLE ile bağlanınca `disarm()`, bağlantı kesilince/park edince
`arm()` çağırarak otomatikleştir.

## Durumlar
`disarmed` → `armed` (korumada) → `warning` (giriş gecikmesi, iptal şansı) →
`alarming` (siren + bildirim). `stateStream` ile UI'da göster.

## Dosya haritası
| Dosya | Görev |
|---|---|
| `models/antitheft_config.dart` | Ayarlar (hassasiyet/GPS yarıçapı/gecikme/siren) + JSON store |
| `services/antitheft_detector.dart` | İvmeölçer kurcalama + GPS çekme algılama |
| `services/alarm_siren.dart` | Siren (AudioSiren asset / NoopSiren) |
| `services/antitheft_controller.dart` | Kur/iptal + uyarı→tam alarm + bildirim |
| `ui/antitheft_page.dart` | Kur/iptal + durum + hassasiyet ayarları |

## Notlar
- Uygulama arka planda öldürülürse alarm çalışmayabilir; gerçek koruma için
  foreground service ile süreklilik sağla.
- `onAlarm`'ı `feature-crash-sos`'taki `SosSender` ile birleştirerek alarmda
  konumlu SMS gönderebilirsin.
- Yanlış alarmı azaltmak için hassasiyeti aracına göre ayarla.
