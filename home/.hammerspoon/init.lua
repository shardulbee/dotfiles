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

local bindings = {
	-- { mods = { ALT }, key = "0", app = "Kitty" },
	-- { mods = { ALT }, key = "1", app = "Visual Studio Code" },
	-- { mods = { ALT }, key = "3", app = "Google Chrome" },
	--
	{ mods = { CTRL },           key = "right", fn = yabai.NextSpace },
	{ mods = { CTRL },           key = "left",  fn = yabai.PrevSpace },

	{ mods = { ALT },            key = "H",     fn = wrapped(yabai.FocusWindow, "west") },
	{ mods = { ALT },            key = "L",     fn = wrapped(yabai.FocusWindow, "east") },
	{ mods = { ALT },            key = "J",     fn = wrapped(yabai.FocusWindow, "south") },
	{ mods = { ALT },            key = "K",     fn = wrapped(yabai.FocusWindow, "north") },
	{ mods = { ALT },            key = "N",     fn = yabai.NextWindow },

	{ mods = { ALT },            key = "1",     fn = wrapped(yabai.FocusSpace, 1) },
	{ mods = { ALT },            key = "2",     fn = wrapped(yabai.FocusSpace, 2) },
	{ mods = { ALT },            key = "3",     fn = wrapped(yabai.FocusSpace, 3) },
	{ mods = { ALT },            key = "4",     fn = wrapped(yabai.FocusSpace, 4) },
	{ mods = { ALT },            key = "5",     fn = wrapped(yabai.FocusSpace, 5) },
	{ mods = { ALT },            key = "6",     fn = wrapped(yabai.FocusSpace, 6) },
	{ mods = { ALT },            key = "7",     fn = wrapped(yabai.FocusSpace, 7) },
	{ mods = { ALT },            key = "8",     fn = wrapped(yabai.FocusSpace, 8) },
	{ mods = { ALT },            key = "9",     fn = wrapped(yabai.FocusSpace, 9) },
	{ mods = { ALT },            key = "0",     fn = wrapped(yabai.FocusSpace, 10) },
	{ mods = { ALT },            key = "T",     fn = Yabai.ToggleFloat },
	{ mods = { ALT },            key = "C",     fn = hs.toggleConsole },
	{ mods = { ALT },            key = "Z",     tab = "https://recurse.zulipchat.com/" },

	{ mods = { ALT, SHIFT },     key = "1",     fn = wrapped(yabai.MoveWindowToSpace, 1) },
	{ mods = { ALT, SHIFT },     key = "2",     fn = wrapped(yabai.MoveWindowToSpace, 2) },
	{ mods = { ALT, SHIFT },     key = "3",     fn = wrapped(yabai.MoveWindowToSpace, 3) },
	{ mods = { ALT, SHIFT },     key = "4",     fn = wrapped(yabai.MoveWindowToSpace, 4) },
	{ mods = { ALT, SHIFT },     key = "5",     fn = wrapped(yabai.MoveWindowToSpace, 5) },
	{ mods = { ALT, SHIFT },     key = "6",     fn = wrapped(yabai.MoveWindowToSpace, 6) },
	{ mods = { ALT, SHIFT },     key = "7",     fn = wrapped(yabai.MoveWindowToSpace, 7) },
	{ mods = { ALT, SHIFT },     key = "8",     fn = wrapped(yabai.MoveWindowToSpace, 8) },
	{ mods = { ALT, SHIFT },     key = "9",     fn = wrapped(yabai.MoveWindowToSpace, 9) },
	{ mods = { ALT, SHIFT },     key = "0",     fn = wrapped(yabai.MoveWindowToSpace, 10) },
	{ mods = { ALT, SHIFT },     key = "L",     fn = wrapped(yabai.SwapWindow, "east") },
	{ mods = { ALT, SHIFT },     key = "H",     fn = wrapped(yabai.SwapWindow, "west") },
	{ mods = { ALT, SHIFT },     key = "J",     fn = wrapped(yabai.SwapWindow, "south") },
	{ mods = { ALT, SHIFT },     key = "K",     fn = wrapped(yabai.SwapWindow, "north") },
	{ mods = { ALT, SHIFT },     key = "space", fn = yabai.CycleStackBsp },

	{ mods = { CMD, CTRL },      key = "F",     app = "Finder" },
	{ mods = { CMD, CTRL },      key = "C",     app = "Fantastical" },
	{ mods = { CMD, CTRL },      key = "P",     fn = popclick.Toggle },
	{ mods = { CMD, CTRL },      key = "Z",     app = "zoom.us" },
	{ mods = { CMD, CTRL },      key = "T",     tab = "https://rcverse.recurse.com/" },
	{ mods = { CMD, CTRL },      key = "N",     fn = wrapped(kitty.FocusWindowOrTab, "notes") },
	{ mods = { CMD, CTRL },      key = "D",     fn = wrapped(kitty.FocusWindowOrTab, "dotfiles") },
	{ mods = { CMD, CTRL },      key = "O",     fn = wrapped(kitty.RunScript, "change-repo") },

	{ mods = { CMD, ALT },       key = "left",  fn = yabai.PrevSpace },
	{ mods = { CMD, ALT },       key = "right", fn = yabai.NextSpace },
	{ mods = { CMD, ALT },       key = "space", url = "things:///add?when=today&list=Random&show-quick-entry=true" },

	{ mods = { CMD, CTRL, ALT }, key = "T",     fn = wrapped(kitty.TodayNote) },
	{ mods = { CMD, CTRL, ALT }, key = "C",     fn = chrome.GetTabRichLink },
	{ mods = { CMD, CTRL, ALT }, key = "R",     fn = hs.reload },
}
hs.fnutils.each(bindings, setBinding)

hs.alert.show("Config loaded")
