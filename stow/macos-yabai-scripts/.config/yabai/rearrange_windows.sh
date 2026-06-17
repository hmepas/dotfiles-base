#!/bin/bash

# Приложения прибитые к определенным спейсам
yabai -m rule --apply app="^Cursor$" space=sC label="cursor_placement"

# Outlook Calendar — на sC, остальные окна Outlook — на sM (через title!= — встроенная инверсия yabai)
yabai -m rule --apply app="^Microsoft Outlook$" title="^Calendar$" space=sC label="outlook_calendar_placement"

yabai -m rule --apply app="^Telegram$" space=sG label="telegram_placement"
yabai -m rule --apply app="^WhatsApp$" space=sG label="whatsapp_placement"

# Some minor apps on 10th space, always unmanaged
yabai -m rule --apply app="^Yandex Music$" space=s9 label="yamusic_placement"
yabai -m rule --apply app="^Folx$" space=s9 label="Folx"
yabai -m rule --apply app="^Brain.fm$" space=s9 label="Brainfm"
yabai -m rule --apply app="^Raycast$" space=s9 label="Raycast"
yabai -m rule --apply app="^OBS Studio$" space=s9 label="OBS"

#   Video confs
yabai -m rule --apply app="^Толк$" space=sV label="ktalk_placement"
yabai -m rule --apply app="^zoom.us$" space=sV label="zoom_placement"
yabai -m rule --apply app="^Google Meet$" space=sV label="googlemeet_placement"
yabai -m rule --apply app="^Yandex Telemost$" space=sV label="yandextelemost_placement"

# Приложения у который всегда одно окно, прибитые на хоткей
yabai -m rule --apply app="^Bitwarden$" space=s16 label="bitwarden_placement"
yabai -m rule --apply app="^Obsidian$" space=s16 label="obsidian_placement"
yabai -m rule --apply app="^Microsoft Outlook$" title!="^Calendar$" space=sM label="outlook_remaining_placement"
yabai -m rule --apply app="^Gmail$" space=^sM label="gmail_placement"

