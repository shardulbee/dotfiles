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

local common = {
  ["s"] = {
    "spotify",
    {
      ["p"] = {
        "playlistadd",
        openUrl("raycast://extensions/mattisssa/spotify-player/addPlayingSongToPlaylist"),
      },
      ["n"] = {
        "now playing",
        openUrl("raycast://extensions/mattisssa/spotify-player/nowPlaying"),
      },
    },
  },
  ["f"] = {
    "search files",
    openUrl("raycast://extensions/raycast/file-search/search-files"),
  },
  ["c"] = { "clipboard", openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history") },
  ["h"] = {
    "hammerspoon",
    {
      ["c"] = { "console", hs.toggleConsole },
      ["r"] = { "reload", hs.reload },
      ["p"] = { "popclick", popclickPlayPause },
    },
  },
  ["r"] = {
    "raycast",
    {
      ["e"] = { "emoji", openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols") },
      ["c"] = {
        "capture",
        {
          ["v"] = { "video", openUrl("raycast://extensions/Aayush9029/cleanshotx/record-screen") },
          ["c"] = {
            "capture",
            openUrl(
              "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22copy%22%7D"
            ),
          },
          ["a"] = {
            "annotate",
            openUrl(
              "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22annotate%22%7D"
            ),
          },
          ["s"] = {
            "save",
            openUrl(
              "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22save%22%7D"
            ),
          },
          ["f"] = {
            "find",
            openUrl("raycast://extensions/raycast/file-search/search-files?fallbackText=cleanshot"),
          },
        },
      },
    },
  },
  ["b"] = {
    "browser",
    {
      ["b"] = { "bookmarks", openUrl("raycast://extensions/raycast/browser-bookmarks/index") },
      ["c"] = { "copy tab title", chrome.CopyTabRichLink },
    },
  },
  ["w"] = {
    "window",
    {
      ["t"] = { "tiles", aerospace({ "layout", "tiles", "vertical", "horizontal" }) },
      ["s"] = { "stack", aerospace({ "layout", "accordion", "vertical", "horizontal" }) },
      ["f"] = { "float", aerospace({ "layout", "floating", "tiling" }) },
      ["r"] = { "reload", aerospace({ "reload-config" }) },
      ["j"] = {
        "join",
        {
          ["h"] = { "left", aerospace({ "join-with", "left" }) },
          ["j"] = { "down", aerospace({ "join-with", "down" }) },
          ["k"] = { "up", aerospace({ "join-with", "up" }) },
          ["l"] = { "right", aerospace({ "join-with", "right" }) },
        },
      },
    },
  },
  ["o"] = {
    "open",
    {
      -- ["f"] = { "finder", launchOrFocusApp("Finder") },
      ["f"] = { "focus", openUrl("raycast://extensions/raycast/raycast-focus/start-focus-session") },
      ["z"] = { "zoom", launchOrFocusApp("zoom.us") },
      ["n"] = { "notes", launchOrFocusApp("Obsidian") },
    },
  },
}

local dbnl = {
  ["o"] = {
    "open",
    {
      ["m"] = { "mail", chrome.LaunchOrFocusTab("https://mail.google.com") },
      ["s"] = { "slack", launchOrFocusApp("Slack") },
      ["c"] = { "calendar", chrome.LaunchOrFocusTab("https://calendar.google.com") },
      ["t"] = {
        "TODO",
        openUrl(
          "raycast://extensions/raycast/raycast-notes/raycast-notes?context=%7B%22id%22:%22655B9E55-B0D4-43D8-A276-04BBB7B5C392%22%7D"
        ),
      },
    },
  },
  ["z"] = {
    "zoom",
    {
      ["j"] = {
        "join",
        function()
          hs.eventtap.keyStroke({ "cmd", "ctrl", "alt", "cmd", "shift" }, "j")
        end,
      },
      ["c"] = {
        "calendar",
        function()
          hs.eventtap.keyStroke({ "cmd", "alt", "ctrl" }, "c")
        end,
      },
    },
  },
  ["d"] = {
    "dbnl",
    {
      ["r"] = { "repo", chrome.LaunchOrFocusTab("https://github.com/dbnlAI/dbnl-internal#") },
      ["s"] = {
        "aws sso",
        function()
          local task = hs.task.new("/usr/local/bin/aws", function(exitCode, _, _)
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
        end,
      },
      ["o"] = {
        "open+",
        {
          ["l"] = { "local", chrome.LaunchOrFocusTab("http://localhost:8080/") },
          ["r"] = { "remote", chrome.LaunchOrFocusTab("https://app-shardul.dev.dbnl.com") },
          ["d"] = { "dev", chrome.LaunchOrFocusTab("https://app.dev.dbnl.com") },
          ["p"] = { "prod", chrome.LaunchOrFocusTab("https://app.dbnl.com") },
        },
      },
    },
  },
  ["j"] = {
    "jira",
    {
      ["o"] = { "open issues", openUrl("raycast://extensions/raycast/jira/open-issues") },
      ["s"] = { "search", openUrl("raycast://extensions/raycast/jira/search-issues") },
    },
  },
}

local personal = {
  ["o"] = {
    "open",
    {
      ["m"] = { "mail", chrome.LaunchOrFocusTab("https://app.fastmail.com/mail/") },
      ["c"] = { "calendar", launchOrFocusApp("Fantastical") },
    },
  },
}

-- Function to merge nested mappings
local function mergeMappings(base, extra)
  local result = {}

  -- Copy all entries from base
  for k, v in pairs(base) do
    result[k] = v
  end

  -- Add or merge entries from extra
  for k, v in pairs(extra) do
    if result[k] == nil then
      -- Key doesn't exist in result, simply copy it
      result[k] = v
    elseif type(result[k]) == "table" and type(v) == "table" then
      if not (result[k][1] == v[1]) then
        hs.showError("Conflict for key: " .. k)
      end
      -- Both are tables with the same key format ([key] = {description, action})
      if type(result[k][1]) == "string" and type(v[1]) == "string" then
        -- If second element is a table in both, merge those tables recursively
        if type(result[k][2]) == "table" and type(v[2]) == "table" then
          result[k] = { result[k][1], mergeMappings(result[k][2], v[2]) }
        else
          -- Otherwise just use the extra value
          result[k] = v
        end
      end
    else
      hs.showError("Conflict for key: " .. k)
    end
  end

  return result
end

local function transform(t)
  local transformed = {}
  for keyChar, val in pairs(t) do
    local name = val[1]
    local childOrFn = val[2]

    if type(childOrFn) == "table" then
      -- Nested table => transform recursively
      transformed[singleKey(keyChar, name)] = transform(childOrFn)
    else
      -- It's presumably a function or a Raycast openUrl
      transformed[singleKey(keyChar, name)] = childOrFn
    end
  end
  return transformed
end

-- Create mappings based on host name
local finalMappings
if hs.host.localizedName() == "dbnl-shardul" then
  finalMappings = mergeMappings(common, dbnl)
else
  finalMappings = mergeMappings(common, personal)
end

hs.hotkey.bind({}, "f5", spoon.RecursiveBinder.recursiveBind(transform(finalMappings)))

Watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.alert.show(" ✔︎")
