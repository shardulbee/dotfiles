---@diagnostic disable: undefined-global

local keys = {}
local commands = {
  b = {
    a = function()
      local ok, result = hs.osascript.applescript([[
        tell application "Google Chrome"
          if (count of windows) > 0 then
            set activeTab to active tab of front window
            return URL of activeTab & "|||" & title of activeTab
          end if
        end tell
      ]])
      if ok and result ~= "" then
        local url, title = result:match("([^|||]+)|||(.+)")
        hs.http.asyncPost(
          "https://turbopins.tail8779.ts.net/bookmarks",
          hs.json.encode({ url = url, title = title, description = "" }),
          { ["Content-Type"] = "application/json" },
          function(status)
            hs.alert.show(status == 200 or status == 201 and "✅ Bookmarked" or "❌ Failed")
          end
        )
      end
    end,
    b = function()
      hs.urlevent.openURL("raycast://extensions/turbochardo/bookmarks/search-bookmarks")
    end,
  },
  c = function()
    hs.urlevent.openURL("raycast://extensions/raycast/clipboard-history/clipboard-history")
  end,
  h = {
    c = hs.toggleConsole,
    r = hs.reload,
  },
  o = {
    s = function()
      hs.application.launchOrFocus("Slack")
    end,
    n = function()
      hs.application.launchOrFocus("Obsidian")
    end,
    i = function()
      hs.application.launchOrFocus("Messages")
    end,
    m = function()
      hs.urlevent.openURL("https://app.fastmail.com/mail/Inbox")
    end,
    c = function()
      hs.urlevent.openURL("https://calendar.google.com/calendar/u/0/r")
    end,
  },
  w = {
    d = function()
      hs.task.new("/usr/local/bin/aerospace", nil, { "enable", "toggle" }):start()
    end,
    t = function()
      hs.task.new("/usr/local/bin/aerospace", nil, { "layout", "tiles", "vertical", "horizontal" }):start()
    end,
    s = function()
      hs.task.new("/usr/local/bin/aerospace", nil, { "layout", "accordion", "vertical", "horizontal" }):start()
    end,
    f = function()
      hs.task.new("/usr/local/bin/aerospace", nil, { "layout", "floating", "tiling" }):start()
    end,
    r = function()
      hs.task.new("/usr/local/bin/aerospace", nil, { "reload-config" }):start()
    end,
    j = {
      h = function()
        hs.task.new("/usr/local/bin/aerospace", nil, { "join-with", "left" }):start()
      end,
      j = function()
        hs.task.new("/usr/local/bin/aerospace", nil, { "join-with", "down" }):start()
      end,
      k = function()
        hs.task.new("/usr/local/bin/aerospace", nil, { "join-with", "up" }):start()
      end,
      l = function()
        hs.task.new("/usr/local/bin/aerospace", nil, { "join-with", "right" }):start()
      end,
    },
  },
}

local function reset()
  for _, k in ipairs(keys) do
    if k ~= keys[1] then
      k:delete()
    end
  end
  keys = { keys[1] }
end

local function bind(cmds)
  reset()
  for key, cmd in pairs(cmds) do
    table.insert(
      keys,
      hs.hotkey.bind({}, key, function()
        if type(cmd) == "table" then
          bind(cmd)
        else
          reset()
          cmd()
        end
      end)
    )
  end
  table.insert(
    keys,
    hs.hotkey.bind({}, "escape", function()
      reset()
    end)
  )
end

table.insert(
  keys,
  hs.hotkey.bind({}, "f5", function()
    bind(commands)
  end)
)

hs.pathwatcher
  .new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
    for _, file in pairs(files) do
      if file:sub(-4) == ".lua" then
        hs.reload()
        return
      end
    end
  end)
  :start()

hs.alert.show("✔︎")