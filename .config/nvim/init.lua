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

vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python3")
require("lazy").setup({
	dev = {
		path = "/Users/shardul/Documents",
	},
	spec = {
		"tpope/vim-fugitive",
		"tpope/vim-rhubarb",
		{
			"NicolasGB/jj.nvim",
			dev = true,
			opts = {},
		},
		{
			"julienvincent/hunk.nvim",
			cmd = { "DiffEditor" },
			config = function()
				require("hunk").setup()
			end,
		},
		{
			"lewis6991/gitsigns.nvim",
			opts = {
				current_line_blame = true,
				signs = {
					add = { text = "▎" },
					change = { text = "▎" },
					delete = { text = "" },
					topdelete = { text = "" },
					changedelete = { text = "▎" },
					untracked = { text = "▎" },
				},
				signs_staged = {
					add = { text = "▎" },
					change = { text = "▎" },
					delete = { text = "" },
					topdelete = { text = "" },
					changedelete = { text = "▎" },
				},
				preview_config = { border = "rounded" },
				on_attach = function(bufnr)
					local gitsigns = require("gitsigns")

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map("n", "]c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "]c", bang = true })
						else
							gitsigns.nav_hunk("next")
						end
					end)

					map("n", "[c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "[c", bang = true })
						else
							gitsigns.nav_hunk("prev")
						end
					end)

					map("n", '"', gitsigns.preview_hunk, { desc = "Gitsigns preview hunk" })
				end,
			},
		},

		{
			"nvim-neo-tree/neo-tree.nvim",
			branch = "v3.x",
			dependencies = {
				"nvim-lua/plenary.nvim",
				"MunifTanjim/nui.nvim",
				"nvim-tree/nvim-web-devicons", -- optional, but recommended
			},
			lazy = false, -- neo-tree will lazily load itself,
			keys = {
				{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
			},
			opts = {
				filesystem = {
					filtered_items = {
						hide_dotfiles = false,
						hide_gitignored = true,
						hide_hidden = false,
					},
				},
			},
		},
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
			"nvim-lualine/lualine.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = true,
			opts = {
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "diff", "diagnostics" },
					lualine_c = { { "filename", path = 1 } },
					lualine_x = { "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			},
		},
		{
			"NotAShelf/direnv.nvim",
			opts = {},
		},
		"tpope/vim-eunuch",
		"tpope/vim-surround",
		"tpope/vim-dispatch",
		"tpope/vim-sleuth",
		"tpope/vim-unimpaired",
		"tpope/vim-repeat",
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
						height = 1.0,
						width = 1.0,
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
				vim.keymap.set("v", "<leader>*", ":FzfLua grep_visual<cr>", opts)
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
					keymaps = {
						init_selection = "<space>", -- maps in normal mode to init the node/scope selection with space
						node_incremental = "<space>", -- increment to the upper named parent
						node_decremental = "<bs>", -- decrement to the previous node
						scope_incremental = "<tab>", -- increment to the upper scope (as defined in locals.scm)
					},
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

					buf_set_keymap("n", "gd", vim.lsp.buf.definition, opts)
					buf_set_keymap("n", "gr", vim.lsp.buf.references, opts)
					buf_set_keymap("n", "cd", vim.lsp.buf.rename, opts)
					buf_set_keymap("n", "]d", function()
						vim.diagnostic.goto_next({
							float = true,
							severity = { min = vim.diagnostic.severity.WARN },
						})
					end, opts)
					buf_set_keymap("n", "[d", function()
						vim.diagnostic.goto_prev({
							float = true,
							severity = { min = vim.diagnostic.severity.WARN },
						})
					end, opts)
				end

				require("mason").setup()
				require("mason-lspconfig").setup()

				vim.lsp.config("*", {
					capabilities = require("blink.cmp").get_lsp_capabilities(),
					on_attach = on_attach,
				})

				vim.diagnostic.config({
					virtual_text = true,
					severity_sort = true,
					update_in_insert = false,
					underline = false,
					float = {
						border = "rounded",
					},
				})
			end,
		},
		{ "windwp/nvim-ts-autotag", opts = {} },
		{
			"vim-test/vim-test",
			keys = {
				{ "<leader>tn", "<cmd>TestNearest<cr>", desc = "Run nearest test" },
				{ "<leader>tf", "<cmd>TestFile<cr>", desc = "Run current file tests" },
				{ "<leader>tl", "<cmd>TestLast<cr>", desc = "Re-run last test" },
			},
			config = function()
				vim.g["test#strategy"] = "neovim"
				for _, ft in ipairs({ "javascript", "typescript" }) do
					vim.g[string.format("test#%s#runner", ft)] = "jest"
					vim.g[string.format("test#%s#jest#executable", ft)] =
						"node --expose-gc --max-old-space-size=5000 --stack-trace-limit=1000 --experimental-vm-modules --trace-uncaught node_modules/jest/bin/jest.js --logHeapUsage --runInBand --forceExit"
				end
			end,
		},
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
	},
})

vim.cmd([[filetype plugin indent on]])
vim.cmd([[syntax on]])

-- Define mode display function
vim.opt.wrap = false
vim.opt.scrolloff = 10
vim.opt.showmatch = true
vim.opt.matchtime = 3
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.showcmd = false
vim.opt.autowrite = true
vim.opt.clipboard = "unnamed"
vim.opt.backspace = "indent,eol,start"
vim.opt.smartindent = true
vim.opt.linebreak = true
vim.opt.ttimeoutlen = 0
vim.opt.ignorecase = true
vim.opt.incsearch = false
vim.opt.grepprg = "rg --hidden --vimgrep --no-heading --smart-case"

vim.keymap.set("n", "<leader>c", function()
	for _, win in ipairs(vim.fn.getwininfo()) do
		if win.quickfix == 1 then
			vim.cmd("cclose")
			return
		end
	end
	vim.cmd("copen")
end, { noremap = true, silent = true, desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>gb", "<cmd>GBrowse<cr>", { noremap = true, silent = true, desc = "Open in browser" })
vim.keymap.set("v", "<leader>gb", ":GBrowse<CR>", { silent = true, desc = "Open selection in browser" })

vim.keymap.set("n", "gl", "<cmd>nohl<cr>", { silent = true, desc = "Remove search highlighting" })

vim.api.nvim_create_augroup("TRIM_WHITESPACE", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = "TRIM_WHITESPACE",
	pattern = { "*" },
	command = [[%s/\s\+$//e]],
})
