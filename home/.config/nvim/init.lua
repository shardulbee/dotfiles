-- vim: fdm=marker fdl=0
-- settings {{{
vim.cmd([[filetype plugin indent on]])
vim.cmd([[syntax on]])
vim.opt.wrap           = false -- soft wrap off
vim.opt.scrolloff      = 10  -- scroll once the cursor is < 10 lines from the bottom
vim.opt.showmatch      = true -- briefly jump to the matching bracket when the closing one is entered
vim.opt.matchtime      = 3 -- how long to jump to the matching bracket
vim.opt.incsearch      = true -- search as you type
vim.opt.tabstop        = 2 -- number of spaces to insert when tab is pressed (also controls the number of spaces used for < and >)
vim.opt.shiftwidth     = 2 -- number of spaces to use for autoindent
vim.opt.expandtab      = true  -- use spaces instead of tabs
vim.opt.number         = true  -- show line numbers
vim.opt.relativenumber = true  -- show relative line numbers
vim.opt.ruler          = true  -- show the current line and column number
vim.opt.laststatus     = 3  -- always show the status line
vim.opt.showmode       = true  -- show what editing mode we are in
vim.opt.undodir        = "~/.config/nvim/undo"  -- where to store undo files
vim.opt.undolevels     = 1000 -- number of undos to keep in memory
vim.opt.backup         = false -- don't backup file when writing
vim.opt.writebackup    = false -- don't backup file when writing
vim.opt.swapfile       = false -- don't create swap files which allow you to recover from crashes even if you didn't save
vim.opt.showcmd        = false -- don't show the command you are typing on the last line
vim.opt.autowrite      = true -- automatically write the file when switching buffers
vim.opt.hidden         = true -- allow switching buffers without saving
vim.opt.clipboard      = "unnamed" -- use the system clipboard
vim.opt.backspace      = "indent,eol,start" -- allow backspacing over everything
vim.opt.autoread       = true -- automatically reload files that have changed on disk
vim.opt.linebreak      = true  -- wrap long lines at characters in 'breakat'
vim.opt.list           = false -- dont show tabs as >- and trailing spaces as .
vim.opt.ttimeoutlen    = 0 -- don't wait for key codes to complete
vim.opt.ignorecase     = true  -- ignore case when searching
vim.opt.history        = 10000  -- keep 10000 lines of history
vim.opt.encoding       = "utf-8"  -- use utf-8 encoding
vim.opt.hlsearch       = false  -- don't highlight search results
vim.opt.background     = "dark"  -- assume a dark background
vim.opt.grepprg        = "rg --hidden --vimgrep --no-heading --smart-case"  -- use ripgrep for :grep
vim.opt.conceallevel   = 2  -- mostly important for concealling markdown links and other formatting
-- }}}

-- {{{ statusline
function _G.filetype()
  local filetype = vim.api.nvim_buf_get_option(0, 'filetype')
  if filetype ~= '' then
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
  local errors =
    #vim.diagnostic.get(0, { severity = { min = vim.diagnostic.severity.ERROR, max = vim.diagnostic.severity.ERROR } })
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

  local hints =
    #vim.diagnostic.get(0, { severity = { min = vim.diagnostic.severity.HINT, max = vim.diagnostic.severity.HINT } })
  if hints > 0 then
    table.insert(status, "HINT: " .. hints)
  end

  local infos =
    #vim.diagnostic.get(0, { severity = { min = vim.diagnostic.severity.INFO, max = vim.diagnostic.severity.INFO } })
  if infos > 0 then
    table.insert(status, "INFO: " .. infos)
  end

  if #status > 0 then return table.concat(status, " | ") .. " | " else return "" end
end

vim.opt.statusline = " %{mode()} | %f%m%=%{v:lua.workspace_diagnostics_status()} %{v:lua.filetype()} | L:%l C:%c "
-- }}}

-- keymaps {{{
vim.api.nvim_set_keymap("n", "<space>", ":",                                         { noremap = true })
vim.api.nvim_set_keymap("n", "<tab>", "za",                                          { noremap = true })
vim.api.nvim_set_keymap("i", "jk", "<esc>",                                          { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>d", ":bd<cr>",                                 { noremap = true, silent = true })

function WrappedMovement(movement)
  return function ()
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
      vim.api.nvim_command('wincmd =')
    end
})
-- }}}

