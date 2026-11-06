-- System hotkey handling and AppleScript bindings.

local cfg = require("config")
local kbd = require("modules.keybind")

kbd.setGroup("System")

-- Disable native cmd-h, cmd-m, cmd+alt-h, cmd+shift-w (block hide/minimize/close).
-- HS pattern: bind to a no-op consumes the chord.
kbd.register({}, "⌘h/m/⌥h/⇧w", "Blocked (hide / minimize / close)")
kbd.bind({ "cmd" }, "h", function() end)
kbd.bind({ "cmd" }, "m", function() end)
kbd.bind({ "cmd", "alt" }, "h", function() end)
kbd.bind({ "cmd", "shift" }, "w", function() end)

if cfg.IS_YABAI then
  -- AppleScript: close notifications
  kbd.bind(kbd.alt, "d", "Close notifications", function()
    hs.task.new("/usr/bin/osascript", nil,
      { cfg.SKHD_SCRIPTS .. "/notifications.scpt" }):start()
  end)

  -- AppleScript: menu picker
  -- Peek at the auto-hidden menu bar: park the pointer on the top edge (the bar
  -- stays down while it is there); press again to send the pointer back.
  local peekReturn
  kbd.bind(kbd.alt, "i", "Peek menu bar", function()
    local moved = hs.eventtap.event.types.mouseMoved
    local pos = hs.mouse.absolutePosition()
    local f = hs.screen.mainScreen():fullFrame()
    if peekReturn and pos.y <= f.y + 1 then
      hs.eventtap.event.newMouseEvent(moved, peekReturn):post()
      peekReturn = nil
    else
      peekReturn = pos
      hs.eventtap.event.newMouseEvent(moved, { x = f.x + 200, y = f.y }):post()
    end
  end)

  -- AppleScript: toggle menu autohide
  kbd.bind({ "shift", "alt" }, "i", "Toggle menu autohide", function()
    hs.task.new("/usr/bin/osascript", nil,
      { cfg.SKHD_SCRIPTS .. "/toggle_menu_autohide.scpt" }):start()
  end)
end
