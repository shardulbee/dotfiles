-- vim: fdm=marker fdl=0
-- {{{
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
-- }}}

require("lazy").setup({
	"direnv/direnv.vim",
	"LnL7/vim-nix",
	"ziglang/zig.vim",
	"wakatime/vim-wakatime",
	"tpope/vim-eunuch",
	"tpope/vim-unimpaired",
	"tpope/vim-surround",
	"tpope/vim-sleuth",
	"tpope/vim-rhubarb",
	"tpope/vim-repeat",
	{
		"preservim/vim-markdown",
		ft = "markdown",
		config = function()
			vim.g.vim_markdown_folding_disabled = 1
			vim.g.vim_markdown_frontmatter = 1
			vim.g.vim_markdown_auto_insert_bullets = 1
			vim.g.vim_markdown_new_list_item_indent = 0
			vim.g.vim_markdown_math = 1
		end,
	},
	{
		"tpope/vim-fugitive",
		keys = {
			{ "<leader>gs", "<cmd>Git<cr>", "n", { silent = true, noremap = true } },
			{ "<leader>gp", "<cmd>Git p<cr>", "n", { silent = true, noremap = true } },
			{ "<leader>gc", "<cmd>Git commit<cr>", "n", { silent = true, noremap = true } },
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/nvim-treesitter-context",
			"RRethy/nvim-treesitter-endwise",
		},
		config = function()
			require("treesitter")
		end,
	},
	{ "knubie/vim-kitty-navigator", build = "cp ./*.py ~/.config/kitty/" },
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "kyazdani42/nvim-web-devicons" },
		keys = {
			{ "<leader>,", "<cmd>NvimTreeToggle<cr>", "n", { silent = true, noremap = true } },
		},
		config = function()
			require("nvim-tree").setup({})
		end,
	},
	{
		"RRethy/nvim-base16",
		lazy = false,
		config = function()
			vim.cmd("colorscheme base16-default-dark")
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {
			indent = { char = "▏" },
			scope = {
				show_start = false,
				show_end = false,
			},
		},
	},
	{
		"Wansmer/treesj",
		dev = false,
		keys = function()
			local treesj = require("treesj")
			return {
				{ "gS", treesj.split, "n", { silent = true, noremap = true } },
				{ "gJ", treesj.join, "n", { silent = true, noremap = true } },
			}
		end,
		config = function()
			local lang_utils = require("treesj.langs.utils")
			local treesj = require("treesj")
			treesj.setup({
				max_join_length = 150,
				langs = {
					zig = {
						InitList = lang_utils.set_preset_for_dict(),
						SwitchExpr = lang_utils.set_preset_for_list({
							join = {
								no_format_with = { "line_comment" },
							},
						}),
						FnCallArguments = lang_utils.set_preset_for_args(),
						ParamDeclList = lang_utils.set_preset_for_args(),

						Block = lang_utils.set_preset_for_statement({
							join = {
								no_format_with = { "line_comment" },
								no_insert_if = {
									lang_utils.helpers.contains({
										"IfStatement",
										"LabeledStatement",
									}),
								},
							},
							split = {
								recursive = false,
							},
						}),
					},
				},
			})
		end,
	},
	{ "numToStr/Comment.nvim", opts = {}, lazy = false },
	{
		"zbirenbaum/copilot.lua",
		event = "InsertEnter",
		cmd = "Copilot",
		opts = {
			panel = { enabled = false },
			suggestion = {
				auto_trigger = true,
				keymap = {
					accept = "<c-l>",
					next = "<c-j>",
					prev = "<c-k>",
					dismiss = "<c-e>",
				},
				filetype = {
					markdown = false,
				},
			},
		},
	},
	{
		"vim-test/vim-test",
		keys = {
			{ "<leader>tf", "<cmd>TestFile<cr>", "n", { silent = true, noremap = true } },
			{ "<leader>tn", "<cmd>TestNearest<cr>", "n", { silent = true, noremap = true } },
		},
		config = function()
			vim.g["test#strategy"] = "kitty"
		end,
	},
	{
		"ibhagwan/fzf-lua",
		config = function()
			require("fzf")
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
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
					map("n", "<leader>hp", gitsigns.preview_hunk)
					map("n", "<leader>hs", gitsigns.stage_hunk)
				end,
				preview_config = {
					border = "rounded",
					style = "minimal",
					relative = "cursor",
					row = 0,
					col = 1,
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"hrsh7th/nvim-cmp",
				"williamboman/mason.nvim",
				"williamboman/mason-lspconfig.nvim",
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/vim-vsnip",
				"hrsh7th/cmp-vsnip",
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-cmdline",
				"hrsh7th/cmp-nvim-lsp-signature-help",
				"mhartington/formatter.nvim",
				"jose-elias-alvarez/null-ls.nvim",
				"nvim-lua/plenary.nvim",
				"WhoIsSethDaniel/mason-tool-installer.nvim",
				"lewis6991/gitsigns.nvim",
				"python-lsp/python-lsp-ruff",
			},
		},
		config = function()
			require("lsp")
			require("format")
			require("completion")
		end,
	},
}, {
	dev = {
		path = "~/src/github.com/shardulbee",
	},
	change_detection = {
		enabled = true,
		notify = true,
	},
})

