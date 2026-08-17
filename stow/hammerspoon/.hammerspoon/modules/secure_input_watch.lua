-- Secure Input watchdog. Both hosts.
--
-- macOS "Secure Input" (EnableSecureEventInput) is session-global: any
-- process can turn it on and it silently kills every Carbon hotkey
-- (all of hs.hotkey) until released. Password fields enable it
-- legitimately for a few seconds; a background app that forgets to
-- release it (Bitwarden unlock screen at login, 2026-08) leaves HS dead
-- with no visible reason. Poll and shout while it stays on.
--
-- Culprit hint comes from IOConsoleUsers/kCGSSessionSecureInputPID —
-- that is the *frontmost* app at the moment the flag flipped on, not
-- necessarily the enabler (background enablers get misattributed).

local M = {}

local INTERVAL = 5           -- seconds between checks
local GRACE_TICKS = 2        -- ignore short legit password entry
local ALERT_DURATION = INTERVAL - 0.5

local onTicks = 0
local hint = nil
local alertId = nil

local function culpritHint()
  local out = hs.execute("/usr/sbin/ioreg -d1 -k IOConsoleUsers")
  local pid = tonumber(out:match('kCGSSessionSecureInputPID"=(%d+)'))
  if not pid then return "unknown" end
  local app = hs.application.applicationForPID(pid)
  local name = app and app:name()
  if not name then
    local comm = hs.execute("/bin/ps -p " .. pid .. " -o comm=")
    name = comm ~= "" and comm:match("([^/\n]+)%s*$") or "dead process"
  end
  return string.format("%s (pid %d)", name, pid)
end

local function tick()
  if hs.eventtap.isSecureInputEnabled() then
    onTicks = onTicks + 1
    if onTicks == 1 then
      hint = culpritHint()
      print("secure_input_watch: ON, hint " .. hint)
    end
    if onTicks >= GRACE_TICKS then
      if alertId then hs.alert.closeSpecific(alertId) end
      alertId = hs.alert.show(
        string.format("⚠️ Secure Input ON %ds — hotkeys blocked\nfrontmost when enabled: %s",
          onTicks * INTERVAL, hint),
        ALERT_DURATION)
    end
  elseif onTicks > 0 then
    if onTicks >= GRACE_TICKS then
      if alertId then hs.alert.closeSpecific(alertId) end
      hs.alert.show("Secure Input released", 2)
    end
    print("secure_input_watch: OFF after " .. onTicks * INTERVAL .. "s")
    onTicks, hint, alertId = 0, nil, nil
  end
end

M.timer = hs.timer.doEvery(INTERVAL, tick)

return M
