# SIAVM20 VCU Smart Cloud System — Fizibilite ve Yol Haritası

> **Belge türü:** Ürün/teknoloji fizibilitesi ve al-veya-yap (buy vs build) karar dokümanı
> **Hazırlayan rolü:** Kıdemli Ürün Yöneticisi & Analist bakış açısı
> **Tarih:** 2026-07-01
> **Durum:** Karar taslağı (üreticiden teknik teyit bekleyen varsayımlar içerir)
> **Kaynak ürün sayfası:** <https://www.siaecosys.com/show/?id=151>

---

## 1. Yönetici Özeti

**Ürün.** SIAECOSYS/QS Motor'un **VCU Smart Cloud System (model: SIAVM20)** ürünü, elektrikli iki
tekerlekli araçlar için tasarlanmış **4G bağlantılı bir Araç Kontrol Ünitesidir (VCU)**. Motor
kontrolcüsü, batarya ve gösterge panelini **CAN veriyolu** üzerinden birbirine bağlar; üzerine
**uzaktan araç kontrolü, kilitsiz (keyless) çalıştırma, anlık araç durumu izleme, bulut telemetrisi
ve akıllı anti-hırsızlık alarmı** işlevlerini ekler.

**EvaMania için anlamı.** EvaMania bir e-mobilite ürünüdür (mobil uygulama + OTA dağıtım kanalı bu
repoda). SIAVM20, EvaMania'ya "bağlantılı araç" (connected vehicle) yeteneklerini — konum takibi,
uzaktan kilitleme/çalıştırma, sürüş/batarya telemetrisi, hırsızlık koruması — **hazır bir donanım+bulut
paketi** olarak kazandırma potansiyeli taşır.

**Karar sorusu.** Bu yetenekleri elde etmek için EvaMania **hazır SIAVM20'yi satın alıp entegre mi
etmeli (BUY)**, yoksa **kendi VCU + telemetri katmanını mı geliştirmeli (BUILD)**?

**Tavsiye (koşullu).** **Aşamalı hibrit yaklaşım:**
1. **Kısa vade — BUY (pilot):** Sahaya hızlı çıkmak, özellik-pazar uyumunu ve ticari değeri kanıtlamak
   için SIAVM20 ile bir pilot yürütün. Düşük ön yatırım, hızlı time-to-market.
2. **Orta/uzun vade — koşullu BUILD:** Ölçek, veri sahipliği, birim maliyet ve ürün farklılaşması kritik
   hale geldiğinde kendi telemetri/bulut katmanınızı inşa edin (donanımı fason/OEM, yazılım+bulutu kendi
   markanızda tutan model önerilir).

Bu tavsiye, aşağıdaki **§9 Açık Sorular** başlığındaki teknik/ticari verilerin üreticiden teyidine bağlıdır.

---

## 2. Ürün Künyesi (SIAVM20)

| Alan | Bilgi | Kaynak / Not |
|---|---|---|
| Ürün adı | VCU Smart Cloud System | Ürün sayfası (id=151) |
| Model | SIAVM20 | Arama sonuçları |
| Marka / tedarikçi | SIAECOSYS / QS Motor (Çin) | siaecosys.com, cnqsmotor.com |
| Segment | Elektrikli iki tekerlekli (e-scooter, e-motosiklet) | Ürün konumlandırması |
| Bağlantı | 4G hücresel (bulut) | Ürün açıklaması |
| Araç içi haberleşme | CAN veriyolu (kontrolcü + batarya + gösterge) | Ürün açıklaması |

### Beyan edilen işlevler
- **Uzaktan araç kontrolü** (bulut üzerinden komut)
- **Kilitsiz (keyless) çalıştırma**
- **Anlık araç durumu izleme** (hız, batarya, arıza vb. telemetri)
- **Akıllı anti-hırsızlık alarmı**
- **4G bulut bağlantısı** (büyük olasılıkla eşlik eden mobil uygulama ve konum/GPS takibi)

### Mimari (kavramsal)
```
[Motor Kontrolcüsü] --CAN--\
[Batarya / BMS]      --CAN---> [SIAVM20 VCU] --4G--> [SIAECOSYS Bulut] --> [Mobil Uygulama]
[Gösterge Paneli]    --CAN--/
```

> **Doğrulama notu:** Kesin elektriksel spesifikasyonlar (çalışma voltajı, konnektör/pinout, IP koruma
> sınıfı, CE/e-mark/FCC onayları), API/protokol açıklığı, birim fiyat ve minimum sipariş adedi (MOQ)
> kamuya açık kaynaklarda net indekslenmemiştir. Bu belgede bu kalemler **varsayım** olarak işaretlenir
> ve §9'da üreticiden istenecek liste olarak toplanır. **Uydurma teknik değer verilmemiştir.**

---

## 3. EvaMania ile Örtüşme

