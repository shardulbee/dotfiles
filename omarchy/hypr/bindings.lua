-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- macOS-style application shortcuts on Linux, without turning SUPER into CTRL
-- inside terminals/TUIs. Omarchy already provides terminal-aware SUPER+C/V;
-- make SUPER+X safe too, then add the low-risk text/editing chords.
local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function send_shortcut_once(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end

local function nonterminal_shortcut(mods, key)
  return function()
    if not active_window_is_terminal() then
      send_shortcut_once(mods, key)
    end
  end
end

local function active_window_has_tag(tag_name)
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == tag_name then
      return true
    end
  end

  return false
end

local function active_window_is_browser()
  return active_window_has_tag("chromium-based-browser") or active_window_has_tag("firefox-based-browser")
end

local function active_window_class_matches(pattern)
  local window = hl.get_active_window()
  return window and window.class and window.class:match(pattern)
end

local function browser_shortcut(mods, key)
  return function()
    if active_window_is_browser() then
      send_shortcut_once(mods, key)
    end
  end
end

local function browser_shortcut_or_else(mods, key, fallback)
  return function()
    if active_window_is_browser() then
      send_shortcut_once(mods, key)
    else
      hl.dispatch(hl.dsp.exec_cmd(fallback))
    end
  end
end

-- Unbind existing SUPER+X (was: Universal cut, but it sent CTRL+X in terminals).
hl.unbind("SUPER + X")
o.bind("SUPER + X", "Cut (outside terminals)", nonterminal_shortcut("CTRL", "X"))
o.bind("ALT + C", "Copy", function()
  if active_window_is_terminal() then
    send_shortcut_once("CTRL", "Insert")
  else
    send_shortcut_once("CTRL", "C")
  end
end)
o.bind("ALT + V", "Paste", function()
  if active_window_is_terminal() then
    send_shortcut_once("SHIFT", "Insert")
  else
    send_shortcut_once("CTRL", "V")
  end
end)
o.bind("ALT + A", "Select all", function()
  if active_window_is_terminal() then
    send_shortcut_once("CTRL SHIFT", "A")
  else
    send_shortcut_once("CTRL", "A")
  end
end)
o.bind("SUPER + A", "Select all (outside terminals)", nonterminal_shortcut("CTRL", "A"))
o.bind("SUPER + Z", "Undo (outside terminals)", nonterminal_shortcut("CTRL", "Z"))
o.bind("SUPER + SHIFT + Z", "Redo (outside terminals)", nonterminal_shortcut("CTRL SHIFT", "Z"))

o.bind("ALT + L", "Browser address bar", browser_shortcut("CTRL", "L"), { non_consuming = true })
o.bind("ALT + COMMA", "Browser settings", browser_shortcut("CTRL", "COMMA"), { non_consuming = true })
o.bind("ALT + F", "Browser search page", browser_shortcut("CTRL", "F"), { non_consuming = true })
o.bind("ALT + T", "Browser new tab", browser_shortcut("CTRL", "T"), { non_consuming = true })
o.bind("ALT + W", "Close tab/window", function()
  if active_window_is_browser() then
    send_shortcut_once("CTRL", "W")
  elseif active_window_class_matches("ghostty") then
    send_shortcut_once("ALT", "W")
  else
    hl.dispatch(hl.dsp.window.close())
  end
end)
o.bind("ALT + Q", "Close window", hl.dsp.window.close())
o.bind("ALT + CTRL + T", "Toggle Alabaster light/dark", "omarchy-toggle-alabaster")
o.bind("ALT + SHIFT + BRACKETLEFT", "Browser previous tab", browser_shortcut("CTRL SHIFT", "TAB"), { non_consuming = true })
o.bind("ALT + SHIFT + BRACKETRIGHT", "Browser next tab", browser_shortcut("CTRL", "TAB"), { non_consuming = true })
o.bind("ALT + BRACKETLEFT", "Browser back", browser_shortcut("ALT", "LEFT"), { non_consuming = true })
o.bind("ALT + BRACKETRIGHT", "Browser forward", browser_shortcut("ALT", "RIGHT"), { non_consuming = true })
o.bind("ALT + R", "Browser reload", browser_shortcut("CTRL", "R"), { non_consuming = true })
o.bind("ALT + SHIFT + R", "Browser hard reload", browser_shortcut("CTRL SHIFT", "R"), { non_consuming = true })
o.bind("ALT + SHIFT + T", "Browser reopen closed tab", browser_shortcut("CTRL SHIFT", "T"), { non_consuming = true })
o.bind("ALT + 1", "Browser tab 1", browser_shortcut("CTRL", "1"), { non_consuming = true })
o.bind("ALT + 2", "Browser tab 2", browser_shortcut("CTRL", "2"), { non_consuming = true })
o.bind("ALT + 3", "Browser tab 3", browser_shortcut("CTRL", "3"), { non_consuming = true })
o.bind("ALT + 4", "Browser tab 4", browser_shortcut("CTRL", "4"), { non_consuming = true })
o.bind("ALT + 5", "Browser tab 5", browser_shortcut("CTRL", "5"), { non_consuming = true })
o.bind("ALT + 6", "Browser tab 6", browser_shortcut("CTRL", "6"), { non_consuming = true })
o.bind("ALT + 7", "Browser tab 7", browser_shortcut("CTRL", "7"), { non_consuming = true })
o.bind("ALT + 8", "Browser tab 8", browser_shortcut("CTRL", "8"), { non_consuming = true })
o.bind("ALT + 9", "Browser last tab", browser_shortcut("CTRL", "9"), { non_consuming = true })
o.bind("ALT + N", "Browser new window", browser_shortcut("CTRL", "N"), { non_consuming = true })
o.bind("ALT + SHIFT + N", "Browser new incognito window", browser_shortcut("CTRL SHIFT", "N"), { non_consuming = true })
o.bind("ALT + D", "Browser bookmark page", browser_shortcut("CTRL", "D"), { non_consuming = true })
o.bind("ALT + P", "Browser print", browser_shortcut("CTRL", "P"), { non_consuming = true })
o.bind("ALT + S", "Browser save page", browser_shortcut("CTRL", "S"), { non_consuming = true })
o.bind("ALT + O", "Browser open file", browser_shortcut("CTRL", "O"), { non_consuming = true })
o.bind("ALT + J", "Browser downloads", browser_shortcut("CTRL", "J"), { non_consuming = true })
o.bind("ALT + Y", "Browser history", browser_shortcut("CTRL", "H"), { non_consuming = true })
o.bind("ALT + EQUAL", "Browser zoom in", browser_shortcut("CTRL", "EQUAL"), { non_consuming = true })
o.bind("ALT + MINUS", "Browser zoom out", browser_shortcut("CTRL", "MINUS"), { non_consuming = true })
o.bind("ALT + 0", "Browser reset zoom", browser_shortcut("CTRL", "0"), { non_consuming = true })

-- Unbind existing ALT+TAB / SHIFT+ALT+TAB (was: focus next/previous window).
-- ALT+TAB now jumps to the former workspace/space.
hl.unbind("ALT + TAB")
hl.unbind("SHIFT + ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("ALT + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

-- Unbind existing SUPER+LEFT/RIGHT (was: focus left/right window). These now
-- send Linux text-editing word chords to apps, like Option+Left/Right on macOS.
-- On Linux that is CTRL+Left/Right/Backspace, not ALT.
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + BACKSPACE")
o.bind("SUPER + LEFT", "Previous word", function() send_shortcut_once("CTRL", "LEFT") end)
o.bind("SUPER + RIGHT", "Next word", function() send_shortcut_once("CTRL", "RIGHT") end)
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
o.bind("SUPER + SHIFT + LEFT", "Select previous word", function() send_shortcut_once("CTRL SHIFT", "LEFT") end)
o.bind("SUPER + SHIFT + RIGHT", "Select next word", function() send_shortcut_once("CTRL SHIFT", "RIGHT") end)
o.bind("SUPER + BACKSPACE", "Delete previous word", function()
  if active_window_is_terminal() then
    send_shortcut_once("CTRL", "W")
  else
    send_shortcut_once("CTRL", "BACKSPACE")
  end
end, { repeating = true })
o.bind("ALT + BACKSPACE", "Delete to beginning of line", function()
  if active_window_is_terminal() then
    send_shortcut_once("CTRL", "U")
  else
    send_shortcut_once("SHIFT", "HOME")
    hl.timer(function()
      send_shortcut_once("", "BACKSPACE")
    end, { timeout = 50, type = "oneshot" })
  end
end)

-- Vim-style window focus and swaps.
-- Unbind existing SUPER+J (was: Toggle window split), SUPER+K (was: Keybindings),
-- and SUPER+L (was: Toggle workspace layout / browser address bar).
hl.unbind("SUPER + H")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + SHIFT + H")
hl.unbind("SUPER + SHIFT + J")
hl.unbind("SUPER + SHIFT + K")
hl.unbind("SUPER + SHIFT + L")
o.bind("SUPER + H", "Focus left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))
