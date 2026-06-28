# Votol EM150 — Masaüstü Testinde Gaz Voltajını Simüle Etmek

> Gaz kolu serbestken **0.2 V** gibi çok düşük bir değer gören cihaz, *"gaz kablosu
> koptu veya şaseye kısa devre var"* diye düşünüp kendini korumaya (hata moduna) alır.
> Sinyali dışarıdan **0.8 V – 1.2 V** arasına yükseltmek, cihazın normal çalışma
> (rölanti) bölgesine girmesini ve kilitten çıkmasını sağlar.

İlgili konular: [Arıza kodları (Throttle Error)](03-ariza-kodlari.md) ·
[Pin haritası](02-pin-haritasi.md) · [Kaynaklar](kaynaklar.md)

---

## Yöntem 1 — Gaz Pedalını Çok Az Basılı Tutmak (En basit)

Pedala elle veya bir mandalla çok az basarak multimetrede **0.8 V – 1.0 V** arası bir
değer yakalayıp pedalı sabitleyin. Cihazı bu sabit voltajdayken kapatıp açtığınızda
hatanın silinmesi gerekir.

## Yöntem 2 — Harici Güç Kaynağı / Pil ile Voltaj Vermek

Ayarlı bir laboratuvar güç kaynağı varsa:

- Güç kaynağını **1.0 V** değerine ayarlayın.
- **Eksi (–)** ucunu Votol'un **Siyah (GND)** kablosuna bağlayın.
- **Artı (+)** ucunu Votol'un **Yeşil (gaz sinyal)** kablosuna bağlayın.
  *(Pedaldan gelen yeşil kabloyu test için cihazdan ayırın.)*

## Yöntem 3 — Direnç ile Gerilim Bölücü (En profesyonel)

Votol'un kendi ürettiği **Pembe (+5 V)** hattını kullanarak araya küçük bir direnç
ekleyin:

- **Pembe** kablo ile **Yeşil** kablo arasına **4.7 kΩ** direnç bağlayın → yeşil kabloda
  yaklaşık **0.8 V – 1.0 V** arası temiz bir rölanti voltajı oluşur.

## Bu Voltajı Verdikten Sonra Ne Olacak?

1. **Mor (e-lock/kontak)** kabloyu akü artıya bağlayıp cihazı çalıştırın.
2. Cihaz artık 0.2 V hatası vermeyeceği için **kilit moduna girmez**.
3. Kilit açıldığı için bilgisayar yazılımı veya Bluetooth modülü saniyeler içinde
   bağlanır ve **"Communication Abnormal"** hatası kalıcı olarak kaybolur.
4. Bağlantı sağlanınca yazılımda **Page 1 → Throttle** sekmesine girip başlangıç
   voltajını (**Throttle Min**) pedalın gerçek değeri olan **0.1 V / 0.2 V** seviyesine
   çekip **"Write"** ile kaydedin. Böylece dışarıdan voltaj vermeye bir daha gerek kalmaz.
