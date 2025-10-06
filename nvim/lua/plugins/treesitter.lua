-- Treesitter configuration
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"vue",
				"tsx",
				"gitignore",
				"javascript",
				"typescript",
				"markdown",
				"html",
				"css",
				"yaml",
			},
			highlight = { enable = true },
		})
	end,
}
