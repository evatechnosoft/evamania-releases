# EvaMania — Tuning Preset Yöneticisi

Kontrolcü ayar profillerini (Eco / Sport / Yağmur / Şehir...) **kaydet**, tek
dokunuşla **uygula**, düzenle, **QR ile paylaş** ve başka telefondan **tara-içe
aktar**. Kontrolcü-bağımsız: parametreler serbest `anahtar→değer` haritasıdır;
gerçek BLE yazımını uygulama `onApply` callback'inde yapar.

## Kurulum
1. `lib/features/tuning_presets/`'i uygulamanın `lib/`'ine kopyala.
2. `pubspec-snippet.yaml` → `path_provider`, `qr_flutter`, `mobile_scanner`
   (varsa tekrar ekleme) → `flutter pub get`.
3. Kamera izni (QR tara): Android `CAMERA`, iOS `NSCameraUsageDescription`.

## Kullanım
```dart
import 'package:<app>/features/tuning_presets/tuning_presets.dart';

Navigator.push(context, MaterialPageRoute(
  builder: (_) => PresetListPage(
    knownKeys: const ['phaseCurrent', 'speedLimit', 'rampUp', 'fieldWeakening'],
    onApply: (preset) async {
      // Burada preset.params'i kontrolcüye BLE ile yaz:
      for (final e in preset.params.entries) {
        await myController.writeParam(e.key, e.value); // senin BLE kodun
      }
    },
  ),
));
```

Mevcut ayarları preset olarak kaydetmek için, kontrolcüden okuduğun değerlerle
bir `TuningPreset` oluştur ve `PresetStore().upsert(preset)` çağır.

## Özellikler
- **Tek dokunuş uygula** — onay diyaloğu + `onApply` ile BLE'ye yaz.
- **Düzenle** — isim, kontrolcü tipi, not + anahtar/değer editörü.
- **QR paylaş / tara** — `toShareString()` payload'ı QR'a gömülür; tarayınca
  yeni id ile içe aktarılır (mevcut preset'i ezmez).
- **Kalıcılık** — tek JSON dosyası (`<docs>/tuning_presets.json`).
- `diffFrom(other)` ile "ne değişecek?" karşılaştırması yapılabilir.

## Dosya haritası
| Dosya | Görev |
|---|---|
| `models/tuning_preset.dart` | Preset modeli + JSON + QR payload + diff |
| `services/preset_store.dart` | Kaydet/yükle/sil/dışa-içe aktar |
| `ui/preset_list_page.dart` | Liste + uygula/düzenle/sil/QR/tara |
| `ui/preset_edit_page.dart` | İsim/tip/not + parametre editörü |
| `ui/preset_qr_page.dart` | QR göster (`PresetQrPage`) + tara (`PresetScanPage`) |

## Güvenlik notu
Kontrolcüye yanlış değer yazmak donanıma zarar verebilir. `onApply` içinde
uygulama tarafında sınır/aralık doğrulaması yapman önerilir.
