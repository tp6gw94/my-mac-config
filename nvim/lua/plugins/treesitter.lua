require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"c",
		"lua",
		"vim",
		"vimdoc",
    "json",
		"query",
		"markdown",
		"markdown_inline",
		"tsx",
		"gitignore",
		"javascript",
		"typescript",
		"html",
		"css",
		"yaml",
		"go",
		"gomod",
		"gowork",
		"gosum",
	},
	-- Install parsers synchronously (only applied to `ensure_installed`)
	sync_install = false,
	auto_install = false,

	-- List of parsers to ignore installing (or "all")
	ignore_install = {},

	---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
	-- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

	highlight = {
		enable = true,
		additional_vim_regex_highlighting = { "markdown" },
	},

	modules = {},
})
