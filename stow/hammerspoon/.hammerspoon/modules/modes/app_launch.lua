-- App-launch mode. Both hosts.
-- alt-a → mode → letter → app launches → mode exits.

local cfg = require("config")
local kbd = require("modules.keybind")
local yab = require("modules.yabai")
local cs  = require("modules.cheatsheet")
local calendarImage = require("modules.calendar_image")

local m = hs.hotkey.modal.new()
local modeKeys = {}

-- Private per-host values, kept OUT of the repo: ~/.hammerspoon_local.lua
-- must `return { ZOOM_MEETING_URL = "https://…zoom.us/j/…?pwd=…",
--                STREAM_ROOM_URL = "https://stream.wb.ru/room/…" }`.
local localCfg = {}
do
  local p = os.getenv("HOME") .. "/.hammerspoon_local.lua"
  if hs.fs.attributes(p) then localCfg = dofile(p) or {} end
end

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
entry("q", "Calendar image", calendarImage.togglePersistent)
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

-- Meetings: focus sV (no-op without yabai), then open the link.
-- Zoom links go straight to zoom.us via zoommtg:// (no browser hop);
-- stream.wb.ru links open in a new Safari window.
-- Returns false when the URL is not a recognised meeting link.
local function openMeeting(url)
  local host, id = url:match("^https://([%w%.%-]*zoom%.us)/j/(%d+)")
  local isStream = url:match("^https://stream%.wb%.ru/room/") ~= nil
  if not host and not isStream then return false end

  yab.cmd({ "space", "--focus", "sV" })
  hs.timer.doAfter(0.3, function()
    if host then
      local pwd = url:match("[?&]pwd=([^&#]*)") or ""
      hs.urlevent.openURL(string.format(
        "zoommtg://%s/join?confno=%s&pwd=%s", host, id, pwd))
    else
      hs.osascript.applescript(string.format(
        'tell application "Safari"\n'
        .. '  make new document with properties {URL:"%s"}\n'
        .. '  activate\n'  -- after: activate first jumps to a space with an existing Safari window
        .. 'end tell', url))
    end
  end)
  return true
end

entry("v", "Video meeting from clipboard", function()
  local url = (hs.pasteboard.getContents() or ""):match("^%s*(.-)%s*$")
  if not openMeeting(url) then
    hs.alert.show("Clipboard: no zoom / stream.wb.ru link")
  end
end)

-- Also copies the link to clipboard — join, then paste it to a colleague.
entry("z", "Zoom (my link)", function()
  local url = localCfg.ZOOM_MEETING_URL
  if not url or not openMeeting(url) then
    hs.alert.show("ZOOM_MEETING_URL missing in ~/.hammerspoon_local.lua")
    return
  end
  hs.pasteboard.setContents(url)
end)

-- "k" = ktalk mnemonic (s/t taken); currently points at WB Stream.
entry("k", "WB Stream (my link)", function()
  local url = localCfg.STREAM_ROOM_URL
  if not url or not openMeeting(url) then
    hs.alert.show("STREAM_ROOM_URL missing in ~/.hammerspoon_local.lua")
    return
  end
  hs.pasteboard.setContents(url)
end)

table.insert(modeKeys, { key = "⎋ ⏎", desc = "cancel" })
m:bind({}, "return", exitMode)
m:bind({}, "escape", exitMode)
