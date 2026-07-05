-- Alabaster BG for Neovim.
-- Minimal syntax philosophy:
--   plain text by default
--   grey punctuation
--   purple constants
--   green strings
--   yellow comments
--   blue definitions
local variant = vim.o.background
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "alabaster"

local palettes = {
  light = {
    fg = "#000000",
    bg = "#ffffff",
    ui = "#e6e6e6",
    gutter = "#f7f7f7",
    line = "#efefef",
    border = "#d2d2d2",
    active = "#007acc",
    selection = "#b4d8fd",
    comment = "#fffabc",
    string = "#f1fadf",
    special = "#dbecb6",
    definition = "#dbf1ff",
    constant = "#7a3e9d",
    punctuation = "#707070",
    muted = "#666666",
    faint = "#999999",
    invisible = "#cccccc",
    orange = "#ffbc5d",
    red = "#cc3333",
    red_bg = "#ffe0e0",
    green = "#6abf40",
    yellow = "#ec8013",
    line_nr = "#9da39a",
    cursor_line_nr = "#44454b",
    search_fg = "#000000",
    status = "#dadada",
    pmenu_sel = "#d2d2d2",
    directory = "#325cc0",
    more = "#448c37",
    diagnostic_warn_bg = "#faf2e6",
    diagnostic_info_bg = "#e6f3ff",
    diagnostic_ok_bg = "#dfeadb",
    reference = "#cfcfcf",
    spell_local = "#0083b2",
    terminal = {
      "#000000", "#aa3731", "#448c37", "#cb9000",
      "#325cc0", "#7a3e9d", "#0083b2", "#666666",
      "#777777", "#f05050", "#60cb00", "#ffbc5d",
      "#007acc", "#e64ce6", "#00aacb", "#d4d4d4",
    },
  },
  dark = {
    fg = "#e8e6e3",
    bg = "#0f1115",
    ui = "#1f232b",
    gutter = "#151922",
    line = "#1b2029",
    border = "#343b49",
    active = "#5aa7ff",
    selection = "#264f78",
    comment = "#3d3616",
    string = "#22351f",
    special = "#2f3f1f",
    definition = "#1c3447",
    comment_fg = "#d7d787",
    string_fg = "#a7d68d",
    special_fg = "#77d7df",
    definition_fg = "#7bb7ff",
    todo_fg = "#d7d787",
    constant = "#d7a8ff",
    punctuation = "#9a9a9a",
    muted = "#aaa6a0",
    faint = "#69717d",
    invisible = "#343a45",
    orange = "#d19a66",
    red = "#ff6b6b",
    red_bg = "#3a1f1f",
    green = "#98c379",
    yellow = "#e5b567",
    line_nr = "#69717d",
    cursor_line_nr = "#d0d0d0",
    search_fg = "#0f1115",
    status = "#20242c",
    pmenu_sel = "#303744",
    directory = "#7bb7ff",
    more = "#98c379",
    diagnostic_warn_bg = "#342711",
    diagnostic_info_bg = "#142a3d",
    diagnostic_ok_bg = "#1e301b",
    reference = "#303744",
    spell_local = "#56b6c2",
    terminal = {
      "#e8e6e3", "#ff6b6b", "#98c379", "#e5b567",
      "#7bb7ff", "#d7a8ff", "#56b6c2", "#aaa6a0",
      "#69717d", "#ff8787", "#b5e890", "#ffd08a",
      "#5aa7ff", "#e0b0ff", "#77d7df", "#ffffff",
    },
  },
}

local c = palettes[variant]

for i, color in ipairs(c.terminal) do
  vim.g["terminal_color_" .. (i - 1)] = color
end

