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
