local utf8 = require("utf8")

Chrome = {}

local CHROME_CLI_PATH = "/opt/homebrew/bin/chrome-cli"
local hostname = hs.host.localizedName()
print("hostname", hostname)
local CHROME_BUNDLE_IDENTIFIER = string.find(hostname, "turbochardo", 1, true) and "com.google.Chrome"
	or "com.brave.Browser"
print("CHROME_BUNDLE_IDENTIFIER", CHROME_BUNDLE_IDENTIFIER)

--------------------------------------------------------------------------------
-- Helper: run a shell command via hs.task, collecting its output asynchronously.
--   cmdArgs is a table, e.g. { "/usr/local/bin/chrome-cli", "info" }
--   callback is called as callback(stdOut, stdErr, exitCode).
--------------------------------------------------------------------------------
local function asyncReadCommandOutput(cmdArgs, callback)
	-- The first element in cmdArgs is the command path, e.g. "/usr/local/bin/chrome-cli"
	-- The rest are arguments, e.g. {"info", "list", "links"} etc.

	local task = hs.task.new(CHROME_CLI_PATH, function(exitCode, stdOut, stdErr)
		if callback then
			callback(stdOut, stdErr, exitCode)
		end
	end, cmdArgs)

	task:setEnvironment({
		["CHROME_BUNDLE_IDENTIFIER"] = CHROME_BUNDLE_IDENTIFIER,
	})

	task:start()
end

local function chromeCliPath()
	return "/opt/homebrew/bin/chrome-cli"
end

--------------------------------------------------------------------------------
-- Asynchronously fetch the active tab's title & URL via "chrome-cli info",
-- then call callback(title, url, err).
-- "chrome-cli info" output typically looks like:
--   Id: 73380884
--   Window id: 73380876
--   Title: Some Page
--   Url: https://example.com
--   Loading: No
--------------------------------------------------------------------------------
local function getActiveTabTitleAndUrlAsync(callback)
	asyncReadCommandOutput({ "info" }, function(stdOut, stdErr, exitCode)
		if exitCode ~= 0 then
			if callback then
				callback(nil, nil, "Error running chrome-cli info: " .. (stdErr or ""))
			end
			return
		end

		local title = stdOut:match("Title:%s*(.-)\n") or ""
		local url = stdOut:match("Url:%s*(.-)\n") or ""
		if callback then
			callback(title, url, nil)
		end
	end)
end

--------------------------------------------------------------------------------
-- If a URL is a GitHub pull request or Atlassian Jira ticket, do a quick
-- title fix. E.g., removing " by ..." from GitHub PR titles or " - Jira" from
-- Atlassian tickets.
--------------------------------------------------------------------------------
local function maybeAdjustTitle(title, url)
	if not title or not url then
		return title
	end
	if url:match("/pull/") then
		return title:match("^(.-) by .+ · Pull Request") or title
	elseif url:match("atlassian%.net/browse/") then
		return title:match("^(.-) %- Jira") or title
	elseif url:match("docs.google.com") then
		return title:match("^(.-) %- Google Docs") or title
	end

	return title
end

--------------------------------------------------------------------------------
-- Chrome.CopyTabRichLink():
--   Gets the active tab's title & URL asynchronously, modifies if needed,
--   then copies a Markdown link [title](url) to the clipboard, displaying
--   a small Hammerspoon alert.
--------------------------------------------------------------------------------
function Chrome.CopyTabRichLink()
	local frontApp = hs.application.frontmostApplication()
	-- if frontApp:bundleID() ~= CHROME_BUNDLE_IDENTIFIER then
	-- 	return
	-- end

	getActiveTabTitleAndUrlAsync(function(title, url, err)
		if err then
			hs.alert("Failed to retrieve active tab: " .. err)
			return
		end
		title = maybeAdjustTitle(title, url)

		-- Encode the title as HTML entities in case it has special/unicode characters
		local encodedTitle = ""
		for _, codepoint in utf8.codes(title) do
			encodedTitle = encodedTitle .. "&#" .. codepoint .. ";"
		end

		local mdLink = string.format("[%s](%s)", title, url)
		hs.pasteboard.writeObjects(mdLink)
		hs.alert('Copied link to "' .. title .. '"')
	end)
end

--------------------------------------------------------------------------------
-- Chrome.GetTabTitleAndUrl(callback):
--   Asynchronously obtains the active Chrome tab's title and URL, then calls
--   callback(title, url, err).
--------------------------------------------------------------------------------
function Chrome.GetTabTitleAndUrl(callback)
	local frontApp = hs.application.frontmostApplication()
	if frontApp:bundleID() ~= CHROME_BUNDLE_IDENTIFIER then
		if callback then
			callback(nil, nil, "Not in Chrome")
		end
		return
	end

	getActiveTabTitleAndUrlAsync(function(title, url, err)
		if err then
			if callback then
				callback(nil, nil, err)
			end
			return
		end
		if callback then
			callback(maybeAdjustTitle(title, url), url, nil)
		end
	end)
end

--------------------------------------------------------------------------------
-- Chrome.LaunchOrFocusTab(tabURL):
--   Returns a function that, when called, finds a tab whose URL starts with
--   tabURL or opens a new one if none exist.
--   Using "chrome-cli list links" asynchronously in one shot.
--------------------------------------------------------------------------------
function Chrome.LaunchOrFocusTab(tabURL)
	return function() -- So you can do e.g. hs.hotkey.bind(..., Chrome.LaunchOrFocusTab("https://..."))
		local appName = string.find(hostname, "turbochardo", 1, true) and "Google Chrome" or "Brave Browser"

		local script = [[
      tell application "]] .. appName .. [["
        set foundTab to false
        set windowCount to count windows
        repeat with w from 1 to windowCount
          set tabCount to count tabs of window w
          repeat with t from 1 to tabCount
            set tabUrl to URL of tab t of window w
            if tabUrl starts with "]] .. tabURL .. [[" then
              set active tab index of window w to t
              set index of window w to 1
              set foundTab to true
              exit repeat
            end if
          end repeat
          if foundTab then exit repeat
        end repeat

        if not foundTab then
          tell window 1
            set newTab to make new tab with properties {URL:"]] .. tabURL .. [["}
          end tell
        end if

        activate
      end tell
    ]]

		local _, _, success = hs.osascript.applescript(script)
		if not success then
			hs.alert("Failed to find or open tab with URL: " .. tabURL)
		end
	end
end

return Chrome
