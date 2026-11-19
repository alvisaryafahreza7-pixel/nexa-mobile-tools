#!/data/data/com.termux/files/usr/bin/sh
# NEXA-AGENT-ARENA - dispatcher generik.
# Satu perintah untuk peran mana pun; semua path & peran diambil dari variabel.
#
# Pakai:
#   ./dispatch.zsh <role> <tugas>      # prompt untuk satu peran (stdout)
#   ./dispatch.zsh --list              # daftar peran yang punya otak
#   ./dispatch.zsh --all <tugas>       # prompt untuk semua peran
#
# stderr berisi metadata AGENT=/BRAIN=/ROLE= supaya pemanggil tahu agen mana
# yang dipakai. stdout = prompt siap ditempel ke subagent.
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
BRAINS="$ROOT/brains"
HISTORY="$ROOT/history"
ROLES="planner worker-a worker-b worker-c verifier challenger risk arbiter synthesizer judge scribe"

agent_for() {
  case "$1" in
    worker-a|worker-b|worker-c) echo explore ;;
    *) echo general ;;
  esac
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

case "${1:-}" in
  --list)
    printf '%s\n' $ROLES | tr ' ' '\n'
    exit 0
    ;;
  --all)
    shift
    [ "$#" -gt 0 ] || { echo "usage: dispatch.zsh --all <tugas>" >&2; exit 1; }
    for r in $ROLES; do
      printf '===== %s =====\n' "$r"
      build_prompt "$r" "$@" || exit 1
      printf '\n'
    done
    exit 0
    ;;
esac

[ "$#" -ge 2 ] || { echo "usage: dispatch.zsh <role> <tugas> | --list | --all <tugas>" >&2; exit 1; }
build_prompt "$@"
