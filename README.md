# NEXA Mobile Tools

Helper lokal untuk mengawal HP Android lewat **NEXA Bridge** (accessibility service, tanpa root / Wi-Fi / komputer).

Repo ini **hanya berisi wrapper & dokumentasi**. Tidak berisi source app, keystore, password, atau APK.

## Isi

- `bin/nexa-bridge` — CLI pengirim perintah broadcast ke `com.nexa.bridge`
- `bin/nexa-drive` — wrapper cepat: auto-focus, auto-retry, batch `run`
- `docs/PHONE-CONTROL.md` — panduan supaya sesi kontrol HP tidak lama
- `docs/CHANGELOG.md` — ringkasan perubahan tool & bridge

## Instalasi di Termux

```bash
cp bin/nexa-bridge bin/nexa-drive ~/.local/bin/
chmod +x ~/.local/bin/nexa-bridge ~/.local/bin/nexa-drive
```

Pastikan APK `NEXA Bridge v1.6.0` terpasang dan accessibility service aktif.

## Contoh tercepat

```bash
nexa-drive focus com.nexa.robloxultraexplorer
nexa-drive run 'CLICK_TEXT Players;WAIT 2;CLICK_TEXT Cari Pemain;WAIT 1;DUMP'
```

## Kenapa `run` penting

Tiap kali perintah bridge dikirim dari Termux, fokus layar bisa kembali ke Termux.
`nexa-drive run` menjaga fokus di app target **sebelum setiap perintah** dan mengulang
DUMP yang gagal. Satu `run` = satu tool call = jauh lebih cepat daripada puluhan panggilan.

## Prinsip

- Tanpa root, tanpa Wi-Fi, tanpa komputer
- Satu kali tap manual untuk izin / install diperbolehkan
- Tidak pernah mengubah repo sumber yang sudah ada
- Tidak mengaktifkan SMS, kontak, kamera, mic, lokasi, atau device admin tanpa permintaan eksplisit
