# Votol EM150 — Gizli Güvenlik Kilitleri (Interlock) Açma Rehberi

> Masaüstü (bench) testinde gaz voltajı düzgün artmasına rağmen motorun dönmemesi
> ve bilgisayar bağlantısında "Communication Abnormal" hatası alınması durumu için
> hazırlanmış kontrol listesi.
>
> *Kaynak: Gemini araştırması — bir araya derlenmiştir.*

---

## İçindekiler

1. [Gizli Güvenlik Kilitleri (Interlock) Açma Rehberi](#votol-em150--gizli-güvenlik-kilitleri-interlock-açma-rehberi)
2. [Arıza Kodları (Fault Codes) ve Çözümleri](#votol-em150--arıza-kodları-fault-codes-ve-çözümleri)
3. ["One Key Repair" Butonu ve Reset Doğrulaması](#votol-em150--one-key-repair-butonu-ve-reset-doğrulaması)
4. [Masaüstü Testinde Gaz Voltajını Simüle Etmek](#votol-em150--masaüstü-testinde-gaz-voltajını-simüle-etmek)
5. ["Communication Abnormal" Hatasının 4 Olası Nedeni](#votol-em150--communication-abnormal-hatasının-4-olası-nedeni)
6. [Kaynaklar](#kaynaklar)

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

---
---

# Votol EM150 — Arıza Kodları (Fault Codes) ve Çözümleri

> Votol EM150 kontrol cihazında oluşan arıza kodlarını (Fault Codes) görmenin
> iki ana yolu vardır: cihazın üzerindeki **fiziksel LED ışığın çakma sayısını**
> saymak veya **bilgisayar/telefon yazılımındaki** arıza ekranını okumak.
>
> *Kaynak: Gemini araştırması — bir araya derlenmiştir. Kaynak listesi en altta.*

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
| **0x20 / MCU_ERROR** (İşlemci Hatası) | Sürücünün ana beyni (mikroçip) anlık olarak kilitlenmiş veya yanlış yazılım dosyası (`.ini`) yüklenmiştir. | Kontağı (**mor kablo**) kapatıp 5 saniye bekleyip yeniden açın. Düzelmezse **kahverengi kablo** ile donanımsal reset kombinasyonunu uygulayın. |
| **0x40 / MOTOR_BLOCK** (Motor Kilitli) | Motor fiziksel olarak dönemiyor, sıkışmış veya faz-hall kablo sıralaması tamamen yanlıştır. | Motorun mekanik olarak rahat döndüğünü kontrol edin. Kablo renkleri tutsa bile Page 2 üzerinden **Hall Smid** açısını değiştirerek otomatik kalibrasyon (**Self-learning**) yapın. |
| **THROTTLE ERROR** (Gaz Kolu Hatası) | Sinyalin **0.5 V** sınırının altında (örn. ölçülen 0.2 V) veya **4.5 V** sınırının üstünde olması. | **Kesin çözüm:** Page 1 → **Throttle** kısmına girip **Low Voltage (Start)** değerini 0.2 V veya 0.3 V olarak güncelleyin ve **"Write"** butonuna basın. |

---

## 3. Bilgisayarsız Hızlı "Fix" Yöntemi

Bu hatalardan biri yüzünden motor tamamen bloke olduysa ve bilgisayara bağlanamıyorsanız:

1. Kontağı (**mor kabloyu**) açın.
2. **Kahverengi kabloyu (Pin 5)**, yanındaki **Siyah kabloya (GND)** buton yardımıyla
   **1 kez kısa**, ardından **1 kez uzun (5–10 saniye)** temas ettirin.
3. Bu işlem hata loglarını temizler ve sistemi sıfırlayarak kilit modundan çıkarır.

> **Sıradaki adım:** Cihazdaki kırmızı LED belirli bir düzende yanıp sönüyorsa,
> flaş sayısını (örn. *3 kısa, 1 uzun*) not edin — buradan doğrudan hangi arızayı
> düzelteceğiniz nokta atışı belirlenebilir.

---
---

# Votol EM150 — "One Key Repair" Butonu ve Reset Doğrulaması

> Orijinal araç şemasında kırmızı daire içine alınan buton **"one key repair"**
> (tek tuşla tamir / kurtarma / reset) butonudur. Şemadaki pin dizilimi, kablo
> renkleri ve şaseleme mantığı aşağıdadır.

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
> kombinasyonunun **doğru** pinleri aşağıdaki gibidir.

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
   çalışır.
2. **Multimetre ile süreklilik (bip) testi:** Cihazda elektrik yokken multimetreyi
   **kısa devre / süreklilik (bip)** moduna alın. Bir probu kalın **B– (ana negatif)**
   terminaline sabitleyin, diğer probu Pin 5'teki kabloya değdirin. **Bip sesi gelirse**
   o pin kesinlikle GND'dir ve buton bağlantısı için güvenlidir.

## 2. Sıfırlama (Reset) Doğrulama Testi — Oldu mu, Olmadı mı?

**Mor kablo (e-lock switch)** akü artıya bağlı ve cihaz açıkken, butona **1 kez kısa**
ve ardından **1 kez uzun (5–10 sn)** basıldığında işlemin gerçekleştiği şu 3 yöntemle
doğrulanır:

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

---
---

# Votol EM150 — Masaüstü Testinde Gaz Voltajını Simüle Etmek

> Gaz kolu serbestken **0.2 V** gibi çok düşük bir değer gören cihaz, *"gaz kablosu
> koptu veya şaseye kısa devre var"* diye düşünüp kendini korumaya (hata moduna) alır.
> Sinyali dışarıdan **0.8 V – 1.2 V** arasına yükseltmek, cihazın normal çalışma
> (rölanti) bölgesine girmesini ve kilitten çıkmasını sağlar.

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

---
---

# Votol EM150 — "Communication Abnormal" Hatasının 4 Olası Nedeni

> Gaz pedalından **0.2 V – 4.4 V** arası doğrusal voltaj alınıyorsa gaz okuma
> donanımı çalışıyordur. Buna rağmen motor tetiklenmiyor ve yazılımda hâlâ
> **"Communication Abnormal"** alınıyorsa, sorun genellikle şu 4 nedenden biridir.

## 1. Yazılım Klasöründeki `port.ini` Kilidi

Votol yazılımı, ilk takılan COM portunu hafızasına kilitler. Kablo farklı bir USB
portuna takıldıysa veya port numarası değiştiyse yazılım bağlanmaz.

- **Çözüm:** Votol programının kurulu olduğu klasördeki **`port.ini`** dosyasını
  bulup **silin**. Program yeniden açıldığında portları sıfırdan tarar.

## 2. Sürücü (Driver) Güncellik Sorunu — *En sık yaşanan*

USB programlama kablosunun sürücüsü yüklü görünse bile Windows arka planda otomatik
güncellemiş olabilir.

- **Kontrol:** Aygıt Yöneticisi → **Bağlantı Noktaları (COM ve LPT)**. Kablonun yanında
  **sarı ünlem** veya adının sonunda **"PL2303… Please contact support"** yazısı var mı?
- **Çözüm:** Varsa, internetten **Prolific PL2303 v3.3.2 (2008–2009 eski sürüm)** sürücüsünü
  indirip **el ile** yükleyin.

## 3. Kablolarda RX – TX Karışıklığı

Votol, bilgisayar veya Bluetooth modülüyle haberleşirken kullanılan kabloya/modüle göre
çapraz (cross) ya da düz bağlantı isteyebilir.

- **Deneme:** **Mavi (TX)** ve **Turuncu (RX)** kabloların yerini birbiriyle değiştirip
  tekrar bağlanmayı deneyin. Birçok kullanıcı bu iki kabloyu ters çevirince sorunu çözüyor.

## 4. Kontak (Mor Kablo) Akım Eksikliği

Masaüstü testinde ince **Mor (E-Lock/Kontak)** kabloyu akü artıya bağlarken, ince test
kabloları veya zayıf güç kaynakları işlemcinin ihtiyaç duyduğu anlık akımı karşılayamayabilir.
Voltaj var görünse de işlemci **"boot"** aşamasına geçemez.

- **Çözüm:** Mor kabloyu doğrudan kalın **B+ (ana pozitif)** terminaline **sert ve sağlam**
  bağlayın; temassızlık veya ark olmamalı.

> **Sonraki adım / teşhis:** Sorun kabloda mı yoksa işlemcide mi, ayırt etmek için:
> Aygıt Yöneticisi'nde kablo hangi **COM numarasıyla** (örn. COM3, COM4) görünüyor ve
> üzerinde **sarı ünlem** var mı?

---

## Kaynaklar

1. [Facebook — Votol grup paylaşımı](https://www.facebook.com/groups/1239467163147932/posts/2448865588874744/)
2. [Scribd — Votol EM Series](https://www.scribd.com/document/741946737/votol-em-series)
3. [SIAECOSYS — Resmi PDF](https://www.siaecosys.com/upfile/202402/2024020242619245.pdf)
4. [SlideShare — Controller Programming Manual](https://www.slideshare.net/slideshow/controller-programming-manual-20221125-1-pdf/272072385)
5. [Scribd — Controller Error Solutions ENG V1.2](https://www.scribd.com/document/655438329/Controller-Error-Solutions-ENG-V1-2)
6. [Scribd — VOTOL Controller Fault Indication](https://www.scribd.com/document/741946479/VOTOL-controller-Fault-indication)
7. [Scribd — Votol Controller 1](https://www.scribd.com/document/632843938/Votol-Controler-1)
8. [Manuals.plus — 1005009643638848](https://manuals.plus/ae/1005009643638848)
9. [Facebook — Electric Motorcycle Builds](https://www.facebook.com/groups/electricmotorcyclebuilds/posts/3060302777440406/)
10. [Endless Sphere — Votol EM-100 / EM-150 Controllers](https://endless-sphere.com/sphere/threads/votol-em-100-em-150-controllers.95969/page-13)
11. [Scribd — EM-150 Votol Diagram](https://www.scribd.com/document/742535427/Em-150-Voto-l-Diagram)
12. [Manuals.plus (PL) — 1005004089831930](https://pl.manuals.plus/ae/1005004089831930)
13. [Votol.net — Resmi PDF (2019-03-30)](http://votol.net/upload/file/20190330/20190330091729_60097.pdf)
14. [Endless Sphere — Votol EM-100/EM-150 (page 36)](https://endless-sphere.com/sphere/threads/votol-em-100-em-150-controllers.95969/page-36)
15. [Endless Sphere — Votol EM-100/EM-150 (page 52)](https://endless-sphere.com/sphere/threads/votol-em-100-em-150-controllers.95969/page-52)
16. [Facebook — Electric Motorcycle Builds (3832234473580562)](https://www.facebook.com/groups/electricmotorcyclebuilds/posts/3832234473580562/)
