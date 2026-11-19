#!/data/data/com.termux/files/usr/bin/sh
# NEXA-AGENT-ARENA - jembatan Boss -> Captain -> prajurit.
# Ekstrak blok `ORDERS:` dari output Captain jadi file plan `role: tugas`,
# lalu Boss tinggal: ./dispatch.zsh --plan <plan.txt>
#
# Pakai: ./orders.zsh <output-captain.txt> <plan.txt>
set -u

[ "$#" -eq 2 ] || { echo "usage: orders.zsh <output-captain.txt> <plan.txt>" >&2; exit 1; }
IN="$1"; OUT="$2"
[ -f "$IN" ] || { echo "file tidak ada: $IN" >&2; exit 1; }

awk '
  /^ORDERS:[[:space:]]*$/ { on=1; next }
  on && /^[a-z][a-z0-9-]*:[[:space:]]/ { print; next }
  on && /^[^[:space:]]/ { exit }
' "$IN" > "$OUT"

if [ ! -s "$OUT" ]; then
  echo "tidak ada blok ORDERS: di $IN" >&2
  rm -f "$OUT"
  exit 1
fi
echo "ORDERS: $(wc -l < "$OUT" | tr -d ' ') perintah -> $OUT" >&2
