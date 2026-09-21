-- Alabaster for Neovim.
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
    fg = "#26251e",
    bg = "#f7f7f4",
    ui = "#e6e6e6",
    gutter = "#f7f7f4",
    line = "#f0efeb",
    border = "#d2d2d2",
    active = "#007acc",
    selection = "#b4d8fd",
    comment = "#fef9c5",
    string = "#f2f9e2",
    special = "#dfedbf",
    definition = "#dff2fe",
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
    search_fg = "#26251e",
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
      "#26251e", "#aa3731", "#448c37", "#cb9000",
      "#325cc0", "#7a3e9d", "#0083b2", "#666666",
      "#777777", "#f05050", "#60cb00", "#ffbc5d",
      "#007acc", "#e64ce6", "#00aacb", "#d4d4d4",
    },
  },
  dark = {
    fg = "#cecece",
    bg = "#14120b",
    ui = "#1b1913",
    gutter = "#14120b",
    line = "#201e18",
    border = "#2b2923",
    active = "#739fc8",
    selection = "#3a382f",
    comment = "#2b2923",
    string = "#263022",
    special = "#29342a",
    definition = "#202d38",
    comment_fg = "#c7c78f",
    string_fg = "#8fb980",
    special_fg = "#6faeb3",
    definition_fg = "#739fc8",
    todo_fg = "#c7c78f",
    constant = "#b986b5",
    punctuation = "#708b8d",
    muted = "#999999",
    faint = "#6f716c",
    invisible = "#34322b",
    orange = "#c7a55f",
    red = "#d66a64",
    red_bg = "#2b1d1e",
    green = "#8fb980",
    yellow = "#c7a55f",
    line_nr = "#777777",
    cursor_line_nr = "#cecece",
    search_fg = "#14120b",
    status = "#1b1913",
    pmenu_sel = "#2b2923",
    directory = "#739fc8",
    more = "#8fb980",
    diagnostic_warn_bg = "#2b2415",
    diagnostic_info_bg = "#18232b",
    diagnostic_ok_bg = "#1d291a",
    reference = "#2b2923",
    spell_local = "#6faeb3",
    terminal = {
      "#14120b", "#d66a64", "#8fb980", "#c7a55f",
      "#739fc8", "#b986b5", "#6faeb3", "#cecece",
      "#777777", "#e47e78", "#a5ca98", "#d5b773",
      "#8bb2d5", "#c99bc5", "#88c0c4", "#ffffff",
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
