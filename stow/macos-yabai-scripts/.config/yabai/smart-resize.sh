#!/usr/bin/env bash
# Smart resize for yabai: grow/shrink независимо от ориентации сплита.
# usage: smart-resize.sh grow [STEP] | shrink [STEP]
set -euo pipefail

ACTION="${1:-grow}"
STEP="${2:-30}"   # базовый шаг в пикселях
WSEL="${3:-}"

jqbin=$(command -v jq || true)
[ -z "$jqbin" ] && { echo "jq not found. brew install jq"; exit 1; }

# текущее окно
WJSON="$(yabai -m query --windows --window $WSEL 2>/dev/null || echo '{}')"
FLOATING=`echo $WJSON       | jq -r '."is-floating" // "false"'`
SPLIT_TYPE=`echo $WJSON     | jq -r '."split-type" // "horisontal"'`
SPLIT_CHILD=`echo $WJSON    | jq -r '."split-child" // "first_child"'`


if [[ "$FLOATING" == "true" ]]; then
  # для плавающих меняем абсолютные w/h
  FW=$(echo "$WJSON" | jq -r '.frame.w // 0' | sed 's/\.[[:digit:]]\{4\}//g')
  FH=$(echo "$WJSON" | jq -r '.frame.h // 0' | sed 's/\.[[:digit:]]\{4\}//g')
  # растим/ужимаем по обеим осям
  if [ "$ACTION" = "grow" ]; then
    NW=$(( FW + STEP*2 ))
    NH=$(( FH + STEP*2 ))
  else
    # минималки, чтобы не «исчезло» окно
    NW=$(( FW - STEP*2 )); [ $NW -lt 200 ] && NW=200
    NH=$(( FH - STEP*2 )); [ $NH -lt 120 ] && NH=120
  fi
  yabai -m window --resize abs:"$NW":"$NH"
  exit 0
fi


# для тайлинга тянем со всех 4 сторон; если соседей нет — команда просто не сработает
grow() {
    if [ "$SPLIT_TYPE" = "vertical" ]; then
        if [ "$SPLIT_CHILD" = "first_child" ]; then
          yabai -m window $WSEL --resize right:"$STEP":0
        else
          yabai -m window $WSEL  --resize left:-"$STEP":0
        fi
    else # horizontal
        if [ "$SPLIT_CHILD" = "first_child" ]; then
          yabai -m window $WSEL  --resize bottom:0:"$STEP"
        else
          yabai -m window $WSEL  --resize top:0:-"$STEP"
        fi
    fi
}

shrink() {
    if [ "$SPLIT_TYPE" = "vertical" ]; then
        if [ "$SPLIT_CHILD" = "first_child" ]; then
          yabai -m window $WSEL  --resize right:-"$STEP":0
        else
          yabai -m window $WSEL  --resize left:"$STEP":0
        fi
    else # horizontal
        if [ "$SPLIT_CHILD" = "first_child" ]; then
          yabai -m window $WSEL  --resize bottom:0:-"$STEP"
        else
          yabai -m window $WSEL  --resize top:0:"$STEP"
        fi
    fi
}

case "$ACTION" in
  grow)   grow ;;
  shrink) shrink ;;
  *) echo "unknown action: $ACTION"; exit 2 ;;
esac

