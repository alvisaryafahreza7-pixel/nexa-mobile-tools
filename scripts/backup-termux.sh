#!/data/data/com.termux/files/usr/bin/bash
# Backup Termux bertahap, aman untuk ruang terbatas.
#
# Tier 1 (default, dijalankan selalu):
#   $HOME + package-list.txt + APK penting  -> barang TAK bisa di-regenerate.
# Tier 2 (opsional, $PREFIX penuh 7,2 GB):
#   bisa dipasang ulang dari package-list.txt, jadi default MATI.
#   Aktifkan: NEXA_BACKUP_PREFIX=1 bash scripts/backup-termux.sh
#
# Output: ~/storage/downloads/NEXA-BACKUPS/<stamp>/ + pointer LATEST.
# Tidak menyentuh repo sumber apa pun.
set -uo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"
ROOT="$HOME/storage/downloads"
DEST="$ROOT/NEXA-BACKUPS/$STAMP"
LATEST="$ROOT/NEXA-BACKUPS/LATEST"
WITH_PREFIX="${NEXA_BACKUP_PREFIX:-0}"
mkdir -p "$DEST"

log() { printf '[backup] %s\n' "$*"; }
free_mb() { df -k "$ROOT" 2>/dev/null | awk 'NR==2 {print int($4/1024)}'; }

log "dest   = $DEST"
log "free   = $(free_mb) MB"
log "prefix = $WITH_PREFIX (1=ikutkan \$PREFIX, 0=default)"

log "[1/4] daftar package"
pkg list-installed > "$DEST/package-list.txt" 2>/dev/null \
  || dpkg -l > "$DEST/package-list.txt" 2>/dev/null \
  || echo "(gagal)" > "$DEST/package-list.txt"

log "[2/4] backup \$HOME (kecuali cache yang bisa di-regenerate)"
tar -czf "$DEST/termux-home-full.tar.gz" \
  -C "$HOME" \
  --exclude="./storage/downloads/NEXA-BACKUPS" \
  --exclude="./.cache" \
  --exclude="./.npm" \
  --exclude="./.gradle" \
  --exclude="./node_modules" \
  --exclude="./android-sdk-extract" \
  --exclude="./autom4te.cache" \
  --exclude="./.cpan" \
  . 2>/dev/null
log "home   = $(du -h "$DEST/termux-home-full.tar.gz" 2>/dev/null | cut -f1)"

if [ "$WITH_PREFIX" = "1" ]; then
  FREE="$(free_mb)"
  if [ "$FREE" -lt 4000 ]; then
    log "[3/4] SKIP \$PREFIX: sisa ${FREE} MB (butuh ~4000 MB)."
    log "       package tetap tercatat di package-list.txt."
  else
    log "[3/4] backup \$PREFIX penuh (bisa lama)"
    termux-backup -f "$DEST/termux-prefix.tar.gz" 2>&1 | tail -3
    log "prefix = $(du -h "$DEST/termux-prefix.tar.gz" 2>/dev/null | cut -f1)"
  fi
else
  log "[3/4] \$PREFIX dilewati (default). Pulihkan via package-list.txt."
fi

log "[4/4] salin APK penting + checksum + pointer LATEST"
mkdir -p "$DEST/apks"
for f in \
  NEXA-BRIDGE-v1.6.0.apk \
  NEXA-ROBLOX-ULTRA-EXPLORER-v2.2.1.apk \
  NEXA-ROBLOX-ULTRA-EXPLORER-v2.2.0.apk \
  NEXA-PYTH*.apk \
  NEXA-CODELAB*.apk; do
  for src in "$ROOT"/$f; do
    [ -f "$src" ] && cp "$src" "$DEST/apks/" 2>/dev/null
  done
done

( cd "$DEST" && sha256sum *.tar.gz package-list.txt > SHA256SUMS.txt 2>/dev/null )
printf '%s\n' "$DEST" > "$LATEST"

log "SELESAI"
ls -lh "$DEST" | head -20
log "sisa ruang = $(free_mb) MB"
