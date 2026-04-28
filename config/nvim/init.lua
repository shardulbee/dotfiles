-- vim: set ts=2 sw=2
---@diagnostic disable: undefined-global
vim.g.mapleader = ","

vim.pack.add({
  "https://github.com/p00f/alabaster.nvim",
  "https://github.com/tpope/vim-surround",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/nvim-treesitter/nvim-treesitter",
})

vim.o.termguicolors = true
vim.o.wrap = false
vim.o.scrolloff = 10
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.number = true
vim.o.laststatus = 3
vim.o.writebackup = false
vim.o.swapfile = false
vim.o.autowrite = true
vim.o.clipboard = "unnamedplus"
vim.o.smartindent = true
vim.o.ttimeoutlen = 0
vim.o.ignorecase = true
vim.o.grepprg = "rg --hidden --vimgrep --no-heading --smart-case"
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.keymap.set("n", "za", function()
  if vim.fn.foldclosed(".") == -1 then
    pcall(function() vim.cmd("normal! zc") end)
  else
    pcall(function() vim.cmd("normal! zO") end)
  end
end)

vim.cmd.colorscheme("alabaster")

-- nicer diffs everywhere: histogram algorithm + soft pastels
vim.opt.diffopt:append("algorithm:histogram")
vim.opt.fillchars:append({ diff = " " })
vim.api.nvim_set_hl(0, "DiffAdd",    { bg = "#dafbe1" })
vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#ffebe9", fg = "#ffebe9" })
vim.api.nvim_set_hl(0, "DiffChange", { bg = "NONE" })
vim.api.nvim_set_hl(0, "DiffText",   { bg = "#fff5b1", bold = true })

-- Native-ish VCS hunk motion for jj working-copy changes.
-- Built-in ]c/[c only work in diff windows; outside diff mode, diff the
-- current buffer against a jj rev and jump to the resulting hunk starts.
vim.g.hunk_base_rev = "@-"
vim.api.nvim_set_hl(0, "HunkAdd",    { fg = "#2da44e" })
vim.api.nvim_set_hl(0, "HunkChange", { fg = "#bf8700" })
vim.api.nvim_set_hl(0, "HunkDelete", { fg = "#cf222e" })
vim.api.nvim_set_hl(0, "HunkPreviewAdd",    { fg = "#116329", bg = "#dafbe1" })
vim.api.nvim_set_hl(0, "HunkPreviewChange", { fg = "#4d2d00", bg = "#fff8c5" })
vim.api.nvim_set_hl(0, "HunkPreviewDelete", { fg = "#82071e", bg = "#ffebe9" })
local hunk_ns = vim.api.nvim_create_namespace("jj-hunks")

local function hunk_buf_text(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines == 1 and lines[1] == "" then return "" end
  return table.concat(lines, "\n") .. "\n"
end

---@param buf? integer
---@return integer[][]
local function jj_hunks(buf)
  buf = buf or 0
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then return {} end

  local root_result = vim.system({ "jj", "root" }, {
    text = true,
    cwd = vim.fs.dirname(file),
  }):wait()
  if root_result.code ~= 0 then return {} end

  local root = vim.trim(root_result.stdout)
  local path = vim.fs.relpath(root, file)
  if not path then return {} end

  local base_result = vim.system({
    "jj", "file", "show",
    "-r", vim.g.hunk_base_rev or "@-",
    "--", path,
  }, { text = true, cwd = root }):wait()

  -- New file / missing in base: compare against empty text.
  local base = base_result.code == 0 and base_result.stdout or ""

  local diff = vim.text.diff(base, hunk_buf_text(buf), {
    result_type = "indices",
    algorithm = "histogram",
  }) or {}
  ---@cast diff integer[][]
  return diff
end

local function hunk_lnum(h, max)
  return math.min(max, math.max(1, h[3]))
end

local function refresh_hunk_signs(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, hunk_ns, 0, -1)
  if vim.bo[buf].buftype ~= "" then return end

  local hunks = jj_hunks(buf)
  local max = vim.api.nvim_buf_line_count(buf)
  for _, h in ipairs(hunks) do
    -- h = { old_start, old_count, new_start, new_count }
    -- Added/changed lines exist in the buffer, so mark every line.
    -- Deleted lines do not exist, so mark their anchor line once.
    local text, hl, start, count = "▌", "HunkChange", h[3], h[4]
    if h[2] == 0 then
      hl = "HunkAdd"
    elseif h[4] == 0 then
      text, hl, count = "_", "HunkDelete", 1
    end

    for i = 0, count - 1 do
      local lnum = math.min(max, math.max(1, start + i))
      vim.api.nvim_buf_set_extmark(buf, hunk_ns, lnum - 1, 0, {
        sign_text = text,
        sign_hl_group = hl,
        priority = 10,
      })
    end
  end
end

local function schedule_hunk_signs(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.b[buf].hunk_refresh_pending then return end
  vim.b[buf].hunk_refresh_pending = true
  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.b[buf].hunk_refresh_pending = false
    refresh_hunk_signs(buf)
  end, 150)
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "TextChangedP" }, {
  callback = function(args) schedule_hunk_signs(args.buf) end,
})

