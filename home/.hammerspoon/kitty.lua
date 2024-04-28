Kitty = {}

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

function Kitty.Run(runArgs)
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
		end, args)
		:start()
		:waitUntilExit()
		:terminationStatus() == 0
end

function Kitty.FocusWindowOrTab(title)
	if not title then
		return false
	end
	if Kitty.Run({ "focus-tab", "--match", string.format("title:%s", title) }) then
		return true
	end
	if Kitty.Run({ "focus-window", "--match", string.format("title:%s", title) }) then
		return true
	end
	return false
end

function Kitty.sendText(title, text)
	if not title or not text then
		return
	end
	return Kitty.Run({
		"send-text",
		"--match",
		string.format("title:%s", title),
		text,
	})
end

function Kitty.Launch(cwd, title, type, cmd, hold)
	local args = { "launch" }

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

	return Kitty.Run(args)
end

function Kitty.TodayNote()
	if not Kitty.FocusWindowOrTab("today-note") then
		Kitty.RunScript("today-note")
	end
end

function Kitty.RunScript(scriptname)
	Kitty.Launch(nil, scriptname, "tab", scriptname)
	Kitty.FocusWindowOrTab(scriptname)
end

return Kitty
