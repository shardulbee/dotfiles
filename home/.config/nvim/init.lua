local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
-- Add lazy.nvim to Neovim's runtime path
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  "direnv/direnv.vim",    -- Integration with direnv for environment management
  "LnL7/vim-nix",         -- Nix language support
  "tpope/vim-eunuch",     -- Unix shell commands integration
  "tpope/vim-unimpaired", -- Pairs of handy bracket mappings
  "tpope/vim-surround",   -- Surroundings manipulation (parentheses, brackets, etc)
  "tpope/vim-sleuth",     -- Automatic indentation detection
  "tpope/vim-fugitive",   -- Git integration
  "tpope/vim-rhubarb",    -- GitHub integration
  "tpope/vim-repeat",     -- Enable repeating supported plugin maps
  "tpope/vim-dispatch",   -- Asynchronous build and test dispatcher
  {
    "ibhagwan/fzf-lua",
    config = function()
      local fzfLua = require("fzf-lua")

      fzfLua.setup({
        grep = {
          rg_opts =
          "--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
        },
        winopts = {
          height = 0.90,
          width = 0.90,
          preview = {
            winopts = {
              number = false,
            },
          },
          previewers = {
            bat = { theme = "gruvbox-dark" },
          },
        },
      })

      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<C-p>", fzfLua.commands, opts)
      vim.keymap.set("n", "gr", fzfLua.lsp_references, opts)
      vim.keymap.set("n", "<leader>hh", fzfLua.help_tags, opts)
      vim.keymap.set("n", "<leader>b", fzfLua.buffers, opts)
      vim.keymap.set("n", "<leader>f", fzfLua.blines, opts)
      vim.keymap.set("n", "<leader>F", fzfLua.live_grep_native, opts)
      vim.keymap.set("n", "<leader>s", fzfLua.lsp_document_symbols, opts)
      vim.keymap.set("n", "<leader>S", fzfLua.lsp_workspace_symbols, opts)
      vim.keymap.set("n", "<leader>gl", fzfLua.git_bcommits, opts)
      vim.keymap.set("n", "<C-t>", fzfLua.files, opts)
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup({
        contrast = "hard",
      })
      vim.cmd("colorscheme gruvbox")
    end
  },
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    }
  }
}, {})


-- Settings section {{{
vim.cmd([[filetype plugin indent on]])
vim.cmd([[syntax on]])
vim.opt.wrap = false                    -- soft wrap off
vim.opt.scrolloff = 10                  -- scroll once the cursor is < 10 lines from the bottom
vim.opt.showmatch = true                -- briefly jump to the matching bracket when the closing one is entered
vim.opt.matchtime = 3                   -- how long to jump to the matching bracket
vim.opt.tabstop = 2                     -- number of spaces to insert when tab is pressed (also controls the number of spaces used for < and >)
vim.opt.shiftwidth = 2                  -- number of spaces to use for autoindent
vim.opt.expandtab = true                -- use spaces instead of tabs
vim.opt.number = true                   -- show line numbers
vim.opt.relativenumber = true           -- show relative line numbers
vim.opt.ruler = true                    -- show the current line and column number
vim.opt.laststatus = 3                  -- always show the status line
vim.opt.showmode = true                 -- show what editing mode we are in
vim.opt.undodir = "~/.config/nvim/undo" -- where to store undo files
vim.opt.undolevels = 1000               -- number of undos to keep in memory
vim.opt.backup = false                  -- don't backup file when writing
vim.opt.writebackup = false             -- don't backup file when writing
vim.opt.swapfile = false                -- don't create swap files which allow you to recover from crashes even if you didn't save
vim.opt.showcmd = false                 -- don't show the command you are typing on the last line
vim.opt.autowrite = true                -- automatically write the file when switching buffers
vim.opt.hidden = true                   -- allow switching buffers without saving
vim.opt.clipboard = "unnamed"           -- use the system clipboard
vim.opt.backspace = "indent,eol,start"  -- allow backspacing over everything
vim.opt.smartindent = true              -- autoindent based on the previous line
vim.opt.autoread = true                 -- automatically reload files that have changed on disk
vim.opt.linebreak = true                -- wrap long lines at characters in 'breakat'
vim.opt.ttimeoutlen = 0                 -- don't wait for key codes to complete
vim.opt.ignorecase = true               -- ignore case when searching
vim.opt.history = 10000
vim.opt.encoding = "utf-8"
vim.opt.hlsearch = false -- don't highlight search results
vim.opt.incsearch = true -- search as you type
vim.opt.grepprg = "rg --hidden --vimgrep --no-heading --smart-case"
vim.opt.termguicolors = true
-- }}}

-- Create autocommand for trimming whitespace on save
vim.api.nvim_create_augroup("TRIM_WHITESPACE", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = "TRIM_WHITESPACE",
  pattern = { "*" },
  command = [[%s/\s\+$//e]],
})

-- Create autocommand to equalize window sizes when terminal is resized
vim.api.nvim_create_augroup("RESIZE_NVIM", { clear = true })
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = "RESIZE_NVIM",
  pattern = { "*" },
  callback = function()
    vim.api.nvim_command("wincmd =")
  end,
})

-- Define keymap to open current file in Zed
vim.keymap.set("n", "<leader><space>", function()
  -- Helper function to find the git root directory
  local function find_git_root()
    local current = vim.fn.expand("%:p:h")
    while current ~= "/" do
      if vim.fn.isdirectory(current .. "/.git") == 1 then
        return current
      end
      current = vim.fn.fnamemodify(current, ":h")
    end
    return nil
  end

  -- Get the git root directory
  local git_root = find_git_root()
  if not git_root then
    print("No git root found")
    return
  end

  -- Get current file path and cursor position
  local file = vim.fn.expand("%:p")
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  -- Open file in Zed at current cursor position
  vim.fn.system({ "zed", git_root, file .. ":" .. line .. ":" .. col })
end, { noremap = true, silent = true })
