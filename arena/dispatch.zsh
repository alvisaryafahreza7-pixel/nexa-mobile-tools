#!/data/data/com.termux/files/usr/bin/sh
# NEXA-AGENT-ARENA - dispatcher generik.
# Satu perintah untuk peran mana pun; semua path & peran diambil dari variabel.
#
# Pakai:
#   ./dispatch.zsh <role> <tugas>       # prompt untuk satu peran
#   ./dispatch.zsh --list               # daftar peran yang punya otak
#   ./dispatch.zsh --plan <file>        # TIAP peran punya tugas sendiri (dipakai untuk A/B/C)
#   ./dispatch.zsh --broadcast <tugas>  # semua peran dapat tugas sama (jarang; A/B/C tetap beda sudut)
#
# Format file plan: satu baris `role: tugas`, baris `#` diabaikan.
# stderr = metadata AGENT=/BRAIN=/ROLE=; stdout = prompt siap ditempel ke subagent.
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
BRAINS="$ROOT/brains"
HISTORY="$ROOT/history"
ROLES="planner worker-a worker-b worker-c verifier challenger risk arbiter synthesizer judge scribe"
# Meta-role: bukan bagian dari 11 peran battle, dipanggil sekali untuk input→output.
META_ROLES="commander"

agent_for() {
  case "$1" in
    worker-a|worker-b|worker-c) echo explore ;;
    *) echo general ;;
  esac
}

valid_role() {
  case " $ROLES $META_ROLES " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

build_prompt() {
  role="$1"; shift
  task="$*"
  brain="$BRAINS/$role.md"
  [ -f "$brain" ] || { echo "otak tidak ada: $brain" >&2; return 1; }
  agent="$(agent_for "$role")"
  printf 'AGENT=%s BRAIN=%s ROLE=%s\n' "$agent" "$brain" "$role" >&2
  cat <<EOF
Kamu $role.

Baca file ini SAJA sebagai instruksi lengkapmu:
$brain

Ikuti bagian \`## SOP eksekusi\` di dalamnya. Jangan cari/generate prompt lain,
jangan baca \`roles/\` atau \`history/\`.

Tugas: $task

Kembalikan HANYA output sesuai SOP (status block + batas baris peranmu).
Default baca-saja; jangan sentuh SD card; jangan baca token/kredensial.
Pengecualian tulis hanya untuk Scribe -> folder history/ di $HISTORY.
EOF
}

dispatch_plan() {
  plan="$1"
  [ -f "$plan" ] || { echo "plan tidak ada: $plan" >&2; return 1; }
  n=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    role="$(printf '%s\n' "$line" | sed 's/:.*//')"
    task="$(printf '%s\n' "$line" | sed 's/^[^:]*:[[:space:]]*//')"
    valid_role "$role" || { echo "peran tidak dikenal: $role" >&2; return 1; }
    [ -n "$task" ] || { echo "tugas kosong untuk: $role" >&2; return 1; }
    printf '===== %s =====\n' "$role"
    build_prompt "$role" "$task" || return 1
    printf '\n'
    n=$((n + 1))
  done < "$plan"
  [ "$n" -gt 0 ] || { echo "plan kosong: $plan" >&2; return 1; }
  echo "PLAN: $n peran, masing-masing tugas berbeda" >&2
}

case "${1:-}" in
  --list)
    printf '%s\n' $ROLES
    printf 'commander (meta: input->output)\n'
    exit 0
    ;;
  --plan)
    [ "$#" -eq 2 ] || { echo "usage: dispatch.zsh --plan <file>" >&2; exit 1; }
    dispatch_plan "$2" || exit 1
    exit 0
    ;;
  --all|--broadcast)
    shift
    [ "$#" -gt 0 ] || { echo "usage: dispatch.zsh --broadcast <tugas>" >&2; exit 1; }
    echo "PERINGATAN: broadcast = semua peran dapat tugas SAMA. Worker A/B/C sebaiknya pakai --plan." >&2
    for r in $ROLES; do
      printf '===== %s =====\n' "$r"
      build_prompt "$r" "$@" || exit 1
      printf '\n'
    done
    exit 0
    ;;
esac

[ "$#" -ge 2 ] || { echo "usage: dispatch.zsh <role> <tugas> | --list | --plan <file> | --broadcast <tugas>" >&2; exit 1; }
build_prompt "$@"
