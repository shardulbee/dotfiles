---@diagnostic disable: undefined-global, lowercase-global
function setup(config)
    local function require_selected_change()
        local change = context.change_id()
        if not change then
            flash("No change selected")
            return nil
        end

        return change
    end

    config.action("retrunk_this", function()
        local change = require_selected_change()
        if not change then
            return
        end

        jj("rebase", "-b", change, "-d", "main")
        revisions.refresh()
    end, {
        scope = "revisions",
        key = "t",
        desc = "Rebase selected change onto main",
    })

    config.action("retrunk_all", function()
        if not require_selected_change() then
            return
        end

        jj("rebase", "-b", "mine() & mutable()", "-d", "main")
        revisions.refresh()
    end, {
        scope = "revisions",
        key = "T",
        desc = "Rebase mine() & mutable() onto main",
    })

    config.action("open_bookmark_on_github", function()
        local function shell_quote(value)
            return "'" .. string.gsub(value, "'", "'\\''") .. "'"
        end

        local function bookmark_for_change(change)
            local output, err = jj("bookmark", "list", "-r", change, "-T", 'name ++ "\\n"')
            if err then
                return nil, err
            end

            for line in string.gmatch(output or "", "[^\r\n]+") do
                if line ~= "" then
                    return line, nil
                end
            end

            return nil, nil
        end

        local change = context.change_id()
        if not change then
            flash("No change selected")
            return
        end

        local bookmark, err = bookmark_for_change(change)
        if err then
            flash("Failed to find bookmark: " .. err)
            return
        end

        if not bookmark or bookmark == "" then
            flash("No bookmark on selected change")
            return
        end

        exec_shell("gh browse --branch " .. shell_quote(bookmark))
        flash("Opened " .. bookmark .. " on GitHub")
    end, {
        scope = "revisions",
        key = "G",
        desc = "Open bookmark branch on GitHub",
    })

    config.ui = config.ui or {}
    config.ui.theme = {
        dark = "dark",
        light = "light",
    }
end
