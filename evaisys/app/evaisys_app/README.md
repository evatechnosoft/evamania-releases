# EvaISYS Flutter Uygulaması

Araç izleme ve uzaktan kontrol için MVP mobil uygulama.

## Çalıştırma
```bash
flutter pub get

# Android emülatör (host backend'e 10.0.2.2 ile erişir) — varsayılan
flutter run

# Gerçek cihaz / özel backend adresi
flutter run --dart-define=API_BASE=http://192.168.1.100:3000
```

## Ekranlar
- **Araçlar:** filo listesi, canlı hız/batarya/durum, 2 sn'de bir yenilenir.
- **Araç detayı:** telemetri metrikleri + uzaktan komutlar
  (kilitle/aç, immobilize, alarm, konum iste).

## Yapı
```
lib/
  config.dart          # API adresi ve ayarlar
  models/vehicle.dart  # veri modeli (backend sözleşmesiyle hizalı)
  services/api.dart    # REST istemcisi
  main.dart            # UI (liste + detay)
```

> Not: Bu bir MVP iskeletidir. `flutter create .` ile platform klasörlerini (android/ios)
> oluşturmanız gerekebilir; `lib/`, `pubspec.yaml` ve `analysis_options.yaml` hazırdır.
