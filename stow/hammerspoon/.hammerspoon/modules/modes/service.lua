-- Service mode. Yabai-only.
-- hyper - ; (0x29) enters mode and disables ALL Hammerspoon hotkeys
-- managed via keybind.lua. Only the modal's return/escape work.
-- Use to type into apps that conflict with bound chords.

local kbd = require("modules.keybind")
local yab = require("modules.yabai")
local cs  = require("modules.cheatsheet")

local m = hs.hotkey.modal.new()

local MODE_KEYS = {
  { key = "⎋ ⏎", desc = "exit, re-enable keys" },
}

local function enterMode()
  kbd.disableAll()
  yab.setSimpleBarMode("service_mode", "red")
  cs.showMode("SERVICE MODE — keys disabled", MODE_KEYS, cs.accentRed)
  m:enter()
end

local function exitMode()
  m:exit()
  kbd.enableAll()
  yab.setSimpleBarMode("", "main")
  cs.hideMode()
end

-- hyper - `;`: enter.
-- NOTE: this binding lives outside kbd.list so disableAll cannot kill
-- our way back — we use raw hs.hotkey.bind here.
kbd.setGroup("Modes")
kbd.register(kbd.hyper, ";", "Service mode (all keys off)")
hs.hotkey.bind(kbd.hyper, ";", enterMode)

m:bind({}, "return", exitMode)
m:bind({}, "escape", exitMode)
