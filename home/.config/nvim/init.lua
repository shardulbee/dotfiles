-- vim: set ts=2 sw=2
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

require("lazy").setup({
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
			"TmuxNavigatorProcessList",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},
	"preservim/vimux",
	{
		"mfussenegger/nvim-lint",
		config = function()
			require("lint").linters_by_ft = {
				python = { "mypy" },
			}

			-- Create autocmd group for linting
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

			-- Setup autocommands for automatic linting
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave", "TextChanged" }, {
				group = lint_augroup,
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
	"nvim-lua/plenary.nvim",
	"ActivityWatch/aw-watcher-vim",
	{
		"zbirenbaum/copilot.lua",
		config = function()
			require("copilot").setup({
				panel = {
					enabled = true,
					auto_refresh = false,
					keymap = {
						jump_prev = "[[",
						jump_next = "]]",
						accept = "<CR>",
						refresh = "gr",
						open = "<M-CR>",
					},
					layout = {
						position = "right", -- | top | left | right | horizontal | vertical
						ratio = 0.4,
					},
				},
				suggestion = {
					enabled = true,
					auto_trigger = true,
					hide_during_completion = true,
					debounce = 75,
					keymap = {
						accept = "<C-l>",
						accept_word = false,
						accept_line = false,
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<C-e>",
					},
				},
			})
			vim.keymap.set("i", "<M-CR>", require("copilot.panel").open, { silent = true, noremap = true })
		end,
	},

	{ "folke/todo-comments.nvim", opts = {} },
	{
		"vim-test/vim-test",
		keys = {
			{ "<leader>tf", "<cmd>TestFile<cr>" },
			{ "<leader>tn", "<cmd>TestNearest<cr>" },
			{ "<leader>ts", "<cmd>TestSuite<cr>" },
			{ "<leader>ts", "<cmd>TestSuite -nauto<cr>", ft = "python" },
			{ "<leader>tl", "<cmd>TestLast<cr>" },
		},
	},
	{
		"olimorris/codecompanion.nvim",
		config = true,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			adapters = {
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						schema = {
							model = {
								order = 1,
								mapping = "parameters",
								type = "enum",
								desc = "ID of the model to use. See the model endpoint compatibility table for details on which models work with the Chat API.",
								---@type string|fun(): string
								default = "claude-3.5-sonnet",
								choices = {
									["o3-mini-2025-01-31"] = { opts = { can_reason = true } },
									["o1-2024-12-17"] = { opts = { can_reason = true } },
									["o1-mini-2024-09-12"] = { opts = { can_reason = true } },
									"claude-3.5-sonnet",
									"claude-3.7-sonnet",
									"claude-3.7-sonnet-thought",
									"gpt-4o-2024-08-06",
									"gemini-2.0-flash-001",
								},
							},
						},
					})
				end,
			},
			strategies = {
				chat = {
					slash_commands = {
						["file"] = {
							opts = { provider = "fzf_lua" },
						},
						["symbols"] = {
							opts = { provider = "fzf_lua" },
						},
						["buffer"] = {
							opts = { provider = "fzf_lua" },
						},
					},
					adapter = "copilot",
				},
				inline = {
					adapter = "copilot",
				},
			},
		},
	},
	"direnv/direnv.vim",
	"tpope/vim-eunuch",
	"tpope/vim-surround",
	"tpope/vim-dispatch",
	"tpope/vim-sleuth",
	"tpope/vim-unimpaired",
	"tpope/vim-repeat",
	"tpope/vim-dadbod",
	{
		"tpope/vim-fugitive",
		event = "VeryLazy",
		cmd = "Git",
		keys = {
			{ "<leader>gs", "<cmd>Git<cr>" },
		},
		config = function()
			vim.opt.statusline = ""
			vim.opt.statusline = "%f:%l:%c %m%=%y"
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
			vim.keymap.set("n", "gt", fzfLua.tags, opts)
			vim.keymap.set("n", "<leader>gfu", function()
				fzfLua.git_commits({
					prompt = "Git Fixup> ",
					actions = {
						["default"] = function(selected)
							local commit_hash = selected[1]:match("(%S+)")
							vim.cmd("Git commit --fixup=" .. commit_hash)
						end,
					},
				})
			end, { desc = "Git fixup commit" })
			vim.keymap.set("n", "<leader>gl", function()
				require("fzf-lua").git_commits({
					actions = {
						-- ["default"] = function(selected)
						-- 	-- Default behavior remains the same
						-- 	require("fzf-lua").actions.git_checkout(selected)
						-- end,
						-- cant use ctrl-f because it conflicts with tmux bind
						-- ["ctrl-f"] = function(selected)
						-- 	local commit_hash = selected[1]:match("(%S+)")
						-- 	vim.cmd("Git commit --fixup=" .. commit_hash)
						-- end,
						["ctrl-r"] = function(selected)
							local commit_hash = selected[1]:match("(%S+)")
							vim.cmd("Git rebase -i " .. commit_hash)
						end,
					},
				})
			end, { silent = true, noremap = true })

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
				per_filetype = {
					codecompanion = { "codecompanion" },
				},
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
				vim.keymap.set("n", "<leader>gd", gitsigns.diffthis, opts)
				vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, opts)
				vim.keymap.set("n", "<leader>hu", gitsigns.undo_stage_hunk, opts)
				vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, opts)
			end,
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

