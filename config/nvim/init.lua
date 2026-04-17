-- vim: set ts=2 sw=2
---@diagnostic disable: undefined-global
vim.g.mapleader = ","

vim.pack.add({
  "https://github.com/p00f/alabaster.nvim",
  "https://github.com/tpope/vim-eunuch",
  "https://github.com/tpope/vim-surround",
  "https://github.com/tpope/vim-sleuth",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/nvim-treesitter/nvim-treesitter",
})

vim.opt.termguicolors = true
pcall(vim.cmd.colorscheme, "alabaster")

pcall(function()
  require("nvim-treesitter.configs").setup({ highlight = { enable = true }, indent = { enable = true } })
  require("nvim-treesitter").install({ "bash", "html", "javascript", "json", "lua", "markdown", "python", "tsx", "typescript", "vim", "vimdoc", "yaml" })
end)

local fzf = require("fzf-lua")
vim.keymap.set("n", "<C-t>", fzf.files)
vim.keymap.set("n", "<leader><leader>", fzf.builtin)

vim.lsp.enable({ "lua_ls", "vtsls" })
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf })
  end,
})

local o = vim.opt
o.wrap = false
o.scrolloff = 10
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.number = true
o.laststatus = 3
o.writebackup = false
o.swapfile = false
o.autowrite = true
o.clipboard = "unnamedplus"
o.smartindent = true
o.linebreak = true
o.ttimeoutlen = 0
o.ignorecase = true
o.grepprg = "rg --hidden --vimgrep --no-heading --smart-case"

local map = vim.keymap.set
map("n", "gl", "<cmd>nohl<cr>")
map("n", "<leader>d", "<cmd>bd<cr>")
map("n", "<leader>q", "<cmd>q<cr>")
map("n", "<leader>ww", "<cmd>w<cr>")
map("n", "<leader>y", function() vim.fn.setreg("+", vim.fn.expand("%")) end)
for _, k in ipairs({ "h", "j", "k", "l" }) do
  map("", "<C-" .. k .. ">", "<C-w>" .. k)
  map("t", "<C-" .. k .. ">", "<C-\\><C-n><C-w>" .. k)
end
