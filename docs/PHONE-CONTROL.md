# Panduan Kontrol HP (anti-lama)

## Masalah yang sudah diatasi

1. **Fokus balik ke Termux** — `nexa-drive` memanggil `monkey -p <pkg> -c android.intent.category.LAUNCHER 1`
   sebelum tiap perintah. Ini *reuse* instance yang sudah jalan, jadi WebView tidak di-restart.
2. **DUMP gagal intermittent** ("tidak ada hasil dari bridge") — `nexa-drive` retry otomatis
   (`NEXA_DRIVE_RETRY`, default 4).
3. **Koordinat geser saat keyboard muncul** — pakai `CLICK_TEXT` / `FIND`, bukan `TAP` hardcoded.
4. **Background launch dibatasi Android 12** — command `FOCUS` dari service tidak cukup;
   tetap pakai `am start`/`monkey` dari Termux.

## Pola kerja disarankan

```bash
# Sekali di awal sesi
nexa-drive focus com.nexa.robloxultraexplorer

# Semua aksi berikutnya digabung
nexa-drive run '
  CLICK_TEXT Players;
  WAIT 2;
  CLICK_TEXT 25 Players - maksimal 25 hasil;
  WAIT 1;
  TAP 300,818;
  TYPE builderman;
  CLICK_TEXT Cari Pemain;
  WAIT 10;
  DUMP
'
```

## Command berguna

| Perintah | Fungsi |
|---|---|
| `nexa-drive dump` | DUMP dengan auto-retry |
| `nexa-drive click "Cari Pemain"` | klik node by teks |
| `nexa-drive tap 300,818` | tap koordinat (hati-hati keyboard) |
| `nexa-drive goto players` | shortcut nav bawah |
| `nexa-drive find Roblox` | cari node + koordinat |
| `nexa-drive raw PING` | perintah bridge apa saja |

## Env

- `NEXA_DRIVE_RETRY` — jumlah retry (default 4)
- `NEXA_DRIVE_FOCUS_WAIT` — jeda setelah focus (default 2 detik)

## Command bridge v1.6.0

- `FOCUS <package>` — set target + launch
- `TARGET <package>` — arahkan pembacaan UI ke package
- `AUTO` — reset target ke active window

Catatan: `TARGET` tidak bisa membaca window app yang benar-benar di background
(keterbatasan `getWindows()`), jadi `nexa-drive` tetap menjaga fokus per perintah.
