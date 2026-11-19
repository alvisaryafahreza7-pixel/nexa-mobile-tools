#!/data/data/com.termux/files/usr/bin/sh
# NEXA-AGENT-ARENA - orkestrator otomatis
# Menjalankan tiap peran sebagai sesi OpenCode terpisah, melempar hasil ke tahap berikutnya.
# Pakai: orchestrate.zsh [--mode cepat|ringan|sedang|penuh] [--fast] [--learn] [--model provider/model] [--dry-run] <tugas>
# --fast: Planner∥Worker, lewati Synthesizer & Scribe (FINAL.md tetap dari Judge)
# --learn: tiap peran boleh menulis 1 pelajaran ke brains/<role>.md (default: baca-saja)
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
MODE="penuh"
MODEL=""
DRY=""
FAST=""
LEARN=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --dry-run) DRY="1"; shift ;;
    --fast) FAST="1"; shift ;;
    --learn) LEARN="1"; shift ;;
    *) break ;;
  esac
done
[ "$#" -gt 0 ] || { echo "usage: orchestrate.zsh [--mode cepat|ringan|sedang|penuh] [--fast] [--learn] [--model provider/model] [--dry-run] <tugas>"; exit 1; }
TASK="$*"

case "$MODE" in
  cepat)  ROLES="worker-a judge" ;;
  ringan) ROLES="planner worker-a worker-b judge" ;;
  sedang) ROLES="planner worker-a worker-b verifier risk arbiter synthesizer judge" ;;
  penuh)  ROLES="planner worker-a worker-b worker-c verifier challenger risk arbiter synthesizer judge scribe" ;;
  *) echo "mode tidak dikenal: $MODE"; exit 1 ;;
esac

agent_for() {
  case "$1" in
    worker-a) echo explore ;;
    *) echo general ;;
  esac
}

have_role() {
  case " $ROLES " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

D="$("$ROOT/arena.zsh" new --mode "$MODE" "$TASK" 2>/dev/null)" || exit 1
ID="$(basename "$D")"
echo "BATTLE: $D ($MODE)" >&2

# Tulis 1 pelajaran ke brains/<role>.md. Orkestrator yang menulis, bukan agen.
learn_to_brain() {
  role="$1"; lesson="$2"
  BRAIN="$ROOT/brains/$role.md"
  [ -f "$BRAIN" ] || return 0
  # Tolak baris yang tampak seperti kredensial/secret.
  case "$lesson" in
    *ghp_*|*gho_*|*github_pat_*|*'BEGIN '*'PRIVATE KEY'*|*'token='*|*'password='*) 
      echo "LEARN ditolak ($role): mengandung pola sensitif" >&2; return 0 ;;
  esac
  [ -n "$DRY" ] && { echo "DRY LEARN: $BRAIN <- $lesson"; return 0; }
  if grep -q '^- (belum ada)$' "$BRAIN"; then
    sed '/^- (belum ada)$/d' "$BRAIN" > "$BRAIN.tmp" && mv "$BRAIN.tmp" "$BRAIN"
  fi
  printf -- '- %s\n' "$lesson" >> "$BRAIN"
  echo "LEARN $role -> brains/$role.md" >&2
}

run_role() {
  role="$1"
  ctx="$2"
  sess="$(printf 'ses_arena_%s_%s' "$ID" "$role" | tr -cd 'A-Za-z0-9_-')"
  set -- --archived --format json --session "$sess" --agent "$(agent_for "$role")"
  [ -n "$MODEL" ] && set -- "$@" --model "$MODEL"
  [ -s "$ctx" ] && set -- "$@" --file "$ctx"
  if [ -n "$DRY" ]; then
    printf 'DRY: opencode run %s "<%s>"\n' "$*" "$role"
    [ -n "$LEARN" ] && printf 'LEARN-DRY: %s boleh kirim 1 baris PELAJARAN: -> brains/%s.md\n' "$role" "$role"
    return 0
  fi

  PROMPT="$D/$role.prompt.md"
  [ -f "$PROMPT" ] || cp "$D/$role.md" "$PROMPT"
  if [ -n "$LEARN" ] && [ -f "$ROOT/brains/$role.md" ]; then
    {
      cat "$PROMPT"
      printf '\n## Mode belajar (--learn)\nDi akhir jawaban, tambahkan MAKSIMAL 1 baris diawali `PELAJARAN: ` berisi pelajaran ringkas yang bisa dipakai ulang di battle berikutnya. Jangan tulis data sensitif. Ini satu-satunya pengecualian aturan baca-saja; jangan mengubah file apa pun.\n'
    } > "$D/$role.run.md"
    PROMPT="$D/$role.run.md"
  fi

  opencode run "$@" "$(cat "$PROMPT")" > "$D/$role.jsonl" 2>"$D/$role.err" || true
  if grep -q '"type":"error"' "$D/$role.jsonl" 2>/dev/null; then
    echo "GAGAL $role: $(jq -r 'select(.type=="error") | .error.message' "$D/$role.jsonl" | head -1)" >&2
    return 1
  fi
  jq -r 'select(.type=="text") | (.part.text // .text // empty)' "$D/$role.jsonl" > "$D/$role.md"
  if grep -q '^status: ERROR' "$D/$role.md" 2>/dev/null; then
    echo "GAGAL $role: agen melaporkan status ERROR" >&2
    return 1
  fi
  if ! grep -q '^status:' "$D/$role.md" 2>/dev/null; then
    echo "PERINGATAN $role: tidak ada status block" >&2
  fi
  if [ -n "$LEARN" ]; then
    lesson="$(grep -m1 '^PELAJARAN:' "$D/$role.md" 2>/dev/null | sed 's/^PELAJARAN:[[:space:]]*//')"
    [ -n "$lesson" ] && learn_to_brain "$role" "$lesson"
  fi
  echo "SELESAI $role ($(wc -c < "$D/$role.md") byte)" >&2
}

