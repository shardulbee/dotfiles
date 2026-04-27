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

    local function shell_quote(value)
        return "'" .. string.gsub(value, "'", "'\\''") .. "'"
    end

    local function open_in_editor(files, line)
        if #files == 0 then
            exec_shell("$EDITOR")
            return
        end

        local quoted = {}
        for _, file in ipairs(files) do
            table.insert(quoted, shell_quote(file))
        end

        local command = "$EDITOR "
        if line then
            command = command .. "+" .. tostring(line) .. " "
        end
        exec_shell(command .. table.concat(quoted, " "))
    end

    local function is_current_change(change)
        local output, err = jj("log", "--no-graph", "-r", change .. " & @", "-T", 'change_id ++ "\\n"')
        if err then
            return false, err
        end

        return output and string.match(output, "%S") ~= nil
    end

    local function require_current_change()
        local change = require_selected_change()
        if not change then
            return nil
        end

        local current, err = is_current_change(change)
        if err then
            flash("Failed to check selected revision: " .. err)
            return nil
        end

        if not current then
            flash("Can only edit files from the current revision (@)")
            return nil
        end

        return change
    end

    local function first_changed_line(change, file)
        local output, err = jj("diff", "-r", change, "--git", "--color", "never", file)
        if err then
            return nil, err
        end

        local new_line = nil
        for line in string.gmatch(output or "", "[^\r\n]+") do
            local hunk_start = string.match(line, "^@@ %-[%d,]+ %+(%d+)")
            if hunk_start then
                new_line = tonumber(hunk_start) or 1
                if new_line < 1 then
                    new_line = 1
                end
            elseif new_line then
                local prefix = string.sub(line, 1, 1)
                if prefix == " " then
                    new_line = new_line + 1
                elseif prefix == "+" and string.sub(line, 1, 3) ~= "+++" then
                    return new_line, nil
                elseif prefix == "-" and string.sub(line, 1, 3) ~= "---" then
                    return new_line, nil
                end
            end
        end

        return 1, nil
    end

    config.action("revisions.diff_edit", function()
        local change = require_current_change()
        if not change then
            return
        end

        local output, err = jj("diff", "-r", change, "--name-only")
        if err then
            flash("Failed to list changed files: " .. err)
            return
        end

        local files = split_lines(output)
        open_in_editor(files)
    end, {
        scope = "revisions",
        key = "shift+e",
        desc = "Open changed files in $EDITOR",
    })

    config.action("edit_selected_file", function()
        local change = require_current_change()
        if not change then
            return
        end

        local file = context.file()
        if not file then
            flash("No file selected")
            return
        end

        local line, err = first_changed_line(change, file)
        if err then
            flash("Failed to find first changed line: " .. err)
            return
        end

        open_in_editor({ file }, line)
    end, {
        scope = "revisions.details",
        key = "shift+e",
        desc = "Open file in $EDITOR",
    })

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
