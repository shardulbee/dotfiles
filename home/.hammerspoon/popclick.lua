Popclick = {}

local timer = require("hs.timer")
local popclick = require("hs.noises")
local eventtap = require("hs.eventtap")

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

popclickListening = false
local fn = scrollHandler
Listener = popclick.new(fn)

function Popclick.Toggle()
	if not popclickListening then
		Listener:start()
		hs.alert.show("Popclick listening.")
	else
		Listener:stop()
		hs.alert.show("Popclick stopped listening.")
	end
	popclickListening = not popclickListening
end

return Popclick
