# Votol EM150 — 16 Pin (2×8) Ana Soket Haritası

> EM150 serisi (özellikle **EM150S** ve **EM150-2sp**) ana işlevleri barındıran
> **16 pinli (2×8)** soketin pin karşılıkları. Dizilim, kablo giriş tarafına (arka)
> **tırnak üstte** bakarken soldan sağa: **üst sıra 1–8**, **alt sıra 9–16**.

İlgili konular: [Güvenlik kilitleri](01-guvenlik-kilitleri.md) ·
[Reset](04-reset-one-key-repair.md) · [Kaynaklar](kaynaklar.md)

---

| Pin | Standart Kablo Rengi | Görevi | Bağlantı Tipi / Açıklama |
|-----|----------------------|--------|--------------------------|
| 1 | Pembe | **Throttle +5V** | Gaz kolu / pedal pozitif beslemesi |
| 2 | Mor / Gri-Mor | **E-Lock (Kontak)** | Sürücüyü uyandırmak için Akü (+) verilir |
| 3 | Beyaz | **LIN Speed Sinyali** | Tek kablo (LIN) dijital gösterge hız verisi |
| 4 | Yeşil / Beyaz | **3-Speed (Low/High)** | Hız kademe sinyali; GND'ye çekilerek değişir |
| 5 | Siyah / Kahverengi | **GND (Şase)** | Giriş ve fonksiyon butonları için ortak izoleli eksi |
| 6 | Kahverengi | **Sport Modu (S) / Restore** | GND'ye tetiklenince tepe güç / reset hattı |
| 7 | Kahverengi / Beyaz | **Parking Modu (P)** | Güvenlik kilidi; GND'ye bağlıyken motor gaz yemez |
| 8 | Gri / Beyaz | **Reverse (Geri Vites)** | GND'ye kısa devre edilince motor geri döner |
| 9 | Yeşil | **Throttle Signal** | Gaz kolunun 0–5 V analog veri kablosu |
| 10 | Siyah | **Throttle GND** | Gaz kolunun şase (eksi) bağlantısı |
| 11 | Mor | **High Brake (+12V)** | Fren lambası / +12 V hattından gelen fren sinyali |
| 12 | Mavi | **CAN H / TX** | Bilgisayar/Bluetooth için veri **gönderme** hattı |
| 13 | Turuncu | **CAN L / RX** | Bilgisayar/Bluetooth için veri **alma** hattı |
| 14 | Mavi / Beyaz | **Eco Modu / Hall Eco** | Bazı modellerde düşük tüketim modu tetikleme |
| 15 | Siyah / Kahverengi | **GND (Şase)** | Yedek fonksiyon şasesi (buton eksileri için ortak hat) |
| 16 | Kırmızı / Sarı | **Contactor Control** | Ana kontaktör (röle) tetikleme sinyal çıkışı |

## ⚠️ Kritik Montaj ve Güvenlik Notları

- **Ortak şaseler (GND):** **Pin 5, Pin 10 ve Pin 15** cihaz içinde genellikle ortak
  şasedir (köprülü). Bluetooth modülünün veya butonların GND hatlarını bu
  siyah/kahverengi kablolardan **herhangi birine** bağlayabilirsiniz.
- **Haberleşme pinleri (12 ve 13):** USB-TTL kablosunda sorun yoksa,
  **"Communication Abnormal"** çoğunlukla **Pin 12 (TX)** ve **Pin 13 (RX)** hatlarının
  yanlış sırayla/temassız bağlanmasından kaynaklanır. Bluetooth modülünü bağlarken bu
  ikisini **çaprazlamayı** deneyin: *Modül RX → Pin 12*, *Modül TX → Pin 13*.

> **Çapraz referans:** Bu harita, reset için **Pin 6 (Kahverengi)** + **Pin 5 (GND)** ve
> Park kilidi için **Pin 7 (Kahverengi/Beyaz)** bilgisini doğrular.
