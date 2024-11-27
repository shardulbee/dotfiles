local chrome = require("chrome")

local function wrapped(fnToWrap, ...)
  local vararg = { ... }
  local wrapped_fn = function()
    fnToWrap(table.unpack(vararg))
  end
  return wrapped_fn
end

local function setBinding(binding)
  if binding.app then
    hs.hotkey.bind(binding.mods, binding.key, wrapped(hs.application.launchOrFocus, binding.app))
  elseif binding.fn then
    hs.hotkey.bind(binding.mods, binding.key, binding.fn)
  elseif binding.tab then
    hs.hotkey.bind(binding.mods, binding.key, chrome.LaunchOrFocusTab(binding.tab))
  elseif binding.url then
    hs.hotkey.bind(binding.mods, binding.key, wrapped(hs.urlevent.openURL, binding.url))
  end
end

LALT = "lalt"
LCMD = "lcmd"
RCMD = "rcmd"
LCTRL = "lctrl"
LSHIFT = "lshift"

local function connectVPN()
  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()
  local centerX = screenFrame.x + (screenFrame.w / 2)
  local centerY = screenFrame.y + (screenFrame.h / 2)
  hs.mouse.absolutePosition({ x = centerX, y = centerY })
  hs.eventtap.keyStroke({ "cmd", "ctrl", "alt" }, "v")
  hs.timer.doAfter(1, function()
    hs.eventtap.keyStroke({}, "down", 0)
    hs.eventtap.keyStroke({}, "down", 0)
    hs.eventtap.keyStroke({}, "down", 0)
    hs.eventtap.keyStroke({}, "down", 0)
    hs.eventtap.keyStroke({}, "return", 0)
  end)
end

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
end

local bindings = {

  { mods = { LCMD, LCTRL, LALT }, key = "C", fn = chrome.GetTabRichLink },
}
hs.fnutils.each(bindings, setBinding)

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

local keyMap = {
  [singleKey('o', 'open+')] = {
    [singleKey('b', 'browser')] = launchOrFocusApp("Google Chrome"),
    [singleKey('t', 'terminal')] = launchOrFocusApp("kitty"),
    [singleKey('m', 'mail')] = launchOrFocusApp("Mimestream"),
    [singleKey('s', 'music')] = launchOrFocusApp("Spotify"),
    [singleKey('i', 'messaging')] = launchOrFocusApp("Slack"),
    [singleKey('z', 'zoom')] = launchOrFocusApp("zoom.us"),
    [singleKey('c', 'calendar')] = chrome.LaunchOrFocusTab("https://calendar.google.com"),
    [singleKey('e', 'zed')] = launchOrFocusApp("Zed"),
  },
  [singleKey('h', 'hammerspoon')] = {
    [singleKey('c', 'console')] = hs.toggleConsole,
    [singleKey('r', 'console')] = hs.reload
  },
  [singleKey('d', 'dbnl')] = {
    [singleKey('v', 'connect vpn')] = connectVPN,
    [singleKey('a', 'aws sso')] = connectAwsSso
  },
  [singleKey('r', 'raycast')] = {
    [singleKey('c', 'clipboard')] = openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history"),
    [singleKey('e', 'emoji')] = openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"),
    [singleKey('r', 'ai chat')] = openUrl("raycast://extensions/raycast/raycast-ai/ai-chat")
  },
  [singleKey('c', 'capture')] = {
    [singleKey('v', 'video')] = openUrl("raycast://extensions/Aayush9029/cleanshotx/record-screen"),
    [singleKey('c', 'screenshot')] = openUrl(
      "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22copy%22%7D"),
    [singleKey('a', 'annotate')] = openUrl(
      "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22annotate%22%7D")
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
  [singleKey('j', 'jira')] = {
    [singleKey('o', 'open issues')] = openUrl("raycast://extensions/raycast/jira/open-issues"),
    [singleKey('s', 'search')] = openUrl("raycast://extensions/raycast/jira/search-issues"),
    [singleKey('c', 'create')] = openUrl("raycast://extensions/raycast/jira/create-issue"),
  }
}

hs.hotkey.bind({}, 'f5', spoon.RecursiveBinder.recursiveBind(keyMap))

Watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.alert.show(" ✔︎")
