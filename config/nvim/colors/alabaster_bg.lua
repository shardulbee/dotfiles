-- Alabaster BG for Neovim.
-- Based on Nikita Prokopov's Sublime Alabaster BG palette.
vim.o.background = "light"
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "alabaster_bg"

local c = {
  fg = "#000000",
  bg = "#ffffff",
  ui = "#e6e6e6",
  gutter = "#f7f7f7",
  line = "#efefef", -- Sublime: #00000010 over white
  border = "#d2d2d2",
  active = "#007acc",
  selection = "#b4d8fd",
  inactive_selection = "#e0e0e0",

  blue_bg = "#dbf1ff",
  green_bg = "#f1fadf",
  dark_green_bg = "#dbecb6",
  red_bg = "#ffe0e0",
  yellow_bg = "#fffabc",
  orange = "#ffbc5d",

  purple = "#7a3e9d",
  red = "#aa3731",
  green = "#448c37",
  cyan = "#0083b2",
  blue = "#325cc0",
  vcs_green = "#6abf40", -- Sublime: hsl(100, 50%, 50%)
  vcs_yellow = "#ec8013", -- Sublime: hsl(30, 85%, 50%)
  vcs_red = "#d2322d", -- Sublime: hsl(2, 65%, 50%)

  muted = "#666666",
  faint = "#999999",
  invisible = "#cccccc",
  punctuation = "#707070",
  inner_punctuation = "#8a8a8a",
  error = "#cc3333",
}

vim.g.terminal_color_0 = c.fg
vim.g.terminal_color_1 = c.red
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = "#cb9000"
vim.g.terminal_color_4 = c.blue
vim.g.terminal_color_5 = c.purple
vim.g.terminal_color_6 = c.cyan
vim.g.terminal_color_7 = c.muted
vim.g.terminal_color_8 = "#777777"
vim.g.terminal_color_9 = "#f05050"
vim.g.terminal_color_10 = "#60cb00"
vim.g.terminal_color_11 = c.orange
vim.g.terminal_color_12 = c.active
vim.g.terminal_color_13 = "#e64ce6"
vim.g.terminal_color_14 = "#00aacb"
vim.g.terminal_color_15 = "#d4d4d4"

