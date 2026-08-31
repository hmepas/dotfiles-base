-- Hotkey cheatsheet overlay + which-key popups for modal modes.
--
-- The sheet is rendered from the keybind.lua registry, so it always
-- shows exactly the bindings active on this host (yabai/SA branches
-- register only what they actually bind).
--
-- hyper-/ toggles the sheet; esc, the same chord, or a click closes it.
-- Modes call M.showMode(title, entries[, accent]) / M.hideMode().

local kbd = require("modules.keybind")

local M = {}

-- ---------------------------------------------------------------- labels

local MOD_ORDER = { "ctrl", "alt", "shift", "cmd" }
local MOD_GLYPH = { ctrl = "⌃", alt = "⌥", shift = "⇧", cmd = "⌘" }
local KEY_GLYPH = { ["return"] = "⏎", escape = "⎋", space = "␣", tab = "⇥" }

local function modLabel(mods)
  local set, n = {}, 0
  for _, m in ipairs(mods) do set[m] = true; n = n + 1 end
  if n == 4 then return "✦" end
  if n == 3 and set.ctrl and set.alt and set.cmd then return "⇪" end
  local s = ""
  for _, m in ipairs(MOD_ORDER) do
    if set[m] then s = s .. MOD_GLYPH[m] end
  end
  return s
end

local function keyLabel(key)
  return KEY_GLYPH[key] or key
end

-- ---------------------------------------------------------------- layout

local COLS      = 3
local PAD       = 26
local COL_W     = 340
local KEY_W     = 104
local ROW_H     = 21
local HEADER_H  = 34
local GROUP_GAP = 8
local LEGEND_H  = 30

local COLORS = {
  bg     = { hex = "#16161e", alpha = 0.97 },
  header = { hex = "#e8b35a" },
  key    = { hex = "#7fb4ff" },
  desc   = { hex = "#d8d8e0" },
  dim    = { hex = "#8a8a96" },
  red    = { hex = "#e06c75" },
}

local function collectGroups()
  local byName, order = {}, {}
  for _, e in ipairs(kbd.registry) do
    local g = byName[e.group]
    if not g then
      g = { name = e.group, entries = {} }
      byName[e.group] = g
      table.insert(order, g)
    end
    table.insert(g.entries, e)
  end
  return order
end

local function groupHeight(g)
  return HEADER_H + #g.entries * ROW_H + GROUP_GAP
end

-- First-fit-decreasing into COLS columns: big groups first, each into
-- the currently shortest column. Keeps the sheet compact.
local function packColumns(groups)
  table.sort(groups, function(a, b) return groupHeight(a) > groupHeight(b) end)
  local cols, heights = {}, {}
  for i = 1, COLS do cols[i], heights[i] = {}, 0 end
  for _, g in ipairs(groups) do
    local best = 1
    for i = 2, COLS do
      if heights[i] < heights[best] then best = i end
    end
    table.insert(cols[best], g)
    heights[best] = heights[best] + groupHeight(g)
  end
  local maxH = 0
  for i = 1, COLS do
    if heights[i] > maxH then maxH = heights[i] end
  end
  return cols, maxH
end

-- ---------------------------------------------------------------- sheet

local sheet, escHotkey

local function hideSheet()
  if sheet then sheet:delete(); sheet = nil end
  if escHotkey then escHotkey:delete(); escHotkey = nil end
end

