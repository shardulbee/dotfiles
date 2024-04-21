M = {}

function M.FocusSpace(space)
	local spaceAsStr = tostring(space)
	local args = { "-m", "space", "--focus", spaceAsStr }
	hs.task
			.new("/usr/local/bin/yabai", function(_, stdOut, _)
				print(stdOut)
			end, args)
			:start()
			:waitUntilExit()
			:terminationStatus()
end

function M.FocusWindow(direction)
	local args = { "-m", "window", "--focus", direction }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
end

function M.FocusSpace(space)
	local spaceAsStr = tostring(space)
	local args = { "-m", "space", "--focus", spaceAsStr }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
end

function M.MoveWindow(space)
	local spaceAsStr = tostring(space)
	local args = { "-m", "window", "--space", spaceAsStr }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
end

function M.SwapWindow(direction)
	args = { "-m", "window", "--swap", direction }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit()
end

function M.NextWindow()
	query_args = { "-m", "query", "--spaces" }
	callbackFn = function(_, stdOut, _)
		spaces = hs.json.decode(stdOut)
		focusedSpace = hs.fnutils.find(spaces, function(space)
			return space["has-focus"]
		end)
		local nextWindowStr = "next"
		local firstWindowStr = "first"

		if focusedSpace["type"] == "stack" then
			nextWindowStr = "stack.next"
			firstWindowStr = "stack.first"
		end

		local args = { "-m", "window", "--focus", nextWindowStr }
		local success = hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus() == 0
		if not success then
			args = { "-m", "window", "--focus", firstWindowStr }
			hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
		end
	end
	hs.task.new("/usr/local/bin/yabai", callbackFn, query_args):start():waitUntilExit()
end

function M.ToggleZoom()
	local query_args = { "-m", "query", "--spaces" }
	local callbackFn = function(_, stdOut, _)
		local spaces = hs.json.decode(stdOut)
		local focusedSpace = hs.fnutils.find(spaces, function(space)
			return space["has-focus"]
		end)
		local spaceIndexStr = tostring(focusedSpace["index"])
		if focusedSpace["type"] == "stack" then
			hs.task
					.new("/usr/local/bin/yabai", nil, { "-m", "config", "--space", spaceIndexStr, "layout", "bsp" })
					:start()
					:waitUntilExit()
		else
			hs.task
					.new("/usr/local/bin/yabai", nil, { "-m", "config", "--space", spaceIndexStr, "layout", "stack" })
					:start()
					:waitUntilExit()
		end
	end
	hs.task.new("/usr/local/bin/yabai", callbackFn, query_args):start():waitUntilExit()
end

local function toggleWindowAttribute(attr)
	local args = { "-m", "window", "--toggle", attr }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit()
end

function M.ZoomFullscreen()
	toggleWindowAttribute("zoom-fullscreen")
end

function M.ToggleNotes()
	toggleWindowAttribute("notes")
end

function M.CycleStackBsp()
	local query_args = { "-m", "query", "--spaces" }
	local callbackFn = function(_, stdOut, _)
		local spaces = hs.json.decode(stdOut)
		local focusedSpace = hs.fnutils.find(spaces, function(space)
			return space["has-focus"]
		end)
		local spaceIndexStr = tostring(focusedSpace["index"])
		local layout = "stack"
		if focusedSpace["type"] == "stack" then
			layout = "bsp"
		end
		hs.task
				.new("/usr/local/bin/yabai", nil, { "-m", "config", "--space", spaceIndexStr, "layout", layout })
				:start()
				:waitUntilExit()
	end
	hs.task.new("/usr/local/bin/yabai", callbackFn, query_args):start():waitUntilExit()
end

return M
