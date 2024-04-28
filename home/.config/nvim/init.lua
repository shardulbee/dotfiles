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
	{ "junegunn/vim-easy-align" },
	{ "ziglang/zig.vim" },
	{ "wakatime/vim-wakatime" },
	{ "windwp/nvim-autopairs", event = "InsertEnter", config = true },
	"tpope/vim-eunuch",
	"tpope/vim-unimpaired",
	"tpope/vim-surround",
	"tpope/vim-sleuth",
	"tpope/vim-rhubarb",
	"tpope/vim-repeat",
	{ "tpope/vim-dispatch", keys = { { "<leader>c", "<cmd>Make!<cr>", "n", { silent = true, noremap = true } } } },
	{ "tpope/vim-fugitive", keys = { { "<leader>gs", "<cmd>Git<cr>", "n", { silent = true, noremap = true } } } },
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter-context",
				opts = { enable = true },
			},
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
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
		"ms-jpq/chadtree",
		keys = {
			{ "<leader>,", "<cmd>CHADopen<cr>", "n", { silent = true, noremap = true } },
		},
		config = function()
			vim.g.chadtree_settings = {
				["theme.text_colour_set"] = "nerdtree_syntax_dark",
			}
		end,
	},
	{
		"RRethy/nvim-base16",
		lazy = false,
		config = function()
			vim.cmd("colorscheme base16-default-dark")
		end,
	},
	"RRethy/nvim-treesitter-endwise",

	"airblade/vim-gitgutter",
	"LnL7/vim-nix",
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
		keys = function()
			local fzfLua = require("fzf-lua")

			return {
				{
					"<C-t>",
					function()
						require("fzf-lua").files({
							winopts = {
								preview = {
									default = "bat",
									flip_columns = 140,
									winopts = {
										number = false,
										relativenumber = false,
									},
								},
							},
							actions = {
								["alt-d"] = function(selected)
									-- delete all selected
									for _, file in ipairs(selected) do
										vim.fn.delete(file)
									end
								end,
							},
						})
					end,
					"n",
					{ silent = true },
				},
				{ "<C-p>", fzfLua.commands, "n", { silent = true } },
				{ "<leader>hh", fzfLua.help_tags, "n", { silent = true } },
				{ "<leader>b", fzfLua.buffers, "n", { silent = true } },
				{ "<leader>f", fzfLua.blines, "n", { silent = true } },
				{ "<leader>F", fzfLua.live_grep_native, "n", { silent = true } },
			}
		end,
		opts = {
			grep = {
				rg_opts = "--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
			},
			winopts = {
				height = 0.95,
				width = 0.95,
				preview = {
					flip_columns = 140,
					winopts = {
						number = false,
						relativenumber = false,
					},
				},
				fzf_opts = {
					["--layout"] = "reverse-list",
				},
				previewers = {
					bat = { theme = "base16-default-dark" },
				},
			},
		},
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
			-------------------------------------------------------------------------
			-- UI
			------------------------------------------------------------------------
			vim.diagnostic.config({
				virtual_text = true,
				update_in_insert = true,
				underline = false,
				float = { border = "rounded" },
			})
			vim.cmd([[autocmd! ColorScheme * highlight NormalFloat guibg=#1f2335]])
			vim.cmd([[autocmd! ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335]])
			local border = {
				{ "🭽", "FloatBorder" },
				{ "▔", "FloatBorder" },
				{ "🭾", "FloatBorder" },
				{ "▕", "FloatBorder" },
				{ "🭿", "FloatBorder" },
				{ "▁", "FloatBorder" },
				{ "🭼", "FloatBorder" },
				{ "▏", "FloatBorder" },
			}
			local handlers = {
				["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
				["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
			}

			-------------------------------------------------------------------------
			-- Keymaps
			-------------------------------------------------------------------------
			local on_attach = function(_, bufnr)
				local opts = { noremap = true, silent = true }
				vim.api.nvim_buf_set_keymap(
					bufnr,
					"n",
					",ca",
					"<cmd>lua require('fzf-lua').lsp_code_actions()<CR>",
					opts
				)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "i", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)

				vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
			end

			require("mason").setup()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"shfmt",
					"shellcheck",

					"rust-analyzer",
					"rustfmt",

					"jsonls",
					"clangd",
					"lua-language-server",
					"zls",
					"gopls",
					"markdownlint",
				},
			})
			require("mason-lspconfig").setup()
			require("mason-lspconfig").setup_handlers({
				function(server_name)
					require("lspconfig")[server_name].setup({
						handlers = handlers,
						on_attach = on_attach,
					})
				end,
			})

			-------------------------------------------------------------------------
			-- Completion
			-------------------------------------------------------------------------
			local cmp = require("cmp")
			cmp.setup({
				enabled = function()
					if
						require("cmp.config.context").in_treesitter_capture("comment") == true
						or require("cmp.config.context").in_syntax_group("Comment")
					then
						return false
					else
						return true
					end
				end,
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				formatting = {
					fields = { "menu", "abbr", "kind" },
					format = function(entry, item)
						local menu_icon = {
							nvim_lsp = "λ",
							buffer = "Ω",
						}
						item.menu = menu_icon[entry.source.name]
						return item
					end,
				},
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = vim.schedule_wrap(function(fallback)
						if cmp.visible() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						else
							fallback()
						end
					end),
					["<S-Tab>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						end
					end, { "i", "s" }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({
						select = false,
						behavior = cmp.ConfirmBehavior.Replace,
					}),
				}),
				sources = {
					{ name = "vsnip" },
					{ name = "path" },
					{ name = "nvim_lsp", keyword_length = 3 }, -- from language server
					{ name = "nvim_lsp_signature_help" }, -- display function signatures with current parameter emphasized
					{ name = "buffer", keyword_length = 2 }, -- source current buffer
				},
			})

			-------------------------------------------------------------------------
			-- Formatting / linting
			-------------------------------------------------------------------------
			local null_ls = require("null-ls")
			local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
			require("gitsigns").setup()
			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.ocamlformat,
					null_ls.builtins.formatting.fixjson,
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.jq,
					null_ls.builtins.formatting.rustfmt,
					null_ls.builtins.formatting.shfmt,
					null_ls.builtins.formatting.markdownlint,

					null_ls.builtins.diagnostics.pylint,
					null_ls.builtins.diagnostics.shellcheck,
					null_ls.builtins.diagnostics.markdownlint,

					null_ls.builtins.code_actions.gitsigns,
				},
				on_attach = function(client, bufnr)
					if client.supports_method("textDocument/formatting") then
						vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
						vim.api.nvim_create_autocmd("BufWritePre", {
							group = augroup,
							buffer = bufnr,
							callback = function()
								vim.lsp.buf.format()
							end,
						})
					end
				end,
			})
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
vim.api.nvim_set_keymap("n", "<leader>d", ":bd<cr>", { noremap = true, silent = true })

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