local function hi(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

local function link(group, target)
  hi(group, { link = target })
end

local function hi_many(groups, spec)
  for _, group in ipairs(groups) do
    hi(group, spec)
  end
end

local function link_many(target, groups)
  for _, group in ipairs(groups) do
    link(group, target)
  end
end

-- Core UI only. This avoids random defaults without turning the colorscheme
-- into a plugin-theme zoo.
hi_many({ "Normal", "NormalNC" }, { fg = c.fg, bg = c.bg })
hi_many({ "LineNr", "LineNrAbove", "LineNrBelow" }, { fg = c.line_nr, bg = c.bg })
hi_many({ "SignColumn", "FoldColumn" }, { fg = c.faint, bg = c.bg })
hi_many({ "WinSeparator", "VertSplit" }, { fg = c.border, bg = c.bg })
hi_many({ "Visual", "VisualNOS" }, { bg = c.selection })
hi_many({ "Search", "IncSearch", "CurSearch", "Substitute" }, { fg = c.search_fg, bg = c.orange })
hi_many({ "DiffAdd", "Added" }, { fg = c.green })
hi_many({ "DiffChange", "Changed" }, { fg = c.yellow })
hi_many({ "DiffDelete", "Removed" }, { fg = c.red })

for group, spec in pairs({
  EndOfBuffer = { fg = c.gutter, bg = c.bg },
  Folded = { fg = c.muted, bg = c.gutter },
  ColorColumn = { bg = c.line },
  Cursor = { fg = c.bg, bg = c.active },
  lCursor = { fg = c.bg, bg = c.active },
  CursorLine = { bg = c.line },
  CursorLineNr = { fg = c.cursor_line_nr, bg = c.line },
  NonText = { fg = c.invisible },
  Whitespace = { fg = c.invisible },
  StatusLine = { fg = c.fg, bg = c.status },
  StatusLineNC = { fg = c.muted, bg = c.status },
  Pmenu = { fg = c.fg, bg = c.ui },
  PmenuSel = { fg = c.fg, bg = c.pmenu_sel },
  NormalFloat = { fg = c.fg, bg = c.gutter },
  FloatBorder = { fg = c.border, bg = c.gutter },
  QuickFixLine = { bg = c.line },
  MatchParen = { underline = true, sp = c.active },
  Directory = { fg = c.directory },
  Title = { fg = c.constant },
  ModeMsg = { fg = c.muted },
  MoreMsg = { fg = c.more },
  WarningMsg = { fg = c.yellow },
  ErrorMsg = { fg = c.red, bg = c.red_bg },
  DiffText = { fg = c.fg, bg = c.comment },
  Underlined = { underline = true, sp = c.active },
  Error = { fg = c.red, bg = c.red_bg },
  Debug = { fg = c.red, bg = c.red_bg },
  Ignore = { fg = c.faint },
}) do
  hi(group, spec)
end

-- Diagnostics use the same small palette.
hi_many({ "DiagnosticError", "DiagnosticUnderlineError" }, { fg = c.red })
hi_many({ "DiagnosticWarn", "DiagnosticUnderlineWarn" }, { fg = c.yellow })
hi_many({ "DiagnosticInfo", "DiagnosticHint", "DiagnosticUnderlineInfo", "DiagnosticUnderlineHint" }, { fg = c.active })
hi("DiagnosticOk", { fg = c.green })
hi("DiagnosticVirtualTextError", { fg = c.red, bg = c.red_bg })
hi("DiagnosticVirtualTextWarn", { fg = c.yellow, bg = c.diagnostic_warn_bg })
hi("DiagnosticVirtualTextInfo", { fg = c.active, bg = c.diagnostic_info_bg })
hi("DiagnosticVirtualTextHint", { fg = c.active, bg = c.diagnostic_info_bg })
hi("DiagnosticVirtualTextOk", { fg = c.green, bg = c.diagnostic_ok_bg })
hi_many({ "LspReferenceText", "LspReferenceRead" }, { bg = c.reference })
hi("LspReferenceWrite", { bg = c.reference, underline = true, sp = c.active })
hi_many({ "LspCodeLens", "LspCodeLensSeparator" }, { fg = c.faint })

hi("SpellBad", { undercurl = true, sp = c.red })
hi("SpellCap", { undercurl = true, sp = c.active })
hi("SpellLocal", { undercurl = true, sp = c.spell_local })
hi("SpellRare", { undercurl = true, sp = c.constant })

-- Generic Vim syntax groups are boring fallbacks. This is what keeps netrw,
-- help, startup, etc. from inheriting the semantic backgrounds.
hi_many({
  "Comment", "String", "Character", "Identifier", "Function",
  "Statement", "Conditional", "Repeat", "Label", "Keyword", "Exception",
  "PreProc", "Include", "Define", "Macro", "PreCondit", "Type",
  "StorageClass", "Structure", "Typedef", "SpecialChar", "Tag",
  "SpecialComment", "Todo",
}, { fg = c.fg })
hi_many({ "Constant", "Number", "Boolean", "Float", "Special" }, { fg = c.constant })
hi_many({ "Operator", "Delimiter" }, { fg = c.punctuation })

-- The actual Alabaster BG semantics. In dark mode, use normal foreground
-- syntax colors instead of colored background blocks.
if variant == "dark" then
  hi("AlabasterComment", { fg = c.comment_fg })
  hi("AlabasterString", { fg = c.string_fg })
  hi("AlabasterSpecial", { fg = c.special_fg })
  hi("AlabasterDefinition", { fg = c.definition_fg })
  hi("AlabasterTodo", { fg = c.todo_fg })
else
  hi("AlabasterComment", { fg = c.fg, bg = c.comment })
  hi("AlabasterString", { fg = c.fg, bg = c.string })
  hi("AlabasterSpecial", { fg = c.fg, bg = c.special })
  hi("AlabasterDefinition", { fg = c.fg, bg = c.definition })
  hi("AlabasterTodo", { fg = c.fg, bg = c.comment })
end
hi("Bold", {})
hi("Italic", {})
hi("Strikethrough", { strikethrough = true })

-- Tree-sitter captures.
link_many("AlabasterComment", {
  "@comment", "@comment.documentation", "@string.documentation",
})
link_many("AlabasterTodo", { "@comment.todo", "@text.todo" })
link_many("AlabasterString", { "@string", "@string.regexp", "@character" })
link_many("AlabasterSpecial", {
  "@string.escape", "@string.special", "@string.special.symbol", "@character.special",
})
link_many("AlabasterDefinition", { "@label", "@function", "@function.method", "@type.definition" })
link_many("Constant", { "@constant", "@constant.builtin", "@constant.macro", "@number", "@number.float", "@boolean" })
link_many("Identifier", {
  "@variable", "@variable.builtin", "@variable.parameter", "@variable.member",
  "@module", "@module.builtin", "@attribute", "@property", "@constructor",
  "@tag.attribute",
})
link_many(variant == "dark" and "AlabasterDefinition" or "Identifier", {
  "@function.call", "@function.method.call", "@function.builtin", "@function.macro",
})
link_many("Type", { "@type", "@type.builtin" })
link_many("Keyword", {
  "@keyword", "@keyword.coroutine", "@keyword.function", "@keyword.type",
  "@keyword.modifier", "@keyword.return",
})
link_many("Operator", { "@operator", "@keyword.operator" })
link_many("Delimiter", {
  "@punctuation.delimiter", "@punctuation.bracket", "@punctuation.special",
  "@tag.delimiter", "@markup.list",
})
link_many("Tag", { "@tag", "@tag.builtin" })
link_many("Title", { "@markup.heading" })
link_many("Underlined", { "@markup.link", "@markup.link.url" })
link_many("Bold", { "@markup.strong" })
link_many("Italic", { "@markup.italic" })
link_many("Strikethrough", { "@markup.strikethrough" })
link_many("Added", { "@diff.plus" })
link_many("Removed", { "@diff.minus" })
link_many("Changed", { "@diff.delta" })
link_many("Error", { "@error" })
link("@keyword.import", "Include")
link("@keyword.repeat", "Repeat")
link("@keyword.conditional", "Conditional")
link("@keyword.exception", "Exception")
link("@keyword.debug", "Debug")

-- LSP semantic tokens. Light keeps plain references; dark uses normal
-- foreground coloring for function-like references.
link_many("AlabasterComment", { "@lsp.type.comment" })
link_many("AlabasterString", { "@lsp.type.string", "@lsp.type.regexp" })
link_many("Constant", { "@lsp.type.number", "@lsp.type.boolean", "@lsp.type.enumMember" })
link_many("Type", { "@lsp.type.typeParameter", "@lsp.type.class", "@lsp.type.enum", "@lsp.type.interface", "@lsp.type.struct", "@lsp.type.type" })
link_many("Identifier", {
  "@lsp.type.namespace", "@lsp.type.variable", "@lsp.type.parameter", "@lsp.type.property",
})
link_many(variant == "dark" and "AlabasterDefinition" or "Identifier", {
  "@lsp.type.function", "@lsp.type.method", "@lsp.type.macro", "@lsp.type.decorator",
})
link("@lsp.type.keyword", "Keyword")
link("@lsp.type.operator", "Operator")

for _, kind in ipairs({ "function", "method", "macro", "class", "enum", "interface", "namespace", "struct", "type" }) do
  link("@lsp.typemod." .. kind .. ".declaration", "AlabasterDefinition")
  link("@lsp.typemod." .. kind .. ".definition", "AlabasterDefinition")
end
