-- Window management.
--
-- yabai mac: full set (focus/warp/swap/resize/float; sticky if SA).
-- non-yabai mac: focus via hs.window, display move, native fullscreen.
-- Tiling/swap/resize on non-yabai → Amethyst (see AMETHYST.md).
--
-- SA-only bindings (skipped on yabai + SIP-enabled host):
--   hyper-s   window --toggle sticky

local cfg   = require("config")
local kbd   = require("modules.keybind")
local yab   = require("modules.yabai")

local alt        = kbd.alt
local alt_shift  = kbd.alt_shift
local hyper      = kbd.hyper
local cmd_alt_ctrl = kbd.cmd_alt_ctrl
local super      = kbd.super

local function centeredFocusFrame(screenFrame)
  local width = math.max(1000, screenFrame.w * 0.40)
  local height = width * 0.75 -- 4:3

  local maxWidth = screenFrame.w * 0.85
  local maxHeight = screenFrame.h * 0.85
  if width > maxWidth then
    width = maxWidth
    height = width * 0.75
  end
  if height > maxHeight then
    height = maxHeight
    width = height * 4 / 3
  end

  return hs.geometry.rect(
    screenFrame.x + (screenFrame.w - width) / 2,
    screenFrame.y + (screenFrame.h - height) / 2,
    width,
    height
  )
end

local function centerFocusedWindow(resize)
  local fw = hs.window.focusedWindow()
  if not fw then return end

  local screen = fw:screen() or hs.screen.mainScreen()
  local frame = resize and centeredFocusFrame(screen:frame()) or fw:frame()
  if not resize then
    local sf = screen:frame()
    frame.x = sf.x + (sf.w - frame.w) / 2
    frame.y = sf.y + (sf.h - frame.h) / 2
  end

  fw:setFrame(frame, 0)
end

local function yabaiFocusedWindowIsFloating()
  local out, ok = hs.execute(cfg.YABAI_BIN .. " -m query --windows --window 2>/dev/null", true)
  if not ok or not out or out == "" then return false end
  local win = hs.json.decode(out)
  return win and win["is-floating"] == true
end

local function floatAndCenterFocusedWindow()
  if cfg.IS_YABAI and not yabaiFocusedWindowIsFloating() then
    yab.cmd({ "window", "--toggle", "float" })
    hs.timer.doAfter(0.08, function() centerFocusedWindow(true) end)
  else
    centerFocusedWindow(true)
  end
end

kbd.setGroup("Windows")

-- Make current window floating (on yabai), resize to focused 4:3 area, and center it.
kbd.bind(super, "c", "Float + center (4:3)", floatAndCenterFocusedWindow)

