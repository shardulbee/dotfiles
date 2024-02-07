local kitty = require("kitty")
local timer = require("hs.timer")
local popclick = require("hs.noises")
local eventtap = require("hs.eventtap")

local utf8 = require('utf8')

-- Copies a rich link to your currently visible Chrome browser tab that you
-- can paste into Slack/anywhere else that supports it.
--
-- Link is basically formatted as:
--
--   <a href="http://the.url.com">Page title</a>
local function getRichLinkToCurrentChromeTab()
  local application = hs.application.frontmostApplication()

  -- Only copy from Chrome
  if application:bundleID() ~= 'com.google.Chrome' then
    return
  end

  -- Grab the <title> from the page.
  local script = [[
    tell application "Google Chrome"
      get title of active tab of first window
    end tell
  ]]

  local _, title = hs.osascript.applescript(script)

  -- Remove trailing garbage from window title for a better looking link.
  local removePatterns = {
    ' – Dropbox Paper.*',
    '- - Google Chrome.*',
    ' %- Google Docs',
    ' %- Google Sheets',
    ' %- Jira',
    ' – Figma',
    -- Notion's "(9+) " comment indicator
    '%(%d+%+*%) ',
  }

  for _, pattern in ipairs(removePatterns) do
    title = string.gsub(title, pattern, '')
  end

  -- Encode the title as html entities like (&#107;&#84;), so that we can
  -- print out unicode characters inside of `getStyledTextFromData` and have
  -- them render correctly in the link.
  local encodedTitle = ''

  for _, code in utf8.codes(title) do
    encodedTitle = encodedTitle .. '&#' .. code .. ';'
  end

  -- Get the current URL from the address bar.
  script = [[
    tell application "Google Chrome"
      get URL of active tab of first window
    end tell
  ]]

  local _, url = hs.osascript.applescript(script)

  -- Embed the URL + title in an <a> tag so macOS converts it to a rich link
  -- on paste.
  local md = string.format('[%s](%s)', title, url)
  hs.pasteboard.writeObjects(md)
  hs.alert('Copied link to "' .. title .. '"')
end

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

Listener = nil
local popclickListening = false
local tssScrollDown = newScroller(0.02, -10)
local function scrollHandler(evNum)
    -- alert.show(tostring(evNum))
    if evNum == 1 then
        startScroll(tssScrollDown)
    elseif evNum == 2 then
        stopScroll(tssScrollDown)
    elseif evNum == 3 then
        if hs.application.frontmostApplication():name() == "ReadKit" then
            eventtap.keyStroke({}, "j")
        else
            eventtap.scrollWheel({ 0, 250 }, {}, "pixel")
        end
    end
end

local function popclickPlayPause()
    if not popclickListening then
        Listener:start()
        hs.alert.show("Popclick listening.")
    else
        Listener:stop()
        hs.alert.show("Popclick stopped listening.")
    end
    popclickListening = not popclickListening
end

local function popclickInit()
    popclickListening = false
    -- local fn = wrap(scrollHandler)
    local fn = scrollHandler
    Listener = popclick.new(fn)
end

local function launchOrActivate(appName)
    return function()
        hs.application.launchOrFocus(appName)
    end
end

local function launchOrFocusTab(tabURL)
    local baseScript = [[
    let site = "%s"
    let chrome = Application("Google Chrome");
    chrome.includeStandardAdditions = true;
    let windows = chrome.windows.tabs.url();
    let found = false;
    for (let windowIndex = 0; windowIndex < windows.length; windowIndex++) {
      for (let tabIndex = 0; tabIndex < windows[windowIndex].length; tabIndex++) {
        if (windows[windowIndex][tabIndex].startsWith(site)) {
          chrome.windows[windowIndex].visible = true;
          chrome.windows[windowIndex].activeTabIndex = tabIndex + 1;
          chrome.windows[windowIndex].index = 1;
          chrome.activate();
          found = true;
        }
      }
    };
    if (!found) {
      var tab = chrome.Tab({url: site});
      chrome.windows[0].tabs.push(tab);
    }
  ]]

    return function()
        hs.osascript.javascript(string.format(baseScript, tabURL))
    end
end
--
-- function to switch to a safari tab by URL

local hotkeyToAppNameMapping = {
    ["1"] = launchOrActivate("Sublime Text"),
    ["2"] = launchOrActivate("Sublime Merge"),
    ["3"] = launchOrActivate("Google Chrome"),
    ["0"] = launchOrActivate("Kitty"),
    ["6"] = hs.toggleConsole,
    ["8"] = launchOrActivate("Messages"),
    ["9"] = launchOrActivate("Things3"),
    K = launchOrActivate("Kindle"),

}

for hotkey, appName in pairs(hotkeyToAppNameMapping) do
    hs.hotkey.bind("option", hotkey, appName)
end

local function openRepo(repoName)
    return function()
        local repoPath = string.format("~/src/github.com/shardulbee/%s", repoName)
        if not kitty.FocusWindowOrTab(repoName) and not kitty.FocusWindowOrTab(string.format("shardulbee/%s", repoName)) then
            kitty.Launch(repoPath, repoName, "tab", "nvim", false)
        end
    end
end

local hotkeyToActionMapping = {
    R = function()
        hs.reload()
    end,
    M = launchOrActivate("Mimestream"),
    C = launchOrFocusTab("https://calendar.google.com/calendar/u/0/r"),
    D = openRepo("dotfiles"),
    F = function() -- repo launcher
        kitty.Launch(nil, "repo launcher", "overlay", "change-repo", false)
        hs.application.launchOrFocus("Kitty")
    end,
    N = launchOrActivate("iA Writer"),
    P = popclickPlayPause,
}

for hotkey, lambda in pairs(hotkeyToActionMapping) do
    hs.hotkey.bind({ "cmd", "ctrl" }, hotkey, lambda)
end

local superMapping = {
    F = launchOrActivate("Finder"),
    C = getRichLinkToCurrentChromeTab,
    T = function() -- open today note
        if not kitty.FocusWindowOrTab("today") then
            kitty.Launch("/Users/shardul/Library/Mobile Documents/27N4MQEA55~pro~writer/Documents", "today", "tab", "today-note", false)
        else
            local filename = string.format("%s-daily-note.md", os.date("%Y-%m-%d"))
            kitty.sendText("today", string.format(":e %s\r", filename))
        end
        hs.application.launchOrFocus("Kitty")
    end,
    S = function()
        if not kitty.FocusWindowOrTab("scratch") then
            kitty.Launch("/Users/shardul/Library/Mobile Documents/27N4MQEA55~pro~writer/Documents", "scratch", "tab", "nvim scratch.md", true)
        end
        hs.application.launchOrFocus("Kitty")
    end,
    R = launchOrActivate("Reader"),
}

for hotkey, lambda in pairs(superMapping) do
    hs.hotkey.bind({ "cmd", "ctrl", "alt" }, hotkey, lambda)
end

popclickInit()
hs.alert.show("Config loaded")
