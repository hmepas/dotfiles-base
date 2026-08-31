-- Scratchpad mode. Yabai-only.
--
-- Direct (no mode):
--   hyper - 1..9: toggle scratchpad swN
--
-- Assign mode (hyper - 0 enters):
--   1..9: assign current window to scratchpad swN
--   0:    recover (sub-layer normal)
--   return/escape: exit mode

local kbd = require("modules.keybind")
local yab = require("modules.yabai")
local cs  = require("modules.cheatsheet")

kbd.setGroup("Modes")

-- Direct toggle bindings
kbd.register(kbd.hyper, "1…9", "Toggle scratchpad 1–9 (SA)")
for i = 1, 9 do
  kbd.bind(kbd.hyper, tostring(i), function()
    yab.cmd({ "window", "--toggle", "sw" .. i })
  end)
end

local m = hs.hotkey.modal.new()

local MODE_KEYS = {
  { key = "1…9", desc = "assign window to scratchpad" },
  { key = "0",   desc = "recover (drop assignment)" },
  { key = "⎋ ⏎", desc = "cancel" },
}

local function enterMode()
  yab.setSimpleBarMode("scratchpad", "red")
  cs.showMode("SCRATCHPAD ASSIGN", MODE_KEYS)
  m:enter()
end

local function exitMode()
  m:exit()
  yab.setSimpleBarMode("", "main")
  cs.hideMode()
end

-- hyper - 0: enter assign mode
kbd.bind(kbd.hyper, "0", "Scratchpad assign mode (SA)", enterMode)

-- 1..9 inside mode: assign current window to swN
for i = 1, 9 do
  m:bind({}, tostring(i), function()
    yab.cmd({ "window", "--sub-layer", "above", "--scratchpad", "sw" .. i })
    exitMode()
  end)
end

-- 0 inside mode: recover (drop scratchpad assignment)
m:bind({}, "0", function()
  yab.cmd({ "window", "--sub-layer", "normal", "--scratchpad", "recover" })
  exitMode()
end)

m:bind({}, "return", exitMode)
m:bind({}, "escape", exitMode)
