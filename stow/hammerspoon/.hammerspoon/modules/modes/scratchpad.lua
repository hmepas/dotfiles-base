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

-- Direct toggle bindings
for i = 1, 9 do
  kbd.bind(kbd.hyper, tostring(i), function()
    yab.cmd({ "window", "--toggle", "sw" .. i })
  end)
end

local m = hs.hotkey.modal.new()
local alertId

local function enterMode()
  yab.setSimpleBarMode("scratchpad", "red")
  alertId = hs.alert.show("SCRATCHPAD ASSIGN", true)
  m:enter()
end

local function exitMode()
  m:exit()
  yab.setSimpleBarMode("", "main")
  if alertId then hs.alert.closeSpecific(alertId) end
end

-- hyper - 0: enter assign mode
kbd.bind(kbd.hyper, "0", enterMode)

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
