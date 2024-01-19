vim.o.wrap = true
vim.o.linebreak = true
vim.opt_local.spell = true

local function insertTextAtCursor(text, newline)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local column = cursor[2]

  if not newline then
    vim.api.nvim_buf_set_text(0, row - 1, column, row - 1, column, { text })
  else
    vim.api.nvim_buf_set_lines(0, row, row, false, { text })
  end
end

local function completePath()
  require("fzf-lua").files({
    cmd = "rg --files -t md | grep -v 'daily-note' | grep -v 'scratch'",
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
      ["default"] = function(selected)

        insertTextAtCursor('[[' .. selected[1] .. ']]', false)
      end,
    },
  })
end

local function newNote()
  local noteName = vim.fn.input('Note name: ')
  if noteName == '' then
    vim.api.nvim_err_writeln('\nNo note name provided')
    return
  end
  local currentTime = os.date('%Y%m%d%H%M')
  local filename = string.format("%s %s.md", currentTime, noteName)
  local file = io.open(filename, 'w')
  if file then
    file:write(string.format('# %s\n', noteName))
    file:close()
    print('File created: ' .. filename)
    vim.cmd("e " .. filename)
  else
    print('Could not create file: ' .. filename)
  end
end

vim.keymap.set("n", "<leader>n", newNote, { noremap = true, silent = true })
vim.keymap.set("i", "[[", completePath, { noremap = true, silent = true })
-- vim.api.nvim_set_hl(0, "Underlined", { fg = "#ab4642", underline = true  }) -- underline links
vim.g.markdown_fenced_languages = {
  "zsh",
  "python",
  "ruby",
  "sql",
  "lua"
}
