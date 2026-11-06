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
  -- Since macOS 27.2 an AX click no longer slides the auto-hidden menu bar down;
  -- the pointer on the top edge still does. Two alt-i variants, pick one below.
  local moved = hs.eventtap.event.types.mouseMoved
  local function movePointer(p) hs.eventtap.event.newMouseEvent(moved, p):post() end
  local function topEdge()
    local f = hs.screen.mainScreen():fullFrame()
    return { x = f.x + 200, y = f.y }
  end

  -- Reveal the bar, open the first menu, put the pointer back.
  local function menuPicker()
    local pos = hs.mouse.absolutePosition()
    movePointer(topEdge())
    hs.timer.doAfter(0.3, function()
      hs.task.new("/usr/bin/osascript", function() movePointer(pos) end,
        { cfg.SKHD_SCRIPTS .. "/menu.scpt" }):start()
    end)
  end

  -- Reveal the bar only: park the pointer on the top edge (the bar stays down
  -- while it is there); press again to send the pointer back.
  local peekReturn
  local function menuBarPeek()
    local pos = hs.mouse.absolutePosition()
    local top = topEdge()
    if peekReturn and pos.y <= top.y + 1 then
      movePointer(peekReturn)
      peekReturn = nil
    else
      peekReturn = pos
      movePointer(top)
    end
  end

  -- Switch variant here: menuPicker | menuBarPeek
  kbd.bind(kbd.alt, "i", "Menu picker", menuPicker)

  -- AppleScript: toggle menu autohide
  kbd.bind({ "shift", "alt" }, "i", "Toggle menu autohide", function()
    hs.task.new("/usr/bin/osascript", nil,
      { cfg.SKHD_SCRIPTS .. "/toggle_menu_autohide.scpt" }):start()
  end)
end
