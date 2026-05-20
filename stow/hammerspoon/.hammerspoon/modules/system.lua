-- System hotkey handling and AppleScript bindings.

local cfg = require("config")
local kbd = require("modules.keybind")

-- Disable native cmd-h, cmd-m, cmd+alt-h, cmd+shift-w (block hide/minimize/close).
-- HS pattern: bind to a no-op consumes the chord.
kbd.bind({ "cmd" }, "h", function() end)
kbd.bind({ "cmd" }, "m", function() end)
kbd.bind({ "cmd", "alt" }, "h", function() end)
kbd.bind({ "cmd", "shift" }, "w", function() end)

if cfg.IS_YABAI then
  -- AppleScript: close notifications
  kbd.bind(kbd.alt, "d", function()
    hs.task.new("/usr/bin/osascript", nil,
      { cfg.SKHD_SCRIPTS .. "/notifications.scpt" }):start()
  end)

  -- AppleScript: menu picker
  kbd.bind(kbd.alt, "i", function()
    hs.task.new("/usr/bin/osascript", nil,
      { cfg.SKHD_SCRIPTS .. "/menu.scpt" }):start()
  end)

  -- AppleScript: toggle menu autohide
  kbd.bind({ "shift", "alt" }, "i", function()
    hs.task.new("/usr/bin/osascript", nil,
      { cfg.SKHD_SCRIPTS .. "/toggle_menu_autohide.scpt" }):start()
  end)
end
