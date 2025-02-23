local utf8 = require("utf8")

Chrome = {}

function Chrome.CopyTabRichLink()
  local application = hs.application.frontmostApplication()

  -- Only copy from Chrome
  if application:bundleID() ~= "com.google.Chrome" then
    return
  end

  -- Grab the <title> from the page.
  local script = [[
    tell application "Google Chrome"
      get title of active tab of first window
    end tell
  ]]

  local _, title = hs.osascript.applescript(script)

  -- Get the current URL from the address bar.
  script = [[
    tell application "Google Chrome"
      get URL of active tab of first window
    end tell
  ]]

  local _, url = hs.osascript.applescript(script)

  -- Check if the URL is a GitHub pull request and modify the title if necessary
  if url:match("/pull/") then
    title = title:match("^(.-) by .+ · Pull Request")
  elseif url:match("atlassian.net/browse/") then
    print("Title before: " .. title)
    title = title:match("^(.-) %- Jira")
    print("Title after: " .. title)
  end

  -- Encode the title as html entities like (&#107;&#84;), so that we can
  -- print out unicode characters inside of `getStyledTextFromData` and have
  -- them render correctly in the link.
  local encodedTitle = ""

  for _, code in utf8.codes(title) do
    encodedTitle = encodedTitle .. "&#" .. code .. ";"
  end

  -- Embed the URL + title in an <a> tag so macOS converts it to a rich link
  -- on paste.
  local md = string.format("[%s](%s)", title, url)
  hs.pasteboard.writeObjects(md)
  hs.alert('Copied link to "' .. title .. '"')
end

function Chrome.GetTabTitleAndUrl()
  local application = hs.application.frontmostApplication()

  -- Only copy from Chrome
  if application:bundleID() ~= "com.google.Chrome" then
    return
  end

  -- Grab the <title> from the page.
  local script = [[
    tell application "Google Chrome"
      get title of active tab of first window
    end tell
  ]]

  local _, title = hs.osascript.applescript(script)

  -- Get the current URL from the address bar.
  script = [[
    tell application "Google Chrome"
      get URL of active tab of first window
    end tell
  ]]

  local _, url = hs.osascript.applescript(script)

  -- Check if the URL is a GitHub pull request and modify the title if necessary
  if url:match("/pull/") then
    title = title:match("^(.-) by .+ · Pull Request")
  elseif url:match("atlassian.net/browse/") then
    print("Title before: " .. title)
    title = title:match("^(.-) %- Jira")
    print("Title after: " .. title)
  end

  -- Encode the title as html entities like (&#107;&#84;), so that we can
  -- print out unicode characters inside of `getStyledTextFromData` and have
  -- them render correctly in the link.
  local encodedTitle = ""

  for _, code in utf8.codes(title) do
    encodedTitle = encodedTitle .. "&#" .. code .. ";"
  end

  -- Embed the URL + title in an <a> tag so macOS converts it to a rich link
  -- on paste.
  return title, url
end

function Chrome.LaunchOrFocusTab(tabURL)
  local baseScript = [[
    let site = "%s"
    let chrome = Application("Google Chrome");
    chrome.includeStandardAdditions = true;
    let windows = chrome.windows.tabs.url();
    let found = false;
    windowLoop: for (let windowIndex = 0; windowIndex < windows.length; windowIndex++) {
      for (let tabIndex = 0; tabIndex < windows[windowIndex].length; tabIndex++) {
        if (windows[windowIndex][tabIndex].startsWith(site)) {
          chrome.windows[windowIndex].visible = true;
          chrome.windows[windowIndex].activeTabIndex = tabIndex + 1;
          chrome.windows[windowIndex].index = 1;
          chrome.activate();
          found = true;
          break windowLoop;
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
    hs.application.launchOrFocus("Google Chrome")
  end
end

return Chrome
