-- yabai command helpers. No-op on non-yabai host.
--
-- All calls invoke the yabai binary directly (full path, no shell).
-- Fallback chains (`||` from skhd) are reproduced via `tryCmd` —
-- consecutive runs guarded by exitCode in a Lua callback. This avoids
-- depending on the GUI-process PATH.

local cfg = require("config")
local M = {}

-- PATH for child scripts that internally call `yabai` themselves.
local function pathEnv()
  return {
    PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin",
    HOME = os.getenv("HOME") or "",
    USER = os.getenv("USER") or "",
  }
end

-- Run `yabai -m <args...>` async.
function M.cmd(args)
  if not cfg.IS_YABAI then return end
  local full = { "-m" }
  for _, a in ipairs(args) do table.insert(full, a) end
  hs.task.new(cfg.YABAI_BIN, nil, full):start()
end

-- Try yabai commands in order until one exits with code 0.
-- Each chain element is an args list (table). Replaces shell `||` chains.
function M.tryCmd(...)
  if not cfg.IS_YABAI then return end
  local chains = { ... }
  local function tryNext(i)
    if i > #chains then return end
    local args = { "-m" }
    for _, a in ipairs(chains[i]) do table.insert(args, a) end
    hs.task.new(cfg.YABAI_BIN, function(exitCode)
      if exitCode ~= 0 then tryNext(i + 1) end
    end, args):start()
  end
  tryNext(1)
end

-- Run helper script (e.g. cycle-space-windows.sh). Inject PATH so the
-- script can call `yabai` plainly.
function M.helper(script, ...)
  if not cfg.IS_YABAI then return end
  local task = hs.task.new(cfg.YABAI_HELPERS .. "/" .. script, nil, { ... })
  task:setEnvironment(pathEnv())
  task:start()
end

-- simple-bar mode indicator. Two commands chained — use shell + PATH.
-- Gated by IS_YABAI_SA: Übersicht/simple-bar is personal-mac only (work host
-- doesn't install ubersicht — see Brewfile.personal).
function M.setSimpleBarMode(name, color)
  if not cfg.IS_YABAI_SA then return end
  local cmd = string.format(
    "%s '%s' %s && curl -qs %s",
    cfg.YABAI_MODE_SCRIPT, name, color, cfg.SIMPLE_BAR_REFRESH)
  local task = hs.task.new("/bin/sh", nil, { "-c", cmd })
  task:setEnvironment(pathEnv())
  task:start()
end

return M
