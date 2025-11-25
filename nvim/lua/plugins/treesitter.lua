-- Treesitter configuration
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			auto_install = false,
			ignore_install = {},
			modules = {},
			sync_install = false,
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
				"go",
				"gomod",
				"gowork",
				"gosum",
			},
			highlight = { enable = true },
		})
	end,
}
