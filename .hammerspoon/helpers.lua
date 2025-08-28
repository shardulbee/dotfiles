local M = {}

-- Creates a function that executes an aerospace command.
-- @param args table A table of string arguments for the aerospace command.
-- @return function A function that, when called, runs the specified aerospace command.
function M.aerospace(args)
  return function()
    local t = hs.task.new("/usr/local/bin/aerospace", nil, args)
    t:start()
  end
end

-- Creates a function that launches or focuses an application by name.
-- @param name string The name of the application to launch or focus.
-- @return function A function that, when called, launches or focuses the specified application.
function M.launchOrFocusApp(name)
  return function()
    hs.application.launchOrFocus(name)
  end
end

-- Creates a function that opens a URL.
-- @param url string The URL to open.
-- @return function A function that, when called, opens the specified URL.
function M.openUrl(url)
  return function()
    hs.urlevent.openURL(url)
  end
end

return M
