-- Markdown plugins
return {
	{
		"HakonHarnes/img-clip.nvim",
		event = "VeryLazy",
		opts = {
			-- add options here
			-- or leave it empty to use the default settings
		},
		keys = {
			-- suggested keymap
			{ "<C-p>", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			completions = { lsp = { enabled = true } },
		},
	},
	{
		"obsidian-nvim/obsidian.nvim",
		version = "*", -- recommended, use latest release instead of latest commit
		---@module 'obsidian'
		---@type obsidian.config
		opts = {
			templates = {
				folder = "templates",
			},
			picker = {
				name = "mini.pick",
			},
			completion = {
				blink = true,
			},
			legacy_commands = false,
			ui = {
				enable = false,
			},
			workspaces = {
				{
					name = "personal",
					path = "~/vaults/personal",
				},
				{
					name = "work",
					path = "~/vaults/work",
				},
			},
			pre_write_note = function(note)
				local template = vim.fn.readfile(vim.fn.expand("~/vaults/personal/templates/00 Default.md"))
				vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
				Snacks.debug.inspect(note)
			end,
			frontmatter = {
				func = function(note)
					local frontmatter = note:frontmatter()

					frontmatter.title = note.title
					frontmatter.aliases = nil

					-- Snacks.debug.inspect(frontmatter)
					return frontmatter
				end,
			},
		},
		config = function(_, opts)
			require("obsidian").setup(opts)
			local utils = require("config.utils")
			utils.nmap_leader("oo", "<CMD>Obsidian<CR>", "Obsidian")
			utils.nmap_leader("os", "<CMD>Obsidian search<CR>", "Search")
			utils.nmap_leader("ow", "<CMD>Obsidian workspace<CR>", "Workspace")
		end,
	},
}
