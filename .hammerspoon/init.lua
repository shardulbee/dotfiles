local leaderkey = require('leaderkey')
leaderkey.escapeKey = { {}, "escape" }
local singleKey = leaderkey.singleKey
local helper = require("helpers")

local common = {
    ["c"] = {
        alias = "clipboard",
        fn = helper.openUrl("raycast://extensions/raycast/clipboard-history/clipboard-history"),
    },

    ["h"] = {
        alias = "hammerspoon",
        sub_mappings = {
            ["c"] = { alias = "console", fn = hs.toggleConsole },
            ["r"] = { alias = "reload", fn = hs.reload },
        },
    },

    ["o"] = {
        alias = "open",
        sub_mappings = {
            ["s"] = { alias = "slack", fn = helper.launchOrFocusApp("Slack") },
            ["n"] = { alias = "obsidian", fn = helper.launchOrFocusApp("Obsidian") },
        },
    },

    ["w"] = {
        alias = "window",
        sub_mappings = {
            ["d"] = { alias = "disable", fn = helper.aerospace({ "enable", "toggle" }) },
            ["t"] = { alias = "tiles", fn = helper.aerospace({ "layout", "tiles", "vertical", "horizontal" }) },
            ["s"] = { alias = "stack", fn = helper.aerospace({ "layout", "accordion", "vertical", "horizontal" }) },
            ["f"] = { alias = "float", fn = helper.aerospace({ "layout", "floating", "tiling" }) },
            ["r"] = { alias = "reload", fn = helper.aerospace({ "reload-config" }) },
            ["j"] = {
                alias = "join",
                sub_mappings = {
                    ["h"] = { alias = "left", fn = helper.aerospace({ "join-with", "left" }) },
                    ["j"] = { alias = "down", fn = helper.aerospace({ "join-with", "down" }) },
                    ["k"] = { alias = "up", fn = helper.aerospace({ "join-with", "up" }) },
                    ["l"] = { alias = "right", fn = helper.aerospace({ "join-with", "right" }) },
                },
            },
        },
    },
}
local personal = {
    ["o"] = {
        alias = "open",
        sub_mappings = {
            ["i"] = { alias = "messages", fn = helper.launchOrFocusApp("Messages") },
            ["m"] = {
                alias = "mail",
                fn = helper.openUrl("https://app.fastmail.com/mail/Inbox"),
            },
        },
    },
}
local work = {
    ["o"] = {
        alias = "open",
        sub_mappings = {
            ["m"] = {
                alias = "mail",
                fn = helper.openUrl("https://mail.google.com/mail/u/0/"),
            },
            ["c"] = {
                alias = "calendar",
                fn = helper.openUrl("https://calendar.google.com/calendar/u/0/r"),
            },
        },
    },
}

-- Current mode (default to personal)
local currentMode = "personal"

-- Function to merge nested mappings
-- Recursively merges two nested mapping tables.
-- If keys conflict, it merges sub_mappings if both values have them,
-- otherwise, it prefers the value from the 'extra' table or reports errors for alias/structure/type conflicts.
-- @param base table The base mapping table.
-- @param extra table The table with mappings to merge into the base.
-- @return table The merged mapping table.
local function mergeMappings(base, extra)
    local result = {}

    -- Copy all entries from base
    for k, v in pairs(base) do
        result[k] = v
    end

    -- Add or merge entries from extra
    for k, v in pairs(extra) do
        if result[k] == nil then
            result[k] = v
        elseif type(result[k]) == "table" and type(v) == "table" then
            -- Check for alias conflict
            if result[k].alias ~= v.alias then
                hs.showError("Alias conflict for key '" .. k .. "': '" .. result[k].alias .. "' vs '" .. v.alias .. "'")
            end

            -- Check if both have sub_mappings
            if result[k].sub_mappings and v.sub_mappings then
                -- Merge sub_mappings recursively
                result[k] = {
                    alias = result[k].alias,
                    sub_mappings = mergeMappings(result[k].sub_mappings, v.sub_mappings),
                }
            elseif result[k].fn and v.fn then
                -- Prefer the 'extra' one if both have 'fn'
                result[k] = v
            else
                -- Structure conflict (e.g., one has fn, one has sub_mappings)
                hs.showError("Structure conflict for key '" .. k .. "'")
            end
        else
            hs.showError("Type conflict for key '" .. k .. "'")
        end
    end

    return result
end

-- Transforms a nested mapping table into a format suitable for RecursiveBinder.
-- It converts the alias-based structure into key-function pairs, recursively handling sub_mappings.
-- @param t table The nested mapping table to transform.
-- @return table The transformed table ready for RecursiveBinder.
local function transform(t)
    local transformed = {}
    for keyChar, val in pairs(t) do
        local name = val.alias

        if val.sub_mappings then
            transformed[singleKey(keyChar, name)] = transform(val.sub_mappings)
        else
            transformed[singleKey(keyChar, name)] = val.fn
        end
    end
    return transformed
end

-- Function to rebuild and rebind the mappings
local function rebindMappings()
    local finalMappings
    if currentMode == "work" then
        finalMappings = mergeMappings(common, work)
    else
        finalMappings = mergeMappings(common, personal)
    end

    -- Add mode switching submenu
    if not finalMappings["m"] then
        finalMappings["m"] = {
            alias = "mode",
            sub_mappings = {
                ["w"] = {
                    alias = "work",
                    fn = function()
                        currentMode = "work"
                        hs.alert.show("Switched to WORK mode")
                        rebindMappings()
                    end,
                },
                ["p"] = {
                    alias = "personal",
                    fn = function()
                        currentMode = "personal"
                        hs.alert.show("Switched to PERSONAL mode")
                        rebindMappings()
                    end,
                },
                ["t"] = {
                    alias = "toggle",
                    fn = function()
                        currentMode = currentMode == "work" and "personal" or "work"
                        hs.alert.show("Switched to " .. string.upper(currentMode) .. " mode")
                        rebindMappings()
                    end,
                },
            },
        }
    end

    -- Unbind the old hotkey before creating a new one
    if RecursiveBinderHotkey then
        RecursiveBinderHotkey:delete()
    end

    -- Create new binding
    RecursiveBinderHotkey = hs.hotkey.bind({}, "f5", leaderkey.recursiveBind(transform(finalMappings)))
end

-- Global variable to store the hotkey
RecursiveBinderHotkey = nil

-- Initial binding
rebindMappings()

hs.hotkey.setLogLevel("nothing")

-- Auto-reload config on changes
ConfigWatcher = hs.pathwatcher
    .new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
        local doReload = false
        for _, file in pairs(files) do
            if file:sub(-4) == ".lua" then
                doReload = true
            end
        end
        if doReload then
            hs.reload()
        end
    end)
    :start()

hs.alert.show(" ✔︎")
