-- Browser-shortcut guard. Both hosts.
--
-- Web apps (OWA etc.) can preventDefault() browser menu shortcuts —
-- the page sees keydown before the menu does. While a browser is
-- frontmost, grab those combos as Carbon hotkeys (the page never sees
-- them) and invoke the menu action directly.
--
-- NOTE: these hotkeys live outside kbd.list on purpose — service-mode
-- enableAll() would otherwise re-enable them outside the browser.

local M = {}

local BROWSERS = { ["Safari"] = true }

-- combo → ordered menu-path candidates (first that selects wins;
-- Close Tab is disabled when a window has a single tab → Close Window)
local guards = {
  { mods = { "cmd" }, key = "n", paths = { { "File", "New Window" } } },
  { mods = { "cmd" }, key = "t", paths = { { "File", "New Tab" } } },
  { mods = { "cmd" }, key = "w", paths = { { "File", "Close Tab" }, { "File", "Close Window" } } },
}

M.keys = {}
for _, g in ipairs(guards) do
  local hk = hs.hotkey.new(g.mods, g.key, function()
    local app = hs.application.frontmostApplication()
    if not app then return end
    for _, path in ipairs(g.paths) do
      if app:selectMenuItem(path) then return end
    end
  end)
  table.insert(M.keys, hk)
end

local function setEnabled(on)
  for _, hk in ipairs(M.keys) do
    if on then hk:enable() else hk:disable() end
  end
end

M.watcher = hs.application.watcher.new(function(name, event)
  if event == hs.application.watcher.activated then
    setEnabled(BROWSERS[name] == true)
  end
end)
M.watcher:start()

-- Initial state: HS may (re)load with a browser already frontmost.
local front = hs.application.frontmostApplication()
setEnabled(front ~= nil and BROWSERS[front:name()] == true)

return M
