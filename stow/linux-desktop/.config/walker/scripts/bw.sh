#!/bin/bash
# ~/.config/walker/scripts/bw.sh

QUERY=$1

# rbw list отдает список имен.
# jq фильтрует по запросу и собирает массив объектов {label, exec}
rbw list | jq -R -s -c '
  split("\n")[:-1] | 
  map(select(. | test("'"$QUERY"'"; "i"))) | 
  map({
    label: ., 
    exec: ("rbw get \"" + . + "\" | wl-copy")
  })
'
