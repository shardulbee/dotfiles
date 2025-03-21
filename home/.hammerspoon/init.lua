local chrome = require("chrome")
local noises = require("hs.noises")
local timer = require("hs.timer")
local eventtap = require("hs.eventtap")

hs.loadSpoon("RecursiveBinder")
spoon.RecursiveBinder.escapeKey = { {}, "escape" } -- Press escape to abort
local singleKey = spoon.RecursiveBinder.singleKey

local function launchOrFocusApp(appName)
  return function()
    hs.application.launchOrFocus(appName)
  end
end

local function openUrl(url)
  return function()
    hs.urlevent.openURL(url)
  end
end

local function aerospace(args)
  return function()
    local task = hs.task.new("/opt/homebrew/bin/aerospace", nil, args)
    task:start()
  end
end

local function newScroller(delay, tick)
  return { delay = delay, tick = tick, timer = nil }
end

Listener = nil
PopclickListening = false
TssScrollDown = newScroller(0.02, -10)

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

local function scrollHandler(evNum)
  -- alert.show(tostring(evNum))
  if evNum == 1 then
    startScroll(TssScrollDown)
  elseif evNum == 2 then
    stopScroll(TssScrollDown)
  elseif evNum == 3 then
    if hs.application.frontmostApplication():name() == "ReadKit" then
      eventtap.keyStroke({}, "j")
    else
      eventtap.scrollWheel({ 0, 250 }, {}, "pixel")
    end
  end
end

local function popclickInit()
  PopclickListening = false
  local fn = scrollHandler
  Listener = noises.new(fn)
end
popclickInit()

local function popclickPlayPause()
  if not PopclickListening then
    Listener:start()
    hs.alert.show("listening")
  else
    Listener:stop()
    hs.alert.show("stopped listening")
  end
  PopclickListening = not PopclickListening
end

function createNewTIL()
  -- Prompt for TIL title
  hs.focus()
  local button, title = hs.dialog.textPrompt("New TIL", "Enter TIL title:", "", "Create", "Cancel")

  if button ~= "Create" or title == "" then
    return
  end

  -- Slugify the title
  local slug = string.lower(title)
  slug = string.gsub(slug, "[^%w%s-]", "")
  slug = string.gsub(slug, "%s+", "-")
  slug = string.gsub(slug, "^-+", "")
  slug = string.gsub(slug, "-+$", "")

  -- Get today's date in ISO format
  local today = os.date("%Y-%m-%d")

  -- Create file path
  local filePath = os.getenv("HOME") .. "/src/github.com/shardulbee/shardul.baral.ca/til/" .. slug .. ".md"
  local relativeFilePath = "til/" .. slug .. ".md"

  -- Create frontmatter
  local frontmatter = "---\ntitle: " .. title .. "\ncreated_at: " .. today .. "\n---\n\n"

  -- Ensure directory exists
  os.execute("mkdir -p " .. os.getenv("HOME") .. "/src/github.com/shardulbee/shardul.baral.ca/til/")

  -- Write initial file with frontmatter
  local file = io.open(filePath, "w")
  if file then
    file:write(frontmatter)
    file:close()
  else
    hs.alert.show("Failed to create TIL file")
    return
  end

  -- Full path to Homebrew tmux
  local tmuxPath = "/usr/local/bin/tmux"
  -- Check for arm64 homebrew location
  if not hs.fs.attributes(tmuxPath) then
    tmuxPath = "/opt/homebrew/bin/tmux"
  end

  -- Check if tmux is running
  local tmuxRunning = os.execute(tmuxPath .. " has-session 2>/dev/null")

  if tmuxRunning then
    -- Escape quotes in the title for the commit message
    local safeTitle = string.gsub(title, '"', '\\"')
    local commitMsg = "Add TIL: " .. safeTitle

    -- Create a workflow script that will:
    -- 1. Open the file in vim
    -- 2. After vim closes, perform git operations
    -- 3. Close the pane when done
    local workflowScript = [[
  /opt/homebrew/bin/nvim "]] .. filePath .. [[" && \
  cd "]] .. os.getenv("HOME") .. [[/src/github.com/shardulbee/shardul.baral.ca" && \
  git add "]] .. relativeFilePath .. [[" && \
  git commit -m "]] .. commitMsg .. [[" && \
  git push && \
  echo "TIL published! Closing in 2 seconds..." && \
  sleep 2 && \
  exit
  ]]

    -- Create a new tmux window with our workflow
    os.execute(tmuxPath .. " new-window -n 'TIL' '" .. workflowScript .. "'")

    hs.alert.show("Created new TIL: " .. slug .. " (tmux window opened)")
  else
    -- No tmux session, show a notification with the file path
    hs.alert.show("Created new TIL: " .. slug .. "\nNo active tmux session found.\nFile path: " .. filePath)
    -- Copy path to clipboard for easy access
    hs.pasteboard.setContents(filePath)
  end
