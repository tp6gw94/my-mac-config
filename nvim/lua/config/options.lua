-- Neovim options configuration

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.numberwidth = 3
vim.opt.signcolumn = "yes:1"
vim.opt.statuscolumn = "%l%s"

-- No swap files
vim.o.swapfile = false

-- Text wrapping
vim.opt.wrap = true

-- Indentation
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.opt.tabstop = 2
vim.opt.breakindent = true

-- UI
vim.opt.showmode = false
vim.opt.background = "light"
vim.opt.cursorline = true
vim.opt.scrolloff = 12
vim.opt.winborder = "rounded"

-- Clipboard (scheduled to avoid startup delay)
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- Undo
vim.opt.undofile = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Timeouts
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 10

-- Split behavior
vim.opt.splitright = true
vim.opt.splitbelow = true

-- List chars
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Live preview
vim.opt.inccommand = "split"

-- Folding (will be configured by nvim-ufo)
vim.o.foldcolumn = "1"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- Diagnostics configuration
vim.diagnostic.config({
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = vim.diagnostic.severity.ERROR },
	virtual_text = {
		current_line = true,
		source = "if_many",
		spacing = 4,
	},
})
