local chrome = require("chrome")
local noises = require("hs.noises")
local timer = require("hs.timer")
local eventtap = require("hs.eventtap")

hs.loadSpoon("RecursiveBinder")
spoon.RecursiveBinder.escapeKey = { {}, "escape" } -- Press escape to abort
local singleKey = spoon.RecursiveBinder.singleKey

local function launchOrFocusApp(appName)
	return function()
		hs.application.launchOrFocus(appName)
	end
end

local function openUrl(url)
	return function()
		hs.urlevent.openURL(url)
	end
end

local function aerospace(args)
	return function()
		local task = hs.task.new("/opt/homebrew/bin/aerospace", nil, args)
		task:start()
	end
end

local function newScroller(delay, tick)
	return { delay = delay, tick = tick, timer = nil }
end

Listener = nil
PopclickListening = false
TssScrollDown = newScroller(0.02, -10)

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

local function scrollHandler(evNum)
	-- alert.show(tostring(evNum))
	if evNum == 1 then
		startScroll(TssScrollDown)
	elseif evNum == 2 then
		stopScroll(TssScrollDown)
	elseif evNum == 3 then
		if hs.application.frontmostApplication():name() == "ReadKit" then
			eventtap.keyStroke({}, "j")
		else
			eventtap.scrollWheel({ 0, 250 }, {}, "pixel")
		end
	end
end

local function popclickInit()
	PopclickListening = false
	local fn = scrollHandler
	Listener = noises.new(fn)
end
popclickInit()

local function popclickPlayPause()
	if not PopclickListening then
		Listener:start()
		hs.alert.show("listening")
	else
		Listener:stop()
		hs.alert.show("stopped listening")
	end
	PopclickListening = not PopclickListening
end

local keyMap = {
	-- top level
	[singleKey("f", "search files")] = openUrl("raycast://extensions/raycast/file-search/search-files"),
	[singleKey("c", "clipboard")] = openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history"),
	[singleKey("d", "daily note")] = openUrl("obsidian://daily"),

	[singleKey("o", "open")] = {
		[singleKey("f", "finder")] = launchOrFocusApp("Finder"),
		[singleKey("m", "mail")] = chrome.LaunchOrFocusTab("https://app.fastmail.com/mail/"),
		[singleKey("c", "calendar")] = launchOrFocusApp("Fantastical"),
		[singleKey("n", "notes")] = launchOrFocusApp("Obsidian"),
	},
	[singleKey("h", "hammerspoon")] = {
		[singleKey("c", "console")] = hs.toggleConsole,
		[singleKey("r", "console")] = hs.reload,
		[singleKey("p", "popclick")] = popclickPlayPause,
	},
	[singleKey("r", "raycast")] = {
		[singleKey("e", "emoji")] = openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"),
		[singleKey("p", "pomodoro")] = openUrl("raycast://extensions/asubbotin/pomodoro/pomodoro-control-timer"),
		[singleKey("c", "capture")] = {
			[singleKey("v", "video")] = openUrl("raycast://extensions/Aayush9029/cleanshotx/record-screen"),
			[singleKey("c", "copy")] = openUrl(
				"raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22copy%22%7D"
			),
			[singleKey("a", "annotate")] = openUrl(
				"raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22annotate%22%7D"
			),
			[singleKey("s", "save")] = openUrl(
				"raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22save%22%7D"
			),
			[singleKey("f", "find")] = openUrl(
				"raycast://extensions/raycast/file-search/search-files?fallbackText=cleanshot"
			),
		},
	},
	[singleKey("b", "browser")] = {
		[singleKey("b", "bookmarks")] = openUrl("raycast://extensions/raycast/browser-bookmarks/index"),
		[singleKey("c", "copy tab title")] = chrome.CopyTabRichLink,
	},
	[singleKey("w", "window")] = {
		[singleKey("t", "tiles")] = aerospace({ "layout", "tiles", "vertical", "horizontal" }),
		[singleKey("s", "stack")] = aerospace({ "layout", "accordion", "vertical", "horizontal" }),
		[singleKey("f", "float")] = aerospace({ "layout", "floating", "tiling" }),
		[singleKey("r", "reload")] = aerospace({ "reload-config" }),
		[singleKey("j", "join")] = {
			[singleKey("h", "left")] = aerospace({ "join-with", "left" }),
			[singleKey("j", "down")] = aerospace({ "join-with", "down" }),
			[singleKey("k", "up")] = aerospace({ "join-with", "up" }),
			[singleKey("l", "right")] = aerospace({ "join-with", "right" }),
		},
	},
}

hs.hotkey.bind({}, "f5", spoon.RecursiveBinder.recursiveBind(keyMap))

Watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.alert.show(" ✔︎")
