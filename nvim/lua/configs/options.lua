-- references https://github.com/nvim-mini/MiniMax/blob/main/configs/nvim-0.11/plugin/10_options.lua
local g = vim.g
g.mapleader = ' '

local o = vim.opt

o.number = true -- show line number
o.relativenumber = true -- relative line number

o.swapfile = false -- no swap files

o.wrap = false -- no wrap text
o.linebreak = true 

o.shiftwidth = 2
o.tabstop = 2
o.expandtab = true
o.smartindent = true
o.smartindent = true
o.autoindent = true
o.scrolloff = 10

vim.schedule(function()
  o.clipboard = "unnamedplus" -- system clipboard
end)

o.undofile = true

-- Timeouts
o.timeoutlen = 500
o.ttimeoutlen = 10

-- search
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.spelloptions = 'camel'

-- split behavior
o.splitright = true
o.splitbelow = true

o.inccommand = "split" -- live preview

-- Folding (will be configured by nvim-ufo)
o.foldcolumn = "1"
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true

o.iskeyword = "@,48-57,_,192-255,-" -- Treat dash as `word` textobject part

o.switchbuf = "usetab"
o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)

-- Enable all filetype plugins and syntax (if not enabled, for better startup)
vim.cmd('filetype plugin indent on')
if vim.fn.exists('syntax_on') ~= 1 then vim.cmd('syntax enable') end

o.list           = true       -- Show helpful text indicators
o.listchars = 'trail:-,nbsp:+,tab:▏ '
o.fillchars = 'eob: ,fold: ,foldopen:,foldsep: ,foldinner: ,foldclose:'
o.ruler = false

o.infercase     = true    -- Infer case in built-in completion
