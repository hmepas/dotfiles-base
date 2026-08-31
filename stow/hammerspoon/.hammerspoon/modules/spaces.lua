-- Space focus and window-to-space movement.
--
-- yabai mac: named spaces (s1..s9, sC, sV, sB, sM, sT, sG, sP).
-- non-yabai mac: native macOS spaces only (cmd+ctrl+arrow). Window
-- move uses hs.spaces (private API, brittle but usable).
--
-- SA-only bindings (skipped on yabai + SIP-enabled host):
--   alt+shift-tab   space --move next (move whole space to next display)

local cfg  = require("config")
local kbd  = require("modules.keybind")
local yab  = require("modules.yabai")

local alt       = kbd.alt
local alt_shift = kbd.alt_shift

kbd.setGroup("Spaces")

if cfg.IS_YABAI then
  -- ============================================================
  -- yabai mode
  -- ============================================================

  -- alt - 1..9: focus space sN
  kbd.register(alt, "1…9", "Focus space 1–9")
  for i = 1, 9 do
    kbd.bind(alt, tostring(i), function()
      yab.cmd({ "space", "--focus", "s" .. i })
    end)
  end

  -- alt - <letter>: focus named space
  kbd.register(alt, "c v b m t", "Focus named space")
  local namedFocus = { c = "sC", v = "sV", b = "sB", m = "sM", t = "sT" }
  for k, label in pairs(namedFocus) do
    kbd.bind(alt, k, function()
      yab.cmd({ "space", "--focus", label })
    end)
  end

  -- alt - tab: focus recent space
  kbd.bind(alt, "tab", "Focus recent space", function()
    yab.cmd({ "space", "--focus", "recent" })
  end)

  -- alt - backtick (` / §±): focus recent display
  kbd.bind(alt, "`", "Focus recent display", function()
    yab.cmd({ "display", "--focus", "recent" })
  end)

  -- alt + shift - tab: move space to next display (SA-only)
  if cfg.SIP_DISABLED then
    kbd.bind(alt_shift, "tab", "Move space to next display (SA)", function()
      yab.cmd({ "space", "--move", "next" })
    end)
  end

  -- alt + shift - 1..9: move window to space sN
  kbd.register(alt_shift, "1…9", "Move window to space 1–9")
  for i = 1, 9 do
    kbd.bind(alt_shift, tostring(i), function()
      yab.cmd({ "window", "--space", "s" .. i })
    end)
  end

  -- alt + shift - <letter>: move window to named space.
  -- 'p' intentionally omitted — collides with alt+shift-p (cycle prev)
  -- in windows.lua; sP rarely used vs cycle.
  kbd.register(alt_shift, "c v g t b m", "Move window to named space")
  local namedMove = {
    c = "sC", v = "sV", g = "sG",
    t = "sT", b = "sB", m = "sM",
  }
  for k, label in pairs(namedMove) do
    kbd.bind(alt_shift, k, function()
      yab.cmd({ "window", "--space", label })
    end)
  end
end
