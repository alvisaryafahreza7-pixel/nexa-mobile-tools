#!/data/data/com.termux/files/usr/bin/bash
# Rapikan $HOME — HANYA jalan kalau:
#   1. backup terakhir terverifikasi (sha256sum -c OK)
#   2. NEXA_CLEANUP_CONFIRM=1
#
# Default = DRY RUN (tampilkan rencana, tidak mengubah apa pun).
set -uo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$HOME/NEXA-CLEANUP-ARCHIVE/$STAMP"
LATEST="$HOME/storage/downloads/NEXA-BACKUPS/LATEST"

CACHE_DIRS=(.cache autom4te.cache android-sdk-extract .gradle .npm node_modules NEXA-backups)
LOG_PATTERNS=(
  '.nexa-*.log'
  '.bashrc.bak-*' '.bashrc-before-*' '.bash_profile.before-*'
  '.zshrc.bak-*' '.zshrc.before-*'
)

log() { printf '[cleanup] %s\n' "$*"; }

# --- Pengaman 1: backup harus terverifikasi ---
if [ ! -f "$LATEST" ]; then
  log "GAGAL: tidak ada pointer LATEST. Jalankan backup-termux.sh dulu."
  exit 1
fi
DEST="$(cat "$LATEST")"
if [ ! -f "$DEST/SHA256SUMS.txt" ] || [ ! -f "$DEST/termux-home-full.tar.gz" ]; then
  log "GAGAL: backup tidak lengkap di $DEST"
  exit 1
fi
if ! (cd "$DEST" && sha256sum -c SHA256SUMS.txt >/dev/null 2>&1); then
  log "GAGAL: checksum backup tidak cocok. Jangan hapus apa pun."
  exit 1
fi
log "backup terverifikasi: $DEST"

# --- Kumpulkan target (hanya yang benar-benar ada) ---
TARGETS=()
for d in "${CACHE_DIRS[@]}"; do
  [ -e "$HOME/$d" ] && TARGETS+=("$d")
done
LOGS=()
for pattern in "${LOG_PATTERNS[@]}"; do
  for f in "$HOME"/$pattern; do
    [ -f "$f" ] && LOGS+=("$f")
  done
done

log "=== RENCANA ==="
for d in "${TARGETS[@]}"; do
  log "HAPUS  $d  ($(du -sh "$HOME/$d" 2>/dev/null | cut -f1))"
done
for f in "${LOGS[@]}"; do
  log "ARSIPKAN  ${f#$HOME/}"
done
log "arsip log -> $ARCHIVE"
log "================="

# --- Pengaman 2: konfirmasi eksplisit ---
if [ "${NEXA_CLEANUP_CONFIRM:-0}" != "1" ]; then
  log "DRY RUN selesai. Untuk eksekusi: NEXA_CLEANUP_CONFIRM=1 bash $0"
  exit 0
fi

log "Mengarsipkan ${#LOGS[@]} file log/config lama..."
mkdir -p "$ARCHIVE"
for f in "${LOGS[@]}"; do
  mv "$f" "$ARCHIVE/" 2>/dev/null || log "gagal pindah: $f"
done

log "Menghapus ${#TARGETS[@]} folder cache..."
for d in "${TARGETS[@]}"; do
  rm -rf "$HOME/$d" 2>/dev/null && log "terhapus: $d" || log "gagal hapus: $d"
done

log "SELESAI. Sisa ruang: $(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $4}')"
