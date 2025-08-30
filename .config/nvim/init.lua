-- vim: set ts=2 sw=2
---@diagnostic disable: undefined-global

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
vim.opt.rtp:prepend(lazypath)

-- Configure Python host before loading plugins
vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python3")

require("lazy").setup({
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = true,
		opts = {
			contrast = "hard",
		},
		init = function()
			vim.cmd("colorscheme gruvbox")
		end,
	},
	{
		"stevearc/oil.nvim",
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {},
		-- Optional dependencies
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
		-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
		lazy = false,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = true,
		opts = {
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "diff", "diagnostics" },
				lualine_c = { "filename" },
				lualine_x = { "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},
	{
		"supermaven-inc/supermaven-nvim",
		opts = {
			color = {
				suggestion_color = "#ffffff",
				cterm = 244,
			},
			log_level = "off",
		},
	},
	"nvim-lua/plenary.nvim",
	"direnv/direnv.vim",
	"tpope/vim-eunuch",
	"tpope/vim-surround",
	"tpope/vim-dispatch",
	"tpope/vim-sleuth",
	"tpope/vim-unimpaired",
	"tpope/vim-repeat",
	"tpope/vim-dadbod",
	"tpope/vim-vinegar",
	{ "echasnovski/mini.pairs", version = false, config = true },
	{ "echasnovski/mini.splitjoin", version = false, config = true },
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		config = function()
			local fzfLua = require("fzf-lua")

			fzfLua.setup({
				fzf_opts = {
					["--ansi"] = "",
					["--prompt"] = "> ",
					["--info"] = "hidden",
					["--layout"] = "reverse",
				},
				winopts = {
					height = 0.9,
					width = 0.9,
				},
				oldfiles = {
					cwd_only = true,
				},
			})

			local opts = { noremap = true, silent = true }
			vim.keymap.set("n", "<C-t>", fzfLua.files, opts)
			vim.keymap.set("n", "<M-t>", fzfLua.oldfiles, opts)
			vim.keymap.set("n", "<leader>h", fzfLua.help_tags, opts)
			vim.keymap.set("n", "<leader>b", fzfLua.buffers, opts)
			vim.keymap.set("n", "<leader>f", fzfLua.blines, opts)
			vim.keymap.set("n", "<leader>F", fzfLua.live_grep_native, opts)
			vim.keymap.set("n", "<leader>r", fzfLua.command_history, opts)
			vim.keymap.set("n", "<leader>z", "<cmd>Fzf<cr>", opts)
		end,
	},
	{
		"saghen/blink.cmp",
		version = "v1.0.0",

		opts = {
			completion = {
				list = { selection = { preselect = true, auto_insert = true } },
			},
			keymap = { preset = "enter" },
			appearance = {
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "buffer" },
			},
		},
	},
	"williamboman/mason-lspconfig.nvim",
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
				"clangd",
				"clang-format",
				"rust-analyzer",
				"rubyfmt",
				"prettier",
				"prettierd",
				"eslint_d",
				"lua-language-server",
				"css-lsp",
				"fixjson",
				"html-lsp",
				"zls",
			},
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					-- trigger FileType event to possibly load this newly installed LSP server
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)

			mr.refresh(function()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end)
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			{ "nvim-treesitter/nvim-treesitter-textobjects", event = "VeryLazy" },
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		build = ":TSUpdate",
		event = { "VeryLazy" },
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
			textobjects = {
				select = {
					enable = true,
					look = true,
					keymaps = {
						["if"] = "@function.inner",
						["af"] = "@function.outer",
					},
				},
			},
			incremental_selection = {
				enable = true,
				-- keymaps = {
				-- },
			},
		},
		main = "nvim-treesitter.configs",
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"saghen/blink.cmp",
		},

		config = function(_, _)
			local on_attach = function(_, bufnr)
				local opts = { noremap = true, silent = true, buffer = bufnr }
				local function buf_set_keymap(...)
					vim.keymap.set(...)
				end
				local fzfLua = require("fzf-lua")

				buf_set_keymap("n", ",ca", fzfLua.lsp_code_actions, opts)
				buf_set_keymap("n", "gl", fzfLua.lsp_document_symbols, opts)

				buf_set_keymap("n", "gd", vim.lsp.buf.definition, opts)
				buf_set_keymap("n", "gr", vim.lsp.buf.references, opts)
				buf_set_keymap("n", "cd", vim.lsp.buf.rename, opts)
				buf_set_keymap("n", "]d", function()
					vim.diagnostic.goto_next({ float = true })
				end, opts)
				buf_set_keymap("n", "[d", function()
					vim.diagnostic.goto_prev({ float = true })
				end, opts)
			end

			require("mason").setup()
			require("mason-lspconfig").setup()

			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
				on_attach = on_attach,
			})

			vim.lsp.config.lua_ls = {
				on_attach = on_attach,
				on_init = function(client)
					if client.workspace_folders then
						local path = client.workspace_folders[1].name
						if path == "/Users/shardul" then
							return
						end
						if
							path ~= vim.fn.stdpath("config")
							and (vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc"))
						then
							return
						end
					end
				end,
			}

			-- vtsls (Vue/TypeScript Language Server) configuration with memory optimizations for large projects
			vim.diagnostic.config({ virtual_text = false })
		end,
	},
	{ "windwp/nvim-ts-autotag", opts = {} },
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = {
				timeout_ms = 3000,
				lsp_format = "fallback",
			},
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format", "ruff_fix", lsp_format = "last" },
				javascript = { "prettierd" },
				typescript = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescriptreact = { "prettierd" },
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			current_line_blame_opts = {
				virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
				delay = 200,
				ignore_whitespace = true,
			},
			current_line_blame = true,
			on_attach = function(_)
				local opts = { remap = false, silent = true }
				local gitsigns = package.loaded.gitsigns
				if vim.g.gitgutter_diff_base then
					-- defer to ensure it happens after setup, I think this variable when set with -C might be set after the plugin has loaded
					vim.defer_fn(function()
						gitsigns.change_base(vim.g.gitgutter_diff_base, true)
					end, 100)
				end

				vim.keymap.set("n", "]c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gitsigns.nav_hunk("next")
					end
				end, opts)

				vim.keymap.set("n", "[c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gitsigns.nav_hunk("prev")
					end
				end, opts)

				-- Actions
				vim.keymap.set("n", '"', gitsigns.preview_hunk, opts)
			end,
		},
	},
})

vim.cmd([[filetype plugin indent on]])
vim.cmd([[syntax on]])

-- Define mode display function
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
vim.opt.showmode = false -- show what editing mode we are in
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
vim.opt.title = true
vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
vim.opt.tags = "./tags,./.tags"

vim.api.nvim_create_augroup("TRIM_WHITESPACE", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = "TRIM_WHITESPACE",
	pattern = { "*" },
	command = [[%s/\s\+$//e]],
})