fail=0

# Tahap 1+2: Planner dan Worker
C0="$D/.ctx-0"; : > "$C0"
C1="$D/.ctx-1"; : > "$C1"

if have_role planner; then
  if [ -n "$FAST" ] && have_role worker-a; then
    echo "FAST: Planner + Worker jalan paralel" >&2
    run_role planner "$C0" &
    for r in worker-a worker-b worker-c; do
      if have_role "$r"; then run_role "$r" "$C0" & fi
    done
    wait
    [ -s "$D/planner.md" ] || { echo "planner kosong" >&2; fail=1; }
    cat "$D/planner.md" >> "$C1" 2>/dev/null || true
  else
    run_role planner "$C0" || fail=1
    [ "$fail" -eq 0 ] && [ -s "$D/planner.md" ] && cat "$D/planner.md" >> "$C1"
  fi
fi

if [ "$fail" -eq 0 ] && [ -z "$FAST" ]; then
  for r in worker-a worker-b worker-c; do
    if have_role "$r"; then run_role "$r" "$C1" || fail=1 & fi
  done
  wait
fi

for r in worker-a worker-b worker-c; do
  if have_role "$r"; then
    [ -s "$D/$r.md" ] || { echo "worker kosong: $r" >&2; fail=1; }
    [ -s "$D/$r.md" ] && cat "$D/$r.md" >> "$C1"
  fi
done

# Tahap 3: Verifier / Challenger / Risk paralel
C2="$D/.ctx-2"; : > "$C2"
cat "$C1" >> "$C2"
if [ "$fail" -eq 0 ]; then
  for r in verifier challenger risk; do
    if have_role "$r"; then run_role "$r" "$C2" || fail=1 & fi
  done
  wait
  for r in verifier challenger risk; do
    if have_role "$r"; then
      [ -s "$D/$r.md" ] || { echo "peran kosong: $r" >&2; fail=1; }
      [ -s "$D/$r.md" ] && cat "$D/$r.md" >> "$C2"
    fi
  done
fi

# Tahap 4: Arbiter - resolusi konflik (coordinator-mode)
if [ "$fail" -eq 0 ] && have_role arbiter; then
  run_role arbiter "$C2" || fail=1
  [ -s "$D/arbiter.md" ] && cat "$D/arbiter.md" >> "$C2"
fi

# Tahap 5: Synthesizer (dilewati saat --fast; output Arbiter langsung jadi draf Judge)
if [ "$fail" -eq 0 ] && have_role synthesizer && [ -z "$FAST" ]; then
  run_role synthesizer "$C2" || fail=1
fi

# Tahap 6: Judge
C3="$D/.ctx-3"; : > "$C3"
cat "$C2" >> "$C3"
[ -s "$D/synthesizer.md" ] && cat "$D/synthesizer.md" >> "$C3"
if [ "$fail" -eq 0 ]; then
  run_role judge "$C3" || fail=1
  [ -f "$D/judge.md" ] && cp "$D/judge.md" "$D/FINAL.md"
fi

# Tahap 7: Scribe (--fast: ringkasan dibuat otomatis, tanpa agen tambahan)
if [ "$fail" -eq 0 ] && have_role scribe && [ -z "$FAST" ]; then
  run_role scribe "$C3" || fail=1
elif [ "$fail" -eq 0 ] && [ -n "$FAST" ] && [ -z "$DRY" ]; then
  {
    echo "# Ringkasan otomatis (--fast)"
    echo
    echo "Keputusan akhir ada di FINAL.md (dari Judge)."
    echo
    for r in $ROLES; do
      if [ -f "$D/$r.md" ]; then
        printf '## %s\n' "$r"
        grep -E '^(agent|status|findings):' "$D/$r.md" | head -4
        echo
      fi
    done
  } > "$D/SUMMARY.md"
fi

if [ "$fail" -ne 0 ]; then
  echo "BATTLE GAGAL. Cek $D/*.err dan *.jsonl" >&2
  exit 1
fi
echo "SELESAI: $D/FINAL.md"
