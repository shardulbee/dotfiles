local chrome = require("chrome")

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
	},
	[singleKey("r", "raycast")] = {
		[singleKey("e", "emoji")] = openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"),
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
