local chrome = require("chrome")

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

local function blueutil(args)
  return function()
    local task = hs.task.new("/usr/local/bin/blueutil", nil, args)
    task:start()
  end
end

local keyMap = {
  [singleKey('o', 'open+')] = {
    [singleKey('b', 'browser')] = launchOrFocusApp("Google Chrome"),
    [singleKey('t', 'terminal')] = launchOrFocusApp("kitty"),
    [singleKey('m', 'mail')] = launchOrFocusApp("Mimestream"),
    [singleKey('s', 'slack')] = launchOrFocusApp("Slack"),
    [singleKey('z', 'zoom')] = launchOrFocusApp("zoom.us"),
    [singleKey('c', 'calendar')] = chrome.LaunchOrFocusTab("https://calendar.google.com"),
    [singleKey('e', 'zed')] = launchOrFocusApp("Zed"),
  },
  [singleKey('z', 'zoom')] = {
    [singleKey('o', 'open')] = launchOrFocusApp("zoom.us"),
    [singleKey('j', 'join')] = function() hs.eventtap.keyStroke({ "cmd", "alt", "cmd", "shift" }, "j") end,
    [singleKey('c', 'calendar')] = function() hs.eventtap.keyStroke({ "cmd", "alt", "ctrl", }, "c") end,
  },
  [singleKey('h', 'hammerspoon')] = {
    [singleKey('c', 'console')] = hs.toggleConsole,
    [singleKey('r', 'console')] = hs.reload
  },
  [singleKey('r', 'raycast')] = {
    [singleKey('c', 'clipboard')] = openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history"),
    [singleKey('e', 'emoji')] = openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"),
    [singleKey('r', 'ai chat')] = openUrl("raycast://extensions/raycast/raycast-ai/ai-chat"),
    [singleKey('f', 'search files')] = openUrl("raycast://extensions/raycast/file-search/search-files")
  },
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
  [singleKey('b', 'browser')] = {
    [singleKey('b', 'bookmarks')] = openUrl("raycast://extensions/raycast/browser-bookmarks/index"),
    [singleKey('t', 'tabs')] = openUrl("raycast://extensions/Codely/google-chrome/search-tab"),
    [singleKey('c', 'copy tab title')] = chrome.GetTabRichLink
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
  [singleKey('s', 'spotify')] = {
    [singleKey('o', 'open')] = launchOrFocusApp("Spotify"),
    [singleKey('l', 'library')] = openUrl("raycast://extensions/mattisssa/spotify-player/yourLibrary")
  },
  [singleKey('f', 'focus')] = {
    [singleKey('b', 'break')] = openUrl("focus://break"),
    [singleKey('p', 'pomodoro')] = openUrl("focus://focus?minutes=25"),
    [singleKey('u', 'unfocus')] = openUrl("focus://unfocus"),
    [singleKey('c', 'config')] = openUrl("focus://preferences")
  }
}

hs.hotkey.bind({}, 'f5', spoon.RecursiveBinder.recursiveBind(keyMap))

Watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.alert.show(" ✔︎")