if cfg.IS_YABAI then
  -- ============================================================
  -- yabai mode
  -- ============================================================

  -- Close focused window via yabai (phantom windows only visible through
  -- bsp+borders, where cmd-w has nothing to grab onto). Physically fn+c:
  -- Karabiner maps fn to hyper on this host.
  kbd.bind(hyper, "c", "Close window (yabai)", function() yab.cmd({ "window", "--close" }) end)

  -- Float / split
  kbd.bind(hyper, "f", "Toggle float", function() yab.cmd({ "window", "--toggle", "float" }) end)
  kbd.bind(cmd_alt_ctrl, "s", "Toggle split", function() yab.cmd({ "window", "--toggle", "split" }) end)

  -- Sticky (SA-only)
  if cfg.SIP_DISABLED then
    kbd.bind(hyper, "s", "Toggle sticky (SA)", function() yab.cmd({ "window", "--toggle", "sticky" }) end)
  end

  -- Center unmanaged window without resizing (legacy binding from skhd).
  kbd.bind(hyper, "space", "Center window (no resize)", function() centerFocusedWindow(false) end)

  -- Focus by direction. Fallback to display, then to recent window.
  kbd.register(alt, "h j k l", "Focus window (→ display → recent)")
  kbd.bind(alt, "h", function() yab.cmd({ "window", "--focus", "west" }) end)
  kbd.bind(alt, "l", function() yab.cmd({ "window", "--focus", "east" }) end)
  kbd.bind(alt, "k", function()
    yab.tryCmd(
      { "window", "--focus", "north" },
      { "display", "--focus", "north" },
      { "window", "--focus", "recent" }
    )
  end)
  kbd.bind(alt, "j", function()
    yab.tryCmd(
      { "window", "--focus", "south" },
      { "display", "--focus", "south" },
      { "window", "--focus", "recent" }
    )
  end)

  -- Stack navigation / cycle
  kbd.register(alt, "n / p", "Focus stack next / prev")
  kbd.bind(alt, "n", function() yab.cmd({ "window", "--focus", "stack.next" }) end)
  kbd.bind(alt, "p", function() yab.cmd({ "window", "--focus", "stack.prev" }) end)
  kbd.register(alt_shift, "n / p", "Cycle space windows")
  kbd.bind(alt_shift, "n", function() yab.helper("cycle-space-windows.sh", "next") end)
  kbd.bind(alt_shift, "p", function() yab.helper("cycle-space-windows.sh", "prev") end)

  -- Warp (move into split)
  kbd.register(alt_shift, "h j k l", "Warp window into split")
  kbd.bind(alt_shift, "h", function() yab.cmd({ "window", "--warp", "west" }) end)
  kbd.bind(alt_shift, "l", function() yab.cmd({ "window", "--warp", "east" }) end)
  kbd.bind(alt_shift, "k", function() yab.cmd({ "window", "--warp", "north" }) end)
  kbd.bind(alt_shift, "j", function() yab.cmd({ "window", "--warp", "south" }) end)

  -- Swap (or move floating)
  kbd.register(hyper, "h j k l", "Swap window (move if floating)")
  kbd.bind(hyper, "h", function()
    yab.tryCmd({ "window", "--swap", "west" }, { "window", "--move", "rel:-100:0" })
  end)
  kbd.bind(hyper, "l", function()
    yab.tryCmd({ "window", "--swap", "east" }, { "window", "--move", "rel:100:0" })
  end)
  kbd.bind(hyper, "k", function()
    yab.tryCmd({ "window", "--swap", "north" }, { "window", "--move", "rel:0:-100" })
  end)
  kbd.bind(hyper, "j", function()
    yab.tryCmd({ "window", "--swap", "south" }, { "window", "--move", "rel:0:100" })
  end)

  -- Move window to display
  kbd.bind(alt_shift, "w", "Move window to display 2", function() yab.cmd({ "window", "--display", "2", "--focus" }) end)
  kbd.bind(alt_shift, "s", "Move window to display 1", function() yab.cmd({ "window", "--display", "1", "--focus" }) end)

  -- Layouts
  kbd.bind(alt, ",", "Rotate space / bsp layout", function()
    yab.tryCmd({ "space", "--rotate", "90" }, { "space", "--layout", "bsp" })
  end)
  kbd.bind(alt, "/", "Stack layout", function() yab.cmd({ "space", "--layout", "stack" }) end)
  kbd.bind(alt, "space", "Float layout", function() yab.cmd({ "space", "--layout", "float" }) end)

  -- Fullscreen
  kbd.bind(alt_shift, "f", "Zoom fullscreen", function() yab.cmd({ "window", "--toggle", "zoom-fullscreen" }) end)
  kbd.bind(hyper, "return", "Native fullscreen", function() yab.cmd({ "window", "--toggle", "native-fullscreen" }) end)

  -- Smart resize
  kbd.register(hyper, "= / -", "Resize grow / shrink")
  kbd.bind(hyper, "=", function() yab.helper("smart-resize.sh", "grow", "50") end)
  kbd.bind(hyper, "-", function() yab.helper("smart-resize.sh", "shrink", "50") end)

  -- Resize perpendicular (uncle)
  kbd.register(cmd_alt_ctrl, "= / -", "Resize perpendicular (uncle)")
  kbd.bind(cmd_alt_ctrl, "=", function() yab.helper("smart-resize.sh", "shrink", "50", "uncle") end)
  kbd.bind(cmd_alt_ctrl, "-", function() yab.helper("smart-resize.sh", "grow", "50", "uncle") end)

else
  -- ============================================================
  -- non-yabai mode
  -- ============================================================

  -- Focus by direction (hs.window built-in).
  -- Args: candidates, frontmost, strict
  local function focusDir(dir)
    return function()
      local fw = hs.window.focusedWindow()
      if not fw then return end
      local fn = fw["focusWindow" .. dir]
      fn(fw, nil, true, false)
    end
  end
  kbd.register(alt, "h j k l", "Focus window by direction")
  kbd.bind(alt, "h", focusDir("West"))
  kbd.bind(alt, "l", focusDir("East"))
  kbd.bind(alt, "k", focusDir("North"))
  kbd.bind(alt, "j", focusDir("South"))

  -- Move floating window by 100 px (no tile-aware swap; tiling = Amethyst).
  local function moveBy(dx, dy)
    return function()
      local fw = hs.window.focusedWindow()
      if not fw then return end
      local f = fw:frame()
      f.x = f.x + dx
      f.y = f.y + dy
      fw:setFrame(f)
    end
  end
  kbd.register(hyper, "h j k l", "Move floating window 100px")
  kbd.bind(hyper, "h", moveBy(-100, 0))
  kbd.bind(hyper, "l", moveBy(100, 0))
  kbd.bind(hyper, "k", moveBy(0, -100))
  kbd.bind(hyper, "j", moveBy(0, 100))

  -- Move window to next/prev display (matches alt+shift-w/s intent).
  -- Maps "w" → screen index 2, "s" → screen index 1 (matches yabai config).
  local function moveToScreen(idx)
    return function()
      local fw = hs.window.focusedWindow()
      if not fw then return end
      local screens = hs.screen.allScreens()
      if screens[idx] then
        fw:moveToScreen(screens[idx], true, true)
      end
    end
  end
  kbd.bind(alt_shift, "w", "Move window to display 2", moveToScreen(2))
  kbd.bind(alt_shift, "s", "Move window to display 1", moveToScreen(1))

  -- Native macOS fullscreen
  kbd.bind(hyper, "return", "Native fullscreen", function()
    local fw = hs.window.focusedWindow()
    if fw then fw:toggleFullScreen() end
  end)
end
