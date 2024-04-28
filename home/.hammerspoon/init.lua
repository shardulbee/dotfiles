local yabai = require("yabai")
local timer = require("hs.timer")
local popclick = require("hs.noises")
local eventtap = require("hs.eventtap")
local chrome = require("chrome")
local kitty = require("kitty")

local function newScroller(delay, tick)
	return { delay = delay, tick = tick, timer = nil }
end

local function startScroll(scroller)
	if scroller.timer == nil then
		scroller.timer = timer.doEvery(scroller.delay, function()
			eventtap.scrollWheel({ 0, scroller.tick }, {}, "pixel")
		end)
	end
end

local function stopScroll(scroller)
	if scroller.timer then
		scroller.timer:stop()
		scroller.timer = nil
	end
end

Listener = nil
local popclickListening = false
local tssScrollDown = newScroller(0.02, -10)
local function scrollHandler(evNum)
	if evNum == 1 then
		startScroll(tssScrollDown)
	elseif evNum == 2 then
		stopScroll(tssScrollDown)
	elseif evNum == 3 then
		eventtap.scrollWheel({ 0, 250 }, {}, "pixel")
	end
end

local function popclickInit()
	popclickListening = false
	-- local fn = wrap(scrollHandler)
	local fn = scrollHandler
	Listener = popclick.new(fn)
end

local function popclickPlayPause()
	if not popclickListening then
		Listener:start()
		hs.alert.show("Popclick listening.")
	else
		Listener:stop()
		hs.alert.show("Popclick stopped listening.")
	end
	popclickListening = not popclickListening
end

local function launchOrActivate(appName)
	return function()
		hs.application.launchOrFocus(appName)
	end
end

local function wrapped(fn, args)
	local wrapped_fn = function()
		fn(args)
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
	{ mods = { ALT },            key = "H",     fn = wrapped(yabai.FocusWindow, "west") },
	{ mods = { ALT },            key = "L",     fn = wrapped(yabai.FocusWindow, "east") },
	{ mods = { ALT },            key = "J",     fn = wrapped(yabai.FocusWindow, "south") },
	{ mods = { ALT },            key = "K",     fn = wrapped(yabai.FocusWindow, "north") },
	{ mods = { ALT },            key = "N",     fn = yabai.NextWindow },

	{ mods = { ALT },            key = "0",     app = "Kitty" },
	{ mods = { ALT },            key = "1",     app = "Visual Studio Code" },
	{ mods = { ALT },            key = "3",     app = "Google Chrome" },
	{ mods = { ALT },            key = "6",     fn = hs.toggleConsole },
	{ mods = { ALT },            key = "Z",     tab = "https://recurse.zulipchat.com/" },

	{ mods = { ALT, SHIFT },     key = "L",     fn = wrapped(yabai.SwapWindow, "east") },
	{ mods = { ALT, SHIFT },     key = "H",     fn = wrapped(yabai.SwapWindow, "west") },
	{ mods = { ALT, SHIFT },     key = "J",     fn = wrapped(yabai.SwapWindow, "south") },
	{ mods = { ALT, SHIFT },     key = "K",     fn = wrapped(yabai.SwapWindow, "north") },
	{ mods = { ALT, SHIFT },     key = "space", fn = yabai.CycleStackBsp },

	{ mods = { CMD, CTRL },      key = "R",     fn = hs.reload },
	{ mods = { CMD, CTRL },      key = "F",     app = "Finder" },
	{ mods = { CMD, CTRL },      key = "C",     app = "Fantastical" },
	{ mods = { CMD, CTRL },      key = "P",     fn = popclickPlayPause },
	{ mods = { CMD, CTRL },      key = "Z",     app = "zoom.us" },
	{ mods = { CMD, CTRL },      key = "T",     tab = "https://rcverse.recurse.com/" },

	{ mods = { CMD, ALT },       key = "left",  fn = yabai.PrevSpace },
	{ mods = { CMD, ALT },       key = "right", fn = yabai.NextSpace },
	{ mods = { CMD, ALT },       key = "space", url = "things:///add?when=today&list=Random&show-quick-entry=true" },

	{ mods = { CMD, CTRL, ALT }, key = "C",     fn = chrome.GetTabRichLink },
}
hs.fnutils.each(bindings, setBinding)

local function init()
	popclickInit()
	hs.alert.show("Config loaded")
end

init()
