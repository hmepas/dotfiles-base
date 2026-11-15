-- Hyprland Lua config, migrated from hyprland.conf (hyprlang) on 2026-07-31.
-- hyprlang is deprecated since 0.55 and will be dropped ~1-2 releases after it.
-- Reference: /usr/share/hypr/stubs/hl.meta.lua and https://wiki.hypr.land/Configuring/Start/
--
-- The old hyprland.conf is kept next to this file as a fallback: Hyprland prefers
-- hyprland.lua when it exists, so renaming this file reverts to the legacy config.

------------------
---- MONITORS ----
------------------

-- 10-bit output. In June 2026 (nvidia 595/610, aquamarine 0.11) XR30 allocation failed with
-- flicker; retested 2026-11-13 on nvidia 615 / Hyprland 0.57 / aquamarine 0.14: XR30 is still
-- rejected but aquamarine falls back to XB30 (XBGR2101010) cleanly, 160 Hz kept. Needed for HDR.
-- Main monitor. Its logical size at scale 1.25 is 3072x1728.
-- Shift it right and vertically center it relative to the 1080x1920 portrait monitor.
-- Keep VRR off while testing brightness flicker on the INNOCN 32M2V + RTX 5070 Ti.
-- Fixed 160 Hz stays enabled; disabling VRR improved the initial test.
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@160", position = "1080x96", scale = 1.25, vrr = 0, bitdepth = 10 })

-- Match the secondary monitor by EDID description: its DP-* name may change after reboot.
-- It is left of the main display and rotated 90 degrees clockwise.
local secondary = "desc:Dell Inc. DELL U2414H 9TG463BF2MUL"
hl.monitor({ output = secondary, mode = "1920x1080@60", position = "0x0", scale = 1, transform = 1, vrr = 0 })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "yazi"
local menu        = "wofi --show=drun -iG -M=fuzzy"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Start both components directly; combining them with `&` leaves a shell
    -- process waiting on hyprpaper for the entire session.
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")

    -- Resolve the secondary monitor's unstable DP-* name and apply its black wallpaper.
    hl.exec_cmd("~/.config/hypr/scripts/configure_secondary.sh")

    -- Load Hyprland plugins, then reparse the config so plugin dispatchers bind cleanly.
    -- After a system/Hyprland update, ABI changes often make plugins stale. If plugin
    -- dispatchers become invalid again, run this manually from a terminal inside Hyprland:
    --   hyprpm update
    --   hyprpm enable hyprexpo   # only if hyprpm shows hyprexpo disabled/renamed after update
    --   hyprpm reload -n
    --   hyprctl reload
    -- Check state with:
    --   hyprpm list
    --   hyprctl configerrors
    hl.exec_cmd("hyprpm reload -n && hyprctl reload")

    hl.exec_cmd("nm-applet --indicator")                                  -- network icon in tray
    hl.exec_cmd("wl-paste --type text --watch cliphist store")            -- clipboard
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1") -- password manager

    -- Application launcher service (opened with Ctrl+Space)
    hl.exec_cmd("walker --gapplication-service")

    -- Quick terminal, always running on its special workspace
    hl.exec_cmd("ghostty --gtk-single-instance=false --class=com.mitchellh.ghostty.quickterm",
        { workspace = "special:quickterm silent" })

    -- and another one for myself
    hl.exec_cmd("ghostty")

    hl.exec_cmd("snappy-switcher --daemon")
    hl.exec_cmd("swaync") -- notifications
end)

hl.window_rule({
    match     = { class = "^(com.mitchellh.ghostty.quickterm)$" },
    workspace = "special:quickterm",
})


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- The old config forced WLR_DRM_DEVICES to card1:card0. Aquamarine uses
-- AQ_DRM_DEVICES now, card0 does not exist on this host, and the sole NVIDIA
-- GPU is selected automatically, so no explicit DRM device list is needed.
hl.env("EDITOR", "nvim")

hl.env("NVD_BACKEND", "direct")
hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- UWSM sets XDG_SESSION_TYPE and the other XDG session variables.
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        allow_tearing = true,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    -- Replaces the deprecated WLR_NO_HARDWARE_CURSORS environment variable.
    cursor = {
        no_hardware_cursors = true,
    },
})

