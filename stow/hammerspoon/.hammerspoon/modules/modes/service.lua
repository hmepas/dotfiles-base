-- Service mode. Yabai-only.
-- hyper - ; (0x29) enters mode and disables ALL Hammerspoon hotkeys
-- managed via keybind.lua. Only the modal's return/escape work.
-- Use to type into apps that conflict with bound chords.

local kbd = require("modules.keybind")
local yab = require("modules.yabai")

local m = hs.hotkey.modal.new()
local alertId

local function enterMode()
  kbd.disableAll()
  yab.setSimpleBarMode("service_mode", "red")
  alertId = hs.alert.show("SERVICE MODE — keys disabled", true)
  m:enter()
end

local function exitMode()
  m:exit()
  kbd.enableAll()
  yab.setSimpleBarMode("", "main")
  if alertId then hs.alert.closeSpecific(alertId) end
end

-- hyper - `;`: enter.
-- NOTE: this binding lives outside kbd.list so disableAll cannot kill
-- our way back — we use raw hs.hotkey.bind here.
hs.hotkey.bind(kbd.hyper, ";", enterMode)

m:bind({}, "return", exitMode)
m:bind({}, "escape", exitMode)
