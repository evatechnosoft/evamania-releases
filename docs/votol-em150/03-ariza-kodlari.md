# Votol EM150 — Arıza Kodları (Fault Codes) ve Çözümleri

> Votol EM150 kontrol cihazında oluşan arıza kodlarını (Fault Codes) görmenin
> iki ana yolu vardır: cihazın üzerindeki **fiziksel LED ışığın çakma sayısını**
> saymak veya **bilgisayar/telefon yazılımındaki** arıza ekranını okumak.

İlgili konular: [Pin haritası](02-pin-haritasi.md) · [Reset](04-reset-one-key-repair.md) ·
[Kaynaklar](kaynaklar.md)

---

## 1. Arıza Kodlarını Nasıl Görebiliriz?

### Yöntem A — Cihaz Üzerindeki Kırmızı LED Işığı Okuma (Blink Codes)

Votol EM150 hata moduna geçtiğinde, üzerindeki kırmızı LED ışık belirli bir düzende
yanıp sönmeye başlar. Kodlar **Uzun (yavaş)** ve **Kısa (hızlı)** flaşların
birleşimi olarak okunur.

- **Örnek:** LED 2 kez yavaş, ardından 2 kez hızlı yanıp sönüyorsa → **Hata 22 (Error 22)**.

### Yöntem B — Bilgisayar / Telefon Yazılımından Görme

Mavi ve Turuncu kablolar üzerinden bilgisayara (veya Bluetooth ile telefona) bağlandığınızda:

- Yazılım ana ekranında (**Page 1**) alt kısımdaki **"Fault Status"** veya
  **"Error Code"** kutucuğuna bakın.
- Orada `0x02`, `0x08` gibi **hexadecimal (onaltılık)** kodlar ya da doğrudan
  hatanın adı yazar.

---

## 2. Arıza Kodları Listesi ve Çözümleri (Fix)

| Hata Kodu / Adı | Muhtemel Nedeni | Nokta Atışı Çözümü (Fix) |
|---|---|---|
| **0x01 / E_BRAKE_ON** (Fren Kilidi) | Yüksek veya alçak fren sinyal kablolarından biri şaseye veya +12 V'a takılı kalmıştır. | Fren kollarını kontrol edin. Yazılımdan (Page 1) **Brake Type** ayarını değiştirin veya masaüstü testinde **mor kabloya** yanlışlıkla enerji vermediğinizden emin olun. |
| **0x02 / OVER_CURRENT** (Aşırı Akım) | Motor faz kabloları kısa devre yapmış veya yazılımdaki akım limiti motora göre çok yüksek girilmiştir. | Kalın **U, V, W** faz kablolarının birbirine değmediğinden emin olun. Yazılımdan **Phase Current** (Tepe Faz Akımı) değerini düşürün. |
| **0x04 / UNDER_VOLTAGE** (Düşük Voltaj) | Akü voltajı, sürücüye tanıtılan minimum voltaj limitinin altına düşmüştür. | Akü voltajını ölçün. Page 1 menüsünden **Under Voltage** (alt sınır) değerini akünüze uygun seviyeye düşürün (örn. 72 V akü için 60 V). |
| **0x08 / HALL_ERROR** (Hall Sensör Hatası) | Motorun içindeki konum sensörlerinin kabloları kopmuş, soketi gevşemiş veya sensör yanmıştır. | 5'li ince motor soketini kontrol edin. Multimetre ile motora giden kırmızı-siyah kablolarda **5 V** olduğunu teyit edin. Motor elle dönerken sarı, yeşil, mavi kablolardaki sinyal **0–5 V** arası değişmelidir. |
| **0x10 / OVER_VOLTAGE** (Yüksek Voltaj) | Şarjdan yeni çıkmış akünün voltajı, sürücünün üst sınır koruma değerini aşmıştır. | Yazılımdan **Over Voltage** limitini biraz yükseltin (maks. 90 V). Rejeneratif frenleme (enerji geri kazanımı) esnasında oluyorsa **Regen** ayarlarını kısın. |
| **0x20 / MCU_ERROR** (İşlemci Hatası) | Sürücünün ana beyni (mikroçip) anlık olarak kilitlenmiş veya yanlış yazılım dosyası (`.ini`) yüklenmiştir. | Kontağı (**mor kablo**) kapatıp 5 saniye bekleyip yeniden açın. Düzelmezse **kahverengi kablo** ile [donanımsal reset](04-reset-one-key-repair.md) kombinasyonunu uygulayın. |
| **0x40 / MOTOR_BLOCK** (Motor Kilitli) | Motor fiziksel olarak dönemiyor, sıkışmış veya faz-hall kablo sıralaması tamamen yanlıştır. | Motorun mekanik olarak rahat döndüğünü kontrol edin. Kablo renkleri tutsa bile Page 2 üzerinden **Hall Smid** açısını değiştirerek otomatik kalibrasyon (**Self-learning**) yapın. |
| **THROTTLE ERROR** (Gaz Kolu Hatası) | Sinyalin **0.5 V** sınırının altında (örn. ölçülen 0.2 V) veya **4.5 V** sınırının üstünde olması. | **Kesin çözüm:** Page 1 → **Throttle** kısmına girip **Low Voltage (Start)** değerini 0.2 V veya 0.3 V olarak güncelleyin ve **"Write"** butonuna basın. Bench'te bkz. [05-gaz-voltaji-simulasyon.md](05-gaz-voltaji-simulasyon.md). |

---

## 3. Bilgisayarsız Hızlı "Fix" Yöntemi

Bu hatalardan biri yüzünden motor tamamen bloke olduysa ve bilgisayara bağlanamıyorsanız:

1. Kontağı (**mor kabloyu**) açın.
2. **Kahverengi kabloyu (Pin 6)**, yanındaki **Siyah kabloya (Pin 5 / GND)** buton yardımıyla
   **1 kez kısa**, ardından **1 kez uzun (5–10 saniye)** temas ettirin.
3. Bu işlem hata loglarını temizler ve sistemi sıfırlayarak kilit modundan çıkarır.

> Reset bağlantı/pin detayı ve doğrulama için bkz. [04-reset-one-key-repair.md](04-reset-one-key-repair.md).

> **Sıradaki adım:** Cihazdaki kırmızı LED belirli bir düzende yanıp sönüyorsa,
> flaş sayısını (örn. *3 kısa, 1 uzun*) not edin — buradan doğrudan hangi arızayı
> düzelteceğiniz nokta atışı belirlenebilir.
