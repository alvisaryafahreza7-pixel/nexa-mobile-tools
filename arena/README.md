# NEXA-AGENT-ARENA

Sistem multi-agen: banyak agen menyelesaikan bagian tugas secara bersamaan, lalu hasilnya
digabung, diverifikasi, dan dipilih yang terbaik.

Proyek aktif baru (menggantikan NEXA ROBLOX ULTRA EXPLORER yang sudah selesai).
Offline-safe, berjalan di Termux, tanpa Wi-Fi.

## Prinsip
- Pakai kemampuan **subagent yang sudah ada** (`explore`, `general`), bukan bikin skill baru.
- Agen bekerja paralel; agen utama jadi komandan yang menggabungkan hasil.
- Semua baca-saja terhadap repo sumber. Kalau butuh tulis, pakai folder staging sendiri.
- Jangan pernah baca/cetak file berisi token, APK, keystore, atau kredensial.
- Jangan sentuh `storage/external-1` (SD card) saat proses copy masih jalan.

## Peran

| Peran | Tugas | Agen yang dipakai |
|---|---|---|
| **Planner** | Memecah tugas jadi sub-tugas independence + kriteria sukses | `general` |
| **Worker A** | Pendekatan langsung, paling hemat | `explore` / `general` |
| **Worker B** | Pendekatan alternatif (pembanding) | `explore` / `general` |
| **Worker C** | Sudut pandang integritas & kelengkapan | `explore` / `general` |
| **Verifier** | Cek tiap hasil terhadap kriteria sukses | `general` |
| **Challenger** | Menyerang hasil: cari kontradiksi & asumsi lemah (ini "pertempuran"-nya) | `general` |
| **Risk** | Audit bahaya: uninstall, hapus, token, SD, repo sumber | `general` |
| **Arbiter** | ⚖️ Hakim konflik: bandingkan klaim yang bertentangan, putuskan mana yang dipakai (dari `coordinator-mode`) | `general` |
| **Synthesizer** | Gabungkan semua jadi satu draf, soroti yang diperdebatkan | `general` |
| **Judge** | Putuskan jawaban akhir | agen utama |
| **Scribe** | Catat ringkasan ke `history/` (satu-satunya yang boleh menulis) | `general` |

## Alur satu "battle"
1. Terima tugas → Planner buat sub-tugas + kriteria.
2. Kirim Worker A, B, C **barengan** (paralel).
3. Verifier cek → Challenger serang → Risk audit (paralel).
4. **Arbiter** selesaikan konflik antar klaim.
5. Synthesizer gabungkan jadi satu draf.
6. Judge putuskan jawaban akhir.
7. Scribe simpan ringkasan singkat di `history/`.

## Bukti konsep sudah jalan
Demo 2026-11-19: dua subagent paralel mengaudit backup & skill secara bersamaan.
Hasil: backup utuh, 78 file / 77 nama skill unik. Waktu tunggu jauh lebih singkat
daripada sequential, dan konteks agen utama tetap bersih.

## Pola prompt yang dipakai
Diadaptasi dari `undeadlist/claude-code-agents` (MIT) — salinan lokal ada di
`~/NEXA-REF/claude-code-agents`. Kredit lengkap: `ATTRIBUTION.md`.

1. **Status block** — tiap output diawali `agent`, `status`, `findings`, `errors`.
   Orkestrator mendeteksi `status: ERROR` dan menghentikan battle.
2. **Scope NON-OVERLAPPING** — tiap peran punya daftar "JANGAN lakukan", supaya
   Worker A/B/C tidak mengerjakan hal yang sama.
3. **Single authority** — Risk satu-satunya auditor bahaya, Arbiter satu-satunya
   hakim konflik, Judge satu-satunya yang mengeluarkan jawaban final.
4. **Aturan resolusi konflik** — tabel keputusan di `arbiter.md` (keparahan,
   fakta vs opini, bukti kurang, temuan dobel), plus label prioritas P1-P4.

Prompt asli disimpan sebagai `<role>.prompt.md` sebelum output ditimpa, jadi bisa
diulang tanpa kehilangan instruksi.

## Status
- [x] Desain & 11 role
- [x] Demo paralel 2 agen
- [x] Orkestrator otomatis (`orchestrate.zsh`, dry-run sudah lolos)
- [x] Status block + deteksi ERROR
- [x] Perkuat prompt dari pola `claude-code-agents`
- [ ] Uji battle 11 peran penuh (tunggu kuota model reset)

## Catatan
Satu sesi = satu proyek. Proyek ini hanya dikerjakan di sesi ini;
repo sumber NEXA-REPO tidak diubah.
