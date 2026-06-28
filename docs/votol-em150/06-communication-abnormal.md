# Votol EM150 — "Communication Abnormal" Hatasının 4 Olası Nedeni

> Gaz pedalından **0.2 V – 4.4 V** arası doğrusal voltaj alınıyorsa gaz okuma
> donanımı çalışıyordur. Buna rağmen motor tetiklenmiyor ve yazılımda hâlâ
> **"Communication Abnormal"** alınıyorsa, sorun genellikle şu 4 nedenden biridir.

İlgili konular: [Pin haritası (TX/RX)](02-pin-haritasi.md) ·
[Güvenlik kilitleri (baud rate)](01-guvenlik-kilitleri.md) · [Kaynaklar](kaynaklar.md)

---

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

- **Deneme:** **Mavi (TX / Pin 12)** ve **Turuncu (RX / Pin 13)** kabloların yerini
  birbiriyle değiştirip tekrar bağlanmayı deneyin. Birçok kullanıcı bu iki kabloyu ters
  çevirince sorunu çözüyor. *(Bluetooth: Modül RX → Pin 12, Modül TX → Pin 13.)*

## 4. Kontak (Mor Kablo) Akım Eksikliği

Masaüstü testinde ince **Mor (E-Lock/Kontak)** kabloyu akü artıya bağlarken, ince test
kabloları veya zayıf güç kaynakları işlemcinin ihtiyaç duyduğu anlık akımı karşılayamayabilir.
Voltaj var görünse de işlemci **"boot"** aşamasına geçemez.

- **Çözüm:** Mor kabloyu doğrudan kalın **B+ (ana pozitif)** terminaline **sert ve sağlam**
  bağlayın; temassızlık veya ark olmamalı.

> **Sonraki adım / teşhis:** Sorun kabloda mı yoksa işlemcide mi, ayırt etmek için:
> Aygıt Yöneticisi'nde kablo hangi **COM numarasıyla** (örn. COM3, COM4) görünüyor ve
> üzerinde **sarı ünlem** var mı?

> Windows seri port hız (baud rate) kilidi de benzer belirti verir; bkz.
> [01-guvenlik-kilitleri.md → Baud Rate](01-guvenlik-kilitleri.md#3-bilgisayar-bağlantısını-kurtarmak--baud-rate-çakışması).
