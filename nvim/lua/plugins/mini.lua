-- Mini.nvim plugins suite
return {
	"echasnovski/mini.nvim",
	version = "*",
	dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", "folke/trouble.nvim" },
	lazy = false,
	config = function()
		local colors = require("config.colors")

		require("mini.hues").setup({
			background = colors.theme.background,
			foreground = colors.theme.foreground,
			n_hues = 4,
			saturation = "lowmedium",
		})

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

		colors.setup()

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
		require("mini.jump").setup()
		require("mini.jump2d").setup({
			allowed_windows = { not_current = false },
			mappings = {
				start_jumping = "",
			},
		})

		require("mini.cursorword").setup()
		require("mini.icons").setup()
		require("mini.indentscope").setup()
		require("mini.statusline").setup()
		require("mini.files").setup()
		require("mini.misc").setup()
		local miniclue = require("mini.clue")
		miniclue.setup({
			triggers = {
				{ mode = "n", keys = "<leader>" },
				{ mode = "i", keys = "<C-x>" },
				{ mode = "v", keys = "<leader>"},
			},
			clues = {
				{ mode = "n", keys = "<leader>b", desc = "Buffer" },
				{ mode = "n", keys = "<leader>c", desc = "Code" },
				{ mode = "n", keys = "<leader>f", desc = "Pick" },
				{ mode = "n", keys = "<leader>g", desc = "Git" },
				{ mode = "n", keys = "<leader>o", desc = "Obsidian" },
				{ mode = "n", keys = "<leader>w", desc = "Window" },
				{ mode = "n", keys = "<leader>x", desc = "Trouble" },
				{ mode = "n", keys = "<leader>s", desc = "Search/Jump" },

				miniclue.gen_clues.builtin_completion(),
				miniclue.gen_clues.g(),
				miniclue.gen_clues.marks(),
				miniclue.gen_clues.registers(),
				miniclue.gen_clues.windows(),
				miniclue.gen_clues.z(),
			},
			window = {
				delay = 0,
				config = {
					width = "auto",
					border = "double",
				},
			},
		})

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

		require("mini.pick").setup()
		vim.ui.select = function(items, opts, on_choice)
			local start_opts = { window = { config = { width = vim.o.columns } } }
			return require("mini.pick").ui_select(items, opts, on_choice, start_opts)
		end

		require("mini.extra").setup()

		local smartpick = require("config.smartpick")
		smartpick.setup()

		local utils = require("config.utils")
		utils.nmap_leader("ff", smartpick.picker, "Smart Pick")
		utils.nmap_leader("fl", '<CMD>Pick buf_lines scope="current"<CR>', "Lines(buf)")
		utils.nmap_leader("fL", '<CMD>Pick buf_lines scope="all"<CR>', "Lines(all)")
		utils.nmap_leader("fg", "<CMD>Pick grep_live<CR>", "Grep live")
		utils.nmap_leader("fG", '<CMD>Pick grep pattern="<cword>"<CR>', "Grep word")
		utils.nmap_leader("fh", "<CMD>Pick help<CR>", "Help")
		utils.nmap_leader("f'", "<CMD>Pick resume<CR>", "Resume")
		utils.nmap_leader("e", "<CMD>lua MiniFiles.open(vim.api.nvim_buf_get_name(0), false)<CR>", "Explore(current)")
		utils.nmap_leader("E", "<CMD>lua MiniFiles.open(nil, false)<CR>", "Explore(root)")
		utils.nmap_leader("wz", "<CMD>lua MiniMisc.zoom()<CR>", "Zoom")
    utils.nmap_leader("gd", "<CMD>lua MiniDiff.toggle_overlay()<CR>", "Git Diff")

		vim.keymap.set("n", "gr", '<CMD>Pick lsp scope="references"<CR>', { desc = "References" })
		vim.keymap.set("n", "gd", '<CMD>Pick lsp scope="definition"<CR>', { desc = "Definition" })
		vim.keymap.set("n", "gD", '<CMD>Pick lsp scope="declaration"<CR>', { desc = "Declaration" })
		vim.keymap.set("n", "gt", '<CMD>Pick lsp scope="type_definition"<CR>', { desc = "Type definition" })
		vim.keymap.set("n", "gi", '<CMD>Pick lsp scope="implementation"<CR>', { desc = "Implementation" })

		utils.nmap_leader("sw", "<CMD>lua MiniJump2d.start(MiniJump2d.builtin_opts.word_start)<CR>", "Jump Word")
		utils.nmap_leader("sl", "<CMD>lua MiniJump2d.start(MiniJump2d.builtin_opts.line_start)<CR>", "Jump Word")
	end,
}
