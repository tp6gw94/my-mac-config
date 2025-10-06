-- Neovim configuration entry point

-- Global configuration
vim.g.have_nerd_font = true

-- Bootstrap lazy.nvim and load configuration modules
require("config.lazy")
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.commands")

-- Setup lazy.nvim with plugins
require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	install = { colorscheme = { "base16" } },
})

vim.cmd([[colorscheme base16]])
