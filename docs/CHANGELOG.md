# Changelog

## 2026-11-19

### nexa-drive (baru)
- Auto-focus app target sebelum setiap perintah (pakai `monkey`, reuse instance)
- Auto-retry saat bridge mengembalikan "tidak ada hasil"
- `run "CMD;WAIT n;CMD;DUMP"` — batch dalam satu proses
- Fallback otomatis ke mode legacy untuk bridge < 1.6.0
- Shortcut `goto home|discover|players|api|settings`

### NEXA Bridge v1.6.0 (versionCode 7)
- Command baru: `FOCUS`, `TARGET`, `AUTO`
- `DUMP` retry internal 3x100ms
- `LAUNCH` otomatis mengarahkan target ke package yang dibuka
- Target disimpan di SharedPreferences

### Backup & restore (baru)
- `scripts/backup-termux.sh` — Tier 1 default: `$HOME` + package-list + APK penting,
  ke `~/storage/downloads/NEXA-BACKUPS/<stamp>/` + pointer `LATEST`
- Tier 2 opsional `NEXA_BACKUP_PREFIX=1`: `$PREFIX` penuh (7,2 GB). Default mati
  karena ruang terbatas; package bisa di-install ulang dari `package-list.txt`
- `docs/RESTORE.md` — prosedur pemulihan Termux kehapus vs factory reset
- `scripts/cleanup-home.sh` — dry-run by default, butuh backup terverifikasi
  + `NEXA_CLEANUP_CONFIRM=1` untuk eksekusi

### NEXA ROBLOX ULTRA EXPLORER v2.2.1 (versionCode 5)
- `#gameMore`: tombol "Muat lebih banyak" hilang kalau load-next menghasilkan 0 baris baru
- v2.2.0 sebelumnya: perbaikan Single Player, paginasi cursor-aware, retry 429,
  error state jujur, download avatar, chips Discover tanpa `filters_v5`,
  KPI API dinamis, nested module, dan cleanup aset.
