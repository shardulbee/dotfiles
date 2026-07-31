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

-- Wrap Markdown on words and make j/k follow displayed lines. Other file types
-- keep nowrap and normal j/k.
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

-- Goyo queues a resize when fzf-lua's terminal closes. Auto-exit can delete
-- t:goyo_dim before it runs, causing E121. fzf-lua floats, so remove only this
-- TermClose hook; keep VimResized. Before removing, reproduce in tmux with:
-- README.md -> ,b -> code file.
vim.api.nvim_create_autocmd("User", {
  pattern = "GoyoEnter",
  callback = function()
    vim.api.nvim_clear_autocmds({ group = "goyo", event = "TermClose" })
  end,
})

-- Mirror Goyo to the file type. BufWinEnter catches buffers whose filetype was
-- not ready at BufEnter.
local changing_goyo = false
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  callback = function(args)
    -- Goyo fires these events itself; its nofile pads must not turn it off.
    if changing_goyo or vim.bo[args.buf].buftype == "nofile" then return end

    local markdown = vim.bo[args.buf].filetype == "markdown"
    local goyo = vim.fn.exists("t:goyo_dim") == 1

    if markdown and not goyo then
      changing_goyo = true
      -- Entering inline can leave focus on a Goyo pad. Recheck after scheduling
      -- because the user may have switched buffers.
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
      -- Goyo! closes its tab. Keep the selected buffer alive and restore it in
      -- the original tab.
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