end

local common = {
  ["t"] = { alias = "til", fn = createNewTIL },
  ["s"] = {
    alias = "spotify",
    sub_mappings = {
      ["p"] = {
        alias = "playlistadd",
        fn = openUrl("raycast://extensions/mattisssa/spotify-player/addPlayingSongToPlaylist"),
      },
      ["n"] = {
        alias = "now playing",
        fn = openUrl("raycast://extensions/mattisssa/spotify-player/nowPlaying"),
      },
    },
  },
  ["f"] = {
    alias = "search files",
    fn = openUrl("raycast://extensions/raycast/file-search/search-files"),
  },
  ["c"] = { alias = "clipboard", fn = openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history") },
  ["h"] = {
    alias = "hammerspoon",
    sub_mappings = {
      ["c"] = { alias = "console", fn = hs.toggleConsole },
      ["r"] = { alias = "reload", fn = hs.reload },
      ["p"] = { alias = "popclick", fn = popclickPlayPause },
    },
  },
  ["r"] = {
    alias = "raycast",
    sub_mappings = {
      ["e"] = { alias = "emoji", fn = openUrl("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols") },
      ["c"] = {
        alias = "capture",
        sub_mappings = {
          ["v"] = { alias = "video", fn = openUrl("raycast://extensions/Aayush9029/cleanshotx/record-screen") },
          ["c"] = {
            alias = "capture",
            fn = openUrl(
              "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22copy%22%7D"
            ),
          },
          ["a"] = {
            alias = "annotate",
            fn = openUrl(
              "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22annotate%22%7D"
            ),
          },
          ["s"] = {
            alias = "save",
            fn = openUrl(
              "raycast://extensions/Aayush9029/cleanshotx/capture-area?arguments=%7B%22action%22%3A%22save%22%7D"
            ),
          },
          ["f"] = {
            alias = "find",
            fn = openUrl("raycast://extensions/raycast/file-search/search-files?fallbackText=cleanshot"),
          },
        },
      },
    },
  },
  ["b"] = {
    alias = "browser",
    sub_mappings = {
      ["b"] = { alias = "bookmarks", fn = openUrl("raycast://extensions/raycast/browser-bookmarks/index") },
      ["c"] = { alias = "copy tab title", fn = chrome.CopyTabRichLink },
    },
  },
  ["w"] = {
    alias = "window",
    sub_mappings = {
      ["d"] = { alias = "disable", fn = aerospace({ "enable", "toggle" }) },
      ["t"] = { alias = "tiles", fn = aerospace({ "layout", "tiles", "vertical", "horizontal" }) },
      ["s"] = { alias = "stack", fn = aerospace({ "layout", "accordion", "vertical", "horizontal" }) },
      ["f"] = { alias = "float", fn = aerospace({ "layout", "floating", "tiling" }) },
      ["r"] = { alias = "reload", fn = aerospace({ "reload-config" }) },
      ["j"] = {
        alias = "join",
        sub_mappings = {
          ["h"] = { alias = "left", fn = aerospace({ "join-with", "left" }) },
          ["j"] = { alias = "down", fn = aerospace({ "join-with", "down" }) },
          ["k"] = { alias = "up", fn = aerospace({ "join-with", "up" }) },
          ["l"] = { alias = "right", fn = aerospace({ "join-with", "right" }) },
        },
      },
    },
  },
  ["o"] = {
    alias = "open",
    sub_mappings = {
      -- ["f"] = { alias = "finder", fn = launchOrFocusApp("Finder") },
      ["f"] = { alias = "focus", fn = openUrl("raycast://extensions/raycast/raycast-focus/start-focus-session") },
      ["z"] = { alias = "zoom", fn = launchOrFocusApp("zoom.us") },
      ["n"] = { alias = "notes", fn = launchOrFocusApp("Obsidian") },
    },
  },
}

local dbnl = {
  ["o"] = {
    alias = "open",
    sub_mappings = {
      ["m"] = { alias = "mail", fn = chrome.LaunchOrFocusTab("https://mail.google.com") },
      ["s"] = { alias = "slack", fn = launchOrFocusApp("Slack") },
      ["c"] = { alias = "calendar", fn = chrome.LaunchOrFocusTab("https://calendar.google.com") },
      ["t"] = {
        alias = "TODO",
        fn = openUrl(
          "raycast://extensions/raycast/raycast-notes/raycast-notes?context=%7B%22id%22:%22655B9E55-B0D4-43D8-A276-04BBB7B5C392%22%7D"
        ),
      },
    },
  },
  ["z"] = {
    alias = "zoom",
    sub_mappings = {
      ["j"] = {
        alias = "join",
        fn = function()
          hs.eventtap.keyStroke({ "cmd", "ctrl", "alt", "cmd", "shift" }, "j")
        end,
      },
      ["c"] = {
        alias = "calendar",
        fn = function()
          hs.eventtap.keyStroke({ "cmd", "alt", "ctrl" }, "c")
        end,
      },
    },
  },
  ["d"] = {
    alias = "dbnl",
    sub_mappings = {
      ["r"] = { alias = "repo", fn = chrome.LaunchOrFocusTab("https://github.com/dbnlAI/dbnl-internal#") },
      ["s"] = {
        alias = "aws sso",
        fn = function()
          local task = hs.task.new("/usr/local/bin/aws", function(exitCode, _, _)
            if exitCode == 0 then
              hs.alert.show("AWS SSO Login Successful", {
                atScreenEdge = 2,
                strokeColor = { white = 0, alpha = 2 },
                textFont = "Courier",
                textSize = 20,
              })
            else
              hs.alert.show("AWS SSO Login Failed", {
                atScreenEdge = 2,
                strokeColor = { white = 0, alpha = 2 },
              })
            end
          end, { "sso", "login", "--profile", "app-dev" })
          task:start()
          hs.timer.doAfter(20, function()
            task:terminate()
          end)
        end,
      },
      ["o"] = {
        alias = "open+",
        sub_mappings = {
          ["l"] = { alias = "local", fn = chrome.LaunchOrFocusTab("http://localhost:8080/") },
          ["r"] = { alias = "remote", fn = chrome.LaunchOrFocusTab("https://app-shardul.dev.dbnl.com") },
          ["d"] = { alias = "dev", fn = chrome.LaunchOrFocusTab("https://app.dev.dbnl.com") },
          ["p"] = { alias = "prod", fn = chrome.LaunchOrFocusTab("https://app.dbnl.com") },
        },
      },
    },
  },
  ["j"] = {
    alias = "jira",
    sub_mappings = {
      ["c"] = { alias = "create issue", fn = openUrl("raycast://extensions/raycast/jira/create-issue") },
      ["o"] = { alias = "open issues", fn = openUrl("raycast://extensions/raycast/jira/open-issues") },
      ["s"] = { alias = "search", fn = openUrl("raycast://extensions/raycast/jira/search-issues") },
    },
  },
}

local personal = {
  ["o"] = {
    alias = "open",
    sub_mappings = {
      ["m"] = { alias = "mail", fn = chrome.LaunchOrFocusTab("https://app.fastmail.com/mail/") },
      ["c"] = { alias = "calendar", fn = launchOrFocusApp("Fantastical") },
    },
  },
}

-- Function to merge nested mappings
local function mergeMappings(base, extra)
  local result = {}

  -- Copy all entries from base
  for k, v in pairs(base) do
    result[k] = v
  end

  -- Add or merge entries from extra
  for k, v in pairs(extra) do
    if result[k] == nil then
      -- Key doesn't exist in result, simply copy it
      result[k] = v
    elseif type(result[k]) == "table" and type(v) == "table" then
      -- Check for alias conflict
      if result[k].alias ~= v.alias then
        hs.showError("Alias conflict for key '" .. k .. "': '" .. result[k].alias .. "' vs '" .. v.alias .. "'")
      end

      -- Check if both have sub_mappings (can be recursively merged)
      if result[k].sub_mappings and v.sub_mappings then
        -- Merge sub_mappings recursively
        result[k] = {
          alias = result[k].alias,
          sub_mappings = mergeMappings(result[k].sub_mappings, v.sub_mappings),
        }
      elseif result[k].fn and v.fn then
        -- Both have fn fields, prefer the extra one
        result[k] = v
      else
        -- One has fn, one has sub_mappings, or some other conflict
        hs.showError("Structure conflict for key '" .. k .. "'")
      end
    else
      hs.showError("Type conflict for key '" .. k .. "'")
    end
  end

  return result
end

local function transform(t)
  local transformed = {}
  for keyChar, val in pairs(t) do
    local name = val.alias

    if val.sub_mappings then
      -- Nested table => transform recursively
      transformed[singleKey(keyChar, name)] = transform(val.sub_mappings)
    else
      -- It's presumably a function (fn field)
      transformed[singleKey(keyChar, name)] = val.fn
    end
  end
  return transformed
end

-- Create mappings based on host name
local finalMappings
if hs.host.localizedName() == "dbnl-shardul" then
  finalMappings = mergeMappings(common, dbnl)
else
  finalMappings = mergeMappings(common, personal)
end

hs.hotkey.bind({}, "f5", spoon.RecursiveBinder.recursiveBind(transform(finalMappings)))

Watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/home/.hammerspoon", hs.reload):start()
hs.alert.show(" ✔︎")
