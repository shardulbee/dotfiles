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

function Aerospace(args)
  return function()
    local function handleOutput(exitCode, stdout, stderr)
      if exitCode ~= 0 then
        hs.logger.new('aerospace'):e(stderr)
      end
    end
    local task = hs.task.new("/opt/homebrew/bin/aerospace", handleOutput, args)
    task:start()
  end
end

local keyMap = {
  [singleKey('c', 'clipboard')] = openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history"),
  [singleKey('f', 'files')] = openUrl("raycast://extensions/raycast/file-search/search-files"),

  [singleKey('o', 'open+')] = {
    [singleKey('b', 'browser')] = launchOrFocusApp("Google Chrome"),
    [singleKey('k', 'kitty')] = launchOrFocusApp("kitty"),
    [singleKey('t', 'things')] = launchOrFocusApp("Things3"),
    [singleKey('m', 'mail')] = launchOrFocusApp("Mail"),
    [singleKey('i', 'messages')] = launchOrFocusApp("Messages"),
    [singleKey('s', 'spotify')] = launchOrFocusApp("Spotify"),
    [singleKey('n', 'notes')] = launchOrFocusApp("Logseq"),
    [singleKey('z', 'zoom')] = launchOrFocusApp("zoom.us"),
    [singleKey('c', 'calendar')] = launchOrFocusApp("Fantastical"),
    [singleKey('e', 'zed')] = launchOrFocusApp("Zed"),
  },
  [singleKey('h', 'hammerspoon')] = {
    [singleKey('c', 'console')] = hs.toggleConsole,
    [singleKey('r', 'reload')] = hs.reload
  },
  [singleKey('r', 'raycast')] = {
    [singleKey('c', 'clipboard')] = openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history"),
    [singleKey('e', 'emoji')] = openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"),
    [singleKey('r', 'ai chat')] = openUrl("raycast://extensions/raycast/raycast-ai/ai-chat"),
    [singleKey('f', 'search files')] = openUrl("raycast://extensions/raycast/file-search/search-files"),
    [singleKey('m', 'search menu items')] = openUrl("raycast://extensions/raycast/navigation/search-menu-items"),
  },
  [singleKey('b', 'browser')] = {
    [singleKey('b', 'bookmarks')] = openUrl("raycast://extensions/raycast/browser-bookmarks/index"),
    [singleKey('t', 'tabs')] = openUrl("raycast://extensions/Codely/google-chrome/search-tab"),
    [singleKey('c', 'copy tab title')] = chrome.GetTabRichLink,
  },
  [singleKey('w', 'window')] = {
    [singleKey('f', 'float')] = Aerospace({ "layout", "floating", "tiling" }),

    [singleKey('r', 'reload')] = Aerospace({ "reload-config" }),
    [singleKey('l', 'layout')] = Aerospace({ "layout", "h_accordion", "h_tiles" }),
    [singleKey('m', 'monitor')] = {
      [singleKey('l', 'right')] = Aerospace({ "move-node-to-monitor", "right" }),
      [singleKey('h', 'left')] = Aerospace({ "move-node-to-monitor", "left" }),
    },
    [singleKey('j', 'join')] = {
      [singleKey('h', 'left')] = Aerospace({ "join-with", "left" }),
      [singleKey('j', 'down')] = Aerospace({ "join-with", "down" }),
      [singleKey('k', 'up')] = Aerospace({ "join-with", "up" }),
      [singleKey('l', 'right')] = Aerospace({ "join-with", "right" }),
    }
  },
  [singleKey('s', 'screenshot')] = {
    [singleKey('v', 'video')] = openUrl("raycast://extensions/Aayush9029/cleanshotx/record-screen"),
    [singleKey('c', 'copy')] = openUrl(
      "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22copy%22%7D"),
    [singleKey('a', 'annotate')] = openUrl(
      "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22annotate%22%7D"),
    [singleKey('s', 'save')] = openUrl(
      "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22save%22%7D"),
    [singleKey('f', 'find')] = openUrl("raycast://extensions/raycast/file-search/search-files?fallbackText=cleanshot")
  },
}

hs.hotkey.bind({}, 'f5', spoon.RecursiveBinder.recursiveBind(keyMap))

Watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.alert.show(" ✔︎")
