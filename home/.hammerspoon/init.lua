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

local function openPathInZed(path)
	return function()
		local task = hs.task.new("/opt/homebrew/bin/zed", function(_, stdout, stderr)
			if stdout then
				print(stdout)
			end
			if stderr then
				print(stderr)
			end
		end, { path })
		task:start()
	end
end

local keyMap = {
	-- p1 keys
	[singleKey("space", "scratch note")] = openUrl("raycast://extensions/raycast/raycast-notes/raycast-notes"),
	[singleKey("d", "daily note")] = openUrl("obsidian://daily"),
	[singleKey("c", "clipboard")] = openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history"),
	[singleKey("f", "search files")] = openUrl("raycast://extensions/raycast/file-search/search-files"),
	[singleKey("s", "safari")] = launchOrFocusApp("Safari"),
	[singleKey("t", "ticklertask")] = function()
		local _, text = hs.dialog.textPrompt("Task", "Enter your task:", "", "OK", "Cancel", false)

		if text then
			local params = string.format('{"text":"%s", "dueDate": ""}', text)
			local encodedParams = hs.http.encodeForQuery(params)
			local url = string.format(
				"raycast://extensions/KevinBatdorf/obsidian/appendTaskCommand?arguments=%s",
				encodedParams
			)
			hs.urlevent.openURL(url)
		end
	end,
	[singleKey("e", "edit")] = {
		[singleKey("d", "dotfiles")] = openPathInZed("/Users/shardul/dotfiles"),
	},
	[singleKey("o", "open")] = {
		[singleKey("i", "messages")] = launchOrFocusApp("Messages"),
		[singleKey("s", "slack")] = launchOrFocusApp("Spotify"),
		[singleKey("c", "calendar")] = launchOrFocusApp("Fantastical"),
		[singleKey("m", "mail")] = chrome.LaunchOrFocusTab("https://app.fastmail.com/mail/"),
		[singleKey("z", "open")] = launchOrFocusApp("zoom.us"),
		[singleKey("n", "notes")] = launchOrFocusApp("Obsidian"),
	},
	[singleKey("h", "hammerspoon")] = {
		[singleKey("c", "console")] = hs.toggleConsole,
		[singleKey("r", "console")] = hs.reload,
		[singleKey("e", "edit")] = openPathInZed("/Users/shardul/dotfiles/home/.hammerspoon/init.lua"),
		[singleKey("m", "mouse")] = function() end,
	},
	[singleKey("r", "raycast")] = {
		[singleKey("e", "emoji")] = openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"),
		[singleKey("r", "ai chat")] = openUrl("raycast://extensions/raycast/raycast-ai/ai-chat"),
		[singleKey("f", "search files")] = openUrl("raycast://extensions/raycast/file-search/search-files"),
		[singleKey("m", "search menu")] = openUrl("raycast://extensions/raycast/navigation/search-menu-items"),
		[singleKey("t", "timers")] = openUrl("raycast://extensions/ThatNerd/timers/manageTimers"),
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
		[singleKey("t", "tabs")] = openUrl("raycast://extensions/Codely/google-chrome/search-tab"),
		[singleKey("c", "copy tab title")] = chrome.CopyTabRichLink,
	},
	[singleKey("w", "window")] = {
		[singleKey("f", "float")] = aerospace({ "layout", "floating", "tiling" }),
		[singleKey("r", "reload")] = aerospace({ "reload-config" }),
		[singleKey("l", "layout")] = {
			[singleKey("t", "tiles")] = aerospace({ "layout", "tiles", "vertical", "horizontal" }),
			[singleKey("s", "stack")] = aerospace({ "layout", "accordion", "vertical", "horizontal" }),
		},
		[singleKey("s", "space")] = {
			[singleKey("tab", "next")] = aerospace({ "move-workspace-to-monitor", "next", "--wrap-around" }),
		},
		[singleKey("m", "monitor")] = {
			[singleKey("l", "right")] = aerospace({ "move-node-to-monitor", "right" }),
			[singleKey("h", "left")] = aerospace({ "move-node-to-monitor", "left" }),
		},
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
