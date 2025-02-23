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

	"direnv/direnv.vim",
	"tpope/vim-eunuch",
	"tpope/vim-surround",
	"tpope/vim-sleuth",
	"tpope/vim-unimpaired",
	"tpope/vim-repeat",
	{
		"tpope/vim-fugitive",
		event = "VeryLazy",
		cmd = "Git",
		keys = {
			{ "<leader>gs", "<cmd>Git<cr>" },
		},
		config = function()
			vim.opt.statusline = ""
			vim.opt.statusline = "%f:%l:%c %m%=%{FugitiveStatusline()} %y"
		end,
	},

	{ "tpope/vim-rhubarb", event = "VeryLazy" },
	{ "echasnovski/mini.surround", version = false, config = true },
	{ "echasnovski/mini.pairs", version = false, config = true },
	{ "echasnovski/mini.splitjoin", version = false, config = true },
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		config = function()
			local fzfLua = require("fzf-lua")

			fzfLua.setup({
				grep = {
					rg_opts = "--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
				},
				winopts = {
					height = 0.9,
					width = 0.9,
					previewers = {
						bat = { theme = "gruvbox-dark" },
					},
					preview = {
						hidden = true,
					},
				},
				git = {
					commits = {
						winopts = { preview = { vertical = "down:60%" } },
						actions = {
							["ctrl-o"] = {
								fn = function(selected, _)
									local commit = selected[1]:match("[^ ]+")
									local cmd = "GBrowse " .. commit
									vim.cmd(commit and cmd or "GBrowse")
								end,
							},
						},
					},
				},
			})

			local opts = { noremap = true, silent = true }
			vim.keymap.set("n", "<C-t>", fzfLua.files, opts)
			vim.keymap.set("n", "<leader>h", fzfLua.help_tags, opts)
			vim.keymap.set("n", "<leader>b", fzfLua.buffers, opts)
			vim.keymap.set("n", "<leader>f", fzfLua.blines, opts)
			vim.keymap.set("n", "<leader>F", fzfLua.live_grep_native, opts)
			vim.keymap.set("n", "<leader>r", fzfLua.command_history, opts)
			vim.keymap.set("n", "<leader>p", fzfLua.commands, opts)

			vim.keymap.set("n", "<leader>co", fzfLua.git_branches, opts)
		end,
	},
	{
		"ellisonleao/gruvbox.nvim",

		priority = 1000,
		opts = {
			contrast = "hard",
			overrides = {
				SignColumn = { bg = "#1d2021" },
			},
		},
		init = function()
			vim.cmd([[colorscheme gruvbox]])
		end,
	},
	{
		"saghen/blink.cmp",
		version = "v0.9.3",
		opts = {
			keymap = { preset = "enter" },
			appearance = {
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "buffer" },
				cmdline = {},
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
		"JoosepAlviste/nvim-ts-context-commentstring",
		opts = {
			enable_autocmd = false,
		},
		config = function()
			local get_option = vim.filetype.get_option
			vim.filetype.get_option = function(filetype, option)
				return option == "commentstring"
						and require("ts_context_commentstring.internal").calculate_commentstring()
					or get_option(filetype, option)
			end
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
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
		},
		main = "nvim-treesitter.configs",
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
		},

		config = function(_, _)
			local function organize_imports()
				local params = {
					command = "typescript.organizeImports",
					arguments = { vim.fn.expand("%:p") },
				}
				vim.lsp.buf.execute_command(params)
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local client = vim.lsp.get_client_by_id(ev.data.client_id)
					if client.name == "vtsls" then
						vim.api.nvim_create_user_command(
							"OrganizeImports",
							organize_imports,
							{ desc = "Organize Imports" }
						)
					end
				end,
			})

			require("mason").setup()
			require("mason-lspconfig").setup()

			require("mason-lspconfig").setup_handlers({
				-- The first entry (without a key) will be the default handler
				-- and will be called for each installed server that doesn't have
				-- a dedicated handler.
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup({
						capabilities = require("blink.cmp").get_lsp_capabilities(),
						on_attach = function(_, bufnr)
							local opts = { noremap = true, silent = true, buffer = bufnr }
							local function buf_set_keymap(...)
								vim.keymap.set(...)
							end
							local fzfLua = require("fzf-lua")

							buf_set_keymap("n", ",ca", fzfLua.lsp_code_actions, opts)
							buf_set_keymap("n", "gs", fzfLua.lsp_document_symbols, opts)
							buf_set_keymap("n", "gl", fzfLua.lsp_document_symbols, opts)
							buf_set_keymap("n", "gL", fzfLua.lsp_workspace_symbols, opts)

							buf_set_keymap("n", "gd", vim.lsp.buf.definition, opts)
							buf_set_keymap("n", "gr", vim.lsp.buf.references, opts)
							buf_set_keymap("n", "cd", vim.lsp.buf.rename, opts)

							buf_set_keymap("n", "]d", function()
								vim.diagnostic.goto_next({ float = true, severity = vim.diagnostic.severity.ERROR })
							end, opts)
							buf_set_keymap("n", "[d", function()
								vim.diagnostic.goto_prev({ float = true, severity = vim.diagnostic.severity.ERROR })
							end, opts)
							buf_set_keymap("n", "]D", function()
								vim.diagnostic.goto_next({ float = true })
							end, opts)
							buf_set_keymap("n", "[D", function()
								vim.diagnostic.goto_prev({ float = true })
							end, opts)
						end,
					})
				end,
			})
			vim.diagnostic.config({ virtual_text = false })
		end,
	},
	{ "windwp/nvim-ts-autotag", opts = {} },
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format", "ruff_fix", lsp_format = "last" },
				javascript = { "prettierd", "eslint", stop_after_first = false },
				typescript = { "prettierd", "eslint", stop_after_first = false },
				typescriptreact = { "prettierd", "eslint", stop_after_first = false, lsp_format = "last" },
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
			on_attach = function(bufnr)
				local opts = { remap = false, silent = true }
				local gitsigns = require("gitsigns")

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
				vim.keymap.set("n", "<leader>gd", gitsigns.diffthis, opts)
			end,
		},
	},
	{
		"vim-test/vim-test",
		keys = {
			{ "<leader>tn", "<cmd>TestNearest<cr>" },
			{ "<leader>tf", "<cmd>TestFile<cr>" },

			{ "<leader>tn", "<cmd>TestNearest -s<cr>", ft = "python" },
			{ "<leader>tf", "<cmd>TestFile -s<cr>", ft = "python" },
			{ "<leader>ts", "<cmd>TestSuite -nauto -s<cr>", ft = "python" },
		},
	},
}, {})

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
vim.opt.title = true
vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"

vim.api.nvim_create_augroup("TRIM_WHITESPACE", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = "TRIM_WHITESPACE",
	pattern = { "*" },
	command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_augroup("RESIZE_NVIM", { clear = true })
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = "RESIZE_NVIM",
	pattern = { "*" },
	callback = function()
		vim.api.nvim_command("wincmd =")
	end,
})

vim.keymap.set("n", "<leader>d", function()
	vim.api.nvim_buf_delete(0, {})
end)

-- Set up autocommand to create mappings only for Python files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.keymap.set("n", "<leader>9", function()
			local pos = vim.api.nvim_win_get_cursor(0)
			local line = pos[1] - 1
			-- Get the indentation of the current line
			local current_line = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
			local indent = current_line:match("^%s*")

			vim.api.nvim_buf_set_lines(0, line, line, false, {
				indent .. "import ipdb",
				indent .. "ipdb.set_trace()",
			})
		end, { buffer = true })
		vim.keymap.set("n", "<leader>0", function()
			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			local new_lines = {}
			for _, line in ipairs(lines) do
				if not line:match("ipdb") then
					table.insert(new_lines, line)
				end
			end
			vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
		end, { buffer = true })
	end,
})
