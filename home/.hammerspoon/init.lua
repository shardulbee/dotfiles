local chrome = require("chrome")

local function connectAwsSso()
	local task = hs.task.new("/opt/homebrew/bin/aws", function(exitCode, _, _)
		if exitCode == 0 then
			hs.alert.show("AWS SSO Login Successful", {
				atScreenEdge = 2,
				strokeColor = { white = 0, alpha = 2 },
				textFont = "Courier",
				textSize = 20,
			})
		else
			hs.alert.show("AWS SSO Login Failed", {
				atScreenEdge = 2,
				strokeColor = { white = 0, alpha = 2 },
			})
		end
	end, { "sso", "login", "--profile", "app-dev" })
	task:start()
	hs.timer.doAfter(20, function()
		task:terminate()
	end)
end

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

	[singleKey("z", "zoom")] = {
		[singleKey("j", "join")] = function()
			hs.eventtap.keyStroke({ "cmd", "ctrl", "alt", "cmd", "shift" }, "j")
		end,
		[singleKey("c", "calendar")] = function()
			hs.eventtap.keyStroke({ "cmd", "alt", "ctrl" }, "c")
		end,
	},
	[singleKey("o", "open")] = {
		[singleKey("f", "finder")] = launchOrFocusApp("Finder"),
		[singleKey("m", "mail")] = launchOrFocusApp("Mimestream"),
		[singleKey("s", "slack")] = launchOrFocusApp("Slack"),
		[singleKey("c", "calendar")] = chrome.LaunchOrFocusTab("https://calendar.google.com"),
		[singleKey("z", "zoom")] = launchOrFocusApp("zoom.us"),
		[singleKey("n", "notes")] = launchOrFocusApp("Obsidian"),
	},
	[singleKey("h", "hammerspoon")] = {
		[singleKey("c", "console")] = hs.toggleConsole,
		[singleKey("r", "console")] = hs.reload,
	},
	[singleKey("d", "dbnl")] = {
		[singleKey("s", "aws sso")] = connectAwsSso,
		[singleKey("o", "open+")] = {
			[singleKey("l", "local")] = openUrl("http://localhost:8080/"),
			[singleKey("r", "remote")] = openUrl("https://app-shardul.dev.dbnl.com"),
			[singleKey("d", "dev")] = openUrl("https://app.dev.dbnl.com"),
			[singleKey("p", "prod")] = openUrl("https://app.dbnl.com"),
		},
	},
	[singleKey("r", "raycast")] = {
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
	[singleKey("j", "jira")] = {
		[singleKey("o", "open issues")] = openUrl("raycast://extensions/raycast/jira/open-issues"),
		[singleKey("s", "search")] = openUrl("raycast://extensions/raycast/jira/search-issues"),
	},
}

hs.hotkey.bind({}, "f5", spoon.RecursiveBinder.recursiveBind(keyMap))

Watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.alert.show(" ✔︎")