local function hi(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

local function link(group, target)
  hi(group, { link = target })
end

local groups = {
  Normal = { fg = c.fg, bg = c.bg },
  NormalNC = { fg = c.fg, bg = c.bg },
  EndOfBuffer = { fg = c.gutter, bg = c.bg },
  SignColumn = { fg = c.muted, bg = c.bg },
  FoldColumn = { fg = c.faint, bg = c.bg },
  Folded = { fg = c.muted, bg = c.gutter },
  ColorColumn = { bg = c.line },
  Cursor = { fg = c.bg, bg = c.active },
  lCursor = { fg = c.bg, bg = c.active },
  CursorLine = { bg = c.line },
  CursorColumn = { bg = c.line },
  CursorLineNr = { fg = "#44454b", bg = c.line, bold = true },
  LineNr = { fg = "#9da39a", bg = c.bg },
  LineNrAbove = { fg = "#9da39a", bg = c.bg },
  LineNrBelow = { fg = "#9da39a", bg = c.bg },
  Conceal = { fg = c.faint, bg = c.bg },
  NonText = { fg = c.invisible },
  SpecialKey = { fg = c.cyan },
  Whitespace = { fg = c.invisible },
  WinSeparator = { fg = c.border, bg = c.bg },
  VertSplit = { fg = c.border, bg = c.bg },

  StatusLine = { fg = c.fg, bg = "#dadada" },
  StatusLineNC = { fg = c.muted, bg = "#dadada" },
  TabLine = { fg = c.muted, bg = c.ui },
  TabLineFill = { bg = c.ui },
  TabLineSel = { fg = c.fg, bg = c.gutter, bold = true },
  WinBar = { fg = c.fg, bg = c.bg, bold = true },
  WinBarNC = { fg = c.muted, bg = c.bg },

  Pmenu = { fg = c.fg, bg = c.ui },
  PmenuSel = { fg = c.fg, bg = "#d2d2d2" },
  PmenuSbar = { bg = "#dfdfe0" },
  PmenuThumb = { bg = c.faint },
  PmenuKind = { fg = c.purple, bg = c.ui },
  PmenuExtra = { fg = c.muted, bg = c.ui },
  NormalFloat = { fg = c.fg, bg = c.gutter },
  FloatBorder = { fg = c.border, bg = c.gutter },
  FloatTitle = { fg = c.fg, bg = c.gutter, bold = true },
  QuickFixLine = { bg = c.line },

  Visual = { bg = c.selection },
  VisualNOS = { bg = c.inactive_selection },
  Search = { fg = c.fg, bg = c.orange },
  IncSearch = { fg = c.fg, bg = c.orange },
  CurSearch = { fg = c.fg, bg = c.orange, bold = true },
  Substitute = { fg = c.fg, bg = c.orange },
  MatchParen = { underline = true, sp = c.active },
  Directory = { fg = c.blue },
  Title = { fg = c.purple },
  Question = { fg = c.green },
  MoreMsg = { fg = c.green },
  ModeMsg = { fg = c.muted },
  ErrorMsg = { fg = c.error, bg = c.red_bg },
  WarningMsg = { fg = c.vcs_yellow },
  WildMenu = { fg = c.fg, bg = c.selection },

  DiffAdd = { fg = c.vcs_green },
  DiffChange = { fg = c.vcs_yellow },
  DiffDelete = { fg = c.vcs_red },
  DiffText = { fg = c.fg, bg = c.yellow_bg, bold = true },
  Added = { fg = c.vcs_green },
  Changed = { fg = c.vcs_yellow },
  Removed = { fg = c.vcs_red },

  DiagnosticError = { fg = c.vcs_red },
  DiagnosticWarn = { fg = c.vcs_yellow },
  DiagnosticInfo = { fg = c.active },
  DiagnosticHint = { fg = c.active },
  DiagnosticOk = { fg = c.vcs_green },
  DiagnosticVirtualTextError = { fg = c.error, bg = c.red_bg },
  DiagnosticVirtualTextWarn = { fg = c.vcs_yellow, bg = "#faf2e6" },
  DiagnosticVirtualTextInfo = { fg = c.active, bg = "#e6f3ff" },
  DiagnosticVirtualTextHint = { fg = c.active, bg = "#e6f3ff" },
  DiagnosticVirtualTextOk = { fg = c.vcs_green, bg = "#dfeadb" },
  DiagnosticUnderlineError = { undercurl = true, sp = c.vcs_red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.vcs_yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.active },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.active },
  LspReferenceText = { bg = "#cfcfcf" },
  LspReferenceRead = { bg = "#cfcfcf" },
  LspReferenceWrite = { bg = "#cfcfcf", underline = true, sp = c.active },
  LspCodeLens = { fg = c.faint },
  LspCodeLensSeparator = { fg = c.faint },

  Comment = { fg = c.fg, bg = c.yellow_bg },
  Constant = { fg = c.purple },
  String = { fg = c.fg, bg = c.green_bg },
  Character = { fg = c.fg, bg = c.green_bg },
  Number = { fg = c.purple },
  Boolean = { fg = c.purple },
  Float = { fg = c.purple },
  Identifier = { fg = c.fg },
  Function = { fg = c.fg, bg = c.blue_bg },
  Statement = { fg = c.fg },
  Conditional = { fg = c.fg },
  Repeat = { fg = c.fg },
  Label = { fg = c.fg, bg = c.blue_bg },
  Operator = { fg = c.punctuation },
  Keyword = { fg = c.fg },
  Exception = { fg = c.fg },
  PreProc = { fg = c.fg },
  Include = { fg = c.fg },
  Define = { fg = c.fg },
  Macro = { fg = c.fg },
  PreCondit = { fg = c.fg },
  Type = { fg = c.fg },
  StorageClass = { fg = c.fg },
  Structure = { fg = c.fg, bg = c.blue_bg },
  Typedef = { fg = c.fg, bg = c.blue_bg },
  Special = { fg = c.purple },
  SpecialChar = { fg = c.fg, bg = c.dark_green_bg },
  -- Sublime excludes entity.name.tag from the blue definition rule.
  Tag = { fg = c.fg },
  Delimiter = { fg = c.punctuation },
  SpecialComment = { fg = c.fg, bg = c.yellow_bg },
  Debug = { fg = c.error, bg = c.red_bg },
  Underlined = { underline = true, sp = c.active },
  Ignore = { fg = c.faint },
  Error = { fg = c.error, bg = c.red_bg },
  Todo = { fg = c.fg, bg = c.yellow_bg, bold = true },

  SpellBad = { undercurl = true, sp = c.error },
  SpellCap = { undercurl = true, sp = c.active },
  SpellLocal = { undercurl = true, sp = c.cyan },
  SpellRare = { undercurl = true, sp = c.purple },

  GitSignsAdd = { fg = c.vcs_green },
  GitSignsChange = { fg = c.vcs_yellow },
  GitSignsDelete = { fg = c.vcs_red },
  GitSignsAddNr = { fg = c.vcs_green },
  GitSignsChangeNr = { fg = c.vcs_yellow },
  GitSignsDeleteNr = { fg = c.vcs_red },

  FzfLuaNormal = { fg = c.fg, bg = c.bg },
  FzfLuaBorder = { fg = c.border, bg = c.bg },
  FzfLuaTitle = { fg = c.fg, bg = c.bg, bold = true },
  FzfLuaCursor = { fg = c.fg, bg = c.line },
  FzfLuaCursorLine = { bg = c.line },
  FzfLuaSearch = { fg = c.fg, bg = c.orange },
  FzfLuaMatch = { fg = c.fg, bg = c.orange },
  FzfLuaPreviewNormal = { fg = c.fg, bg = c.bg },
  FzfLuaPreviewBorder = { fg = c.border, bg = c.bg },
}

