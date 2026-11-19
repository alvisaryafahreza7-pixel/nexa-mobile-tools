# Attribution

Pola prompt di `roles/` diadaptasi dari proyek berikut:

- **Repo:** https://github.com/undeadlist/claude-code-agents
- **Penulis:** Paul @ UndeadList
- **Lisensi:** MIT License — Copyright (c) 2025 UndeadList
- **Salinan lokal:** `~/NEXA-REF/claude-code-agents` (clone `--depth 1`, 2026-11-19)

## Pola yang diadaptasi (ditulis ulang, bukan salinan verbatim)

| Pola | Sumber | Dipakai di |
|---|---|---|
| Status block wajib di awal output | `agents/code-auditor.md`, `agents/security-auditor.md` | semua `roles/*.md` |
| Scope NON-OVERLAPPING + "Does NOT check" | `agents/code-auditor.md`, `CLAUDE.md` | `worker-a/b/c.md`, `verifier.md`, `challenger.md` |
| Single source of truth untuk keamanan | `agents/security-auditor.md` | `risk.md` |
| Tabel resolusi konflik & deduplikasi | `agents/fix-planner.md` | `arbiter.md`, `synthesizer.md` |
| Label prioritas P1-P4 | `agents/fix-planner.md` | `risk.md`, `synthesizer.md` |
| Success criteria + handoff | `agents/fullstack-qa-orchestrator.md` | `judge.md`, `scribe.md` |

Ide awal `coordinator-mode` (break work into units → dispatch → merge → resolve
conflicts) berasal dari metadata di:

- `~/NEXA-REPO/AI-AND-SKILLS/skills-library/manifest.json`
- Sumber: https://github.com/irfad7/claude-power-skills (MIT)

Tidak ada file kode, kredensial, APK, atau keystore dari repo eksternal yang
disalin ke repo helper ini. Hanya pola instruksi yang ditulis ulang.
