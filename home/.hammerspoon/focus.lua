M = {}

local function readFocusStatus()
  local file = io.open("/tmp/focus-status", "r")
  if file then
    local content = string.gsub(file:read("*all"), "\n", "")
    file:close()
    return content
  else
    print("File not found at /tmp/focus-status")
    return nil
  end
end

function M.IsBreaking()
  local focusStatus = readFocusStatus()
  return focusStatus == "focusing"
end

function M.IsFocusing()
  local focusStatus = readFocusStatus()
  return focusStatus == "breaking"
end

return M
