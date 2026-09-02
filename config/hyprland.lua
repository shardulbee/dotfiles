-- Sharchy Hyprland configuration.

local mainMod = "SUPER"

hl.monitor({
    output = "eDP-1",
    mode = "2560x1600@120",
    position = "0x0",
    scale = "2",
})

hl.env("NIXOS_OZONE_WL", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("XCURSOR_THEME", "macOS")
hl.env("XCURSOR_SIZE", "24")

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-fuzzel"))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("vicinae 'vicinae://launch/clipboard/history?toggle=true'"))
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-helium"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-helium"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("1password --quick-access"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("1password --show"))
hl.bind(mainMod .. " + CTRL + T", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-theme toggle"))
hl.bind(mainMod .. " + ALT + K", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-keybindings"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-rebuild"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-layout-toggle"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("systemctl --user start sharchy-lock.service"))
hl.bind(mainMod .. " + N", hl.dsp.focus({ workspace = "name:obsidian" }))
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind("ALT + TAB", hl.dsp.focus({ workspace = "previous" }))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mainMod .. " + MINUS", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind(mainMod .. " + EQUAL", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind(mainMod .. " + SHIFT + EQUAL", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.layout("togglesplit"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

hl.bind("ALT + SHIFT + 3", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-screenshot region"))
hl.bind("ALT + SHIFT + 4", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-screenshot fullscreen"))
hl.bind("PRINT", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-screenshot region"))
hl.bind("CTRL + PRINT", hl.dsp.exec_cmd("/home/shardul/.local/bin/sharchy-screenshot fullscreen"))

hl.window_rule({
    name = "obsidian-space",
    match = {
        class = "(?i).*obsidian.*",
    },
    workspace = "name:obsidian",
    fullscreen = true,
})

hl.window_rule({
    name = "float-1password",
    match = {
        class = "1password",
    },
    float = true,
    center = true,
    size = "900 650",
})

hl.window_rule({
    name = "suppress-maximize",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

hl.config({
    input = {
        kb_options = "ctrl:nocaps",
        repeat_delay = 260,
        repeat_rate = 60,
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            scroll_factor = 0.3,
        },
    },
    general = {
        gaps_in = 2,
        gaps_out = 4,
        border_size = 2,
        col = {
            active_border = "rgb(cd974b)",
            inactive_border = "rgb(5c584c)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled = false,
        },
    },
    animations = {
        enabled = false,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
    debug = {
        vfr = true,
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start sharchy-bar.service mako.service")
    hl.exec_cmd("1password --silent")
    hl.exec_cmd("obsidian")
    hl.exec_cmd("swayidle -w timeout 300 \"systemctl --user start sharchy-lock.service\" timeout 600 \"hyprctl dispatch dpms off\" resume \"hyprctl dispatch dpms on\" before-sleep \"systemctl --user start sharchy-lock.service\"")
end)
