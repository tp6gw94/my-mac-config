-- Mini.nvim plugins suite
return {
	"echasnovski/mini.nvim",
	version = "*",
	dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", "folke/trouble.nvim" },
	lazy = false,
	config = function()
		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})
		require("mini.comment").setup({
			options = {
				custom_commentstring = function()
					return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
				end,
			},
		})
		require("mini.pairs").setup()
		require("mini.surround").setup({
			mappings = {
				add = "ms",
				delete = "md",
				find_left = "",
				highlight = "",
				replace = "mr",
			},
		})
		require("mini.bracketed").setup()
		require("mini.diff").setup()
		require("mini.jump2d").setup({
			mappings = {
				start_jumping = "ss",
			},
		})
		require("mini.cursorword").setup()
		local hipatterns = require("mini.hipatterns")
		hipatterns.setup({
			highlighters = {
				-- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
				fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
				hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
				todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
				note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

				-- Highlight hex color strings (`#rrggbb`) using that color
				hex_color = hipatterns.gen_highlighter.hex_color(),
			},
		})
		require("mini.icons").setup()
		require("mini.indentscope").setup()
		require("mini.statusline").setup()
		require("mini.files").setup()
		require("mini.misc").setup()

		-- Custom keymaps for mini.files
		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesBufferCreate",
			callback = function(args)
				local buf_id = args.data.buf_id
				vim.keymap.set("n", "<C-v>", function()
					local entry = require("mini.files").get_fs_entry()
					if entry and entry.fs_type == "file" then
						require("mini.files").close()
						vim.cmd("vsplit " .. vim.fn.fnameescape(entry.path))
					end
				end, { buffer = buf_id, desc = "Open in vertical split" })
				vim.keymap.set("n", "<C-s>", function()
					local entry = require("mini.files").get_fs_entry()
					if entry and entry.fs_type == "file" then
						require("mini.files").close()
						vim.cmd("split " .. vim.fn.fnameescape(entry.path))
					end
				end, { buffer = buf_id, desc = "Open in horizontal split" })
			end,
		})

		vim.api.nvim_set_hl(0, "MiniHipatternsTodo", {
			bg = "#ffbb00",
			fg = "#ffffff",
		})
	end,
	keys = {
		{
			"<leader>e",
			"<CMD>lua MiniFiles.open(vim.api.nvim_buf_get_name(0), false)<CR>",
			{ desc = "MiniFiles directory of current file" },
		},
		{
			"<leader>E",
			"<CMD>lua MiniFiles.open(nil, false)<CR>",
			{ desc = "MiniFiles current working directory" },
		},
		{
			"<leader>wz",
			"<CMD>lua MiniMisc.zoom()<CR>",
			{ desc = "Zoom" },
		},
	},
}
