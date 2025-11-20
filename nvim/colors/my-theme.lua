local ok, MiniColors = pcall(require, "mini.colors")
if not ok then
  vim.notify("mini.colors not found", vim.log.levels.ERROR)
  return
end

local bg = "#F5F0E8"
local fg = "#2B2B2B"
local gray = "#6B6B6B"
local light_gray = "#D5D0C8"
local dark_gray = "#4A4A4A"

local red = "#8B4049"
local green = "#4A7856"
local yellow = "#8B7355"
local blue = "#4A6A8B"
local magenta = "#7B5A7B"
local cyan = "#4A7B7B"

local red_bg = "#E8D5D7"
local green_bg = "#D5E8DA"
local yellow_bg = "#E8E3D5"
local blue_bg = "#D5DEE8"

local cs = MiniColors.as_colorscheme({
  name = "my-theme",
  groups = {
    Normal = { fg = fg, bg = bg },
    NormalFloat = { fg = fg, bg = light_gray },
    FloatBorder = { fg = gray, bg = light_gray },
    FloatTitle = { fg = dark_gray, bg = light_gray, bold = true },

    Cursor = { fg = bg, bg = fg },
    CursorLine = { bg = light_gray },
    CursorColumn = { bg = light_gray },
    ColorColumn = { bg = light_gray },

    LineNr = { fg = gray },
    CursorLineNr = { fg = dark_gray, bold = true },
    SignColumn = { fg = gray, bg = bg },
    FoldColumn = { fg = gray, bg = bg },

    StatusLine = { fg = fg, bg = light_gray },
    StatusLineNC = { fg = gray, bg = light_gray },
    TabLine = { fg = gray, bg = light_gray },
    TabLineFill = { bg = light_gray },
    TabLineSel = { fg = fg, bg = bg, bold = true },
    WinBar = { fg = fg, bg = bg },
    WinBarNC = { fg = gray, bg = bg },
    WinSeparator = { fg = light_gray },

    Pmenu = { fg = fg, bg = light_gray },
    PmenuSel = { fg = fg, bg = yellow_bg, bold = true },
    PmenuSbar = { bg = light_gray },
    PmenuThumb = { bg = gray },

    Visual = { bg = blue_bg },
    VisualNOS = { bg = blue_bg },
    Search = { fg = fg, bg = yellow_bg, bold = true },
    IncSearch = { fg = bg, bg = yellow, bold = true },
    CurSearch = { fg = bg, bg = yellow, bold = true },
    Substitute = { fg = bg, bg = red },

    MatchParen = { fg = fg, bg = yellow_bg, bold = true },

    Comment = { fg = gray, italic = true },
    Constant = { fg = cyan },
    String = { fg = green },
    Character = { fg = green },
    Number = { fg = magenta },
    Boolean = { fg = magenta },
    Float = { fg = magenta },

    Identifier = { fg = fg },
    Function = { fg = blue },

    Statement = { fg = red },
    Conditional = { fg = red },
    Repeat = { fg = red },
    Label = { fg = red },
    Operator = { fg = dark_gray },
    Keyword = { fg = red },
    Exception = { fg = red },

    PreProc = { fg = magenta },
    Include = { fg = magenta },
    Define = { fg = magenta },
    Macro = { fg = magenta },
    PreCondit = { fg = magenta },

    Type = { fg = yellow },
    StorageClass = { fg = yellow },
    Structure = { fg = yellow },
    Typedef = { fg = yellow },

    Special = { fg = cyan },
    SpecialChar = { fg = cyan },
    Tag = { fg = blue },
    Delimiter = { fg = dark_gray },
    SpecialComment = { fg = gray, bold = true },
    Debug = { fg = red },

    Underlined = { fg = blue, underline = true },
    Error = { fg = red, bold = true },
    Todo = { fg = bg, bg = yellow, bold = true },

    Added = { fg = green },
    Changed = { fg = yellow },
    Removed = { fg = red },

    DiffAdd = { bg = green_bg },
    DiffChange = { bg = yellow_bg },
    DiffDelete = { bg = red_bg },
    DiffText = { bg = yellow_bg, bold = true },

    DiagnosticError = { fg = red },
    DiagnosticWarn = { fg = yellow },
    DiagnosticInfo = { fg = blue },
    DiagnosticHint = { fg = cyan },
    DiagnosticOk = { fg = green },

    DiagnosticUnderlineError = { sp = red, undercurl = true },
    DiagnosticUnderlineWarn = { sp = yellow, undercurl = true },
    DiagnosticUnderlineInfo = { sp = blue, undercurl = true },
    DiagnosticUnderlineHint = { sp = cyan, undercurl = true },

    DiagnosticVirtualTextError = { fg = red, bg = red_bg },
    DiagnosticVirtualTextWarn = { fg = yellow, bg = yellow_bg },
    DiagnosticVirtualTextInfo = { fg = blue, bg = blue_bg },
    DiagnosticVirtualTextHint = { fg = cyan, bg = green_bg },

    DiagnosticSignError = { fg = red },
    DiagnosticSignWarn = { fg = yellow },
    DiagnosticSignInfo = { fg = blue },
    DiagnosticSignHint = { fg = cyan },

    SpellBad = { sp = red, undercurl = true },
    SpellCap = { sp = yellow, undercurl = true },
    SpellLocal = { sp = cyan, undercurl = true },
    SpellRare = { sp = magenta, undercurl = true },

    Title = { fg = blue, bold = true },
    Directory = { fg = blue },
    Question = { fg = green },
    MoreMsg = { fg = green },
    WarningMsg = { fg = yellow },
    ErrorMsg = { fg = red, bold = true },
    ModeMsg = { fg = fg, bold = true },

    NonText = { fg = gray },
    SpecialKey = { fg = gray },
    Conceal = { fg = gray },
    EndOfBuffer = { fg = gray },
    Whitespace = { fg = gray },
    Folded = { fg = gray, bg = light_gray },

    ["@variable"] = { fg = fg },
    ["@variable.builtin"] = { fg = red },
    ["@variable.parameter"] = { fg = fg, italic = true },
    ["@variable.member"] = { fg = fg },

    ["@constant"] = { fg = cyan },
    ["@constant.builtin"] = { fg = cyan },
    ["@constant.macro"] = { fg = cyan },

    ["@module"] = { fg = fg },
    ["@label"] = { fg = red },

    ["@string"] = { fg = green },
    ["@string.escape"] = { fg = cyan },
    ["@string.special"] = { fg = cyan },

    ["@character"] = { fg = green },
    ["@number"] = { fg = magenta },
    ["@boolean"] = { fg = magenta },
    ["@float"] = { fg = magenta },

    ["@function"] = { fg = blue },
    ["@function.builtin"] = { fg = blue },
    ["@function.macro"] = { fg = magenta },
    ["@function.method"] = { fg = blue },

    ["@constructor"] = { fg = blue },
    ["@operator"] = { fg = dark_gray },

    ["@keyword"] = { fg = red },
    ["@keyword.function"] = { fg = red },
    ["@keyword.operator"] = { fg = red },
    ["@keyword.return"] = { fg = red },
    ["@keyword.conditional"] = { fg = red },
    ["@keyword.repeat"] = { fg = red },
    ["@keyword.import"] = { fg = magenta },
    ["@keyword.exception"] = { fg = red },

    ["@type"] = { fg = yellow },
    ["@type.builtin"] = { fg = yellow },

    ["@attribute"] = { fg = magenta },
    ["@property"] = { fg = fg },

    ["@punctuation.delimiter"] = { fg = dark_gray },
    ["@punctuation.bracket"] = { fg = dark_gray },
    ["@punctuation.special"] = { fg = cyan },

    ["@comment"] = { fg = gray, italic = true },
    ["@comment.todo"] = { fg = bg, bg = yellow, bold = true },
    ["@comment.note"] = { fg = bg, bg = blue, bold = true },
    ["@comment.warning"] = { fg = bg, bg = yellow, bold = true },
    ["@comment.error"] = { fg = bg, bg = red, bold = true },

    ["@markup.heading"] = { fg = blue, bold = true },
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.link"] = { fg = cyan },
    ["@markup.link.url"] = { fg = cyan, underline = true },
    ["@markup.raw"] = { fg = green },
    ["@markup.list"] = { fg = red },

    ["@tag"] = { fg = red },
    ["@tag.attribute"] = { fg = yellow },
    ["@tag.delimiter"] = { fg = dark_gray },

    GitSignsAdd = { fg = green },
    GitSignsChange = { fg = yellow },
    GitSignsDelete = { fg = red },

    MiniDiffSignAdd = { fg = green, bold = true },
    MiniDiffSignChange = { fg = yellow, bold = true },
    MiniDiffSignDelete = { fg = red, bold = true },
    MiniDiffOverAdd = { bg = green_bg },
    MiniDiffOverChange = { bg = yellow_bg },
    MiniDiffOverChangeBuf = { bg = blue_bg },
    MiniDiffOverContext = { bg = bg, fg = gray },
    MiniDiffOverContextBuf = { bg = bg, fg = gray },
    MiniDiffOverDelete = { bg = red_bg, bold = true },

    MiniPickBorder = { fg = gray },
    MiniPickNormal = { fg = fg, bg = bg },
    MiniPickMatchCurrent = { bg = yellow_bg },
    MiniPickMatchMarked = { bg = blue_bg },

    MiniStatuslineFilename = { fg = fg },
    MiniStatuslineFileinfo = { fg = gray },
    MiniStatuslineModeNormal = { fg = bg, bg = blue, bold = true },
    MiniStatuslineModeInsert = { fg = bg, bg = green, bold = true },
    MiniStatuslineModeVisual = { fg = bg, bg = magenta, bold = true },
    MiniStatuslineModeReplace = { fg = bg, bg = red, bold = true },
    MiniStatuslineModeCommand = { fg = bg, bg = yellow, bold = true },
    MiniStatuslineModeOther = { fg = bg, bg = cyan, bold = true },

    MiniCursorword = { bg = light_gray },
    MiniIndentscopeSymbol = { fg = gray },

    MiniHipatternsTodo = { fg = bg, bg = yellow, bold = true },
    MiniHipatternsNote = { fg = bg, bg = blue, bold = true },
    MiniHipatternsFixme = { fg = bg, bg = red, bold = true },
    MiniHipatternsHack = { fg = bg, bg = magenta, bold = true },

    MiniJump = { fg = bg, bg = magenta },
    MiniJump2dSpot = { fg = bg, bg = magenta, bold = true },

    MiniFilesNormal = { fg = fg, bg = bg },
    MiniFilesBorder = { fg = gray },
    MiniFilesDirectory = { fg = blue },
    MiniFilesFile = { fg = fg },
    MiniFilesCursorLine = { bg = light_gray },

    MiniStarterHeader = { fg = blue },
    MiniStarterFooter = { fg = gray, italic = true },
    MiniStarterItem = { fg = fg },
    MiniStarterItemBullet = { fg = gray },
    MiniStarterItemPrefix = { fg = yellow },
    MiniStarterSection = { fg = red },
    MiniStarterQuery = { fg = green, bold = true },
    MiniStarterCurrent = { bg = light_gray },

    LazyNormal = { fg = fg, bg = bg },
    LazyButton = { fg = fg, bg = light_gray },
    LazyButtonActive = { fg = fg, bg = yellow_bg, bold = true },
    LazyH1 = { fg = bg, bg = blue, bold = true },

    TelescopeNormal = { fg = fg, bg = bg },
    TelescopeBorder = { fg = gray },
    TelescopeSelection = { bg = yellow_bg },

    TroubleNormal = { fg = fg, bg = bg },

    SmartPickPathMatch = { fg = green, bold = true },
    SmartPickBuffer = { fg = blue, italic = true },

    TinyInlineDiagnosticVirtualTextError = { fg = bg, bg = red, italic = true },
    TinyInlineDiagnosticVirtualTextWarn = { fg = bg, bg = yellow, italic = true },
    TinyInlineDiagnosticVirtualTextInfo = { fg = bg, bg = blue, italic = true },
    TinyInlineDiagnosticVirtualTextHint = { fg = fg, bg = green_bg, italic = true },
  },
  terminal = {
    [0] = "#2B2B2B",
    [1] = red,
    [2] = green,
    [3] = yellow,
    [4] = blue,
    [5] = magenta,
    [6] = cyan,
    [7] = "#D5D0C8",
    [8] = "#4A4A4A",
    [9] = "#A35059",
    [10] = "#5A8866",
    [11] = "#9B8365",
    [12] = "#5A7A9B",
    [13] = "#8B6A8B",
    [14] = "#5A8B8B",
    [15] = "#F5F0E8",
  },
})

cs:add_cterm_attributes():apply()
