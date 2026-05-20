-- App-launch mode. Both hosts.
-- alt-a → mode → letter → app launches → mode exits.

local cfg = require("config")
local kbd = require("modules.keybind")
local yab = require("modules.yabai")

local m = hs.hotkey.modal.new()
local alertId

local function enterMode()
  yab.setSimpleBarMode("app_launch", "red")
  alertId = hs.alert.show("APP LAUNCH", true)
  m:enter()
end

local function exitMode()
  m:exit()
  yab.setSimpleBarMode("", "main")
  if alertId then hs.alert.closeSpecific(alertId) end
end

-- alt - a: enter mode
kbd.bind(kbd.alt, "a", enterMode)

local function entry(key, fn)
  m:bind({}, key, function()
    fn()
    exitMode()
  end)
end

entry("w", function() hs.application.launchOrFocus("WhatsApp") end)
entry("r", function() hs.application.launchOrFocus("OBS") end)
entry("c", function() hs.application.launchOrFocus("Calendar") end)
entry("s", function()
  hs.osascript.applescript('tell application "Safari" to make new document')
end)

-- Yandex Music — name has Cyrillic, easier via shell.
entry("m", function()
  hs.task.new("/usr/bin/open", nil,
    { "-a", "/Applications/Яндекс Музыка.app/Contents/MacOS/Яндекс Музыка" }):start()
end)

-- Terminal: yabai mac uses helper for placement; non-yabai opens iTerm directly.
if cfg.IS_YABAI then
  entry("t", function() yab.helper("new-iterm-window.sh") end)
else
  entry("t", function() hs.application.launchOrFocus("iTerm") end)
end

m:bind({}, "return", exitMode)
m:bind({}, "escape", exitMode)
