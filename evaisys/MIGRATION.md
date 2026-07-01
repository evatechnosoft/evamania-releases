# EvaISYS — Bağımsız Repoya Taşıma

EvaISYS şu an `evatechnosoft/evamania-releases` deposu altında `evaisys/` klasöründe geliştirildi
(otomasyon oturumunun izinleri yalnızca bu repoya erişebildiği için). Kendi deposuna taşımak için:

## 1. GitHub'da repoyu oluşturun
- <https://github.com/new> → Owner: **evatechnosoft**, ad: **`evaisys`**, görünürlük: **Private** (öneri),
  "Add a README" **işaretlemeyin** (taşıma sırasında ekleniyor).

## 2. İçeriği taşıyın
Depo kökünde:

```bash
# Geçmişsiz (basit, temiz başlangıç):
evaisys/scripts/migrate-to-standalone-repo.sh ~/evaisys

# veya geçmişli (evaisys/ commit geçmişini korur):
evaisys/scripts/migrate-to-standalone-repo.sh ~/evaisys --with-history
```

## 3. Yeni repoya push
```bash
cd ~/evaisys
git remote add origin git@github.com:evatechnosoft/evaisys.git
git branch -M main
git push -u origin main
```

## 4. Bu monorepodan temizleme (opsiyonel)
Taşıma doğrulandıktan sonra bu depodan kaldırmak isterseniz:
```bash
git rm -r evaisys
git commit -m "chore: EvaISYS bağımsız repoya taşındı"
```

## Notlar
- `node_modules/`, `.pio/`, `build/`, `*.db` gibi üretilen dosyalar `.gitignore` ile hariç tutulur ve
  taşınmaz; hedefte `npm install` / `pio run` / `flutter pub get` ile yeniden üretilir.
- Flutter platform klasörleri (android/ios) yoksa taşıdıktan sonra `flutter create .` ile oluşturun.
