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
		"tpope/vim-fugitive",
		keys = { { "<leader>gs", "<cmd>Git<cr>", "n", { silent = true, noremap = true } } },
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
			require("treesitter-context").setup()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"ruby",
					"python",
					"rust",
					"lua",
					"ocaml",
					"nix",
					"zig",
				},
				auto_install = false,
				disable = { "markdown" },
				highlight = {
					additional_vim_regex_highlighting = false,
					enable = true,
				},
				indent = {
					enable = true,
					disable = { "ruby" },
				},
				endwise = {
					enable = true,
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true,

						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = {
								query = "@class.inner",
								desc = "Select inner part of a class region",
							},
						},
					},
				},
			})
		end,
	},
	{ "knubie/vim-kitty-navigator", build = "cp ./*.py ~/.config/kitty/" },
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "kyazdani42/nvim-web-devicons" },
		keys = {
			-- map C-K C-B to toggle the tree
			{ "<C-K><C-B>", "<cmd>NvimTreeToggle<cr>", "n", { silent = true, noremap = true } },
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
	"airblade/vim-gitgutter",
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
vim.opt.incsearch = true -- search as you type
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
vim.opt.list = false -- dont show tabs as >- and trailing spaces as .
vim.opt.ttimeoutlen = 0 -- don't wait for key codes to complete
vim.opt.ignorecase = true -- ignore case when searching
vim.opt.history = 10000 -- keep 10000 lines of history
vim.opt.encoding = "utf-8" -- use utf-8 encoding
vim.opt.hlsearch = false -- don't highlight search results
vim.opt.background = "dark" -- assume a dark background
vim.opt.grepprg = "rg --hidden --vimgrep --no-heading --smart-case" -- use ripgrep for :grep
vim.opt.conceallevel = 2 -- mostly important for concealling markdown links and other formatting
vim.opt.termguicolors = true -- use gui colors in the terminal
vim.o.updatetime = 50
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
vim.api.nvim_set_keymap("n", "<tab>", "za", { noremap = true })
vim.api.nvim_set_keymap("i", "jk", "<esc>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>d", ":bd!<cr>", { noremap = true, silent = true })

function WrappedMovement(movement)
	return function()
		if vim.o.wrap then
			return "g" .. movement
		else
			return movement
		end
	end
end

vim.keymap.set("o", "j", WrappedMovement("j"), { expr = true, remap = false, silent = true })
vim.keymap.set("o", "k", WrappedMovement("k"), { expr = true, remap = false, silent = true })
vim.keymap.set("o", "0", WrappedMovement("0"), { expr = true, remap = false, silent = true })
vim.keymap.set("o", "^", WrappedMovement("^"), { expr = true, remap = false, silent = true })
vim.keymap.set("o", "$", WrappedMovement("$"), { expr = true, remap = false, silent = true })
vim.keymap.set("n", "j", WrappedMovement("j"), { expr = true, remap = false, silent = true })
vim.keymap.set("n", "k", WrappedMovement("k"), { expr = true, remap = false, silent = true })
vim.keymap.set("n", "0", WrappedMovement("0"), { expr = true, remap = false, silent = true })
vim.keymap.set("n", "^", WrappedMovement("^"), { expr = true, remap = false, silent = true })
vim.keymap.set("n", "$", WrappedMovement("$"), { expr = true, remap = false, silent = true })
-- }}}

-- autocmds {{{
-- trim trailing whitespace on save
vim.api.nvim_create_augroup("TRIM_WHITESPACE", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = "TRIM_WHITESPACE",
	pattern = { "*" },
	command = [[%s/\s\+$//e]],
})

-- equalize all split panes when resizing the terminal window
vim.api.nvim_create_augroup("RESIZE_NVIM", { clear = true })
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = "RESIZE_NVIM",
	pattern = { "*" },
	callback = function()
		vim.api.nvim_command("wincmd =")
	end,
})
-- }}}
