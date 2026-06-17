# needed to be recreated after messed with spaces since
# rules stored index of spaces not their labels
# so they will be lost on rearrangement when display configuraiton changes

# Coding context (for IDE, terminals excluded)
yabai -m rule --add app="^Cursor$" space=^sC label="cursor_placement"

# Outlook Calendar — на sC, остальные окна Outlook — на sM (через title!= — встроенная инверсия yabai)
yabai -m rule --add app="^Microsoft Outlook$" title="^Calendar$" space=^sC label="outlook_calendar_placement"

# Messengers teleGram
yabai -m rule --add app="^Telegram$" space=^sG label="telegram_placement"
yabai -m rule --add app="WhatsApp$" space=^sG label="whatsapp_placement"

# Some minor apps on 9th space, always unmanaged
yabai -m rule --add app="^Yandex Music$" space=^s9 label="yamusic_placement"
yabai -m rule --add app="^Yandex Music$" space=^s9 label="yamusic_placement"
yabai -m rule --add app="^Folx$" space=^s9 label="folx_placement"
yabai -m rule --add app="^Brain.fm$" space=^s9 label="brainfm_placement"
yabai -m rule --add app="^Raycast$" space=^s9 label="raycast_placement"
yabai -m rule --add app="^OBS Studio$" space=^s9 label="obs_placement"

# Mail context
yabai -m rule --add app="^Microsoft Outlook$" title!="^Calendar$" space=^sM label="outlook_remaining_placement"
yabai -m rule --add app="^Gmail$" space=^sM label="gmail_placement"

# Video confs
yabai -m rule --add app="^Толк$" space=^sV label="ktalk_placement"
yabai -m rule --add app="^zoom.us$" space=^sV label="zoom_placement"
yabai -m rule --add app="^Google Meet$" space=^sV label="googlemeet_placement"
yabai -m rule --add app="^Yandex Telemost$" space=^sV label="yandextelemost_placement"

# Single window apps binded on a personal shortcut
yabai -m rule --add app="^Bitwarden$" space=^s16 label="bitwarden_placement"
yabai -m rule --add app="^Obsidian$" space=^s16 label="obsidian_placement"

