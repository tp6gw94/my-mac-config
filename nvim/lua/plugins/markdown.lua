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
		"3rd/image.nvim",
		build = false,
		opts = {
			processor = "magick_cli",
			integrations = {
				markdown = {
					only_render_image_at_cursor = true,
					only_render_image_at_cursor_mode = "inline",
				},
			},
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
				name = "fzf-lua",
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

			vim.keymap.set("n", "<leader>oo", "<CMD>Obsidian<CR>")
			vim.keymap.set("n", "<leader>os", "<CMD>Obsidian search<CR>")
			vim.keymap.set("n", "<leader>ow", "<CMD>Obsidian workspace<CR>")
		end,
	},
}
