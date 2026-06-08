-- Wrapper around hs.hotkey.bind that tracks all bindings.
-- Used by service_mode to disable everything except its own modal.

local M = {}
M.list = {}

function M.bind(mods, key, pressed, released, repeated)
  local hk = hs.hotkey.bind(mods, key, pressed, released, repeated)
  table.insert(M.list, hk)
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
