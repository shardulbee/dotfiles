-- vim: set ts=2 sw=2
---@diagnostic disable: undefined-global
vim.g.mapleader = ","

vim.pack.add({
  "https://github.com/junegunn/goyo.vim",
  "https://github.com/tpope/vim-surround",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/nvim-treesitter/nvim-treesitter",
})

vim.o.wrap = false
vim.o.scrolloff = 10
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.number = true
vim.o.laststatus = 3
vim.o.swapfile = false
vim.o.autowrite = true
vim.o.clipboard = "unnamedplus"
vim.o.ignorecase = true
vim.o.grepprg = "rg --hidden --vimgrep --no-heading --smart-case"
vim.cmd.colorscheme("alabaster")

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

-- Markdown is the one prose-oriented file type. Wrap at word boundaries and
-- preserve indentation on continuation lines. The buffer-local mappings make
-- j/k follow displayed lines, rather than jumping across an entire soft-wrapped
-- paragraph. Other file types keep the global nowrap setting and normal j/k.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.keymap.set("n", "j", "gj", { buffer = args.buf })
    vim.keymap.set("n", "k", "gk", { buffer = args.buf })
  end,
})

-- Goyo installs a TermClose handler which queues a pad resize with feedkeys().
-- That races with our automatic Goyo exit when fzf-lua selects a non-Markdown
-- buffer: Goyo deletes t:goyo_dim, then the queued resize tries to use it and
-- fills the screen with E121 errors. fzf-lua uses a floating terminal, so its
-- closure does not require Goyo's pad workaround. Keep Goyo's VimResized hook,
-- but remove only this unsafe hook each time Goyo creates its autocmd group.
-- Do not remove this without reproducing `README.md -> ,b -> code file` in
-- tmux.
vim.api.nvim_create_autocmd("User", {
  pattern = "GoyoEnter",
  callback = function()
    vim.api.nvim_clear_autocmds({ group = "goyo", event = "TermClose" })
  end,
})

-- Goyo is a temporary tab containing the document and four unlisted padding
-- buffers. Automatically mirror writing mode to the current file type. Both
-- events are needed: BufEnter handles normal buffer switches, while BufWinEnter
-- gives filetype detection a second chance when a buffer is first displayed.
local changing_goyo = false
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  callback = function(args)
    -- Creating and closing Goyo fires these same events. Without this guard the
    -- callback re-enters itself. Without the nofile check, a Goyo pad looks
    -- like a non-Markdown buffer and immediately shuts writing mode back down.
    if changing_goyo or vim.bo[args.buf].buftype == "nofile" then return end

    local markdown = vim.bo[args.buf].filetype == "markdown"
    -- Goyo's dimensions are tab-local and exist only while its tab is active.
    local goyo = vim.fn.exists("t:goyo_dim") == 1

    if markdown and not goyo then
      changing_goyo = true
      -- Enter after the buffer event finishes. Entering inline interferes with
      -- Goyo's alternate-window bookkeeping and can leave focus on a pad. The
      -- checks matter because the user may switch buffers before this runs.
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf)
            and vim.api.nvim_get_current_buf() == args.buf
            and vim.bo[args.buf].filetype == "markdown"
            and vim.fn.exists("t:goyo_dim") == 0 then
          vim.cmd("Goyo 80")
        end
        changing_goyo = false
      end)
    elseif not markdown and goyo then
      -- Goyo! closes its temporary tab. A buffer selected inside that tab can
      -- otherwise be unloaded with it, so hide it briefly, close Goyo, then put
      -- that same buffer in the restored window before restoring bufhidden.
      local bufhidden = vim.bo[args.buf].bufhidden
      vim.bo[args.buf].bufhidden = "hide"
      changing_goyo = true
      vim.cmd("Goyo!")
      vim.api.nvim_set_current_buf(args.buf)
      changing_goyo = false
      vim.bo[args.buf].bufhidden = bufhidden
    end
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

map("n", "<leader>y", function() vim.fn.setreg("+", vim.fn.expand("%")) end)
map("n", "<leader>e", ":Explore<cr>")

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

