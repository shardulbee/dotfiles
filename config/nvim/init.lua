-- vim: set ts=2 sw=2
---@diagnostic disable: undefined-global
vim.g.mapleader = ","

vim.pack.add({
  "https://github.com/p00f/alabaster.nvim",
  "https://github.com/tpope/vim-surround",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/nvim-treesitter/nvim-treesitter",
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
vim.o.ttimeoutlen = 0
vim.o.ignorecase = true
vim.o.grepprg = "rg --hidden --vimgrep --no-heading --smart-case"
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.keymap.set("n", "za", function()
  if vim.fn.foldclosed(".") == -1 then
    pcall(vim.cmd, "normal! zc")
  else
    pcall(vim.cmd, "normal! zO")
  end
end)

vim.cmd.colorscheme("alabaster")

-- nicer diffs everywhere: histogram algorithm + soft pastels
vim.opt.diffopt:append("algorithm:histogram")
vim.opt.fillchars:append({ diff = " " })
vim.api.nvim_set_hl(0, "DiffAdd",    { bg = "#dafbe1" })
vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#ffebe9", fg = "#ffebe9" })
vim.api.nvim_set_hl(0, "DiffChange", { bg = "NONE" })
vim.api.nvim_set_hl(0, "DiffText",   { bg = "#fff5b1", bold = true })

vim.defer_fn(function()
  require("nvim-treesitter").install({
    "bash", "html", "javascript", "json", "lua", "markdown",
    "python", "tsx", "typescript", "vim", "vimdoc", "yaml",
  })
end, 0)

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

local fzflua = require("fzf-lua")
local map = vim.keymap.set
map("n", "<leader>t", fzflua.files)
map("n", "<leader>f", fzflua.live_grep)
map("n", "<leader>h", fzflua.helptags)
map("n", "<leader>r", fzflua.command_history)
map("n", "<leader>p", fzflua.commands)
map("n", "<leader><leader>", fzflua.builtin)


vim.diagnostic.config({
  signs = false,
})


vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
})

vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

vim.lsp.enable({ "lua_ls", "vtsls" })

local pi = require("pi")
map("n", "<leader><space>", pi.with_context)
map("n", "<leader>y", function() vim.fn.setreg("+", vim.fn.expand("%")) end)

-- Add SHARVIEW comments
map("n", "<leader>c", function()
  local cs = vim.bo.commentstring
  if cs == "" or not cs:find("%%s") then cs = "# %s" end
  local before, after = cs:match("^(.-)%%s(.-)$")
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local indent = vim.api.nvim_get_current_line():match("^%s*") or ""
  local prefix = indent .. before .. "SHARVIEW: "
  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { prefix .. after })
  vim.api.nvim_win_set_cursor(0, { row, #prefix })
  vim.cmd(#after > 0 and "startinsert" or "startinsert!")
end)

-- :Diffmain — review every changed file vs `main` in a new tab.
-- Layout: scratch buffer (jj://main) on the left, real editable file on the right.
-- Quickfix is populated; ]q / [q swap files and the left auto-refreshes.
vim.api.nvim_create_user_command("Diffmain", function()
  local files = vim.tbl_filter(function(s) return s ~= "" end,
    vim.fn.systemlist("jj diff --from main --name-only"))
  if #files == 0 then return vim.notify("no changes vs main") end

  vim.cmd("tabnew")
  vim.fn.setqflist(vim.tbl_map(function(f)
    return { filename = f, lnum = 1, text = "" }
  end, files), "r")
  vim.cmd("cfirst")

  vim.cmd("leftabove vnew")
  local scratch = vim.api.nvim_get_current_buf()
  vim.bo[scratch].buftype = "nofile"
  vim.bo[scratch].bufhidden = "wipe"
  vim.bo[scratch].swapfile = false
  pcall(vim.api.nvim_buf_set_name, scratch, "jj://main")

  local tab = vim.api.nvim_get_current_tabpage()

  local function refresh()
    if not vim.api.nvim_buf_is_valid(scratch) then return end
    local cur = vim.api.nvim_get_current_buf()
    if cur == scratch or vim.bo[cur].buftype ~= "" then return end
    local path = vim.fn.expand("%:.")
    if path == "" then return end
    local content = vim.fn.system({ "jj", "file", "show", "-r", "main", "--", path })
    if vim.v.shell_error ~= 0 then content = "" end
    local lines = vim.split(content, "\n", { plain = true })
    if lines[#lines] == "" then table.remove(lines) end
    vim.bo[scratch].modifiable = true
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
    vim.bo[scratch].modifiable = false
    vim.bo[scratch].filetype = vim.bo[cur].filetype
    -- :cnext leaves stale diff state; tear down and rebuild.
    vim.cmd("diffoff! | windo diffthis")
  end

  vim.cmd("wincmd l")
  refresh()

  local group = vim.api.nvim_create_augroup("diffmain", { clear = true })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_tabpage() == tab then refresh() end
    end,
  })
end, {})
