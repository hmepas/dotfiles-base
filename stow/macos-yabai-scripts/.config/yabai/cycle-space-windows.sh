#!/usr/bin/env bash
# Cycle focus across all windows in the current space (managed + floating).
# Usage: cycle-space-windows.sh next | prev
set -euo pipefail

[ $# -ge 1 ] || { echo "usage: $0 next|prev"; exit 2; }
dir="$1"

# Окна текущего спейса, отсортированные по id: yabai отдает их в z-order,
# который меняется после каждого фокуса, и цикл скачет. Невидимые окна
# (Telegram "Media viewer" и т.п.) исключаем — фокус на них "в никуда".
mapfile -t WIDS < <(yabai -m query --windows --space | jq -r 'map(select(.app != "Wispr Flow" and ."is-visible")) | sort_by(.id) | .[].id')
N=${#WIDS[@]}
[ "$N" -gt 0 ] || exit 0

# Текущее окно (может быть пусто, если фокус на Desktop/Bar и т.п.)
CURID="$(yabai -m query --windows --window 2>/dev/null | jq -r '.id // empty')"

# Найти индекс текущего окна в массиве (если нет — idx=-1)
idx=-1
for i in "${!WIDS[@]}"; do
  if [[ "${WIDS[$i]}" == "$CURID" ]]; then idx=$i; break; fi
done

# Вычислить целевой индекс с wrap-around
case "$dir" in
  next)
    if (( idx < 0 )); then tgt=0; else tgt=$(( (idx + 1) % N )); fi
    ;;
  prev)
    if (( idx < 0 )); then tgt=$(( N - 1 )); else tgt=$(( (idx - 1 + N) % N )); fi
    ;;
  *)
    echo "unknown direction: $dir"; exit 2 ;;
esac

# Фокус на целевое окно
yabai -m window --focus "${WIDS[$tgt]}"