-- {{{ plugins
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

require("lazy").setup({
  "tpope/vim-eunuch",
  "tpope/vim-unimpaired",
  "tpope/vim-surround",
  "tpope/vim-sleuth",
  "tpope/vim-rhubarb",
  "tpope/vim-repeat",
  {
    "tpope/vim-dispatch",
    keys = {
      { "<leader>c", "<cmd>Make!<cr>", "n", { silent=true, noremap=true } },
    }
  },
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", "n", { silent=true, noremap=true } }
    }
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy=false,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-context",
        opts = { enable = true}
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
    end
  },

  {
    "ms-jpq/chadtree",
    keys = {
      {"<leader>,", "<cmd>CHADopen<cr>", "n", { silent = true, noremap = true }},
    },
    config = function()
      vim.g.chadtree_settings = {
        ['theme.text_colour_set'] = "nerdtree_syntax_dark"
      }
    end
  },
  {
    "RRethy/nvim-base16",
    lazy = false,
    config = function()
      vim.cmd('colorscheme base16-default-dark')
      -- vim.cmd('colorscheme base16-bright')
    end
  },
  "RRethy/nvim-treesitter-endwise",

  "airblade/vim-gitgutter",
  "LnL7/vim-nix",
  {
    "Wansmer/treesj",
    keys = function()
      local treesj = require"treesj"
      return {
        { "gS", treesj.split, "n", { silent = true, noremap = true } },
        { "gJ", treesj.join, "n", { silent = true, noremap = true } },
      }
    end
  },
  {
    "numToStr/Comment.nvim",
    opts = {},
    lazy = false
  },
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    cmd = "Copilot",
    opts = {
      server_opts_overrides = {
        settings = {
          advanced = {
            listCount = 10, -- #completions for panel
            inlineSuggestCount = 5, -- #completions for getCompletions
          }
        },
      },
      debounce = 500,
      suggestion = {
        auto_trigger = false,
        keymap = {
          accept = "<c-l>",
          next = "<c-j>",
          prev = "<c-k>",
          dismiss = "<c-e>",
        },
        filetype = {
          markdown = false
        },
        panel = {
          enabled = false,
          auto_refresh = false,
          keymap = {
            jump_prev = "[[",
            jump_next = "]]",
            accept = "<CR>",
            refresh = "gr",
            open = "<C-h>"
          },
        },
      },
    }
  },
  {
    "vim-test/vim-test",
    keys = {
      { "<leader>tf", "<cmd>TestFile<cr>", "n", { silent = true, noremap = true } },
      { "<leader>tn", "<cmd>TestNearest<cr>", "n", { silent = true, noremap = true } },
    }
  },
  {
    "ibhagwan/fzf-lua",
    keys = function()
      local fzfLua = require("fzf-lua")

      return {
        {"<C-t>", function()
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
        end, "n", { silent = true }},
        {"<C-p>", fzfLua.commands, "n", { silent = true }},
        {"<leader>r", fzfLua.command_history, "n", { silent = true }},
        {"<leader>hh", fzfLua.help_tags, "n", { silent = true }},
        {"<leader>b", fzfLua.buffers, "n", { silent = true }},
        {"<leader>f", fzfLua.blines, "n", { silent = true }},
        {"<leader>F", fzfLua.live_grep_native, "n", { silent = true }},
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
      }
    }
  },
  { "neovim/nvim-lspconfig",
    dependencies = {
      {
        'hrsh7th/nvim-cmp',
        dependencies = {
          'neovim/nvim-lspconfig',
          'hrsh7th/cmp-nvim-lsp',
          'hrsh7th/cmp-buffer',
          'hrsh7th/cmp-path',
          'hrsh7th/cmp-cmdline',
          {
            "zbirenbaum/copilot-cmp",
            config = function ()
              require("copilot_cmp").setup {
                method = "getCompletionsCycling",
              }
            end
          },
        }
      }
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local nvim_lsp = require("lspconfig")

      local cmp = require("cmp")
      cmp.setup({
          snippet = {
            -- REQUIRED - you must specify a snippet engine
            expand = function(args)
              vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({
              select = false,
              behavior = cmp.ConfirmBehavior.Replace
            }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          }),
          sources = cmp.config.sources({
            { name = "copilot", group_index = 2 },
            { name = 'nvim_lsp', group_index = 2 },
            { name = 'path', group_index = 2 },
            { name = 'vsnip', group_index = 2 },
          }, {
            { name = 'buffer' },
          })
        })

      local on_attach = function(_, bufnr)
          local function buf_set_keymap(...)
              vim.api.nvim_buf_set_keymap(bufnr, ...)
          end
          local function buf_set_option(...)
              vim.api.nvim_buf_set_option(bufnr, ...)
          end

          buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

          local opts = { noremap = true, silent = true }
          buf_set_keymap("n", ",ca", "<cmd>lua require('fzf-lua').lsp_code_actions()<CR>", opts)
          buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
          buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
          buf_set_keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
          buf_set_keymap("n", "]d", "<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})<CR>", opts)
          buf_set_keymap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})<CR>", opts)
      end

      local function config_with_defaults(overrides)
          local final = {
              on_attach = on_attach,
              capabilities = capabilities,
          }
          for k, v in pairs(overrides) do
              final[k] = v
          end

          return final
      end

      local function merge_tables(t1, t2)
        for k, v in pairs(t2) do
          t1[k] = v
        end
        return t1
      end

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

      local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
          opts = opts or {}
          opts.border = opts.border or border
          return orig_util_open_floating_preview(contents, syntax, opts, ...)
      end

      local server_configs = {
          rust_analyzer = config_with_defaults({
              settings = {
                  ["rust-analyzer"] = {
                      checkOnSave = {
                          command = "clippy",
                      },
                      diagnostics = {
                          disabled = { "inactive-code" },
                      },
                  },
              },
          }),
          rnix = config_with_defaults({}),
          gopls = config_with_defaults({}),
          clangd = config_with_defaults({}),
          ocamllsp = config_with_defaults({}),
          solargraph = config_with_defaults({}),
          lua_ls = config_with_defaults({
              settings = {
                  Lua = {
                      telemetry = {
                          enable = false,
                      },
                      diagnostics = {
                        globals = { "vim", "hs" },
                      },
                  },
              },
          }),
          sorbet = config_with_defaults({
              cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
          }),
      }
      local cmp_capabilities = require('cmp_nvim_lsp').default_capabilities()
      for server, server_config in pairs(server_configs) do
        nvim_lsp[server].setup(
          merge_tables(server_config, cmp_capabilities)
        )
      end

      vim.o.updatetime = 250
      _G.LspDiagnosticsPopupHandler = function()
        local current_cursor = vim.api.nvim_win_get_cursor(0)
        local last_popup_cursor = vim.w.lsp_diagnostics_last_cursor or {nil, nil}

        if not (current_cursor[1] == last_popup_cursor[1] and current_cursor[2] == last_popup_cursor[2]) then
          vim.w.lsp_diagnostics_last_cursor = current_cursor
          vim.diagnostic.open_float(0, {scope="cursor", focusable=false, severity = vim.diagnostic.severity.ERROR})
        end
      end

      vim.api.nvim_create_augroup("POPUP", { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold" }, {
          group = "POPUP",
          pattern = { "*" },
          callback = _G.LspDiagnosticsPopupHandler
      })
    end
  },
  "junegunn/goyo.vim",
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "lewis6991/gitsigns.nvim",
        config = function()
          require('gitsigns').setup {
            current_line_blame = false,
            on_attach = function()
              local gs = package.loaded.gitsigns
              vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { silent = true, noremap = true })
              vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, { silent = true, noremap = true })
              vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { silent = true, noremap = true })
              vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { silent = true, noremap = true })
              vim.keymap.set("n", "<leader>gd", gs.diffthis, { silent = true, noremap = true })
            end
          }
        end
      },
    },
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.ocamlformat,
          null_ls.builtins.formatting.fixjson,
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.jq,
          null_ls.builtins.formatting.rustfmt,
          null_ls.builtins.code_actions.gitsigns,
        },
        on_attach = function(client)
          if client.supports_method("textDocument/formatting") then
            vim.keymap.set("n", "<leader>p", vim.lsp.buf.format, { silent = true, noremap = true })
          end
        end,
      })
    end
  },
})
-- }}}
