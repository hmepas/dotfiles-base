-- Wrapper around hs.hotkey.bind that tracks all bindings.
-- Used by service_mode to disable everything except its own modal,
-- and by cheatsheet.lua to render the hotkey overlay.

local M = {}
M.list = {}

-- Cheatsheet registry: { group, mods, key, desc } display entries.
-- Only entries with a desc appear on the sheet; loops register one
-- compact line via M.register instead of one per bind.
M.registry = {}

local currentGroup = "Other"

-- Set the cheatsheet group for subsequent bind/register calls.
-- Module loading is sequential, so one shared slot is enough.
function M.setGroup(name)
  currentGroup = name
end

-- Display-only cheatsheet entry (for loops, modal keys, raw hotkeys).
-- `key` is a free-form label ("1…9", "h j k l"); mods may be {}.
function M.register(mods, key, desc)
  table.insert(M.registry, {
    group = currentGroup, mods = mods, key = key, desc = desc,
  })
end

-- M.bind(mods, key, [desc,] pressed, released, repeated)
-- Optional desc string before the callbacks adds a cheatsheet entry.
function M.bind(mods, key, a, b, c, d)
  local desc, pressed, released, repeated
  if type(a) == "string" then
    desc, pressed, released, repeated = a, b, c, d
  else
    pressed, released, repeated = a, b, c
  end
  local hk = hs.hotkey.bind(mods, key, pressed, released, repeated)
  table.insert(M.list, hk)
  if desc then M.register(mods, key, desc) end
  return hk
end

function M.disableAll()
  for _, hk in ipairs(M.list) do hk:disable() end
end

function M.enableAll()
  for _, hk in ipairs(M.list) do hk:enable() end
end

-- Modifier sets
M.alt           = { "alt" }
M.alt_shift     = { "alt", "shift" }
M.hyper         = { "ctrl", "alt", "shift", "cmd" }
M.cmd_alt_ctrl  = { "cmd", "alt", "ctrl" }
M.super         = M.cmd_alt_ctrl -- CapsLock via Karabiner

return M