-- Blur the waybar layer (was `blurls = waybar`)
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })

--            NAME,             X0,   Y0,   X1,   Y1
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- Keep one dedicated workspace on the secondary monitor and all numbered
-- workspaces on the main monitor.
hl.workspace_rule({ workspace = "name:left", monitor = secondary, default = true, persistent = true })
for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1" })
end

-- "Smart gaps" / "No gaps when only"
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 3, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })

hl.window_rule({
    name  = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },

    border_size = 2,
    rounding    = 10,
})

hl.window_rule({
    name  = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },

    border_size = 0,
    rounding    = 0,
})

-- for small floating windows
hl.window_rule({
    name   = "calc-rules",
    match  = { class = "^(gnome-calculator|qalculate-gtk|kcalc)$" },
    float  = true,
    center = true,
    size   = { 400, 500 },
})

-- Screenshot window shouldn't disturb layout
hl.window_rule({
    name  = "satty-float",
    match = { class = "^com.gabm.satty$" },
    float = true,
})

-- Yazi under ghostty
hl.window_rule({
    name   = "yazi-float",
    match  = { class = "^com.mitchellh.ghostty.yazifloat$" },
    float  = true,
    center = true,
    size   = { 800, 500 },
})

hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
        -- Disable VRR globally and in the monitor rules above while testing flicker.
        vrr                     = 0,
        -- Default (2) unfullscreens the current window when another window opens or
        -- grabs focus on the same workspace, which kicks games into windowed mode.
        -- 0 keeps the fullscreen window intact; the new window opens behind it.
        on_focus_under_fullscreen = 0,
        -- Follow xdg-activation requests (macOS/Windows-like): opening a link in
        -- another app switches focus to the browser window that received it.
        focus_on_activate         = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    -- Rendering for games: new dynamic frame scheduling
    render = {
        new_render_scheduling = true,
    },
})

hl.window_rule({
    name       = "albion_performance",
    match      = { class = "^(Albion-Online)$" },
    immediate  = true,
    fullscreen = true,
    workspace  = "7",
})

hl.window_rule({
    name       = "steam_apps",
    match      = { class = "^(steam_app_.*)$" },
    immediate  = true,
    fullscreen = true,
    workspace  = "7",
})

-- Pin apps to their dedicated workspaces
hl.window_rule({
    name      = "pin-obsidian",
    match     = { class = "^(obsidian)$" },
    workspace = "8",
})

hl.window_rule({
    name      = "pin-bitwarden",
    match     = { class = "^(Bitwarden)$" },
    workspace = "8",
})

