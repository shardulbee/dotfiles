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

ALT = "alt"
CMD = "cmd"
CTRL = "ctrl"
SHIFT = "shift"

local function connectVPN()
  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()
  local centerX = screenFrame.x + (screenFrame.w / 2)
  local centerY = screenFrame.y + (screenFrame.h / 2)
  hs.mouse.setAbsolutePosition({ x = centerX, y = centerY })
  hs.eventtap.keyStroke({ "cmd", "ctrl", "alt" }, "v")
  hs.timer.doAfter(0.1, function()
    hs.eventtap.keyStroke({}, "down", 0)
    hs.eventtap.keyStroke({}, "down", 0)
    hs.eventtap.keyStroke({}, "down", 0)
    hs.eventtap.keyStroke({}, "down", 0)
    hs.eventtap.keyStroke({}, "return", 0)
  end)
end

local function focusWindow(direction)
  return function()
    local win = hs.window.focusedWindow()
    if win then win["focusWindow" .. direction](win, nil, true) end
  end
end

local bindings = {
  { mods = { ALT },            key = "1", app = "Zed" },
  { mods = { ALT },            key = "3", app = "Google Chrome" },
  { mods = { ALT },            key = "7", app = "Slack" },
  { mods = { ALT },            key = "0", app = "kitty" },

  { mods = { ALT },            key = "h", fn = focusWindow("West") },
  { mods = { ALT },            key = "j", fn = focusWindow("South") },
  { mods = { ALT },            key = "k", fn = focusWindow("North") },
  { mods = { ALT },            key = "l", fn = focusWindow("East") },

  { mods = { CMD, CTRL },      key = "6", fn = hs.toggleConsole },
  { mods = { CMD, CTRL },      key = "F", app = "Finder" },
  { mods = { CMD, CTRL },      key = "C", app = "Fantastical" },
  { mods = { CMD, CTRL },      key = "Z", app = "zoom.us" },
  { mods = { CMD, CTRL },      key = "R", fn = hs.reload },
  { mods = { CMD, CTRL },      key = "C", tab = "https://calendar.google.com/" },
  { mods = { CMD, CTRL },      key = "M", tab = "https://mail.google.com/mail/u" },
  { mods = { CMD, CTRL },      key = "N", app = "Logseq" },
  { mods = { CMD, CTRL },      key = "V", fn = connectVPN },

  { mods = { CMD, CTRL, ALT }, key = "C", fn = chrome.GetTabRichLink },
}
hs.fnutils.each(bindings, setBinding)

hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.notify.new({
  title = 'Hammerspoon',
  informativeText = 'Config loaded'
}):send()