local function jump_hunk(dir)
  -- Preserve Neovim's native diff-mode ]c/[c.
  if vim.wo.diff then
    vim.cmd("normal! " .. vim.v.count1 .. (dir > 0 and "]c" or "[c"))
    return
  end

  local hunks = jj_hunks(0)
  if #hunks == 0 then
    vim.notify("no hunks")
    return
  end

  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local max = vim.api.nvim_buf_line_count(0)
  local targets = {}

  for _, h in ipairs(hunks) do
    -- h = { old_start, old_count, new_start, new_count }
    table.insert(targets, hunk_lnum(h, max))
  end

  local idx
  if dir > 0 then
    for i, lnum in ipairs(targets) do
      if lnum > cur then
        idx = i + vim.v.count1 - 1
        break
      end
    end
  else
    for i = #targets, 1, -1 do
      if targets[i] < cur then
        idx = i - vim.v.count1 + 1
        break
      end
    end
  end

  if not idx or idx < 1 or idx > #targets then
    vim.notify("no more hunks")
    return
  end

  vim.api.nvim_win_set_cursor(0, { targets[idx], 0 })
  vim.cmd("normal! zz")
end

local hunk_preview_win
local hunk_preview_group = vim.api.nvim_create_augroup("jj-hunk-preview", { clear = true })

local function close_hunk_preview()
  vim.api.nvim_clear_autocmds({ group = hunk_preview_group })
  if hunk_preview_win and vim.api.nvim_win_is_valid(hunk_preview_win) then
    vim.api.nvim_win_close(hunk_preview_win, true)
  end
  hunk_preview_win = nil
end

local function split_lines(s)
  local lines = vim.split(s, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  return lines
end

local function current_hunk()
  local hunks = jj_hunks(0)
  if #hunks == 0 then return nil end

  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local max = vim.api.nvim_buf_line_count(0)
  for _, h in ipairs(hunks) do
    local start = hunk_lnum(h, max)
    local finish = start + math.max(1, h[4]) - 1
    if cur >= start and cur <= finish then return h end
  end
end

local function preview_hunk()
  close_hunk_preview()

  local h = current_hunk()
  if not h then
    vim.notify("no hunk under cursor")
    return
  end

  local file = vim.api.nvim_buf_get_name(0)
  local root_result = vim.system({ "jj", "root" }, {
    text = true,
    cwd = vim.fs.dirname(file),
  }):wait()
  if root_result.code ~= 0 then return end

  local root = vim.trim(root_result.stdout)
  local path = vim.fs.relpath(root, file)
  if not path then return end

  local base_result = vim.system({
    "jj", "file", "show",
    "-r", vim.g.hunk_base_rev or "@-",
    "--", path,
  }, { text = true, cwd = root }):wait()

  local old = split_lines(base_result.code == 0 and base_result.stdout or "")
  local new = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local ctx = 3
  local lines = {
    string.format("@@ -%d,%d +%d,%d @@", h[1], h[2], h[3], h[4]),
  }

  local before_end = h[4] == 0 and h[3] or h[3] - 1
  for i = math.max(1, before_end - ctx + 1), before_end do
    if new[i] then table.insert(lines, " " .. new[i]) end
  end

  for i = h[1], h[1] + h[2] - 1 do
    if old[i] then table.insert(lines, "-" .. old[i]) end
  end

  for i = h[3], h[3] + h[4] - 1 do
    if new[i] then table.insert(lines, "+" .. new[i]) end
  end

  local after_start = h[4] == 0 and h[3] + 1 or h[3] + h[4]
  for i = after_start, math.min(#new, after_start + ctx - 1) do
    if new[i] then table.insert(lines, " " .. new[i]) end
  end

  local width = 20
  for _, line in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(line)) end
  width = math.min(width + 2, vim.o.columns - 4)
  local height = math.min(#lines, math.max(1, vim.o.lines - 6))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = false

  hunk_preview_win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " hunk ",
    title_pos = "left",
  })
  vim.wo[hunk_preview_win].wrap = false
  vim.wo[hunk_preview_win].cursorline = true
  vim.wo[hunk_preview_win].signcolumn = "no"
  vim.wo[hunk_preview_win].number = false
  vim.wo[hunk_preview_win].relativenumber = false
  vim.wo[hunk_preview_win].winhighlight = table.concat({
    "DiffAdd:HunkPreviewAdd", "Added:HunkPreviewAdd", "diffAdded:HunkPreviewAdd",
    "DiffChange:HunkPreviewChange", "Changed:HunkPreviewChange", "diffChanged:HunkPreviewChange",
    "DiffDelete:HunkPreviewDelete", "Removed:HunkPreviewDelete", "diffRemoved:HunkPreviewDelete",
  }, ",")

  vim.keymap.set("n", "q", close_hunk_preview, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_hunk_preview, { buffer = buf, nowait = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
    group = hunk_preview_group,
    callback = function()
      if hunk_preview_win and vim.api.nvim_get_current_win() ~= hunk_preview_win then
        close_hunk_preview()
      end
    end,
  })
