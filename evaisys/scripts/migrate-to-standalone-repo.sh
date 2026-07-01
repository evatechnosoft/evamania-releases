#!/usr/bin/env bash
# EvaISYS — bu monorepo klasörünü (evaisys/) bağımsız bir git deposuna taşır.
#
# İki yöntem sunar:
#   A) Geçmişsiz (basit): sadece güncel dosyaları yeni repoya kopyalar.
#   B) Geçmişli (git subtree): evaisys/ klasörünün commit geçmişini korur.
#
# Kullanım:
#   scripts/migrate-to-standalone-repo.sh <hedef-dizin> [--with-history]
#
# Örnek:
#   scripts/migrate-to-standalone-repo.sh ~/evaisys
#   scripts/migrate-to-standalone-repo.sh ~/evaisys --with-history
#
# Sonra:
#   cd <hedef-dizin>
#   git remote add origin git@github.com:evatechnosoft/evaisys.git
#   git push -u origin main

set -euo pipefail

DEST="${1:-}"
MODE="${2:-}"

if [[ -z "$DEST" ]]; then
  echo "Kullanım: $0 <hedef-dizin> [--with-history]" >&2
  exit 1
fi

# Repo kökünü ve bu klasörün adını bul.
ROOT="$(git rev-parse --show-toplevel)"
SUBDIR="evaisys"

if [[ ! -d "$ROOT/$SUBDIR" ]]; then
  echo "Hata: $ROOT/$SUBDIR bulunamadı" >&2
  exit 1
fi

if [[ "$MODE" == "--with-history" ]]; then
  echo "==> Geçmişli taşıma (git subtree split)"
  cd "$ROOT"
  BRANCH="evaisys-split-tmp"
  git subtree split --prefix="$SUBDIR" -b "$BRANCH"
  mkdir -p "$DEST"
  git clone "$ROOT" "$DEST"
  cd "$DEST"
  git checkout "$BRANCH"
  git branch -D main 2>/dev/null || true
  git branch -m main
  git remote remove origin 2>/dev/null || true
  # Kaynak repodaki geçici dalı temizle.
  ( cd "$ROOT" && git branch -D "$BRANCH" )
  echo "==> Tamam. Geçmiş korundu: $DEST"
else
  echo "==> Geçmişsiz taşıma (dosya kopyası)"
  mkdir -p "$DEST"
  # node_modules, build ve db dışında her şeyi kopyala (tar ile taşınabilir).
  tar -C "$ROOT/$SUBDIR" \
      --exclude='./node_modules' --exclude='*/node_modules' \
      --exclude='./.pio' --exclude='*/.pio' \
      --exclude='./build' --exclude='*/build' \
      --exclude='*.db' --exclude='*.db-shm' --exclude='*.db-wal' \
      --exclude='./.dart_tool' --exclude='*/.dart_tool' \
      -cf - . | tar -C "$DEST" -xf -
  cd "$DEST"
  git init -q
  git add .
  git commit -q -m "chore: EvaISYS bağımsız repo başlangıcı (monorepodan taşındı)"
  echo "==> Tamam. Yeni repo hazır: $DEST"
fi

echo
echo "Sonraki adımlar:"
echo "  cd $DEST"
echo "  git remote add origin git@github.com:evatechnosoft/evaisys.git"
echo "  git push -u origin main"