hl.window_rule({
    name              = "pin-telegram",
    match             = { class = "^(org\\.telegram\\.desktop)$" },
    workspace         = "10",
    -- Ignore Telegram's activation requests (e.g. on incoming messages),
    -- while manual focus via click or the launcher shortcut still works.
    focus_on_activate = false,
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_variant = "",
        kb_model   = "",
        -- caps:hyper — Caps Lock now acts as Hyper_L (MOD3 in Hyprland). See `hyper` below.
        -- misc:typo puts typographic chars on levels 3/4 of the keys (e.g. "-" -> — and –) in all layouts;
        -- lv3:ralt_switch makes Right Alt the AltGr key that reaches those levels.
        -- Result: AltGr+"-" types an em dash (—), AltGr+Shift+"-" an en dash (–).
        -- Super+Shift+"-" (like Alt+Shift+"-" on macOS) is remapped to AltGr+"-" by keyd, below
        -- the compositor, so there is no race with held modifiers. In /etc/keyd/default.conf:
        --   [meta+shift]
        --   minus = G-minus
        -- then: sudo keyd reload
        -- Layout switching is a real bind ("Сменить раскладку" below), not grp:alt_space_toggle:
        -- an XKB toggle also reaches the focused client, and ghostty encodes it as ESC + space.
        kb_options = "caps:hyper,misc:typo,lv3:ralt_switch",
        kb_rules   = "",

        follow_mouse = 1,

        touchpad = {
            natural_scroll = false,
        },

        repeat_rate  = 50,
        repeat_delay = 200,

        -- mouse settings, everything is in mouse memory
        sensitivity = 0,

        -- no accel at all
        accel_profile = "flat",

        -- extra insurance to ignore libinput acceleration settings
        force_no_accel = true,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local moveMod = mainMod .. " + SHIFT"
local swapMod = mainMod .. " + ALT"
local hyper   = "MOD3"  -- Caps Lock remapped via kb_options = caps:hyper

-- Keep descriptions beside the actions. `hyprctl binds -j` exposes them to the
-- searchable, categorical and visual cheatsheets without parsing this Lua file.
local function bind(keys, category, description, dispatcher, opts)
    opts = opts or {}
    opts.description = string.format("[%s] %s", category, description)
    return hl.bind(keys, dispatcher, opts)
end

bind(mainMod .. " + Q", "Окна", "Закрыть активное окно", hl.dsp.window.close())
-- This session is managed by UWSM; stopping it through UWSM gives systemd an
-- ordered shutdown instead of pulling Hyprland out from under its clients.
bind(mainMod .. " + M", "Система", "Завершить сеанс Hyprland", hl.dsp.exec_cmd("uwsm stop"))
bind(mainMod .. " + E", "Приложения", "Открыть Yazi", hl.dsp.exec_cmd("ghostty --gtk-single-instance=false --class=\"com.mitchellh.ghostty.yazifloat\" -e " .. fileManager))
bind(mainMod .. " + R", "Приложения", "Меню приложений", hl.dsp.exec_cmd(menu))
bind(moveMod .. " + P", "Окна", "Переключить псевдотайлинг", hl.dsp.window.pseudo())
bind(mainMod .. " + comma", "Окна", "Поменять направление разделения", hl.dsp.layout("togglesplit"))
bind(mainMod .. " + F", "Окна", "Переключить плавающий режим", hl.dsp.window.float())
bind(moveMod .. " + F", "Окна", "Переключить полноэкранный режим", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Eject stray windows from behind a fullscreen one (e.g. a browser opened by an
-- in-game link lands on the game's workspace). Tiled, non-pinned windows other
-- than the fullscreen window are sent to workspace 2; focus stays where it was.
bind(moveMod .. " + O", "Окна", "Вынуть окна из-под fullscreen на стол 2", function()
    local ws = hl.get_active_workspace()
    local fs = ws and ws.fullscreen_window
    if not fs then return end
    local prev = hl.get_active_window()
    for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
        if w.address ~= fs.address and not w.floating and not w.pinned then
            hl.dispatch(hl.dsp.window.move({ workspace = 2, window = "address:" .. w.address }))
        end
    end
    if prev then hl.dispatch(hl.dsp.focus({ window = "address:" .. prev.address })) end
end)

-- OpenRamble hold-to-dictate: hold Right Ctrl, speak, let go. The compositor drives the
-- app over its control socket, so no `input` group is needed. Both binds carry
-- non_consuming so applications keep seeing Right Ctrl (Ctrl+C etc. stay intact).
-- The two lines are asymmetric on purpose: at press time Control_R is not yet in the
-- modifier mask (empty modmask matches), at release time it is (CTRL + release matches).
-- If the press bind turns out not to fire for a bare modifier, swap both for a single
-- toggle: bind("CTRL + Control_R", ..., orctl("hotkey toggle"), { release = true, non_consuming = true })
local orctlSock = os.getenv("XDG_RUNTIME_DIR") .. "/openramble/ctl.sock"
-- Diagnostics: every fired bind appends to /tmp/orctl-bind.log (what fired + socat's reply),
-- so "the bind never fires" and "socat fails" are distinguishable. Remove once dictation works.
local function orctl(line)
    return hl.dsp.exec_cmd("sh -c 'echo bind:" .. line:gsub(" ", "_")
        .. " >> /tmp/orctl-bind.log; echo " .. line
        .. " | socat -t1 - UNIX-CONNECT:" .. orctlSock .. " >> /tmp/orctl-bind.log 2>&1'")
end
-- Hold Hyper+` to dictate, release to insert. A bare modifier never fires binds in this
-- Hyprland build (tested live), so the gesture is a chord on a regular key instead.
-- Release order is covered twice: the MOD3+grave release fires when ` comes up first, and
-- the bare-grave release is the safety net for "Caps Lock released before `" - without it
-- that order would leave the microphone open. The safety net is non-consuming (typing a
-- backtick must stay a backtick) and its stray "release" while the key is already up is
-- deduplicated by OpenRamble against the raw key state, so it costs nothing.
bind(hyper .. " + grave", "Диктовка", "OpenRamble: начать диктовку (держать)", orctl("hotkey press"))
bind(hyper .. " + grave", "Диктовка", "OpenRamble: закончить диктовку", orctl("hotkey release"), { release = true })
bind("grave", "Диктовка", "OpenRamble: страховка release при обратном порядке отпускания",
    orctl("hotkey release"), { release = true, non_consuming = true })

-- The recording overlay must never take focus: focus theft releases the onboarding's
-- hold-button mid-press and would send inserted text into the overlay itself.
hl.window_rule({
    match   = { title = "^OpenRamble dictation$" },
    no_focus = true,
})

-- Arrows act as Home/End inside the focused window
bind(mainMod .. " + left",  "Навигация", "Home в активном окне",      hl.dsp.send_shortcut({ mods = "",     key = "home", window = "activewindow" }))
bind(mainMod .. " + right", "Навигация", "End в активном окне",       hl.dsp.send_shortcut({ mods = "",     key = "end",  window = "activewindow" }))
bind(mainMod .. " + up",    "Навигация", "Ctrl+Home в активном окне", hl.dsp.send_shortcut({ mods = "CTRL", key = "home", window = "activewindow" }))
bind(mainMod .. " + down",  "Навигация", "Ctrl+End в активном окне",  hl.dsp.send_shortcut({ mods = "CTRL", key = "end",  window = "activewindow" }))

-- Move focus with hjkl
bind(mainMod .. " + h", "Навигация", "Фокус влево",  hl.dsp.focus({ direction = "l" }))
bind(mainMod .. " + l", "Навигация", "Фокус вправо", hl.dsp.focus({ direction = "r" }))
bind(mainMod .. " + k", "Навигация", "Фокус вверх",  hl.dsp.focus({ direction = "u" }))
bind(mainMod .. " + j", "Навигация", "Фокус вниз",   hl.dsp.focus({ direction = "d" }))

-- Move a window into a neighbouring node
bind(moveMod .. " + h", "Окна", "Переместить окно влево",  hl.dsp.window.move({ direction = "l" }))
bind(moveMod .. " + j", "Окна", "Переместить окно вниз",   hl.dsp.window.move({ direction = "d" }))
bind(moveMod .. " + k", "Окна", "Переместить окно вверх",  hl.dsp.window.move({ direction = "u" }))
bind(moveMod .. " + l", "Окна", "Переместить окно вправо", hl.dsp.window.move({ direction = "r" }))

-- Move the current window between monitors
bind(moveMod .. " + A", "Мониторы", "Переместить окно на Dell",     hl.dsp.window.move({ monitor = secondary }))
bind(moveMod .. " + D", "Мониторы", "Переместить окно на основной", hl.dsp.window.move({ monitor = "HDMI-A-1" }))

-- Swap window positions
bind(swapMod .. " + h", "Окна", "Поменять с окном слева",  hl.dsp.window.swap({ direction = "l" }))
bind(swapMod .. " + j", "Окна", "Поменять с окном снизу",  hl.dsp.window.swap({ direction = "d" }))
bind(swapMod .. " + k", "Окна", "Поменять с окном сверху", hl.dsp.window.swap({ direction = "u" }))
bind(swapMod .. " + l", "Окна", "Поменять с окном справа", hl.dsp.window.swap({ direction = "r" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    bind(mainMod .. " + " .. key, "Рабочие столы", string.format("Перейти на рабочий стол %d", i), hl.dsp.focus({ workspace = i }))
    bind(moveMod .. " + " .. key, "Рабочие столы", string.format("Переместить окно на рабочий стол %d", i), hl.dsp.window.move({ workspace = i }))
end

bind(mainMod .. " + SPACE", "Окна", "Центрировать окно", hl.dsp.window.center())

-- Special workspace (scratchpad)
bind(mainMod .. " + S", "Рабочие столы", "Показать специальный стол magic", hl.dsp.workspace.toggle_special("magic"))
bind(moveMod .. " + S", "Рабочие столы", "Переместить окно на стол magic", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
bind(mainMod .. " + mouse_down", "Рабочие столы", "Следующий рабочий стол", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up",   "Рабочие столы", "Предыдущий рабочий стол", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(mainMod .. " + mouse:272", "Окна", "Перетаскивать окно мышью", hl.dsp.window.drag(),   { mouse = true })
bind(mainMod .. " + mouse:273", "Окна", "Изменять размер окна мышью", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys. This is a desktop and brightnessctl is not installed, so
-- the dead laptop-backlight binds from the example config are intentionally omitted.
bind("XF86AudioRaiseVolume", "Медиа", "Увеличить громкость", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", "Медиа", "Уменьшить громкость", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
bind("XF86AudioMute",        "Медиа", "Выключить звук",       hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
bind("XF86AudioMicMute",     "Медиа", "Выключить микрофон",   hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

-- Requires playerctl
bind("XF86AudioNext",  "Медиа", "Следующий трек",      hl.dsp.exec_cmd("playerctl next"),       { locked = true })
bind("XF86AudioPause", "Медиа", "Пауза или продолжить", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay",  "Медиа", "Играть или пауза",    hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev",  "Медиа", "Предыдущий трек",     hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

bind("CTRL + SPACE", "Приложения", "Открыть Walker", hl.dsp.exec_cmd([[nc -U "$XDG_RUNTIME_DIR/walker/walker.sock"]]))
bind("ALT + SPACE", "Ввод", "Сменить раскладку", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

-- snappy-switcher: --mod alt is required since 4.0.0, and must match the modifier
-- in this bind, otherwise only the first Tab works (toggle mode, no dismiss-on-release).
bind("ALT + TAB", "Навигация", "Переключиться на следующее окно", hl.dsp.exec_cmd("snappy-switcher next --mod alt"))

bind(hyper .. " + B", "Приложения", "Открыть Chrome", hl.dsp.exec_cmd("google-chrome-stable"))

bind(hyper .. " + T", "Терминал", "Открыть Ghostty", hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + T", "Терминал", "Открыть Ghostty", hl.dsp.exec_cmd(terminal))
bind(moveMod .. " + T", "Терминал", "Показать быстрый терминал", hl.dsp.workspace.toggle_special("quickterm"))

-- Hyper (Caps Lock) app launchers — focus if running, launch otherwise.
-- Workspace is pinned via window rules above; focusing follows it to that workspace.
local function focus_or_launch(window_selector, command)
    return function()
        local window = hl.get_window(window_selector)
        if window ~= nil then
            hl.dispatch(hl.dsp.focus({ window = window }))
        else
            hl.exec_cmd(command)
        end
    end
end

bind(hyper .. " + W", "Приложения", "Открыть или сфокусировать Bitwarden", focus_or_launch("class:Bitwarden", "flatpak run com.bitwarden.desktop"))
bind(hyper .. " + O", "Приложения", "Открыть или сфокусировать Obsidian",  focus_or_launch("class:obsidian", "obsidian"))
bind(hyper .. " + G", "Приложения", "Открыть или сфокусировать Telegram",  focus_or_launch("class:org.telegram.desktop", "Telegram"))

-- not working, while hyprctl globalshortcuts shows toggle_quick_terminal
-- hl.bind(mainMod .. " + slash", hl.dsp.global("toggle_quick_terminal"))
bind(mainMod .. " + slash", "Терминал", "Передать Super+/ быстрому терминалу", hl.dsp.pass({ window = "class:^(com\\.mitchellh\\.ghostty\\.quickterm)$" }))

-- Clipboard history
bind(mainMod .. " + ALT + c", "Буфер обмена", "История буфера обмена", hl.dsp.exec_cmd([[cliphist list | rofi -dmenu --matching fuzzy | cliphist decode | tee >(wl-copy) | wl-copy -p && wtype -M shift -k Insert -m shift]]))

-- Screenshot
bind("Print", "Снимки экрана", "Выбрать область", hl.dsp.exec_cmd("hyprshot -m region -- ~/bin/screenshot-edit"))
bind(mainMod .. " + Print", "Снимки экрана", "Снять активное окно", hl.dsp.exec_cmd("hyprshot -m window -- ~/bin/screenshot-edit"))
bind("SHIFT + Print", "Снимки экрана", "Снять весь монитор", hl.dsp.exec_cmd("hyprshot -m output -- ~/bin/screenshot-edit"))

-- OBS
bind(mainMod .. " + F1", "Система", "Начать или остановить запись OBS", hl.dsp.exec_cmd("~/.config/hypr/obs_toggle.sh"))

-- Cheatsheet: Caps Lock is Hyper in this configuration.
bind(hyper .. " + H", "Справка", "Поиск по всем сочетаниям", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybindings-cheatsheet.py --rofi"))
bind(hyper .. " + SHIFT + H", "Справка", "Справка по категориям", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybindings-cheatsheet.py --categories"))
bind(hyper .. " + CTRL + H", "Справка", "Визуальная карта клавиш", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybindings-cheatsheet.py --visual"))

-- Notification server through swaync
bind(hyper .. " + right", "Система", "Открыть центр уведомлений", hl.dsp.exec_cmd("swaync-client -t"))


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run window rule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = { 20, "monitor_h-120" },
    float = true,
})


----------------
---- GROUPS ----
----------------

hl.config({
    group = {
        col = {
            border_active = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
        },

        groupbar = {
            enabled       = true,
            font_size     = 10,
            gradients     = true,
            render_titles = true,
            col = {
                active   = "rgba(33ccffee)",
                inactive = "rgba(595959aa)",
            },
        },
    },
})

-- Turn a window into a group (or add it to an existing one)
bind(mainMod .. " + G", "Группы", "Добавить окно в группу", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_to_stack.sh"))

-- Navigate inside the "accordion" (by tabs)
bind(mainMod .. " + n", "Группы", "Следующее окно в группе", hl.dsp.group.next())
bind(mainMod .. " + p", "Группы", "Предыдущее окно в группе", hl.dsp.group.prev())


-----------------
---- PLUGINS ----
-----------------

-- Plugins are loaded by `hyprpm reload` from autostart, i.e. AFTER this config is first
-- parsed, so hl.plugin.hyprexpo is nil on the first pass. The `hyprctl reload` that
-- follows re-runs this file, and then the guard passes and the binds register.
if hl.plugin.hyprexpo ~= nil then
    hl.config({
        plugin = {
            hyprexpo = {
                columns          = 3,
                gaps_in          = 5,
                gaps_out         = 0,
                bg_col           = "rgb(111111)",
                workspace_method = "center current", -- or 'first 1'
            },
        },
    })

    -- Plugin Lua helpers execute immediately, so each call belongs inside a
    -- bind callback; unlike hl.dsp.*, they do not return dispatcher objects.
    -- Super + Tab (Mac OS X Mission Control alternative)
    bind(mainMod .. " + tab", "Обзор", "Показать обзор рабочих столов", function()
        hl.plugin.hyprexpo.expo("toggle")
    end)

    -- Submap for hyprexpo keyboard navigation. The plugin activates this
    -- submap while the overview is open and resets it when the overview closes.
    hl.define_submap("hyprexpo", function()
        bind("h", "Обзор", "Фокус влево в обзоре",  function() hl.plugin.hyprexpo.kb_focus("left") end)
        bind("l", "Обзор", "Фокус вправо в обзоре", function() hl.plugin.hyprexpo.kb_focus("right") end)
        bind("k", "Обзор", "Фокус вверх в обзоре",  function() hl.plugin.hyprexpo.kb_focus("up") end)
        bind("j", "Обзор", "Фокус вниз в обзоре",   function() hl.plugin.hyprexpo.kb_focus("down") end)

        bind("return", "Обзор", "Выбрать рабочий стол", function() hl.plugin.hyprexpo.kb_confirm() end)

        -- Close the grid without selecting a workspace.
        bind("escape", "Обзор", "Закрыть обзор без выбора", function() hl.plugin.hyprexpo.expo("cancel") end)
    end)
end
