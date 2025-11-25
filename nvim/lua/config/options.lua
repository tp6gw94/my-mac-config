-- Neovim opt configuration

-- Line numbers
vim.o.number = true
vim.o.relativenumber = true

vim.o.numberwidth = 3
vim.o.signcolumn = "yes:1"
vim.o.statuscolumn = "%l%s"

-- No swap files
vim.o.swapfile = false

-- Text wrapping
vim.o.wrap = false
vim.o.linebreak = true

-- Indentation
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.breakindent = true
vim.o.expandtab = true
vim.o.smartindent = true

-- UI
vim.o.showmode = false
vim.o.background = "light"
vim.o.cursorline = true
vim.o.cursorlineopt = "screenline,number" -- Show cursor line per screen line
vim.o.scrolloff = 12 
vim.o.winborder = "rounded"
vim.o.colorcolumn = "+1"
vim.o.ruler = false

-- Clipboard (scheduled to avoid startup delay)
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- Undo
vim.o.undofile = true

-- Search
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true

-- Timeouts
vim.o.timeoutlen = 500
vim.o.ttimeoutlen = 10

-- Split behavior
vim.o.splitright = true
vim.o.splitbelow = true

-- List chars
vim.o.list = true
vim.o.listchars = 'trail:-,nbsp:+,tab:▏ '

-- Live preview
vim.o.inccommand = "split"

-- Folding (will be configured by nvim-ufo)
vim.o.foldcolumn = "1"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.o.iskeyword = "@,48-57,_,192-255,-" -- Treat dash as `word` textobject part

vim.o.switchbuf = "usetab"
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)

-- Enable all filetype plugins and syntax (if not enabled, for better startup)
vim.cmd('filetype plugin indent on')
if vim.fn.exists('syntax_on') ~= 1 then vim.cmd('syntax enable') end
