require("snacks").setup({
	bigfile = { enabled = true },
	bufdelete = { enabled = true },
	debug = { enabled = true },
	gitbrowse = { enabled = true },
	input = { enabled = true },
	lazygit = { enabled = true },
	notifier = { enabled = true },
	quickfile = { enabled = true },
	rename = { enabled = true },
	scope = { enabled = true },
	statuscolumn = { enabled = true, folds = { open = true } },
	words = { enabled = true },
	image = { enabled = true },
	indent = { enabled = true },
	--
	gh = { enabled = false },
	dashboard = { enabled = false },
	explorer = { enabled = false },
	scroll = { enabled = false },
	picker = { enabled = false },
})

Snacks.indent.enable()
