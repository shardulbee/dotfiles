Yabai = {}

function Yabai.QueryCurrentSpace()
	local space = nil
	local query_args = { "-m", "query", "--spaces", "--space", "mouse" }
	local callbackFn = function(_, stdOut, _)
		space = hs.json.decode(stdOut)
	end
	hs.task.new("/usr/local/bin/yabai", callbackFn, query_args):start():waitUntilExit()
	return space
end

function Yabai.NextWindow()
	local space = Yabai.QueryCurrentSpace()

	local nextWindowStr = "next"
	local firstWindowStr = "first"

	if space and space["type"] == "stack" then
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

function Yabai.CycleStackBsp()
	local focusedSpace = Yabai.QueryCurrentSpace()
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

function Yabai.FocusWindow(direction)
	local args = { "-m", "window", "--focus", direction }
	local status = hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
end

function Yabai.PrevSpace()
	local args = { "-m", "space", "--focus", "prev" }
	local status = hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
	if status == 0 then
		return
	end

	-- if focus previous space fails, go to last space
	args = { "-m", "space", "--focus", "last" }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit()
end

function Yabai.NextSpace()
	local args = { "-m", "space", "--focus", "next" }
	local status = hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
	if status == 0 then
		return
	end

	-- if focus next space fails, go to first space
	args = { "-m", "space", "--focus", "first" }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit()
end

function Yabai.SwapWindow(direction)
	local args = { "-m", "window", "--swap", direction }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
end

function Yabai.FocusSpace(index)
	local args = { "-m", "space", "--focus", tostring(index) }
	hs.task.new("/usr/local/bin/yabai", nil, args):start():waitUntilExit():terminationStatus()
end

return Yabai
