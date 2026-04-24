local map = vim.keymap.set

-- Stream pi --mode json output into a buffer without blocking the UI.
-- append=true is used by follow-ups so prior output stays intact.
local function run_pi(args, buf, append)
  append = append or false
  -- When appending, start writing at the end so we don't overwrite previous runs.
  local offset = append and vim.api.nvim_buf_line_count(buf) or 0
  -- Seed content so the buffer isn't empty while waiting for the first JSON event.
  local content = "⏳ pi is thinking..."
  -- Buffered partial stdout chunks (json lines may split across tcp packets).
  local tail = ""
  -- Coalesce rapid stdout callbacks into a single vim.schedule redraw.
  local dirty = false

  local function draw()
    dirty = false
    -- Always redraw the entire content block from offset to end.
    local lines = vim.split(content, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(buf, offset, -1, false, lines)
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      vim.api.nvim_win_set_cursor(win, { offset + #lines, 0 })
    end
  end

  local function touch()
    if dirty then return end
    dirty = true
    -- vim.schedule batches redraws so rapid json deltas don't lock the ui.
    vim.schedule(draw)
  end

  -- Append streaming assistant text inline (json text_delta events).
  local function text(s)
    content = content .. s
    touch()
  end

  -- Insert a meta-event (tool call, compaction, retry) with blank-line separation.
  local function event(s)
    content = (content ~= "" and content:gsub("\n+$", "") .. "\n\n" or "") .. s .. "\n\n"
    touch()
  end

  -- Reload the source file after pi edits it externally, but only if the
  -- user hasn't modified it in the meantime (avoid clobbering).
  local function reload()
    local file = vim.b[buf] and vim.b[buf].pi_file or ""
    if file == "" then return end
    vim.schedule(function()
      local b = vim.fn.bufnr(file)
      if b ~= -1 and not vim.bo[b].modified then
        vim.api.nvim_buf_call(b, function() vim.cmd("silent! edit") end)
      end
    end)
  end

  -- Dispatch json event types emitted by pi --mode json.
  local handlers = {
    message_update = function(ev)
      local d = ev.assistantMessageEvent
      if d and d.type == "text_delta" then text(d.delta) end
    end,
    tool_execution_start = function(ev)
      local d = ev.args and (ev.args.path or ev.args.file) or ""
      event("🔧 " .. ev.toolName .. (d ~= "" and " " .. d or ""))
    end,
    compaction_start = function(ev)
      event("⋯ compacting context (" .. ev.reason .. ")")
    end,
    compaction_end = function()
      event("✓ compacted")
    end,
    auto_retry_start = function(ev)
      event("⚠ retry " .. ev.attempt .. "/" .. ev.maxAttempts .. ": " .. (ev.errorMessage or ""):gsub("\n", " "):sub(1, 200))
    end,
    tool_execution_end = function(ev)
      if ev.toolName == "edit" and not ev.isError then reload() end
    end,
  }

  local function handle(line)
    local ok, ev = pcall(vim.json.decode, line)
    if not ok then return end
    local h = handlers[ev.type]
    if h then h(ev) end
  end

  -- Accumulate partial stdout lines and flush complete ones to handle().
  local function push(data)
    if not data then return end
    tail = tail .. data
    while true do
      local i = tail:find("\n")
      if not i then break end
      handle(tail:sub(1, i - 1))
      tail = tail:sub(i + 1)
    end
  end

  -- Enable writing so draw() can populate the buffer; lock it again after.
  vim.bo[buf].modifiable = true
  draw()

  -- Run pi async so nvim stays responsive during long llm calls.
  vim.system(args, { text = true, stdout = function(_, d) push(d) end }, function(r)
    vim.schedule(function()
      if r.code ~= 0 then
        event("[pi failed: " .. (#r.stderr > 0 and r.stderr or "unknown error") .. "]")
      elseif tail ~= "" then
        handle(tail)
        reload()
      end
      draw()
      -- Mark readonly and unmodified so nvim doesn't prompt to save scratch output.
      vim.bo[buf].modifiable = false
      vim.bo[buf].modified = false
    end)
  end)
end

-- Continue the conversation in an existing pi output buffer.
-- -c resumes the session so prior context is preserved.
local function pi_follow_up()
  local buf = vim.api.nvim_get_current_buf()
  -- Guard: only run inside buffers created by pi_with_context.
  if not (vim.b[buf] and vim.b[buf].pi_output) then return end

  vim.ui.input({ prompt = "pi follow up> " }, function(prompt)
    if not prompt or vim.trim(prompt) == "" then return end
    prompt = vim.trim(prompt)

    local args = { "pi", "-c", "-p", "--mode", "json", prompt }

    -- Insert a separator before appending the follow-up output.
    vim.bo[buf].modifiable = true
    local n = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_set_lines(buf, n, -1, false, { "", "---", "" })

    -- true = append to existing content instead of replacing.
    run_pi(args, buf, true)
  end)
end

-- Open a side scratch buffer, feed pi the current file + cursor position,
-- and stream the response. The buffer is reused for follow-ups.
local function pi_with_context()
  vim.ui.input({ prompt = "pi> " }, function(prompt)
    if not prompt or vim.trim(prompt) == "" then return end
    prompt = vim.trim(prompt)

    local file = vim.fn.expand("%:p")
    local relfile = vim.fn.expand("%")
    local linenr = vim.fn.line(".")
    local args = {
      "pi", "--provider", "fireworks",
      "--model", "accounts/fireworks/models/kimi-k2p6",
      "-p", "--mode", "json",
    }
    -- Prompt first, then file.
    if file ~= "" then
      prompt = prompt .. "\n(cursor at line " .. linenr .. " in " .. relfile .. ")"
    end
    table.insert(args, prompt)
    if file ~= "" then
      table.insert(args, "@" .. relfile)
    end

    -- Open a side panel so the source window stays in context.
    vim.cmd("botright vnew")
    local buf = vim.api.nvim_get_current_buf()
    -- hide keeps the buffer alive when the split closes (needed for follow-ups).
    vim.bo[buf].bufhidden = "hide"
    -- nofile + modified=false prevents "save changes?" prompts on scratch output.
    vim.bo[buf].buftype = "nofile"
    vim.wo.wrap = true
    -- Mark this as a pi scratch buffer and remember which file was edited.
    vim.b[buf].pi_output = true
    vim.b[buf].pi_file = file

    -- In the scratch buffer, <leader><space> continues instead of spawning a new panel.
    map("n", "<leader><space>", pi_follow_up, { buffer = buf })

    run_pi(args, buf)
  end)
end

return { with_context = pi_with_context }
