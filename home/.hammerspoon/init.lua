local yabai = require("yabai")
local chrome = require("chrome")
local kitty = require("kitty")
local popclick = require("popclick")

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
	if direction == "west" then
		hs.window.focusedWindow():focusWindowWest(nil, true, true)
	elseif direction == "east" then
		hs.window.focusedWindow():focusWindowEast(nil, true, true)
	elseif direction == "north" then
		hs.window.focusedWindow():focusWindowNorth(nil, true, true)
	elseif direction == "south" then
		hs.window.focusedWindow():focusWindowSouth(nil, true, true)
	else
		print("Invalid direction")
	end
end

local function nextWindow()
	local windows = hs.window.orderedWindows()
	local window = windows[#windows]
	if window then
		window:focus()
	end
end

local bindings = {
	{ mods = { ALT }, key = "0", app = "Kitty" },
	{ mods = { ALT }, key = "1", app = "Visual Studio Code" },
	{ mods = { ALT }, key = "3", app = "Google Chrome" },
	{ mods = { ALT }, key = "8", app = "Messages" },
	{ mods = { ALT }, key = "6", fn = hs.toggleConsole },
	{ mods = { ALT }, key = "Z", tab = "https://recurse.zulipchat.com/" },
	{ mods = { ALT }, key = "N", fn = nextWindow },

	{ mods = { CMD, ALT }, key = "space", url = "things:///add?when=today&list=Random&show-quick-entry=true" },

	{ mods = { CMD, CTRL }, key = "F", app = "Finder" },
	{ mods = { CMD, CTRL }, key = "C", app = "Fantastical" },
	{ mods = { CMD, CTRL }, key = "P", fn = popclick.Toggle },
	{ mods = { CMD, CTRL }, key = "Z", app = "zoom.us" },
	{ mods = { CMD, CTRL }, key = "V", tab = "https://rcverse.recurse.com/" },
	{ mods = { CMD, CTRL }, key = "N", fn = wrapped(kitty.FocusWindowOrTab, "notes") },
	{ mods = { CMD, CTRL }, key = "O", fn = wrapped(kitty.RunScript, "change-repo") },
	{ mods = { CMD, CTRL }, key = "T", fn = wrapped(kitty.TodayNote) },
	{ mods = { CMD, CTRL }, key = "R", fn = hs.reload },
	{ mods = { CMD, CTRL }, key = "M", tab = "https://app.fastmail.com/mail/Inbox/?u=00a94062" },

	{ mods = { ALT }, key = "H", fn = wrapped(focusWindow, "west") },
	{ mods = { ALT }, key = "L", fn = wrapped(focusWindow, "east") },
	{ mods = { ALT }, key = "J", fn = wrapped(focusWindow, "south") },
	{ mods = { ALT }, key = "K", fn = wrapped(focusWindow, "north") },

	{ mods = { CMD, CTRL, ALT }, key = "C", fn = chrome.GetTabRichLink },
}
hs.fnutils.each(bindings, setBinding)

hs.alert.show("Config loaded")
