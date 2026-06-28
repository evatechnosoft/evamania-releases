# Votol EM150 — "One Key Repair" Butonu ve Reset Doğrulaması

> Orijinal araç şemasında kırmızı daire içine alınan buton **"one key repair"**
> (tek tuşla tamir / kurtarma / reset) butonudur. Şemadaki pin dizilimi, kablo
> renkleri ve şaseleme mantığı aşağıdadır.

İlgili konular: [Pin haritası](02-pin-haritasi.md) · [Arıza kodları](03-ariza-kodlari.md) ·
[Kaynaklar](kaynaklar.md)

---

## 1. Butonun Bağlandığı Kablolar ve Pinler

Şemada butonun uçları takip edildiğinde:

- **Butonun bir ucu:** Soketin sol sütunundaki **Kahverengi (brown)** kabloya gider.
  Bu kablo doğrudan **"one key repair" / Restore** hattıdır.
- **Butonun diğer ucu:** **Siyah (black)** kabloya, yani şemadaki
  **Toprak / Şase (GND)** sembolüne bağlanır.

> Votol kontrol cihazlarında fonksiyon pinleri (Sport, Reverse, Parking, Reset vb.)
> **GND (eksi) ile tetiklenecek** şekilde tasarlanmıştır. Kahverengi hatta bir işlem
> yaptırmak için onu mutlaka bir şase (GND) hattına **kısa devre** etmek gerekir.

### Kesinleşmiş Pin Sıralaması (16 pinli ana soket)

> **Not — pin numarası düzeltmesi:** Süreç içinde önce "Pin 7" gibi farklı numaralar
> konuşuldu; SiAECOSYS 2×8 ana fonksiyon şeması büyütülerek incelendiğinde reset
> kombinasyonunun **doğru** pinleri aşağıdaki gibidir. (Pin 7 = Park kilidi; bkz.
> [02-pin-haritasi.md](02-pin-haritasi.md).)

| İşlev | Pin | Kablo | Soketteki konum |
|-------|-----|-------|-----------------|
| **Reset / Restore (Sport)** | **Pin 6** | Kahverengi (brown) | Üst sıranın sağdan 3. pini |
| **GND / Şase** | **Pin 5** | Siyah / Siyah-Kahverengi şeritli (Isolated Negative) | Pin 6'nın hemen solu — üst sıranın sağdan 4. pini |

Soketin arkasına (kabloların girdiği taraf) **tırnak üstte** kalacak şekilde
bakıldığında üst sıra dizilimi:

```
[TIRNAK ÜSTTE — KABLO GİRİŞ TARAFINDAN BAKIŞ]

ÜST SIRA: | Pin 1 | Pin 2 | Pin 3 | Pin 4 | Pin 5 (GND) | Pin 6 (KAHVE) | Pin 7 | Pin 8 |
                                              |             |
                                              +--[ BUTON ]--+
```

- Butonun **1. ucu** → **Pin 6** (Kahverengi / Reset).
- Butonun **2. ucu** → **Pin 5** (Siyah veya Siyah-Kahverengi izoleli GND).

### Doğru GND Hattından Emin Değilseniz — Sağlama Yöntemleri

1. **Gaz kolunun siyah kablosunu kullanın:** Gaz pedalına giden 3'lü kablodaki
   **Siyah (Pin 10 — Throttle GND)** kablo doğrudan cihazın ana şasesidir. Butonun
   GND ucunu Pin 5 yerine bu siyah kabloya bağlasanız da sistem teknik olarak aynı
   çalışır. (Pin 5/10/15 ortak GND'dir.)
2. **Multimetre ile süreklilik (bip) testi:** Cihazda elektrik yokken multimetreyi
   **kısa devre / süreklilik (bip)** moduna alın. Bir probu kalın **B– (ana negatif)**
   terminaline sabitleyin, diğer probu Pin 5'teki kabloya değdirin. **Bip sesi gelirse**
   o pin kesinlikle GND'dir ve buton bağlantısı için güvenlidir.

---

## 2. Reset Tetikleme Zamanlaması

**Mor kablo (E-Lock / Kontak)** akü artıya **bağlı** ve cihaz **açık** durumdayken:

1. Butona **1 kez kısa** basın (bas-çek).
2. Hemen ardından **2. kez basıp 5–10 saniye basılı** tutun.

Bu kombinasyon, cihazın donanımsal kurtarma modunu devreye alır ve kilitlenen
gaz/fren hafızasını sıfırlar.

---

## 3. Sıfırlama (Reset) Doğrulama Testi — Oldu mu, Olmadı mı?

Bilgisayara bağlanmadan, tezgah üzerinde cihazın tepkilerinden anlayabilirsiniz:

1. **Gaz sinyal voltajının değişmesi (multimetre):**
   Reset öncesi gaz takılıyken yeşil kabloda ölçülen 0.2 V, cihaz tarafından "arıza"
   olarak algılanır ve sistem kilitlenir. Reset başarılı olduğunda bu kilit kalkar.
   Multimetrenin kırmızı ucu **yeşil**, siyah ucu **siyah** kabloya bağlanır; reset
   anında voltajda küçük bir salınım/değişim (örn. 0.2 V'tan anlık yukarı hareket)
   görülür. Bu, işlemcinin gaz hattını yeniden taradığını gösterir.
2. **Akım çekişi / tık sesi / röle (reboot):**
   Cihaz reset yediğinde MCU milisaniyeler içinde kapanıp açılır (reboot). Dijital güç
   kaynağında çekilen akımda (Amper) anlık düşüş-yükseliş görülür; ana **rölenin tık
   sesi** duyulabilir. Bağlı bir gösterge ekranı (LIN / hız ekranı) varsa, ekran anlık
   kapanıp tıpkı kontağı ilk kez açmış gibi **selamlama grafiğiyle** yeniden açılır.
3. **"Communication Abnormal" hatasının gitmesi:**
   Bilgisayar yazılımı bağlıysa, donanım sıfırlamasından hemen sonra kilit açılır;
   kırmızı hata yazısı kaybolur ve parametreler (Page 1, Page 2 …) otomatik ekrana dökülür.

> **Tepki yoksa:** Kombinasyon sonrası cihaz hiç tepki vermediyse veya gaz hâlâ
> kilitliyse, **kontağın (mor kablo) açık** olduğundan emin olun ve **uzun basış süresini
> biraz daha uzatarak** kombinasyonu tekrarlayın.
