# Votol EM150 — Arıza Giderme Dokümanları

Votol EM150 (EM150S / EM150-2sp) kontrol cihazı için masaüstü (bench) testi,
güvenlik kilitleri, arıza kodları ve haberleşme sorunları üzerine konu konu
ayrılmış Türkçe referans.

> *Kaynak: Gemini araştırması — bir araya derlenmiştir. Tüm kaynak linkleri için
> bkz. [kaynaklar.md](kaynaklar.md).*

## İçindekiler

| # | Konu | Dosya | Ne zaman bakılır? |
|---|------|-------|-------------------|
| 1 | Gizli Güvenlik Kilitleri (Interlock) | [01-guvenlik-kilitleri.md](01-guvenlik-kilitleri.md) | Gaz voltajı artıyor ama motor dönmüyorsa (Park / fren / baud) |
| 2 | 16 Pin (2×8) Ana Soket Haritası | [02-pin-haritasi.md](02-pin-haritasi.md) | Kablo rengi / pin görevi / GND ve TX-RX bulmak için |
| 3 | Arıza Kodları (Fault Codes) | [03-ariza-kodlari.md](03-ariza-kodlari.md) | LED blink veya yazılım hata kodunun anlamı ve çözümü |
| 4 | "One Key Repair" Butonu ve Reset | [04-reset-one-key-repair.md](04-reset-one-key-repair.md) | Donanımsal sıfırlama (Pin 6 + Pin 5) ve doğrulama |
| 5 | Masaüstünde Gaz Voltajı Simülasyonu | [05-gaz-voltaji-simulasyon.md](05-gaz-voltaji-simulasyon.md) | 0.2 V kilidini bench'te aşmak için |
| 6 | "Communication Abnormal" 4 Neden | [06-communication-abnormal.md](06-communication-abnormal.md) | Bilgisayar/Bluetooth bağlanmıyorsa |
| — | Kaynaklar | [kaynaklar.md](kaynaklar.md) | Tüm referans linkleri |

## Hızlı Başvuru

- **Reset kombinasyonu:** Kontak (mor) açıkken **Pin 6 (Kahverengi)** ↔ **Pin 5 (GND)** →
  1 kısa, ardından 1 uzun (5–10 sn) basış.
- **Park kilidi:** **Pin 7 (Kahverengi/Beyaz)** → GND'ye bağla.
- **Haberleşme:** **Pin 12 (Mavi/TX)**, **Pin 13 (Turuncu/RX)** — bağlanmazsa çaprazla.
- **Ortak GND:** Pin 5, Pin 10, Pin 15 (cihaz içinde köprülü).
