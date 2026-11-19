#!/data/data/com.termux/files/usr/bin/sh
# NEXA-AGENT-ARENA - menyiapkan folder battle + prompt peran
# Mode: ringan (4 peran) / sedang (7) / penuh (10). Default: penuh.
# Belum menjalankan agen otomatis; agen utama yang memakai prompt hasil generate.
set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
BATTLES="$ROOT/history"
ROLES="$ROOT/roles"

case "${1:-}" in
  new)
    shift
    MODE="penuh"
    if [ "${1:-}" = "--mode" ]; then
      MODE="${2:-}"
      shift 2
    fi
    case "$MODE" in
      ringan) DAFTAR="planner worker-a worker-b judge" ;;
      sedang) DAFTAR="planner worker-a worker-b verifier risk arbiter synthesizer judge" ;;
      penuh)  DAFTAR="planner worker-a worker-b worker-c verifier challenger risk arbiter synthesizer judge scribe" ;;
      *) echo "mode tidak dikenal: $MODE (pilih ringan|sedang|penuh)"; exit 1 ;;
    esac
    [ "$#" -gt 0 ] || { echo "usage: arena.zsh new [--mode ringan|sedang|penuh] <tugas>"; exit 1; }
    TASK="$*"
    ID="$(date +%Y%m%d-%H%M%S)-$$"
    D="$BATTLES/$ID"
    mkdir -p "$D"
    printf '%s\n' "$TASK" > "$D/task.txt"
    for role in $DAFTAR; do
      [ -f "$ROLES/$role.md" ] || { echo "role hilang: $role"; exit 1; }
      sed "s|{{TASK}}|$TASK|g" "$ROLES/$role.md" > "$D/$role.md"
    done
    echo "mode: $MODE ($(echo $DAFTAR | wc -w) peran)" >&2
    echo "$D"
    ;;
  list)
    ls -1 "$BATTLES" 2>/dev/null || true
    ;;
  *)
    echo "usage: arena.zsh new [--mode ringan|sedang|penuh] <tugas> | arena.zsh list"
    exit 1
    ;;
esac
