# EvaMania — Kaza Algılama & SOS

İvmeölçerle düşüş/darbe algılar; bir **geri sayım** gösterir (sürücü "İyiyim"
diyerek iptal edebilir); süre dolarsa **acil kişilere konum + mesaj** gönderir.

## Nasıl çalışır
- `CrashDetector` ivmeölçer büyüklüğünü izler; eşiği (g) aşan ani darbe = kaza
  adayı. Yanlış alarmı azaltmak için **"sadece hareket halindeyken"** kapısı
  vardır (telemetri/GPS hızını `setSpeed` ile besle).
- Kaza algılanınca `SosCountdownDialog` tam ekran geri sayım açılır.
- İptal edilmezse `CrashSosController.composeAndSend()` konumu alıp mesajı
  acil kişilere yollar.

## Kurulum
1. `lib/features/crash_sos/`'i uygulamanın `lib/`'ine kopyala.
2. `pubspec-snippet.yaml` → `sensors_plus`, `geolocator`, `url_launcher`,
   `path_provider` (varsa tekrarlama) → `flutter pub get`.
3. İzinler: konum (geolocator); SMS göndermek için varsayılan akış cihazın SMS
   uygulamasını açar (ekstra izin gerekmez).

## Kullanım
```dart
import 'package:<app>/features/crash_sos/crash_sos.dart';

final store = SosConfigStore();
final config = await store.load();
final controller = CrashSosController(config: config)..start();

// Telemetri/GPS döngünden hızı besle (yanlış alarmı azaltır):
controller.setSpeed(currentSpeedKmh);

// Uygulama köküne (üst widget) otomatik geri sayım dinleyicisi koy:
CrashSosListener(
  crashes: controller.crashes,
  countdown: config.countdown,
  onSend: () => controller.composeAndSend(),
  child: myAppHome,
);

// Ayarlar ekranı:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => CrashSosSettingsPage(
    config: config, store: store, controller: controller),
));
```

## Otomatik (dokunmasız) SMS hakkında
Varsayılan `UrlLauncherSosSender` cihazın SMS uygulamasını **önceden doldurup
açar** (sürücü "gönder"e basar) — güvenilir ve hem Android hem iOS'ta çalışır.
Tamamen otomatik (dokunmasız) gönderim platforma özel izin/eklenti gerektirir
(yalnızca Android) ve bilinçli olarak pakete dahil edilmedi. İstersen kendi
`SosSender`'ını (ör. backend push veya native auto-SMS) enjekte et:
```dart
CrashSosController(config: config, sender: MyAutoSmsSender());
```

## Dosya haritası
| Dosya | Görev |
|---|---|
| `models/emergency_contact.dart` | Acil kişi |
| `models/sos_config.dart` | Ayarlar (eşik/geri sayım/kişiler/şablon) + JSON store |
| `services/crash_detector.dart` | İvmeölçer darbe algılama + hareket kapısı |
| `services/sos_sender.dart` | SMS/tel/harita gönderimi (enjekte edilebilir) |
| `services/crash_sos_controller.dart` | Algıla→konum al→gönder orkestrasyonu |
| `ui/sos_countdown_dialog.dart` | Geri sayım ekranı + `CrashSosListener` |
| `ui/crash_sos_settings_page.dart` | Ayarlar + test |

## Önemli
Kaza algılama **hayati güvenlik garantisi değildir** — yanlış pozitif/negatif
olabilir. Tek acil durum yöntemin olarak güvenme; cihazın/operatörün acil arama
özelliklerini de kullan.