vim.api.nvim_create_user_command("TogglePlan", function()
	local planBufWin = vim.fn.bufwinnr("plan.md")

	if planBufWin > 0 then
		-- If window exists, close it
		vim.cmd(planBufWin .. "wincmd c")
	else
		-- Calculate 40% of screen width
		local width = math.floor(vim.o.columns * 0.4)

		-- Open in right split
		vim.cmd("botright vsplit plan.md")
		vim.cmd("vertical resize " .. width)
		vim.cmd("/^## Immediate Next-Up")
		vim.cmd("normal! zz")
	end
end, {})

vim.keymap.set("n", "<leader><space>", ":TogglePlan<CR>", { silent = true })
vim.keymap.set("n", "<leader>v", "<cmd>vsp<cr>", { silent = true, noremap = true })
vim.keymap.set("n", "<leader>s", "<cmd>sp<cr>", { silent = true, noremap = true })
vim.keymap.set("n", "<leader>gb", ":GBrowse<CR>", { noremap = true, silent = true })
vim.keymap.set({ "v", "x" }, "<leader>gb", ":'<,'>GBrowse<CR>", { noremap = true, silent = true })

vim.keymap.set(
	"n",
	"<leader>gfo",
	"<cmd>Git fetch origin<cr>",
	{ silent = true, noremap = true, desc = "Git fetch origin" }
)
vim.keymap.set(
	"n",
	"<leader>gro",
	"<cmd>Git rebase origin/main<cr>",
	{ silent = true, noremap = true, desc = "Git fetch origin" }
)

vim.keymap.set(
	"n",
	"<leader>gvp",
	[[<cmd>!gh pr view --web<cr>]],
	{ silent = true, noremap = true, desc = "View PR in browser" }
)
vim.keymap.set(
	"n",
	"<leader>gvr",
	[[<cmd>!gh repo view --web<cr>]],
	{ silent = true, noremap = true, desc = "View PR in browser" }
)

vim.api.nvim_create_user_command("GithubPRMerge", function()
	vim.fn.system("gh pr merge --auto")
end, {})

vim.keymap.set("n", "<leader>q", function()
	local qf_exists = false
	for _, win in pairs(vim.fn.getwininfo()) do
		if win["quickfix"] == 1 then
			qf_exists = true
		end
	end
	if qf_exists then
		vim.cmd("cclose")
	else
		vim.cmd("copen")
	end
end, { silent = true, noremap = true })

vim.keymap.set("n", "!l", function()
	vim.fn.jobstart({ "fish", "-lc", "ctags-build" }, {
		on_exit = function(_, code)
			if code == 0 then
				vim.notify("CTags build completed", vim.log.levels.INFO)
			else
				vim.notify("CTags build failed", vim.log.levels.ERROR)
			end
		end,
	})
end)
vim.api.nvim_create_user_command("Refresh", function()
	-- Use vim-fugitive for git operations
	vim.cmd("Git fetch origin")

	-- After fetch completes, do the rebase
	vim.cmd("Git rebase origin/main")

	-- Show a message to indicate completion
	vim.notify("Refreshed: fetched origin and rebased onto origin/main", vim.log.levels.INFO)
end, {})

-- <leader>gcc opens :CodeCompanionChat
vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { silent = true, noremap = true })
vim.keymap.set({ "v", "x" }, "<leader>cc", ":'<,'>CodeCompanionChat<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cp", "<cmd>CodeCompanion<cr>", { silent = true, noremap = true })
vim.keymap.set({ "v", "x" }, "<leader>cp", ":'<,'>CodeCompanion<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>pg", function()
	local window_ids = vim.fn.win_findbuf(vim.fn.bufnr("postgresql://"))
	if #window_ids > 0 then
		-- Buffer exists and is visible, hide it
		for _, win_id in ipairs(window_ids) do
			vim.api.nvim_win_hide(win_id)
		end
	else
		local buf_nr = vim.fn.bufnr("DB postgresql://")
		if buf_nr ~= -1 then
			-- Buffer exists but not visible, show it
			vim.cmd("sb " .. buf_nr)
		else
			-- Buffer doesn't exist, create it
			vim.cmd("DB postgresql://")
		end
	end
end, { silent = true, noremap = true })

vim.keymap.set("n", "]t", "<cmd>tabnext<cr>", { silent = true, noremap = true })
vim.keymap.set("n", "[t", "<cmd>tabprevious<cr>", { silent = true, noremap = true })
