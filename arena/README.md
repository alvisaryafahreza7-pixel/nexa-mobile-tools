# NEXA-AGENT-ARENA

Sistem multi-agen: banyak agen menyelesaikan bagian tugas secara bersamaan, lalu hasilnya
digabung, diverifikasi, dan dipilih yang terbaik.

Proyek aktif baru (menggantikan NEXA ROBLOX ULTRA EXPLORER yang sudah selesai).
Offline-safe, berjalan di Termux, tanpa Wi-Fi.

## Prinsip
- Pakai kemampuan **subagent yang sudah ada** (`explore`, `general`) untuk prajurit.
  Skill yang ada hanya pembungkus relay Boss (`~/NEXA-SKILLS/nexa-arena-boss`),
  bukan agen baru.
- Agen bekerja paralel; agen utama jadi komandan yang menggabungkan hasil.
- Semua baca-saja terhadap repo sumber. Kalau butuh tulis, pakai folder staging sendiri.
- Jangan pernah baca/cetak file berisi token, APK, keystore, atau kredensial.
- Jangan sentuh `storage/external-1` (SD card) saat proses copy masih jalan.

## Peran

| Peran | Tugas | Agen yang dipakai |
|---|---|---|
| **Commander** | Captain: menyusun perintah untuk prajurit & memutus hasil; Boss tinggal arahan + jawaban | `general` |
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

## Hierarki: Boss → Captain → prajurit

```
Boss (agen utama)   = kasih arahan, sampaikan perintah, terima jawaban
Captain (commander) = mengatur prajurit, susun tugas, memutus hasil
Prajurit (11 peran)  = mengerjakan tugasnya masing-masing
```

Tool `subagent` hanya ada di Boss, bukan di Captain. Karena itu Captain bekerja
dua fase dan Boss jadi pengantar mekanis:

1. **ORDERS** — Boss lempar tugas ke Captain:
   ```sh
   ./dispatch.zsh commander "FASE: ORDERS | <tugas>"
   ```
   Captain balas blok `ORDERS:` berisi baris `role: tugas` berbeda + `KRITERIA:`.
   Boss ekstrak jadi plan:
   ```sh
   ./orders.zsh orders.txt plan.txt
   ./dispatch.zsh --plan plan.txt        # prompt tiap prajurit
   ```
2. **PRAJURIT** — Boss jalankan prompt itu lewat tool `subagent` (boleh paralel).
3. **VERDICT** — Boss kirim semua laporan kembali ke Captain:
   ```sh
   ./dispatch.zsh commander "FASE: VERDICT | <laporan A/B/C/...>"
   ```
   Captain yang menjalankan Verifier, Challenger, Risk, Arbiter, Judge dan
   mengembalikan KEPUTUSAN akhir. Boss tinggal menyampaikan ke kamu.

Captain yang **mengatur dan memutus**; Boss tidak ikut menilai, cuma menyampaikan
perintah dan laporan 👌

## Skill Boss: `@nexa-arena-boss`

Biar alur di atas otomatis, ada skill di `~/NEXA-SKILLS/nexa-arena-boss/SKILL.md`
(terdaftar lewat `"skills": ["~/NEXA-SKILLS"]` di config OpenCode, langsung aktif
tanpa restart). Pemakai cukup kasih satu tugas; skill yang mengatur lima langkah:

```
ORDERS → orders.zsh → dispatch.zsh --plan → subagent prajurit → VERDICT → jawaban
```

Batasan jujur: tool `subagent` secara harfiah **tidak bisa** dipasang ke Captain,
karena itu tool harness milik agen utama. Skill ini yang jadi "tangan" Captain:
perintah Captain diterjemahkan jadi panggilan `subagent` nyata, laporannya balik
lagi ke Captain. Jadi secara fungsi Captain memerintahkan prajurit, sedangkan
Boss murni `suruh + terima`. Dari sisi pemakai: satu tugas masuk, satu VERDICT keluar.

Skill **tidak** mengubah isi perintah Captain, tidak menambah opini Boss, dan tetap
memaksa `worker-c` untuk tugas integritas (aturan sudah ada di otak Captain).

Salinan versioned ada di `skills/nexa-arena-boss/SKILL.md` (path aktif tetap
`~/NEXA-SKILLS/nexa-arena-boss/SKILL.md`). Kalau diubah, samakan keduanya.

Bukti 2026-11-19: tugas "cek LATEST backup masih menunjuk ke folder yang ada" →
Captain ORDERS memilih A+B+C (C otomatis karena validasi path) → A/B `COCOK`
(path + metadata identik), C bantu cek symlink & baseline → Captain VERDICT
`TERIMA`, dengan P2 mengingatkan `SHA256SUMS` masih 2 entri.

## Mode & kecepatan

| Mode | Agen | Tahap | Dipakai untuk |
|---|---|---|---|
| `cepat` | 2 (Worker A + Judge) | 2 | Cek sepele, ~1,5 menit |
| `ringan` | 4 | 3 | Cek cepat, ~3 menit |
| `sedang` | 8 | 6 | Audit menengah |
| `penuh` | 11 | 7 | Keputusan besar, ~7 menit |

