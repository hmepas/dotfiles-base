#!/bin/bash

# Получаем текущий статус записи от OBS
STATUS=$(obs-cmd recording status)

# Проверяем, активна ли запись
if [[ "$STATUS" == *"Active: false"* ]]; then
    obs-cmd recording start
    notify-send -u critical -t 3000 "OBS" "🔴 ЗАПИСЬ ПОШЛА"
else
    obs-cmd recording stop
    notify-send -u normal -t 3000 "OBS" "⬛ ЗАПИСЬ ОСТАНОВЛЕНА"
fi
