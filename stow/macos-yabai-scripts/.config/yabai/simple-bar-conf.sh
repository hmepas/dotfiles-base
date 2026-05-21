# Simple-bar-server signals
yabai -m signal --add event=window_focused action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-bar spaces & windows when focused application changes"
yabai -m signal --add event=window_resized action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-bar spaces & windows when a window is resized"
yabai -m signal --add event=window_destroyed action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-ba spaces & windows when an application window is closed"
yabai -m signal --add event=space_changed action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-bar spaces & windows on space change"
yabai -m signal --add event=display_changed action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-bar spaces & windows on display focus change"
yabai -m signal --add event=window_title_changed action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-bar spaces & windows when current window title changes"
yabai -m signal --add event=space_destroyed action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-bar spaces & windows on space removal"
yabai -m signal --add event=space_created action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-bar spaces & windows on space creation"
yabai -m signal --add event=application_activated action="curl http://localhost:7776/yabai/spaces/refresh && curl http://localhost:7776/yabai/windows/refresh" label="Refresh simple-bar spaces & windows when application is activated"
yabai -m signal --add event=display_added action="curl http://localhost:7776/yabai/displays/refresh" label="Refresh simple-bar displays when a new dispay is added"
yabai -m signal --add event=display_removed action="curl http://localhost:7776/yabai/displays/refresh" label="Refresh simple-bar displays when a dispay is removed"
yabai -m signal --add event=display_moved action="curl http://localhost:7776/yabai/displays/refresh" label="Refresh simple-bar displays when a dispay is moved"

osascript -e 'tell application id "tracesOf.Uebersicht" to refresh'
# // end Simple-bar-server

