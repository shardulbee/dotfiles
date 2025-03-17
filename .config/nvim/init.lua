-- vim: set ts=2 sw=2
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if vim.g.vscode then
  -- set a keymap to run the ~/bin/cursor-to-kitty.sh script with the current file and line number in vscode
  vim.keymap.set("n", "<leader><space>", function()
    vim.fn.system("~/bin/cursor-to-kitty.sh " .. vim.fn.expand("%") .. " " .. vim.fn.line("."))
  end, { desc = "Cursor to Kitty" })
  vim.opt.clipboard = "unnamedplus" -- use the system clipboard
  return
end

vim.keymap.set("n", "<leader><space>", function()
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))
  local line = vim.fn.line(".")
  vim.cmd(string.format("silent !cursor -g %s:%s", file, line))
end, { desc = "Open file in Cursor" })

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
    "mrjones2014/smart-splits.nvim",
    build = "./kitty/install-kittens.bash",
    lazy = false,
    opts = function()
      vim.keymap.set("n", "<A-S-left>", require("smart-splits").resize_left)
      vim.keymap.set("n", "<A-S-down>", require("smart-splits").resize_down)
      vim.keymap.set("n", "<A-S-up>", require("smart-splits").resize_up)
      vim.keymap.set("n", "<A-S-right>", require("smart-splits").resize_right)
      -- moving between splits
      vim.keymap.set("n", "<C-w>h", require("smart-splits").move_cursor_left)
      vim.keymap.set("n", "<C-w>j", require("smart-splits").move_cursor_down)
      vim.keymap.set("n", "<C-w>k", require("smart-splits").move_cursor_up)
      vim.keymap.set("n", "<C-w>l", require("smart-splits").move_cursor_right)
      vim.keymap.set("n", "<C-w>\\", require("smart-splits").move_cursor_previous)
      return {}
    end,
  },

  {
    "supermaven-inc/supermaven-nvim",
    cond = function()
      return vim.fn.hostname() == "turbochardo"
    end,
    opts = {
      keymaps = {
        -- accept_suggestion = "<C-l>",
        clear_suggestion = "<C-e>",
        -- accept_word = "<C-j>",
      },
      color = {
        suggestion_color = "#ffffff",
        cterm = 244,
      },
      log_level = "off",
    },
  },
  {
    "mfussenegger/nvim-lint",
    config = function()
      require("lint").linters_by_ft = {
        python = { "mypy" },
      }
      vim.api.nvim_create_augroup("LintGroup", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = "LintGroup",
        callback = function()
          require("lint").try_lint()
        end,
      })
      vim.api.nvim_create_user_command("Lint", function()
        require("lint").try_lint()
      end, { desc = "Run linters" })
    end,
  },
  "nvim-lua/plenary.nvim",
  {
    "vim-test/vim-test",
    dependencies = "preservim/vimux",
    config = function()
      vim.g["test#strategy"] = "kitty"
    end,
    keys = {
      { "<leader>tf", "<cmd>TestFile<cr>" },
      { "<leader>tn", "<cmd>TestNearest<cr>" },
      { "<leader>ts", "<cmd>TestSuite<cr>" },
      { "<leader>ts", "<cmd>TestSuite -nauto<cr>", ft = "python" },
      { "<leader>tl", "<cmd>TestLast<cr>" },
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
  "tpope/vim-vinegar",
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    cmd = "Git",
    keys = {
      { "<leader>gs", "<cmd>vertical Git | vertical resize 40<cr>" },
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
        files = {
          actions = {
            ["ctrl-x"] = {
              fn = function(selected, _)
                if #selected > 0 then
                  local cmd = "rm"
                  for _, file in ipairs(selected) do
                    cmd = cmd .. " " .. vim.fn.shellescape(file)
                  end
                  vim.fn.system(cmd)
                end
              end,
              reload = true,
            },
          },
        },
        git = {
          branches = {
            cmd_add = { "git", "checkout", "-b" },
            actions = {
              ["ctrl-r"] = function(selected, _)
                local fork_point = vim.fn.systemlist("git merge-base --fork-point " .. selected[1] .. " HEAD")[1]
                if not fork_point then
                  vim.notify("No fork point found", vim.log.levels.ERROR)
                  return
                end

                local cmd = string.format("Git rebase -i %s --onto %s", fork_point, selected[1])
                vim.cmd(cmd)
              end,
              ["ctrl-x"] = {
                fn = function(selected, _)
                  local cmd = string.format("Git branch -D %s", selected[1])
                  vim.cmd(cmd)
                end,
                reload = true,
              },
            },
          },
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
              ["ctrl-d"] = {
                fn = function(selected, _)
                  local commit = selected[1]:match("[^ ]+")
                  if commit then
                    local kitty_path = "/opt/homebrew/bin/kitty"
                    local cwd = vim.fn.getcwd()
                    vim.system({
                      kitty_path,
                      "@",
                      "launch",
                      "--type=overlay",
                      "--title=Git Diff: " .. commit,
                      "--cwd=" .. cwd,
                      "fish",
                      "-c",
                      "git diff " .. commit,
                    })
                  else
                    vim.cmd("echo 'No commit selected'")
                  end
                end,
                reload = false,
              },
            },
          },
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
      vim.keymap.set("n", "<leader>p", fzfLua.commands, opts)
      vim.keymap.set("n", "gT", fzfLua.tags_live_grep, opts)
      vim.keymap.set("n", "gt", fzfLua.tags, opts)
      vim.keymap.set("n", "<leader>z", "<cmd>Fzf<cr>", opts)
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
      vim.cmd([[
        set background=dark
        colorscheme gruvbox
      ]])
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
    "JoosepAlviste/nvim-ts-context-commentstring",
    opts = {
      enable_autocmd = false,
    },
    config = function()
      local get_option = vim.filetype.get_option
      vim.filetype.get_option = function(filetype, option)
        return option == "commentstring" and require("ts_context_commentstring.internal").calculate_commentstring()
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
      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }
        local function buf_set_keymap(...)
          vim.keymap.set(...)
        end
        local fzfLua = require("fzf-lua")

        buf_set_keymap("n", ",ca", fzfLua.lsp_code_actions, opts)
        buf_set_keymap("n", "gs", fzfLua.lsp_document_symbols, opts)
        buf_set_keymap("n", "gl", fzfLua.lsp_document_symbols, opts)

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
      end

      require("mason").setup()
      require("mason-lspconfig").setup()

      require("mason-lspconfig").setup_handlers({
        -- The first entry (without a key) will be the default handler
        -- and will be called for each installed server that doesn't have
        -- a dedicated handler.
        function(server_name) -- default handler (optional)
          require("lspconfig")[server_name].setup({
            capabilities = require("blink.cmp").get_lsp_capabilities(),
            on_attach = on_attach,
          })
        end,
        ["lua_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.lua_ls.setup({
            on_attach = on_attach,
            on_init = function(client)
              if client.workspace_folders then
                local path = client.workspace_folders[1].name
                if
                  path ~= vim.fn.stdpath("config")
                  and (vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc"))
                then
                  return
                end
              end

              client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                runtime = {
                  -- Tell the language server which version of Lua you're using
                  -- (most likely LuaJIT in the case of Neovim)
                  version = "LuaJIT",
                },
                -- Make the server aware of Neovim runtime files
                workspace = {
                  checkThirdParty = false,
                  library = {
                    vim.env.VIMRUNTIME,
                    -- Depending on the usage, you might want to add additional paths here.
                    -- "${3rd}/luv/library"
                    -- "${3rd}/busted/library",
                  },
                  -- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
                  -- library = vim.api.nvim_get_runtime_file("", true)
                },
              })
            end,
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim", "hs", "spoon" },
                },
              },
            },
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
        vim.keymap.set("n", "<leader>gdom", function()
          gitsigns.diffthis("main", { vertical = true })
        end, opts)
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
vim.opt.tags = "./tags,./.tags"

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
    -- Skip resizing fugitive and netrw windows
    local buftype = vim.bo.buftype
    local filetype = vim.bo.filetype
    if filetype ~= "fugitive" and filetype ~= "netrw" and not buftype:match("^fugitive") then
      vim.api.nvim_command("wincmd =")
    end
  end,
})
vim.keymap.set("n", "<leader>d", function()
  vim.api.nvim_buf_delete(0, {})
end)

vim.keymap.set("n", "<leader><enter>", function()
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
    vim.cmd("/^## NOW")
    vim.cmd("normal! zz")
  end
end, { silent = true })
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