for group, spec in pairs(groups) do
  hi(group, spec)
end

local links = {
  -- Current Neovim treesitter captures.
  ["@comment"] = "Comment",
  ["@comment.documentation"] = "Comment",
  ["@string"] = "String",
  ["@string.documentation"] = "Comment",
  ["@string.escape"] = "SpecialChar",
  ["@string.special"] = "SpecialChar",
  ["@string.special.symbol"] = "SpecialChar",
  ["@string.regexp"] = "String",
  ["@character"] = "Character",
  ["@character.special"] = "SpecialChar",
  ["@constant"] = "Constant",
  ["@constant.builtin"] = "Constant",
  ["@constant.macro"] = "Constant",
  ["@number"] = "Number",
  ["@number.float"] = "Float",
  ["@boolean"] = "Boolean",
  ["@variable"] = "Identifier",
  ["@variable.builtin"] = "Identifier",
  ["@variable.parameter"] = "Identifier",
  ["@variable.member"] = "Identifier",
  ["@module"] = "Identifier",
  ["@module.builtin"] = "Identifier",
  ["@label"] = "Label",
  ["@function"] = "Function",
  ["@function.method"] = "Function",
  ["@function.call"] = "Identifier",
  ["@function.method.call"] = "Identifier",
  ["@function.builtin"] = "Identifier",
  ["@function.macro"] = "Identifier",
  ["@constructor"] = "Identifier",
  ["@type"] = "Type",
  ["@type.builtin"] = "Type",
  ["@type.definition"] = "Typedef",
  ["@attribute"] = "Identifier",
  ["@property"] = "Identifier",
  ["@keyword"] = "Keyword",
  ["@keyword.coroutine"] = "Keyword",
  ["@keyword.function"] = "Keyword",
  ["@keyword.operator"] = "Operator",
  ["@keyword.import"] = "Include",
  ["@keyword.type"] = "Keyword",
  ["@keyword.modifier"] = "Keyword",
  ["@keyword.repeat"] = "Repeat",
  ["@keyword.return"] = "Keyword",
  ["@keyword.debug"] = "Debug",
  ["@keyword.exception"] = "Exception",
  ["@keyword.conditional"] = "Conditional",
  ["@operator"] = "Operator",
  ["@punctuation.delimiter"] = "Delimiter",
  ["@punctuation.bracket"] = "Delimiter",
  ["@punctuation.special"] = "Delimiter",
  ["@tag"] = "Tag",
  ["@tag.builtin"] = "Tag",
  ["@tag.attribute"] = "Identifier",
  ["@tag.delimiter"] = "Delimiter",
  ["@markup.heading"] = "Title",
  ["@markup.link"] = "Underlined",
  ["@markup.link.url"] = "Underlined",
  ["@markup.raw"] = "String",
  ["@markup.strong"] = "Bold",
  ["@markup.italic"] = "Italic",
  ["@markup.strikethrough"] = "Strikethrough",
  ["@markup.list"] = "Delimiter",
  ["@diff.plus"] = "Added",
  ["@diff.minus"] = "Removed",
  ["@diff.delta"] = "Changed",
  ["@error"] = "Error",

  -- Older nvim-treesitter captures.
  TSComment = "Comment",
  TSString = "String",
  TSStringDoc = "Comment",
  TSStringEscape = "SpecialChar",
  TSStringSpecial = "SpecialChar",
  TSCharacter = "Character",
  TSConstBuiltin = "Constant",
  TSConstant = "Constant",
  TSNumber = "Number",
  TSFloat = "Float",
  TSBoolean = "Boolean",
  TSVariable = "Identifier",
  TSVariableBuiltin = "Identifier",
  TSParameter = "Identifier",
  TSField = "Identifier",
  TSNamespace = "Identifier",
  TSLabel = "Label",
  TSFunction = "Function",
  TSMethod = "Function",
  TSFuncCall = "Identifier",
  TSFuncBuiltin = "Identifier",
  TSConstructor = "Identifier",
  TSType = "Type",
  TSTypeBuiltin = "Type",
  TSTypeDefinition = "Typedef",
  TSAttribute = "Identifier",
  TSProperty = "Identifier",
  TSKeyword = "Keyword",
  TSKeywordFunction = "Keyword",
  TSKeywordOperator = "Operator",
  TSInclude = "Include",
  TSRepeat = "Repeat",
  TSConditional = "Conditional",
  TSException = "Exception",
  TSOperator = "Operator",
  TSPunctDelimiter = "Delimiter",
  TSPunctBracket = "Delimiter",
  TSPunctSpecial = "Delimiter",
  TSTag = "Tag",
  TSTagAttribute = "Identifier",
  TSTagDelimiter = "Delimiter",
  TSTitle = "Title",
  TSURI = "Underlined",
  TSLiteral = "String",
  TSStrong = "Bold",
  TSEmphasis = "Italic",
  TSStrike = "Strikethrough",
  TSError = "Error",

  -- LSP semantic token fallbacks that should not overpower definition captures.
  ["@lsp.type.comment"] = "Comment",
  ["@lsp.type.string"] = "String",
  ["@lsp.type.regexp"] = "String",
  ["@lsp.type.number"] = "Number",
  ["@lsp.type.boolean"] = "Boolean",
  ["@lsp.type.enumMember"] = "Constant",
  ["@lsp.type.typeParameter"] = "Type",
  ["@lsp.type.class"] = "Type",
  ["@lsp.type.enum"] = "Type",
  ["@lsp.type.interface"] = "Type",
  ["@lsp.type.struct"] = "Type",
  ["@lsp.type.type"] = "Type",
  ["@lsp.type.namespace"] = "Identifier",
  ["@lsp.type.function"] = "Identifier",
  ["@lsp.type.method"] = "Identifier",
  ["@lsp.type.macro"] = "Identifier",
  ["@lsp.type.variable"] = "Identifier",
  ["@lsp.type.parameter"] = "Identifier",
  ["@lsp.type.property"] = "Identifier",
  ["@lsp.type.decorator"] = "Identifier",
  ["@lsp.type.keyword"] = "Keyword",
  ["@lsp.type.operator"] = "Operator",

  -- Recreate Sublime's `entity.name - entity.name.tag` rule as narrowly as
  -- Neovim/LSP allows: definitions/declarations get the blue background;
  -- ordinary calls/references stay black.
  ["@lsp.typemod.function.declaration"] = "Function",
  ["@lsp.typemod.function.definition"] = "Function",
  ["@lsp.typemod.method.declaration"] = "Function",
  ["@lsp.typemod.method.definition"] = "Function",
  ["@lsp.typemod.class.declaration"] = "Typedef",
  ["@lsp.typemod.class.definition"] = "Typedef",
  ["@lsp.typemod.enum.declaration"] = "Typedef",
  ["@lsp.typemod.enum.definition"] = "Typedef",
  ["@lsp.typemod.interface.declaration"] = "Typedef",
  ["@lsp.typemod.interface.definition"] = "Typedef",
  ["@lsp.typemod.namespace.declaration"] = "Function",
  ["@lsp.typemod.namespace.definition"] = "Function",
  ["@lsp.typemod.struct.declaration"] = "Typedef",
  ["@lsp.typemod.struct.definition"] = "Typedef",
  ["@lsp.typemod.type.declaration"] = "Typedef",
  ["@lsp.typemod.type.definition"] = "Typedef",
}

hi("Bold", { bold = true })
hi("Italic", { italic = true })
hi("Strikethrough", { strikethrough = true })

for group, target in pairs(links) do
  link(group, target)
end
