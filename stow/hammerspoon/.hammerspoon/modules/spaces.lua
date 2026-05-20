-- Space focus and window-to-space movement.
--
-- yabai mac: named spaces (s1..s9, sC, sV, sB, sM, sT, sG, sP).
-- non-yabai mac: native macOS spaces only (cmd+ctrl+arrow). Window
-- move uses hs.spaces (private API, brittle but usable).

local cfg  = require("config")
local kbd  = require("modules.keybind")
local yab  = require("modules.yabai")

local alt       = kbd.alt
local alt_shift = kbd.alt_shift

if cfg.IS_YABAI then
  -- ============================================================
  -- yabai mode
  -- ============================================================

  -- alt - 1..9: focus space sN
  for i = 1, 9 do
    kbd.bind(alt, tostring(i), function()
      yab.cmd({ "space", "--focus", "s" .. i })
    end)
  end

  -- alt - <letter>: focus named space
  local namedFocus = { c = "sC", v = "sV", b = "sB", m = "sM", t = "sT" }
  for k, label in pairs(namedFocus) do
    kbd.bind(alt, k, function()
      yab.cmd({ "space", "--focus", label })
    end)
  end

  -- alt - tab: focus recent space
  kbd.bind(alt, "tab", function()
    yab.cmd({ "space", "--focus", "recent" })
  end)

  -- alt - backtick (` / §±): focus recent display
  kbd.bind(alt, "`", function()
    yab.cmd({ "display", "--focus", "recent" })
  end)

  -- alt + shift - tab: move space to next display
  kbd.bind(alt_shift, "tab", function()
    yab.cmd({ "space", "--move", "next" })
  end)

  -- alt + shift - 1..9: move window to space sN
  for i = 1, 9 do
    kbd.bind(alt_shift, tostring(i), function()
      yab.cmd({ "window", "--space", "s" .. i })
    end)
  end

  -- alt + shift - <letter>: move window to named space.
  -- 'p' intentionally omitted — collides with alt+shift-p (cycle prev)
  -- in windows.lua; sP rarely used vs cycle.
  local namedMove = {
    c = "sC", v = "sV", g = "sG",
    t = "sT", b = "sB", m = "sM",
  }
  for k, label in pairs(namedMove) do
    kbd.bind(alt_shift, k, function()
      yab.cmd({ "window", "--space", label })
    end)
  end

else
  -- ============================================================
  -- non-yabai mode
  -- ============================================================
  -- Space focus: native cmd+ctrl+arrow (untouched).
  -- Space move: hs.spaces by Mission Control index.

  for i = 1, 9 do
    kbd.bind(alt_shift, tostring(i), function()
      local fw = hs.window.focusedWindow()
      if not fw then return end
      local screen = fw:screen()
      local spaces = hs.spaces.spacesForScreen(screen:getUUID())
      if not spaces or not spaces[i] then
        hs.alert.show("No space " .. i)
        return
      end
      hs.spaces.moveWindowToSpace(fw:id(), spaces[i])
    end)
  end
end
