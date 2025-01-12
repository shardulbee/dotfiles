-- vim: ts=2
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
	"direnv/direnv.vim", -- Integration with direnv for environment management
	"LnL7/vim-nix", -- Nix language support
	"tpope/vim-eunuch", -- Unix shell commands integration
	-- "tpope/vim-unimpaired", -- Pairs of handy bracket mappings
	"tpope/vim-surround", -- Surroundings manipulation (parentheses, brackets, etc)
	"tpope/vim-sleuth", -- Automatic indentation detection
	{
		"tpope/vim-fugitive", -- Git integration
		config = function()
			---@diagnostic disable: undefined-field
			vim.opt.statusline:append("%f:%l:%c %m")
			vim.opt.statusline:append("%=")
			vim.opt.statusline:append("%{FugitiveStatusline()}")
			---@diagnostic enable: undefined-field
		end,
	},
	"tpope/vim-rhubarb", -- GitHub integration
	"tpope/vim-repeat", -- Enable repeating supported plugin maps
	"tpope/vim-dispatch", -- Asynchronous build and test dispatcher
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	{ "echasnovski/mini.pairs", version = "*", config = true },
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"saghen/blink.cmp",
				version = "v0.8.0",
				opts = {
					-- 'default' for mappings similar to built-in completion
					-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
					-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
					-- See the full "keymap" documentation for information on defining your own keymap.
					keymap = { preset = "enter" },
					sources = {
						default = { "lsp", "path", "snippets", "buffer" },
						cmdline = {},
					},
				},
			},
		},
		config = function()
			require("mason").setup()
			local mason_lspconfig = require("mason-lspconfig")

			local lspconfig = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			mason_lspconfig.setup_handlers({
				-- default handler
				function(server_name)
					lspconfig[server_name].setup({ capabilities = capabilities })
				end,
			})
		end,
	},
	{
		"ibhagwan/fzf-lua",
		config = function()
			local fzfLua = require("fzf-lua")

			fzfLua.setup({
				grep = {
					rg_opts = "--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
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
			vim.keymap.set("n", "gs", fzfLua.lsp_document_symbols, opts)
			vim.keymap.set("n", "gS", fzfLua.lsp_workspace_symbols, opts)
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
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		version = false,
		build = ":TSUpdate",
		event = { "VeryLazy" },
		lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
		init = function(plugin)
			-- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
			-- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
			-- no longer trigger the **nvim-treesitter** module to be loaded in time.
			-- Luckily, the only things that those plugins need are the custom queries, which we make available
			-- during startup.
			require("lazy.core.loader").add_to_rtp(plugin)
			require("nvim-treesitter.query_predicates")
		end,
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		keys = {
			{ "[x", desc = "Increment Selection" },
			{ "]x", desc = "Decrement Selection", mode = "x" },
		},
		opts = {
			highlight = { enable = true },
			indent = { enable = true },
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"javascript",
				"jsdoc",
				"json",
				"jsonc",
				"lua",
				"luadoc",
				"luap",
				"markdown",
				"markdown_inline",
				"printf",
				"python",
				"query",
				"regex",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "[x",
					node_incremental = "[x",
					scope_incremental = false,
					node_decremental = "]x",
				},
			},
			textobjects = {
				move = {
					enable = true,
					goto_next_start = {
						["]f"] = "@function.outer",
						["]c"] = "@class.outer",
						["]a"] = "@parameter.inner",
					},
					goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
					goto_previous_start = {
						["[f"] = "@function.outer",
						["[c"] = "@class.outer",
						["[a"] = "@parameter.inner",
					},
					goto_previous_end = {
						["[F"] = "@function.outer",
						["[C"] = "@class.outer",
						["[A"] = "@parameter.inner",
					},
				},
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff" },
				rust = { "rustfmt", lsp_format = "fallback" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		},
	},
}, {})

-- Settings section {{{
vim.cmd([[filetype plugin indent on]])
vim.cmd([[syntax on]])
vim.opt.wrap = false -- soft wrap off
vim.opt.scrolloff = 10 -- scroll once the cursor is < 10 lines from the bottom
vim.opt.showmatch = true -- briefly jump to the matching bracket when the closing one is entered
vim.opt.matchtime = 3 -- how long to jump to the matching bracket
vim.opt.tabstop = 2 -- number of spaces to insert when tab is pressed (also controls the number of spaces used for < and >)
vim.opt.shiftwidth = 2 -- number of spaces to use for autoindent
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.number = true -- show line numbers
vim.opt.relativenumber = true -- show relative line numbers
vim.opt.ruler = true -- show the current line and column number
vim.opt.laststatus = 3 -- always show the status line
vim.opt.showmode = true -- show what editing mode we are in
vim.opt.undodir = "~/.config/nvim/undo" -- where to store undo files
vim.opt.undolevels = 1000 -- number of undos to keep in memory
vim.opt.backup = false -- don't backup file when writing
vim.opt.writebackup = false -- don't backup file when writing
vim.opt.swapfile = false -- don't create swap files which allow you to recover from crashes even if you didn't save
vim.opt.showcmd = false -- don't show the command you are typing on the last line
vim.opt.autowrite = true -- automatically write the file when switching buffers
vim.opt.hidden = true -- allow switching buffers without saving
vim.opt.clipboard = "unnamed" -- use the system clipboard
vim.opt.backspace = "indent,eol,start" -- allow backspacing over everything
vim.opt.smartindent = true -- autoindent based on the previous line
vim.opt.autoread = true -- automatically reload files that have changed on disk
vim.opt.linebreak = true -- wrap long lines at characters in 'breakat'
vim.opt.ttimeoutlen = 0 -- don't wait for key codes to complete
vim.opt.ignorecase = true -- ignore case when searching
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