local function buildSheet()
  local cols, maxH = packColumns(collectGroups())
  local w = PAD * 2 + COL_W * COLS
  local h = PAD * 2 + maxH + LEGEND_H

  local sf = hs.screen.mainScreen():frame()
  local c = hs.canvas.new(hs.geometry.rect(
    sf.x + (sf.w - w) / 2, sf.y + (sf.h - h) / 2, w, h))

  c:appendElements({
    type = "rectangle", action = "fill",
    roundedRectRadii = { xRadius = 14, yRadius = 14 },
    fillColor = COLORS.bg,
  })

  for ci, col in ipairs(cols) do
    local x = PAD + (ci - 1) * COL_W
    local y = PAD
    for _, g in ipairs(col) do
      c:appendElements({
        type = "text", text = g.name:upper(),
        textFont = ".AppleSystemUIFontBold", textSize = 13,
        textColor = COLORS.header,
        frame = { x = x, y = y + 8, w = COL_W - 16, h = HEADER_H - 8 },
      })
      y = y + HEADER_H
      for _, e in ipairs(g.entries) do
        c:appendElements({
          type = "text", text = modLabel(e.mods) .. " " .. keyLabel(e.key),
          textFont = "Menlo", textSize = 12.5,
          textColor = COLORS.key,
          frame = { x = x, y = y, w = KEY_W, h = ROW_H },
        }, {
          type = "text", text = e.desc,
          textFont = ".AppleSystemUIFont", textSize = 12.5,
          textColor = COLORS.desc,
          frame = { x = x + KEY_W + 8, y = y, w = COL_W - KEY_W - 24, h = ROW_H },
        })
        y = y + ROW_H
      end
      y = y + GROUP_GAP
    end
  end

  c:appendElements({
    type = "text",
    text = "✦ hyper (⌃⌥⇧⌘)   ⇪ super (CapsLock, ⌘⌥⌃)   (SA) personal mac only   ⎋ / click / same chord to close",
    textFont = ".AppleSystemUIFont", textSize = 11.5,
    textColor = COLORS.dim, textAlignment = "center",
    frame = { x = 0, y = h - LEGEND_H, w = w, h = ROW_H },
  })

  c:level(hs.canvas.windowLevels.overlay)
  c:behaviorAsLabels({ "canJoinAllSpaces" })
  return c
end

local function showSheet()
  sheet = buildSheet()
  sheet:canvasMouseEvents(true, false, false, false)
  sheet:mouseCallback(hideSheet)
  sheet:show(0.15)
  escHotkey = hs.hotkey.bind({}, "escape", hideSheet)
end

function M.toggle()
  if sheet then hideSheet() else showSheet() end
end

-- ---------------------------------------------------------------- modes

-- Small which-key popup shown while a modal mode is active.
-- entries: { { key = "w", desc = "WhatsApp" }, ... }

local modeCanvas

function M.hideMode()
  if modeCanvas then modeCanvas:delete(); modeCanvas = nil end
end

function M.showMode(title, entries, accent)
  M.hideMode()
  local w = 320
  local h = 18 + HEADER_H + #entries * ROW_H + 18

  local sf = hs.screen.mainScreen():frame()
  local c = hs.canvas.new(hs.geometry.rect(
    sf.x + (sf.w - w) / 2, sf.y + sf.h * 0.60, w, h))

  c:appendElements({
    type = "rectangle", action = "fill",
    roundedRectRadii = { xRadius = 12, yRadius = 12 },
    fillColor = COLORS.bg,
  }, {
    type = "text", text = title,
    textFont = ".AppleSystemUIFontBold", textSize = 13,
    textColor = accent or COLORS.header,
    frame = { x = PAD, y = 18, w = w - PAD * 2, h = HEADER_H - 10 },
  })

  local y = 18 + HEADER_H
  for _, e in ipairs(entries) do
    c:appendElements({
      type = "text", text = e.key,
      textFont = "Menlo", textSize = 12.5,
      textColor = COLORS.key,
      frame = { x = PAD, y = y, w = 64, h = ROW_H },
    }, {
      type = "text", text = e.desc,
      textFont = ".AppleSystemUIFont", textSize = 12.5,
      textColor = COLORS.desc,
      frame = { x = PAD + 72, y = y, w = w - PAD * 2 - 72, h = ROW_H },
    })
    y = y + ROW_H
  end

  c:level(hs.canvas.windowLevels.overlay)
  c:behaviorAsLabels({ "canJoinAllSpaces" })
  c:show(0.1)
  modeCanvas = c
end

M.accentRed = COLORS.red

kbd.setGroup("Modes")
-- NOTE: not hyper-/ — macOS reserves ⌃⌥⇧⌘ + . , / as diagnostic
-- keychords (sysdiagnose family), eaten by WindowServer before any
-- event tap. alt+shift-/ = "alt+?".
kbd.bind(kbd.alt_shift, "/", "This cheatsheet", M.toggle)

return M
