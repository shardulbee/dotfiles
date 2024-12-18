local chrome = require("chrome")

local function connectAwsSso()
  local task = hs.task.new("/usr/local/bin/aws", function(exitCode, _, _)
    if exitCode == 0 then
      hs.alert.show("AWS SSO Login Successful", {
        atScreenEdge = 2,
        strokeColor = { white = 0, alpha = 2 },
        textFont = 'Courier',
        textSize = 20
      })
    else
      hs.alert.show("AWS SSO Login Failed", {
        atScreenEdge = 2,
        strokeColor = { white = 0, alpha = 2 },
      })
    end
  end, { "sso", "login", "--profile", "app-dev" })
  task:start()
  hs.timer.doAfter(20, function() task:terminate() end)
end

hs.loadSpoon("RecursiveBinder")

spoon.RecursiveBinder.escapeKey = { {}, 'escape' } -- Press escape to abort

local singleKey = spoon.RecursiveBinder.singleKey

local function launchOrFocusApp(appName)
  return function() hs.application.launchOrFocus(appName) end
end

local function openUrl(url)
  return function() hs.urlevent.openURL(url) end
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
      if stdout then print(stdout) end
      if stderr then print(stderr) end
    end, { path })
    task:start()
  end
end


local function captureUrl()
  local title, url, selectedText = Chrome.GetTabTitleAndUrl()
  local deeplink = "logseq://x-callback-url/quickCapture?title=" .. title .. "&url=" .. url
  if selectedText then
    deeplink = deeplink .. "&content=" .. selectedText
  end
  hs.urlevent.openURL(deeplink)
end

local function captureClipboard()
  local clipboardText = hs.pasteboard.getContents()
  local deeplink = "logseq://x-callback-url/quickCapture?content=" .. clipboardText
  hs.urlevent.openURL(deeplink)
end

local keyMap = {
  [singleKey('e', 'edit')] = {
    [singleKey('d', 'dotfiles')] = openPathInZed("/Users/shardul/dotfiles"),
    [singleKey('i', 'internal')] = openPathInZed("/Users/shardul/src/github.com/dbnlAI/dbnl-internal"),
    [singleKey('s', 'sdk')] = openPathInZed("/Users/shardul/src/github.com/dbnlAI/dbnl-sdk"),
  },
  [singleKey('o', 'open')] = {
    [singleKey('b', 'browser')] = launchOrFocusApp("Google Chrome"),
    [singleKey('t', 'terminal')] = launchOrFocusApp("Ghostty"),
    [singleKey('m', 'mail')] = launchOrFocusApp("Mimestream"),
    [singleKey('s', 'slack')] = launchOrFocusApp("Slack"),
    [singleKey('c', 'calendar')] = chrome.LaunchOrFocusTab("https://calendar.google.com"),
    [singleKey('e', 'zed')] = launchOrFocusApp("Zed"),
    [singleKey('z', 'zoom')] = {
      [singleKey('z', 'open')] = launchOrFocusApp("zoom.us"),
      [singleKey('j', 'join')] = function() hs.eventtap.keyStroke({ "cmd", "alt", "cmd", "shift" }, "j") end,
      [singleKey('c', 'calendar')] = function() hs.eventtap.keyStroke({ "cmd", "alt", "ctrl", }, "c") end,
    },
  },
  [singleKey('h', 'hammerspoon')] = {
    [singleKey('c', 'console')] = hs.toggleConsole,
    [singleKey('r', 'console')] = hs.reload
  },
  [singleKey('d', 'dbnl')] = {
    [singleKey('v', 'connect vpn')] = function() hs.eventtap.keyStroke({ "cmd", "ctrl", "alt" }, "v") end,
    [singleKey('s', 'aws sso')] = connectAwsSso,
    [singleKey('o', 'open+')] = {
      [singleKey('l', 'local')] = openUrl("http://localhost:5173/"),
      [singleKey('r', 'remote')] = openUrl("https://app-shardul.dev.dbnl.com"),
      [singleKey('d', 'dev')] = openUrl("https://app.dev.dbnl.com"),
      [singleKey('p', 'prod')] = openUrl("https://app.dbnl.com"),
    },
  },
  [singleKey('r', 'raycast')] = {
    [singleKey('e', 'emoji')] = openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"),
    [singleKey('r', 'ai chat')] = openUrl("raycast://extensions/raycast/raycast-ai/ai-chat"),
    [singleKey('f', 'search files')] = openUrl("raycast://extensions/raycast/file-search/search-files"),
    [singleKey('c', 'capture')] = {
      [singleKey('v', 'video')] = openUrl("raycast://extensions/Aayush9029/cleanshotx/record-screen"),
      [singleKey('c', 'copy')] = openUrl(
        "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22copy%22%7D"),
      [singleKey('a', 'annotate')] = openUrl(
        "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22annotate%22%7D"),
      [singleKey('s', 'save')] = openUrl(
        "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22save%22%7D"),
      [singleKey('f', 'find')] = openUrl("raycast://extensions/raycast/file-search/search-files?fallbackText=cleanshot")
    },
  },
  [singleKey('c', 'clipboard')] = openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history"),
  [singleKey('b', 'browser')] = {
    [singleKey('b', 'bookmarks')] = openUrl("raycast://extensions/raycast/browser-bookmarks/index"),
    [singleKey('t', 'tabs')] = openUrl("raycast://extensions/Codely/google-chrome/search-tab"),
    [singleKey('c', 'copy tab title')] = chrome.CopyTabRichLink
  },
  [singleKey('w', 'window')] = {
    [singleKey('f', 'float')] = aerospace({ "layout", "floating", "tiling" }),
    [singleKey('r', 'reload')] = aerospace({ "reload-config" }),
    [singleKey('l', 'layout')] = aerospace({ "layout", "h_accordion", "h_tiles" }),
    [singleKey('m', 'monitor')] = {
      [singleKey('l', 'right')] = aerospace({ "move-node-to-monitor", "right" }),
      [singleKey('h', 'left')] = aerospace({ "move-node-to-monitor", "left" }),
    },
    [singleKey('j', 'join')] = {
      [singleKey('h', 'left')] = aerospace({ "join-with", "left" }),
      [singleKey('j', 'down')] = aerospace({ "join-with", "down" }),
      [singleKey('k', 'up')] = aerospace({ "join-with", "up" }),
      [singleKey('l', 'right')] = aerospace({ "join-with", "right" }),
    }
  },
  [singleKey('j', 'jira')] = {
    [singleKey('o', 'open issues')] = openUrl("raycast://extensions/raycast/jira/open-issues"),
    [singleKey('s', 'search')] = openUrl("raycast://extensions/raycast/jira/search-issues"),
    [singleKey('c', 'create')] = openUrl("raycast://extensions/raycast/jira/create-issue"),
    [singleKey('f', 'filters')] = openUrl("raycast://extensions/raycast/jira/my-filters")
  },
  [singleKey('n', 'notes')] = {
    [singleKey('o', 'open')] = launchOrFocusApp("Logseq"),
    [singleKey('c', 'capture')] = {
      [singleKey('u', 'url')] = captureUrl,
      [singleKey('n', 'new')] = openUrl("logseq://x-callback-url/quickCapture"),
      [singleKey('c', 'clipboard')] = captureClipboard,
      [singleKey('a', 'anki')] = openUrl("logseq://x-callback-url/quickCapture?content=%23anki%20")
    },
  },
}

hs.hotkey.bind({}, 'f5', spoon.RecursiveBinder.recursiveBind(keyMap))

Watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.alert.show(" ✔︎")
