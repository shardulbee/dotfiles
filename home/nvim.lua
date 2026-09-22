-- vim: set ts=2 sw=2
---@diagnostic disable: undefined-global
vim.g.mapleader = ","

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
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldcolumn = "1"

vim.cmd.colorscheme("alabaster")

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

local fzflua = require("fzf-lua")
local snacks = require("snacks")
snacks.setup({ explorer = {}, picker = {} })
local map = vim.keymap.set
map("n", "<leader>t", fzflua.files)
map("n", "<leader>f", fzflua.live_grep)
map("n", "<leader>h", fzflua.helptags)
map("n", "<leader>r", fzflua.command_history)
map("n", "<leader>p", fzflua.commands)
map("n", "<leader>b", fzflua.buffers)
map("n", "<leader><leader>", fzflua.builtin)

map("n", "<leader>y", function() vim.fn.setreg("+", vim.fn.expand("%")) end)
map("n", "<leader>e", function() snacks.explorer() end, { desc = "file explorer" })
