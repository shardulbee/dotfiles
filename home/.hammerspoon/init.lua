local kitty = require("kitty")
local yabai = require("yabai")
local timer = require("hs.timer")
local popclick = require("hs.noises")
local eventtap = require("hs.eventtap")
local chrome = require("chrome")
-- local focus = require("focus")

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

local function kittySock()
	local lines = {}
	for line in io.popen([[ls /tmp | grep mykitty]]):lines() do
		table.insert(lines, line)
	end

	if not lines or #lines == 0 then
		print("Cannot find a kitty socket. Terminating.")
		hs.application.launchOrFocus("Kitty")

		lines = {}

		-- while loop to wait for the lines to not be empty
		while not lines or #lines == 0 do
			for line in io.popen([[ls /tmp | grep mykitty]]):lines() do
				table.insert(lines, line)
			end
		end
	end

	return "unix:/tmp/mykitty"
end

function KittyRun(runArgs)
	local sock = kittySock()
	if not sock then
		return
	end

	local args = { "@", "--to", sock }
	for _, arg in ipairs(runArgs) do
		table.insert(args, arg)
	end

	return hs.task
			.new("/usr/local/bin/kitty", function(exitCode, stdOut, stdErr)
				print("exitCode: ", exitCode, "stdOut:", stdOut, "stdErr:", stdErr)
			end, function(exitCode, stdOut, stdErr)
				print("exitCode: ", exitCode, "stdOut:", stdOut, "stdErr:", stdErr)
				return true
			end, args)
			:start()
			:waitUntilExit()
			:terminationStatus() == 0
end

function Launch(cwd, title, type, cmd, hold, extraArgs)
	local args = { "launch" }

	if #extraArgs > 0 then
		for _, arg in ipairs(extraArgs) do
			print(arg)
			table.insert(args, arg)
		end
	end

	if hold then
		table.insert(args, "--hold")
	end

	if cwd then
		table.insert(args, string.format("--cwd=%s", cwd))
	else
		table.insert(args, "--cwd=current")
	end

	if title then
		table.insert(args, string.format("--title=%s", title))
	end

	if type then
		table.insert(args, string.format("--type=%s", type))
	else
		table.insert(args, "--type=tab")
	end

	if cmd then
		table.insert(args, "zsh")
		table.insert(args, "--login")
		table.insert(args, "-c")
		table.insert(args, cmd)
	end

	KittyRun(args)
end

-- ##################################################################
-- alt bindings
-- #################################################################
for hotkey, appName in pairs({
	["1"] = wrapped(yabai.FocusSpace, 1),
	["2"] = wrapped(yabai.FocusSpace, 2),
	["3"] = wrapped(yabai.FocusSpace, 3),
	["4"] = wrapped(yabai.FocusSpace, 4),
	["5"] = wrapped(yabai.FocusSpace, 5),
	["6"] = wrapped(yabai.FocusSpace, 6),
	["7"] = wrapped(yabai.FocusSpace, 7),
	["8"] = wrapped(yabai.FocusSpace, 8),
	["9"] = wrapped(yabai.FocusSpace, 9),
	["0"] = wrapped(yabai.FocusSpace, 10),
	["H"] = wrapped(yabai.FocusWindow, "west"),
	["L"] = wrapped(yabai.FocusWindow, "east"),
	["J"] = wrapped(yabai.FocusWindow, "south"),
	["K"] = wrapped(yabai.FocusWindow, "north"),
	["N"] = yabai.NextWindow,
	["Z"] = chrome.LaunchOrFocusTab("https://recurse.zulipchat.com/"),
}) do
	hs.hotkey.bind("option", hotkey, appName)
end

-- ##################################################################
-- alt + shift bindings
-- #################################################################
for hotkey, lambda in pairs({
	["1"] = wrapped(yabai.MoveWindow, 1),
	["2"] = wrapped(yabai.MoveWindow, 2),
	["3"] = wrapped(yabai.MoveWindow, 3),
	["4"] = wrapped(yabai.MoveWindow, 4),
	["5"] = wrapped(yabai.MoveWindow, 5),
	["6"] = wrapped(yabai.MoveWindow, 6),
	["7"] = wrapped(yabai.MoveWindow, 7),
	["8"] = wrapped(yabai.MoveWindow, 8),
	["9"] = wrapped(yabai.MoveWindow, 9),
	["0"] = wrapped(yabai.MoveWindow, 10),
	["H"] = wrapped(yabai.SwapWindow, "west"),
	["L"] = wrapped(yabai.SwapWindow, "east"),
	["J"] = wrapped(yabai.SwapWindow, "south"),
	["K"] = wrapped(yabai.SwapWindow, "north"),
	["space"] = yabai.CycleStackBsp,
	["Z"] = yabai.ZoomFullscreen,
	["N"] = yabai.ToggleNotes,
	["C"] = hs.toggleConsole,
	["P"] = yabai.TogglePip,

	["T"] = function()
		if not KittyRun({ "focus-window", "--match", 'title:"daily\\snote"' }) then
			Launch(
				"/Users/shardul/gdrive/notes",
				"daily note",
				"tab",
				"today-note",
				false,
				{ "--match", "title:^notes$" }
			)
		end
		yabai.FocusNotesIfNotFocused()
	end,
}) do
	hs.hotkey.bind({ "option", "shift" }, hotkey, lambda)
end

-- ##################################################################
-- cmd + ctrl bindings
-- #################################################################
for hotkey, lambda in pairs({
	R = function()
		hs.reload()
	end,
	F = launchOrActivate("Finder"),
	C = launchOrActivate("Fantastical"),
	P = popclickPlayPause,
	Z = launchOrActivate("zoom.us"),
	T = chrome.LaunchOrFocusTab("https://rcverse.recurse.com/"),
}) do
	hs.hotkey.bind({ "cmd", "ctrl" }, hotkey, lambda)
end

-- ##################################################################
-- Super (cmd + ctrl + alt) bindings
-- #################################################################
for hotkey, lambda in pairs({
	C = chrome.GetTabRichLink,
}) do
	hs.hotkey.bind({ "cmd", "ctrl", "alt" }, hotkey, lambda)
end

popclickInit()
hs.alert.show("Config loaded")