-- settings {{{
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

-- {{{ statusline
function _G.filetype()
	local filetype = vim.api.nvim_buf_get_option(0, "filetype")
	if filetype ~= "" then
		return string.format("filetype: %s", filetype)
	else
		return ""
	end
end

function _G.workspace_diagnostics_status()
	if #vim.lsp.buf_get_clients() == 0 then
		return ""
	end

	local status = {}
	local errors = #vim.diagnostic.get(
		0,
		{ severity = { min = vim.diagnostic.severity.ERROR, max = vim.diagnostic.severity.ERROR } }
	)
	if errors > 0 then
		table.insert(status, "ERR: " .. errors)
	end

	local warnings = #vim.diagnostic.get(
		0,
		{ severity = { min = vim.diagnostic.severity.WARNING, max = vim.diagnostic.severity.WARNING } }
	)
	if warnings > 0 then
		table.insert(status, "WARN: " .. warnings)
	end

	local hints = #vim.diagnostic.get(
		0,
		{ severity = { min = vim.diagnostic.severity.HINT, max = vim.diagnostic.severity.HINT } }
	)
	if hints > 0 then
		table.insert(status, "HINT: " .. hints)
	end

	local infos = #vim.diagnostic.get(
		0,
		{ severity = { min = vim.diagnostic.severity.INFO, max = vim.diagnostic.severity.INFO } }
	)
	if infos > 0 then
		table.insert(status, "INFO: " .. infos)
	end

	if #status > 0 then
		return table.concat(status, " | ") .. " | "
	else
		return ""
	end
end

vim.opt.statusline = " %{mode()} | %f%m%=%{v:lua.workspace_diagnostics_status()} %{v:lua.filetype()} | L:%l C:%c "
-- }}}

-- keymaps {{{
vim.api.nvim_set_keymap("n", "<space>", ":", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>d", ":bd!<cr>", { noremap = true, silent = true })

function ScreenMovement(movement)
	if vim.wo.wrap then
		return "g" .. movement
	else
		return movement
	end
end

vim.api.nvim_set_keymap("o", "j", 'v:lua.ScreenMovement("j")', { silent = true, expr = true })
vim.api.nvim_set_keymap("o", "k", 'v:lua.ScreenMovement("k")', { silent = true, expr = true })
vim.api.nvim_set_keymap("o", "0", 'v:lua.ScreenMovement("0")', { silent = true, expr = true })
vim.api.nvim_set_keymap("o", "^", 'v:lua.ScreenMovement("^")', { silent = true, expr = true })
vim.api.nvim_set_keymap("o", "$", 'v:lua.ScreenMovement("$")', { silent = true, expr = true })
vim.api.nvim_set_keymap("n", "j", 'v:lua.ScreenMovement("j")', { silent = true, expr = true })
vim.api.nvim_set_keymap("n", "k", 'v:lua.ScreenMovement("k")', { silent = true, expr = true })
vim.api.nvim_set_keymap("n", "0", 'v:lua.ScreenMovement("0")', { silent = true, expr = true })
vim.api.nvim_set_keymap("n", "^", 'v:lua.ScreenMovement("^")', { silent = true, expr = true })
vim.api.nvim_set_keymap("n", "$", 'v:lua.ScreenMovement("$")', { silent = true, expr = true })
-- }}}

-- autocmds {{{
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
-- }}}