| EvaMania ihtiyacı (varsayılan) | SIAVM20 katkısı |
|---|---|
| Araç konum takibi / filo görünürlüğü | 4G + (muhtemel) GPS telemetri |
| Uzaktan kilitleme / çalıştırma | Uzaktan kontrol + keyless |
| Batarya & sürüş verisi (app'te gösterim) | CAN telemetrisinin buluta aktarımı |
| Hırsızlığa karşı koruma | Akıllı anti-hırsızlık alarmı |
| Mevcut Android app + OTA altyapısı | Bulut API'si app'e entegre edilebilir |

**Entegrasyon hattı (BUY senaryosu):** SIAVM20 bulutu → (API/webhook) → EvaMania backend → EvaMania
Android app. Kritik bağımlılık: **SIAECOSYS bulut API'sinin açık/erişilebilir** olması. Eğer API kapalıysa,
EvaMania yalnızca üreticinin kendi uygulamasına yönlendirme yapabilir; bu da marka/veri kontrolünü zayıflatır.

---

## 4. Fizibilite Analizi (5 eksen)

### 4.1 Teknik
- **Artılar:** CAN + 4G + bulut yığını hazır; VCU-kontrolcü-batarya uyumu aynı üreticide (QS Motor
  ekosistemi) çözülmüş; entegrasyon eforu app tarafında yoğunlaşır.
- **Riskler:** Bulut API açıklığı bilinmiyor (veri sahipliği ve app entegrasyonu buna bağlı); protokol/veri
  formatı dokümantasyonu teyit edilmeli; EvaMania araç donanımı ile SIAVM20 CAN uyumu doğrulanmalı.
- **Karar etkisi:** API açıksa teknik fizibilite **yüksek**; kapalıysa **orta/düşük**.

### 4.2 Ekonomik
- **BUY maliyet kalemleri:** birim VCU donanımı × araç adedi + 4G SIM/veri aboneliği + bulut platform
  ücreti (varsa) + entegrasyon geliştirme (tek seferlik).
- **BUILD maliyet kalemleri:** donanım Ar-Ge/sertifikasyon + firmware + bulut altyapı + app + sürekli bakım.
- **Not:** Birim fiyat/MOQ teyit edilmeden kesin TCO çıkarılamaz (§9). BUY, ön yatırımı düşük tutar;
  BUILD, ölçekte birim maliyeti düşürme ve marj kontrolü sağlar.

### 4.3 Operasyonel
- **BUY:** Montaj ve satış sonrası tedarikçi ekosistemine bağımlı; yedek parça/garanti üretici üzerinden.
  Türkiye'de yerel destek ve TR dil/yerelleştirme ihtiyacı değerlendirilmeli.
- **BUILD:** Tam operasyonel kontrol ama tedarik zinciri, stok ve saha desteğini kurma yükü sizde.

### 4.4 Regülasyon / Uyumluluk
- **Donanım:** CE / e-mark / hücresel telsiz onayları (TR için ilgili onaylar) teyit edilmeli.
- **Veri:** Konum ve araç verisi işlendiğinden **KVKK** (ve gerekiyorsa GDPR) uyumu — verinin nerede
  tutulduğu (yurt dışı bulut riski) BUY senaryosunda kritik.
- **Karar etkisi:** Veri yurt dışında ve API kapalıysa, KVKK ve marka açısından BUILD lehine güçlü argüman.

### 4.5 Zaman / Kaynak (Time-to-Market)
- **BUY:** Haftalar–birkaç ay (entegrasyon ağırlıklı). **Hızlı.**
- **BUILD:** Aylar–yıl (donanım + sertifikasyon + yazılım). **Yavaş ama kalıcı varlık.**

---

## 5. Al-veya-Yap (Buy vs Build) Karşılaştırması

Puanlama: 1 (zayıf) – 5 (güçlü). Ağırlıklar örnek olup EvaMania önceliklerine göre güncellenmelidir.

| Kriter | Ağırlık | BUY (SIAVM20) | BUILD (kendi) |
|---|---:|:---:|:---:|
| Time-to-market | %20 | 5 | 2 |
| Ön yatırım / nakit riski | %15 | 5 | 2 |
| Birim maliyet (ölçekte) | %10 | 3 | 4 |
| Veri sahipliği & KVKK kontrolü | %15 | 2 | 5 |
| Ürün farklılaşması / marka | %10 | 2 | 5 |
| Ölçeklenebilirlik | %10 | 3 | 4 |
| Bakım / operasyon yükü | %10 | 4 | 2 |
| Tedarikçi bağımlılığı riski | %10 | 2 | 5 |
| **Ağırlıklı toplam (yaklaşık)** | %100 | **~3,3** | **~3,4** |

**Okuma:** İki seçenek ağırlıklı toplamda başa baştır — bu tam da **aşamalı hibrit** tavsiyesini destekler:
kısa vadede BUY'ın hız/nakit avantajını al, uzun vadede BUILD'in veri/marj/kontrol avantajına geç.

---

## 6. Riskler ve Azaltıcı Önlemler

| Risk | Etki | Azaltım |
|---|---|---|
| Bulut API kapalı → veri/marka kontrolü yok | Yüksek | Sözleşme öncesi API erişimini yazılı teyit et; açık değilse BUY'ı sadece pilotla sınırla |
| Veri yurt dışı bulut → KVKK | Yüksek | Veri lokasyonu/aktarım sözleşmesi; gerekiyorsa yerel proxy/veri aynası |
| Tek tedarikçiye bağımlılık | Orta-Yüksek | İkinci kaynak / BUILD geçiş planını baştan tut |
| Birim fiyat/MOQ bilinmiyor | Orta | Teklif ve numune iste; TCO'yu teyitten sonra kesinleştir |
| Sertifikasyon (CE/TR/telsiz) eksik | Orta | Uygunluk belgelerini satın alma öncesi talep et |
| 4G SIM/roaming maliyeti | Orta | Yıllık abonelik modelini netleştir; toplu SIM anlaşması |

---

## 7. Karar / Tavsiye

**Aşamalı hibrit (önerilen):**
- **Faz 0–1'de BUY** ile hızlı pilot: değeri kanıtla, entegrasyon riskini ölç, gerçek saha verisi topla.
- **Karar kapısı (§8 sonunda):** API açıklığı + KVKK + birim maliyet + hacim projeksiyonu sonuçlarına göre
  **BUILD'e geçiş** kararı ver.
- **Hedef mimari (uzun vade):** Donanımı fason/OEM tedarik et, **firmware + bulut + app'i EvaMania markasında
  tut** — böylece veri sahipliği, marj ve farklılaşma sizde kalır.

Bu tavsiye, §9'daki verilerin teyidiyle kesinleşir.

---

## 8. Yol Haritası

| Faz | Amaç | Ana çıktılar | Tahmini süre | Başarı kriteri |
|---|---|---|---|---|
| **Faz 0 — Keşif** | Teknik/ticari teyit | §9 sorularının yanıtı, numune, teklif, API dokümanı | 2–4 hafta | API açıklığı ve fiyat netleşti |
| **Faz 1 — Pilot/PoC** | 1–5 araçta entegrasyon | SIAVM20 kurulumu, bulut→EvaMania app veri akışı, uzaktan kilit/takip demosu | 4–8 hafta | Çekirdek işlevler app'te canlı |
| **Faz 2 — Saha testi** | Küçük filo doğrulaması | 10–50 araç, güvenilirlik/kapsama/pil ölçümleri, KVKK uyum kontrolü | 6–10 hafta | Kabul edilebilir arıza/kapsama; KVKK onayı |
| **Karar kapısı** | Buy vs Build kesinleştir | TCO + veri sahipliği + hacim kararı | — | Net BUY-devam / BUILD-geç kararı |
| **Faz 3 — Ölçek** | Seri üretim/yaygınlaştırma | Tedarik/stok, satış sonrası, (BUILD ise) kendi katmanına geçiş planı | 3–6 ay | Ölçekte birim maliyet ve operasyon hedefleri |

**Roller (öneri):** Ürün (PM) — karar kapısı ve öncelik; Donanım/Elektrik — CAN & montaj; Backend —
bulut API entegrasyonu; Mobil — EvaMania app özellikleri; Hukuk/Uyum — KVKK & sertifikasyon; Tedarik — QS Motor ilişkisi.

---

## 9. Açık Sorular / Üreticiden Teyit Edilecekler

1. **Bulut API açık mı?** REST/webhook dokümantasyonu, kimlik doğrulama, veri şeması var mı?
2. **Veri lokasyonu:** Bulut/veri nerede tutuluyor? KVKK uyumlu aktarım mümkün mü?
3. **Elektriksel spec:** Çalışma voltajı, güç tüketimi, konnektör/pinout, IP koruma sınıfı.
4. **CAN protokolü:** Desteklenen kontrolcü/BMS listesi, mesaj tanımları, EvaMania donanımıyla uyum.
5. **Sertifikasyon:** CE / e-mark / hücresel telsiz onayları; TR için geçerlilik.
6. **GPS:** Konum takibi cihazda mı, doğruluk ve güncelleme sıklığı?
7. **Ticari:** Birim fiyat, MOQ, teslim süresi, garanti, 4G SIM/veri abonelik modeli ve ücreti.
8. **Beyaz etiket (white-label):** Uygulama/bulutta EvaMania markası mümkün mü?
9. **Yol haritası & destek:** Firmware güncelleme, teknik destek SLA, uzun dönem ürün ömrü.

---

## 10. Kaynaklar

- VCU Smart Cloud System — ürün sayfası: <https://www.siaecosys.com/show/?id=151>
- SIAECOSYS ana sayfa: <https://www.siaecosys.com/>
- QS Motor — VCU Device kategorisi: <https://www.cnqsmotor.com/product-category/siaecosys-accessories/vcu-device/>
- SIAECOSYS kullanım kılavuzları: <https://www.siaecosys.com/list/?classid=21>

> **Sınırlılık:** Bu belge kamuya açık web bilgileri ve ürün açıklamasıyla derlenmiştir. Kesin teknik ve
> ticari kalemler §9 teyidiyle netleşecek; o güne kadar ilgili değerler **varsayım** kabul edilmelidir.
