# EvaMania — Rider Assist (Sesli Asistan + Alarm Motoru)

Eller serbest sürüş kolaylığı: kontrolcü/BMS telemetrisini **kullanıcı tanımlı
eşiklere** göre değerlendirir, **sesli (TTS) uyarı** + titreşim verir, yeni
arızaları seslendirir ve istenirse **periyodik sesli durum** ("hız 60, batarya
yüzde 80") anons eder.

> Kendi içinde çalışır; sürüş-kaydı modülüne bağımlı değildir.

## Kurulum
1. `lib/features/rider_assist/`'i uygulamanın `lib/`'ine kopyala.
2. `pubspec-snippet.yaml` → `flutter_tts` ekle, `flutter pub get`.
   (Titreşim için ekstra paket yok; `HapticFeedback` kullanılır.)
3. iOS'ta TTS için ek izin gerekmez; Android'de cihazda TR TTS sesi kurulu olmalı.

## Kullanım
```dart
import 'package:<app>/features/rider_assist/rider_assist.dart';

final assist = VoiceAssistant(
  announceStatus: true,                         // periyodik durum anonsu
  statusInterval: const Duration(minutes: 5),
)..start();

// Mevcut BLE telemetri döngünden (ne varsa):
assist.update(RiderTelemetry(
  speedKmh: speed, voltage: v, current: i, soc: soc,
  cellMinMv: cMin, cellMaxMv: cMax,
  motorTempC: mt, controllerTempC: ct, batteryTempC: bt,
  faults: activeFaults,                          // FarDriver fault etiketleri
));

// Kullanıcı sesi kapatmak isterse:
assist.muted = true;

// Anlık durum söylet:
assist.announceNow();

assist.dispose();
```

## Alarm kuralları
`AlarmRule.defaults()` makul EV varsayılanları verir (SOC ≤20/≤8, motor ≥110°C,
sürücü ≥80°C, hücre farkı ≥200mV, voltaj ≤60V). Kendi kurallarını ver:

```dart
final rules = [
  AlarmRule(id: 'soc_low', field: AlarmField.soc,
      comparator: AlarmComparator.lte, threshold: 25,
      severity: AlarmSeverity.warning, message: 'Batarya yüzde {v}'),
  AlarmRule(id: 'overspeed', field: AlarmField.speedKmh,
      comparator: AlarmComparator.gt, threshold: 90,
      message: 'Hız limiti aşıldı, {v}'),
];
final assist = VoiceAssistant(engine: AlarmEngine(rules: rules))..start();
```
Kurallar `toJson()/fromJson()` ile saklanabilir (ayarlar ekranında düzenlenebilir).
Her kuralın `cooldown`'u tekrarlı seslenmeyi engeller; `critical` alarmlar
mevcut konuşmayı keser ve sert titreşir.

## Dosya haritası
| Dosya | Görev |
|---|---|
| `models/rider_telemetry.dart` | Anlık telemetri snapshot + alan eşlemesi |
| `models/alarm_rule.dart` | Eşik kuralı (alan/karşılaştırma/eşik/önem) + JSON + varsayılanlar |
| `services/alarm_engine.dart` | Kuralları değerlendir, cooldown, yeni arıza tespiti, olay akışı |
| `services/tts_speaker.dart` | flutter_tts sarmalayıcı (dil/hız/sustur/kesme) |
| `services/voice_assistant.dart` | Alarm→ses+titreşim + periyodik durum anonsu |

## i18n
Mesajlar TR varsayılan. Çok dilli istersen `AlarmRule.message` ve
`AlarmFieldLabel.label` değerlerini kendi i18n anahtarlarınla üret.
