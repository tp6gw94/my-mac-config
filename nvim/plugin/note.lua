require("obsidian").setup({
	legacy_commands = false, -- this will be removed in 4.0.0
	note_id_func = require("obsidian.builtin").title_id,
	workspaces = {
		{
			name = "personal",
			path = vim.env.OBSIDIAN,
		},
	},
})

require("live_server").setup({})
require("markdown_preview").setup({
  default_theme = "light"
})
