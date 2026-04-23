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
  "https://github.com/neovim/nvim-lspconfig",
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
vim.o.linebreak = true
vim.o.ttimeoutlen = 0
vim.o.ignorecase = true
vim.o.grepprg = "rg --hidden --vimgrep --no-heading --smart-case"

vim.cmd.colorscheme("alabaster")

require("nvim-treesitter").setup({
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = {
    "bash", "html", "javascript", "json", "lua", "markdown",
    "python", "tsx", "typescript", "vim", "vimdoc", "yaml",
  },
})

require("fzf-lua")
local map = vim.keymap.set
map("n", "<leader>t", function() require("fzf-lua").files() end)
map("n", "<leader>f", function() require("fzf-lua").live_grep() end)
map("n", "<leader>h", function() require("fzf-lua").helptags() end)
map("n", "<leader><leader>", function() require("fzf-lua").builtin() end)


vim.diagnostic.config({
  signs = false,
})

map("n", "<leader>d", vim.diagnostic.setloclist)

vim.lsp.enable({ "lua_ls", "vtsls" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

map("n", "<leader>y", function() vim.fn.setreg("+", vim.fn.expand("%")) end)
