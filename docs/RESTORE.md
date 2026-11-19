# Restore dari Backup Termux

Backup dibuat oleh `scripts/backup-termux.sh` ke:

```
~/storage/downloads/NEXA-BACKUPS/<stamp>/
```

## Isi backup

| File | Isi |
|---|---|
| `termux-prefix.tar.gz` | **opsional** — seluruh `$PREFIX` (7,2 GB). Hanya dibuat kalau `NEXA_BACKUP_PREFIX=1` dan ruang cukup |
| `termux-home-full.tar.gz` | `$HOME`: repo, staging, config, keystore, library index |
| `package-list.txt` | daftar package Termux (referensi) |
| `apks/` | APK penting (Bridge, Roblox Explorer, dll.) |
| `SHA256SUMS.txt` | checksum untuk verifikasi |
| `LATEST` (di parent) | pointer ke folder backup terakhir |

Yang **sengaja tidak** disertakan: `.cache`, `.npm`, `.gradle`, `node_modules`,
`android-sdk-extract`, `autom4te.cache`, `.cpan` — semuanya bisa di-regenerate.

## Verifikasi dulu (wajib)

```bash
cd ~/storage/downloads/NEXA-BACKUPS/<stamp>
sha256sum -c SHA256SUMS.txt
```

Semua harus `OK`. Kalau ada `FAILED`, jangan dipakai — ulangi backup.

## Skenario A — Termux kehapus, HP tidak di-reset

1. Install Termux lagi (F-Droid disarankan).
2. Beri izin storage: `termux-setup-storage` (satu kali tap).
3. Pulihkan `$HOME`:
   ```bash
   cd $HOME
   tar -xzf ~/storage/downloads/NEXA-BACKUPS/<stamp>/termux-home-full.tar.gz
   ```
4. Pulihkan `$PREFIX` — **hanya kalau `termux-prefix.tar.gz` ada**
   (ekstrak dari akar filesystem Termux):
   ```bash
   cd /
   tar -xzf ~/storage/downloads/NEXA-BACKUPS/<stamp>/termux-prefix.tar.gz
   ```
   Kalau tidak ada (default), pasang ulang package dari daftar:
   ```bash
   pkg update
   pkg install $(grep -oE '^[a-z0-9.+-]+' <stamp>/package-list.txt | sort -u | tr '\n' ' ')
   ```
   toolchain besar (rust/go/jvm/code-server) memang bisa di-install ulang, jadi
   yang benar-benar tak tergantikan ada di `$HOME` (langkah 3).
5. Install ulang APK dari `apks/` (perlu tap Install manual).
6. Aktifkan lagi accessibility service **NEXA Bridge** di Settings.
7. Pasang wrapper:
   ```bash
   cp $HOME/NEXA-MOBILE-TOOLS/bin/nexa-* ~/.local/bin/
   chmod +x ~/.local/bin/nexa-*
   ```
8. Uji: `nexa-bridge PING`.

## Skenario B — HP di-reset total (factory reset)

⚠️ Backup di `/sdcard` **ikut terhapus** saat factory reset. Yang aman di GitHub
hanya helper (tanpa keystore/token). Maka **sebelum reset**, salin folder backup
ke tempat lain (PC / cloud / flashdisk) secara manual. Setelah reset, salin
kembali ke `storage/downloads/` lalu ikuti Skenario A.

## Isi sensitif — JANGAN di-upload ke repo publik

Arsip `$HOME` mengandung:
- `NEXA-APK-STAGING/keystore/*.jks` + `PASS.txt` (signing APK)
- `NEXA-APK-STAGING/NEXA-ROBLOX-ULTRA-EXPLORER/signing/*.keystore`
- `.config/gh/hosts.yml` (token GitHub)
- `.ssh/`

Repo `nexa-mobile-tools` **hanya** berisi wrapper & docs — bukan arsip ini.

## Rebuild cepat (setelah restore)

```bash
# Roblox Explorer — masukkan passphrase signing secara interaktif (tidak disimpan di repo)
cd ~/NEXA-APK-STAGING/NEXA-ROBLOX-ULTRA-EXPLORER
read -rs -p 'Passphrase signing: ' NEXA_SIGN_PASS; echo
NEXA_INITIAL_PASS="$NEXA_SIGN_PASS" NEXA_ROTATED_PASS="$NEXA_SIGN_PASS" \
  /data/data/com.termux/files/usr/bin/zsh ./tools/build.zsh

# Bridge
cd ~/NEXA-APK-STAGING && bash ./build-bridge.sh
```
