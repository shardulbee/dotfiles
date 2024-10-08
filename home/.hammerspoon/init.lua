local chrome = require("chrome")

local function wrapped(fnToWrap, ...)
    local vararg = { ... }
    local wrapped_fn = function()
        fnToWrap(table.unpack(vararg))
    end
    return wrapped_fn
end

local function setBinding(binding)
    if binding.app then
        hs.hotkey.bind(binding.mods, binding.key, wrapped(hs.application.launchOrFocus, binding.app))
    elseif binding.fn then
        hs.hotkey.bind(binding.mods, binding.key, binding.fn)
    elseif binding.tab then
        hs.hotkey.bind(binding.mods, binding.key, chrome.LaunchOrFocusTab(binding.tab))
    elseif binding.url then
        hs.hotkey.bind(binding.mods, binding.key, wrapped(hs.urlevent.openURL, binding.url))
    end
end

ALT = "alt"
CMD = "cmd"
CTRL = "ctrl"
SHIFT = "shift"

local function focusWindow(direction)
    local directions = {
        west = hs.window.focusedWindow().focusWindowWest,
        east = hs.window.focusedWindow().focusWindowEast,
        north = hs.window.focusedWindow().focusWindowNorth,
        south = hs.window.focusedWindow().focusWindowSouth
    }
    local focusFn = directions[direction]
    if focusFn then
        focusFn(nil, true, true)
    else
        print("Invalid direction")
    end
end

local bindings = {
    { mods = { ALT },            key = "0", app = "Kitty" },
    { mods = { ALT },            key = "2", app = "Sublime Merge" },
    -- { mods = { ALT }, key = "1", app = "Visual Studio Code" },
    { mods = { ALT },            key = "1", app = "Zed" },
    { mods = { ALT },            key = "3", app = "Google Chrome" },
    { mods = { ALT },            key = "6", fn = hs.toggleConsole },
    { mods = { ALT },            key = "7", app = "Slack" },
    { mods = { CMD, CTRL },      key = "F", app = "Finder" },
    { mods = { CMD, CTRL },      key = "C", app = "Fantastical" },
    { mods = { CMD, CTRL },      key = "Z", app = "zoom.us" },
    { mods = { CMD, CTRL },      key = "R", fn = hs.reload },
    { mods = { CMD, CTRL },      key = "C", tab = "https://calendar.google.com/" },
    { mods = { CMD, CTRL },      key = "M", tab = "https://mail.google.com/mail/u" },
    { mods = { CMD, CTRL },      key = "N", app = "Logseq" },

    { mods = { ALT },            key = "H", fn = wrapped(focusWindow, "west") },
    { mods = { ALT },            key = "L", fn = wrapped(focusWindow, "east") },
    { mods = { ALT },            key = "J", fn = wrapped(focusWindow, "south") },
    { mods = { ALT },            key = "K", fn = wrapped(focusWindow, "north") },

    { mods = { CMD, CTRL, ALT }, key = "C", fn = chrome.GetTabRichLink },
}
hs.fnutils.each(bindings, setBinding)

hs.alert.show("Config loaded")
