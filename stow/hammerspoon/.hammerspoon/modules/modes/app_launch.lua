-- App-launch mode. Both hosts.
-- alt-a → mode → letter → app launches → mode exits.

local cfg = require("config")
local kbd = require("modules.keybind")
local yab = require("modules.yabai")
local cs  = require("modules.cheatsheet")

local m = hs.hotkey.modal.new()
local modeKeys = {}

local function enterMode()
  yab.setSimpleBarMode("app_launch", "red")
  cs.showMode("APP LAUNCH", modeKeys)
  m:enter()
end

local function exitMode()
  m:exit()
  yab.setSimpleBarMode("", "main")
  cs.hideMode()
end

-- alt - a: enter mode
kbd.setGroup("Modes")
kbd.bind(kbd.alt, "a", "App launch mode", enterMode)

local function entry(key, desc, fn)
  table.insert(modeKeys, { key = key, desc = desc })
  m:bind({}, key, function()
    fn()
    exitMode()
  end)
end

entry("w", "WhatsApp", function() hs.application.launchOrFocus("WhatsApp") end)
entry("r", "OBS", function() hs.application.launchOrFocus("OBS") end)
entry("c", "Calendar", function() hs.application.launchOrFocus("Calendar") end)
entry("s", "Safari (new window)", function()
  hs.osascript.applescript('tell application "Safari" to make new document')
end)

-- Yandex Music — name has Cyrillic, easier via shell.
entry("m", "Yandex Music", function()
  hs.task.new("/usr/bin/open", nil,
    { "-a", "/Applications/Яндекс Музыка.app/Contents/MacOS/Яндекс Музыка" }):start()
end)

-- Terminal: yabai mac uses helper for placement; non-yabai opens iTerm directly.
if cfg.IS_YABAI then
  entry("t", "iTerm (new window)", function() yab.helper("new-iterm-window.sh") end)
else
  entry("t", "iTerm", function() hs.application.launchOrFocus("iTerm") end)
end

table.insert(modeKeys, { key = "⎋ ⏎", desc = "cancel" })
m:bind({}, "return", exitMode)
m:bind({}, "escape", exitMode)