end

local function preview_hunk_action()
  if hunk_preview_win and vim.api.nvim_win_is_valid(hunk_preview_win) then
    if vim.api.nvim_get_current_win() ~= hunk_preview_win then
      vim.api.nvim_set_current_win(hunk_preview_win)
    end
    return
  end
  preview_hunk()
end

vim.keymap.set("n", "]c", function() jump_hunk(1) end, { desc = "next jj hunk" })
vim.keymap.set("n", "[c", function() jump_hunk(-1) end, { desc = "previous jj hunk" })
vim.keymap.set("n", '"', preview_hunk_action, { desc = "preview/focus jj hunk" })

vim.defer_fn(function()
  require("nvim-treesitter").install({
    "bash", "html", "javascript", "json", "lua", "markdown",
    "python", "tsx", "typescript", "vim", "vimdoc", "yaml",
  })
end, 0)

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

local fzflua = require("fzf-lua")
local map = vim.keymap.set
map("n", "<leader>t", fzflua.files)
map("n", "<leader>f", fzflua.live_grep)
map("n", "<leader>h", fzflua.helptags)
map("n", "<leader>r", fzflua.command_history)
map("n", "<leader>p", fzflua.commands)
map("n", "<leader>b", fzflua.buffers)
map("n", "<leader><leader>", fzflua.builtin)

map("n", "<m-j>", function()
  vim.cmd("tabnew")

  local buf = vim.api.nvim_get_current_buf()
  vim.fn.jobstart({ "jjui" }, {
    term = true,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end,
  })

  vim.cmd("startinsert")
end, { desc = "jjui" })


vim.diagnostic.config({
  signs = false,
})


vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
})

vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

vim.lsp.enable({ "lua_ls", "vtsls" })

local pi = require("pi")
map("n", "<leader><space>", pi.with_context)
map("n", "<leader>y", function() vim.fn.setreg("+", vim.fn.expand("%")) end)

map("n", "<leader>c", function()
  local comment_prefix, comment_suffix = vim.bo.commentstring:match("^(.-)%%s(.-)$")
  if not comment_prefix then
    vim.notify("SHARVIEW: missing commentstring", vim.log.levels.ERROR)
    return
  end
  comment_suffix = comment_suffix or ""

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local indent = vim.api.nvim_get_current_line():match("^%s*") or ""
  local prefix = indent .. comment_prefix .. "SHARVIEW: "

  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { prefix .. comment_suffix })
  vim.api.nvim_win_set_cursor(0, { row, #prefix })
  vim.cmd("startinsert")
end, { desc = "insert SHARVIEW comment" })

-- :Diffmain — review every changed file vs `main` in a new tab.
-- Layout: scratch buffer (jj://main) on the left, real editable file on the right.
-- Quickfix is populated; ]q / [q swap files and the left auto-refreshes.
vim.api.nvim_create_user_command("Diffmain", function()
  local files = vim.tbl_filter(function(s) return s ~= "" end,
    vim.fn.systemlist("jj diff --from main --name-only"))
  if #files == 0 then return vim.notify("no changes vs main") end

  vim.cmd("tabnew")
  vim.fn.setqflist(vim.tbl_map(function(f)
    return { filename = f, lnum = 1, text = "" }
  end, files), "r")
  vim.cmd("cfirst")

  vim.cmd("leftabove vnew")
  local scratch = vim.api.nvim_get_current_buf()
  vim.bo[scratch].buftype = "nofile"
  vim.bo[scratch].bufhidden = "wipe"
  vim.bo[scratch].swapfile = false
  pcall(vim.api.nvim_buf_set_name, scratch, "jj://main")

  local tab = vim.api.nvim_get_current_tabpage()

  local function refresh()
    if not vim.api.nvim_buf_is_valid(scratch) then return end
    local cur = vim.api.nvim_get_current_buf()
    if cur == scratch or vim.bo[cur].buftype ~= "" then return end
    local path = vim.fn.expand("%:.")
    if path == "" then return end
    local content = vim.fn.system({ "jj", "file", "show", "-r", "main", "--", path })
    if vim.v.shell_error ~= 0 then content = "" end
    local lines = vim.split(content, "\n", { plain = true })
    if lines[#lines] == "" then table.remove(lines) end
    vim.bo[scratch].modifiable = true
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
    vim.bo[scratch].modifiable = false
    vim.bo[scratch].filetype = vim.bo[cur].filetype
    -- :cnext leaves stale diff state; tear down and rebuild.
    vim.cmd("diffoff! | windo diffthis")
  end

  vim.cmd("wincmd l")
  refresh()

  local group = vim.api.nvim_create_augroup("diffmain", { clear = true })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_tabpage() == tab then refresh() end
    end,
  })
end, {})
