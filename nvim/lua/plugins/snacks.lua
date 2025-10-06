return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		debug = { enabled = true },
		dashboard = { enabled = false },
		explorer = { enabled = false },
		scroll = { enabled = false },
		bigfile = { enabled = true },
		indent = { enabled = false },
		input = { enabled = true },
		picker = { enabled = false },
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		statuscolumn = { enabled = true, folds = { open = true } },
		words = { enabled = true },
		lazygit = { enabled = true },
		gitbrowse = { enabled = true },
		lazygit = { enabled = true },
		rename = { enabled = true },
	},
	keys = {
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
		},
		{
			"<leader>gv",
			function()
				Snacks.gitbrowse()
			end,
		},
		{
			"<leader>gb",
			function()
				Snacks.git.blame_line()
			end,
		},
	},
}
