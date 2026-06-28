# Votol EM150 — Gizli Güvenlik Kilitleri (Interlock) Açma Rehberi

> Masaüstü (bench) testinde gaz voltajı düzgün artmasına rağmen motorun dönmemesi
> ve bilgisayar bağlantısında "Communication Abnormal" hatası alınması durumu için
> hazırlanmış kontrol listesi.

İlgili konular: [Pin haritası](02-pin-haritasi.md) · [Reset](04-reset-one-key-repair.md) ·
[Communication Abnormal](06-communication-abnormal.md) · [Kaynaklar](kaynaklar.md)

---

## Belirti (Semptom)

- Gaz pedalına/koluna bastıkça voltaj **düzenli olarak artıyor** (yaklaşık **0.2 V → 4.4 V**).
- Bu durum donanımın ve gaz kolunun **kusursuz çalıştığını** kanıtlar.
- Buna rağmen:
  - **Motor dönmüyor.**
  - Bilgisayar bağlantısında hâlâ **"Communication Abnormal"** hatası alınıyor.

### Teşhis

Bu tablo, Votol EM150 işlemcisinin gazı **okuduğunu** ancak yazılımsal bir
**güvenlik kilidi (interlock)** nedeniyle motora **çıkış vermeyi engellediğini**
gösterir. Bilgisayar bağlantısı olmadan motorun dönmesini engelleyen bu gizli
kilitleri açmak için aşağıdaki adımlar sırayla kontrol edilmelidir.

---

## 1. "Park (P)" Modu Kilidini İptal Etmek

Votol kontrol cihazları, fabrika çıkışında güvenlik nedeniyle **"Park" modunda**
başlar. Ekranda veya yazılımda park kilidi açıkken, gaz voltajı yükselse bile
işlemci motora akım göndermez.

**Çözüm:**

- Kablo demetinde (harness) **Kahverengi/Beyaz (Pin 7)** kabloyu bulun.
- Bu kabloyu doğrudan **Siyah (GND / Eksi)** kabloya bağlayın.
- Votol sistemlerinde Park modundan çıkmak için bu hattın **şaselenmesi** gerekir.

| Kablo | Renk / Pin | Yapılacak işlem |
|-------|------------|-----------------|
| Park (P) | Kahverengi/Beyaz — **Pin 7** | **GND (Siyah)** kablosuna bağla → şasele |

---

## 2. "Fren Kesici" (Brake Cut-off) Kilidini Kontrol Etmek

Cihaz, frene basıldığını "zannediyor" olabilir. Votol'da fren sinyali algılandığı
an **gaz tamamen devre dışı** kalır.

| Fren tipi | Kablo rengi | Olması gereken durum | Hatalı durum |
|-----------|-------------|----------------------|--------------|
| **Yüksek Fren** | Mor | Boşta olmalı | +12 V / akü voltajı değiyorsa cihaz gaz yemez |
| **Alçak Fren** | Siyah/Kahverengi | Boşta olmalı | Şaseye (GND) temas ederse cihaz fren modunda kalır |

> **Masaüstü testi notu:** Her iki fren kablosunun da **hiçbir yere değmediğinden**
> emin olun.

---

## 3. Bilgisayar Bağlantısını Kurtarmak — Baud Rate Çakışması

Gaz voltajı değiştiği halde bilgisayarın **RX hattının okumama sebebi**, çoğunlukla
Windows'un **USB seri port hız kilitlenmesidir**. Yeni bilgisayarlarda bunu aşmak için:

1. **Aygıt Yöneticisi**'ni açın, USB kablonuzun üzerine çift tıklayın.
2. **Bağlantı Noktası Ayarları (Port Settings)** sekmesindeki
   **"Saniyedeki bit sayısı" (Bits per second)** değerini el ile **115200** olarak
   değiştirip uygulayın.
3. Votol yazılımını açıp portu açtıktan sonra, **Kahverengi (Reset)** butona basılı
   tutarken **Connect** butonuna basmayı deneyin. Bu işlem cihazın haberleşme
   portunu zorla uyandırır.

> Daha fazla haberleşme nedeni için bkz. [06-communication-abnormal.md](06-communication-abnormal.md).

---

## Hızlı Kontrol Listesi

- [ ] Gaz voltajı 0.2 V → 4.4 V arasında düzgün değişiyor mu? (Donanım sağlam)
- [ ] Park (Pin 7 — Kahverengi/Beyaz) kablosu GND'ye bağlandı mı?
- [ ] Yüksek Fren (Mor) kablosu boşta mı?
- [ ] Alçak Fren (Siyah/Kahverengi) kablosu boşta mı?
- [ ] USB seri port hızı 115200 olarak ayarlandı mı?
- [ ] Reset butonu basılıyken Connect denendi mi?

---

## Sıradaki Adım / Doğrulama

Masaüstü testinde **Park (Pin 7)** kablosunu şaseye bağlayıp gaz verildiğinde
**motor fazlarında veya çıkışta bir hareketlenme** olup olmadığı gözlemlenmelidir.
Bu, Park kilidinin gerçek suçlu olup olmadığını netleştirecektir.
