-- vim: set ts=2 sw=2
---@diagnostic disable: undefined-global
vim.g.mapleader = ","

vim.pack.add({
  "https://github.com/p00f/alabaster.nvim",
  "https://github.com/tpope/vim-eunuch",
  "https://github.com/tpope/vim-surround",
  "https://github.com/tpope/vim-sleuth",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/neovim/nvim-lspconfig",
})

vim.o.termguicolors = true
vim.o.wrap = false
vim.o.scrolloff = 10
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.number = true
vim.o.laststatus = 3
vim.o.writebackup = false
vim.o.swapfile = false
vim.o.autowrite = true
vim.o.clipboard = "unnamedplus"
vim.o.smartindent = true
vim.o.linebreak = true
vim.o.ttimeoutlen = 0
vim.o.ignorecase = true
vim.o.grepprg = "rg --hidden --vimgrep --no-heading --smart-case"

vim.cmd.colorscheme("alabaster")

require("nvim-treesitter").setup({
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = {
    "bash", "html", "javascript", "json", "lua", "markdown",
    "python", "tsx", "typescript", "vim", "vimdoc", "yaml",
  },
})

require("fzf-lua")
local map = vim.keymap.set
map("n", "<leader>t", function() require("fzf-lua").files() end)
map("n", "<leader>f", function() require("fzf-lua").live_grep() end)
map("n", "<leader>h", function() require("fzf-lua").helptags() end)
map("n", "<leader><leader>", function() require("fzf-lua").builtin() end)


vim.diagnostic.config({
  signs = false,
})

map("n", "<leader>d", vim.diagnostic.setloclist)

vim.lsp.enable({ "lua_ls", "vtsls" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

map("n", "<leader><space>", function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local width = 60
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = 1,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - 1) / 2) - 1,
    style = "minimal",
    border = "rounded",
    title = " pi ",
    title_pos = "center",
  })

  vim.cmd("startinsert!")

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local prompt = table.concat(lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
    close()
    if prompt == "" then return end

    local file = vim.fn.expand("%:p")
    local args = file ~= "" and { "pi", "-p", "@" .. file .. " " .. prompt } or { "pi", "-p", prompt }

    vim.notify("pi: " .. prompt, vim.log.levels.INFO)

    local stdout = {}
    local stderr = {}

    vim.fn.jobstart(args, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          table.insert(stdout, line)
        end
      end,
      on_stderr = function(_, data)
        for _, line in ipairs(data) do
          table.insert(stderr, line)
        end
      end,
      on_exit = function(_, code)
        vim.schedule(function()
          if code ~= 0 then
            local err = table.concat(vim.tbl_filter(function(l) return l ~= "" end, stderr), "\n")
            vim.notify("pi failed: " .. (err ~= "" and err or "unknown error"), vim.log.levels.ERROR)
            return
          end
          local out = table.concat(vim.tbl_filter(function(l) return l ~= "" end, stdout), "\n")
          if out ~= "" then
            local out_buf = vim.api.nvim_create_buf(false, true)
            vim.bo[out_buf].buftype = "nofile"
            vim.bo[out_buf].modifiable = true
            vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, vim.split(out, "\n"))
            vim.bo[out_buf].modifiable = false
            vim.cmd("botright 10new")
            vim.api.nvim_win_set_buf(0, out_buf)
            vim.notify("pi done", vim.log.levels.INFO)
          else
            vim.notify("pi done", vim.log.levels.INFO)
            vim.cmd("checktime")
          end
        end)
      end,
    })
  end

  vim.keymap.set("i", "<CR>", submit, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<CR>", submit, { buffer = buf, nowait = true })
  vim.keymap.set({ "n", "i" }, "<Esc>", close, { buffer = buf })
end)
map("n", "<leader>y", function() vim.fn.setreg("+", vim.fn.expand("%")) end)
