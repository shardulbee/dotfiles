local chrome = require("chrome")
require("slack")

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
  -- send the cmd-ctrl-opt-v key
  -- followed by down down down down then enter
  hs.eventtap.keyStroke({ "cmd", "ctrl", "alt" }, "v")
  hs.eventtap.keyStroke({}, "down", 0)
  hs.eventtap.keyStroke({}, "down", 0)
  hs.eventtap.keyStroke({}, "down", 0)
  hs.eventtap.keyStroke({}, "down", 0)
  hs.eventtap.keyStroke({}, "return", 0)
end

local bindings = {
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
