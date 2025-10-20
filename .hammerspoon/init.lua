---@diagnostic disable: undefined-global

local keys = {}
local commands = {
  c = function()
    hs.urlevent.openURL("raycast://extensions/raycast/clipboard-history/clipboard-history")
  end,
  h = { c = hs.toggleConsole, r = hs.reload },
  o = {
    s = function()
      hs.application.launchOrFocus("Slack")
    end,
    m = function()
      hs.urlevent.openURL("https://mail.google.com/mail/u/0/#inbox")
    end,
    c = function()
      hs.urlevent.openURL("https://calendar.google.com/calendar/u/0/r")
    end,
  },
  w = {
    d = function()
      hs.task.new("/opt/homebrew/bin/aerospace", nil, { "enable", "toggle" }):start()
    end,
    t = function()
      hs.task.new("/opt/homebrew/bin/aerospace", nil, { "layout", "tiles", "vertical", "horizontal" }):start()
    end,
    s = function()
      hs.task.new("/opt/homebrew/bin/aerospace", nil, { "layout", "accordion", "vertical", "horizontal" }):start()
    end,
    f = function()
      hs.task.new("/opt/homebrew/bin/aerospace", nil, { "layout", "floating", "tiling" }):start()
    end,
    r = function()
      hs.task.new("/opt/homebrew/bin/aerospace", nil, { "reload-config" }):start()
    end,
    j = {
      h = function()
        hs.task.new("/opt/homebrew/bin/aerospace", nil, { "join-with", "left" }):start()
      end,
      j = function()
        hs.task.new("/opt/homebrew/bin/aerospace", nil, { "join-with", "down" }):start()
      end,
      k = function()
        hs.task.new("/opt/homebrew/bin/aerospace", nil, { "join-with", "up" }):start()
      end,
      l = function()
        hs.task.new("/opt/homebrew/bin/aerospace", nil, { "join-with", "right" }):start()
      end,
    },
  },
}

local function bind(cmds)
  for _, k in ipairs(keys) do
    if k ~= keys[1] then
      k:delete()
    end
  end
  keys = { keys[1] }
  for key, cmd in pairs(cmds) do
    table.insert(
      keys,
      hs.hotkey.bind({}, key, function()
        if type(cmd) == "table" then
          bind(cmd)
        else
          for _, k in ipairs(keys) do
            if k ~= keys[1] then
              k:delete()
            end
          end
          keys = { keys[1] }
          cmd()
        end
      end)
    )
  end
  table.insert(
    keys,
    hs.hotkey.bind({}, "escape", function()
      for _, k in ipairs(keys) do
        if k ~= keys[1] then
          k:delete()
        end
      end
      keys = { keys[1] }
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