Flag `--fast` memotong jalur: Planner ∥ Worker jalan bareng, Synthesizer dan Scribe
dilewati (output Arbiter langsung jadi draf Judge; `FINAL.md` tetap disalin dari Judge,
`SUMMARY.md` dibuat otomatis tanpa agen). Mode `penuh --fast` pakai **9 agen / 5 tahap**
dari 11 / 7. Default tidak berubah, jadi battle lama tetap reproducible.

```sh
./orchestrate.zsh --mode cepat "cek cepat"
./orchestrate.zsh --fast --mode penuh "keputusan besar tapi hemat waktu"
./orchestrate.zsh --mode penuh "uji penuh sesuai alur asli"
```

## Otak peran (memori persisten)

Tiap peran punya file otak di `brains/<role>.md`, berisi tiga bagian:

- **SOP eksekusi** — cara kerja lengkap peran itu (status block, scope, batas baris).
  Jadi otaknya **sudah bisa dipakai sendiri**: cukup suruh agen baca file ini,
  tanpa generate prompt baru.
- **Pengetahuan tetap** — aturan, jalur cepat, dan preseden yang sudah terverifikasi.
- **Ingatan battle** — pelajaran ringkas dari battle sebelumnya.

Nyuruh langsung pakai **variabel**, bukan hardcode per peran. `dispatch.zsh` mengisi
`$ROLE`, `$TASK`, `$BRAIN`, `$AGENT`, `$ROLES`, `$HISTORY` otomatis:

```sh
./dispatch.zsh --list
./dispatch.zsh worker-b "cari celah checksum backup"   # satu peran
./dispatch.zsh --plan examples/plan.txt                # TIAP peran dapat tugas berbeda
./dispatch.zsh --broadcast "audit cepat"               # tugas sama untuk semua (jarang)
```

**Worker A/B/C tidak boleh dapat tugas yang sama.** Mereka menerima sub-tugas
berbeda dari Planner, lalu tiap otak menerjemahkannya ke sudutnya sendiri:
A langsung, B alternatif, C integritas. `--plan` memastikan ini lewat format
`role: tugas` satu baris per peran; peran yang tidak dikenal ditolak otomatis.
Contoh nyata ada di `examples/plan.txt`.

Hasilnya satu prompt siap pakai. Di stderr ada metadata `AGENT=... BRAIN=... ROLE=...`
supaya pemanggil tahu harus pakai agen `explore` atau `general`. Output contoh
untuk `worker-b`:

```
Kamu worker-b.
Baca file ini SAJA sebagai instruksi lengkapmu:
/data/.../arena/brains/worker-b.md
Ikuti bagian `## SOP eksekusi` di dalamnya. ...
Tugas: cari celah checksum backup
Kembalikan HANYA output sesuai SOP (status block + batas baris peranmu).
```

Nilai yang berubah-ubah (path backup, tanggal battle, jumlah file) **tidak di-hardcode**
di otak — dibaca dari variabel/file yang resolusinya aktual, misalnya `LATEST`,
`command -v nexa-drive`, `$ARENA_ROOT`. Angka lama hanya baseline dan harus divalidasi
ulang tiap battle.

Kalau tetap lewat orkestrator, tiap prompt otomatis dapat instruksi `## Otak peran`
untuk membaca file ini. **Default: baca-saja** — agen tidak mengubah brain mana pun.

Flag `--learn` mengaktifkan penulisan, tapi tetap aman:

1. Agen hanya mengeluarkan **maksimal 1 baris** `PELAJARAN: ...` di akhir jawaban.
2. **Orkestrator** (bukan agen) yang menambahkannya ke `## Ingatan battle`.
3. Baris dengan pola secret (`ghp_`, `gho_`, `github_pat_`, private key, `token=`,
   `password=`) ditolak otomatis.
4. `## Pengetahuan tetap` tidak pernah disentuh.

```sh
./orchestrate.zsh --mode ringan "audit backup"          # baca otak, tanpa menulis
./orchestrate.zsh --learn --mode ringan "audit backup"  # baca + simpan 1 pelajaran/peran
```

`brains/` **di-commit** ke git sebagai ingatan bersama. `history/` sengaja di-gitignore.
Review `git diff` setelah `--learn` sebelum commit, karena isinya berasal dari teks agen.

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
- [x] Uji battle 11 peran penuh (2026-11-19, lewat subagent internal, ~7 menit)
- [x] Mode `cepat` + flag `--fast` (dry-run terverifikasi)
- [x] Otak peran di `brains/` + flag `--learn` (default baca-saja)
- [x] `dispatch.zsh` generik pakai variabel (`--list`, `--plan <file>`, `--broadcast`)
- [x] Worker A/B/C dapat sub-tugas berbeda lewat file plan (`examples/plan.txt`)
- [x] Peran `commander` — Captain dua fase (ORDERS → VERDICT), bukan agen baru
- [x] Skill `@nexa-arena-boss` — otomatisasi relay Boss → Captain → prajurit → Captain

## Catatan
Satu sesi = satu proyek. Proyek ini hanya dikerjakan di sesi ini;
repo sumber NEXA-REPO tidak diubah.
