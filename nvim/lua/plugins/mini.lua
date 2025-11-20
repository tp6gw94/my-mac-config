-- Mini.nvim plugins suite
return {
	"echasnovski/mini.nvim",
	version = "*",
	dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", "folke/trouble.nvim" },
	lazy = false,
	config = function()
		vim.cmd.colorscheme("my-theme")

		require("mini.starter").setup()

		local hipatterns = require("mini.hipatterns")
		hipatterns.setup({
			highlighters = {
				fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
				hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
				todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
				warning = { pattern = "%f[%w]()WARNING()%f[%W]", group = "MiniHipatternsTodo" },
				note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
				hex_color = hipatterns.gen_highlighter.hex_color(),
			},
		})

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
				{ mode = "v", keys = "<leader>" },
			},
			clues = {
				{ mode = "n", keys = "<leader>b", desc = "Buffer" },
				{ mode = "n", keys = "<leader>c", desc = "Code" },
				{ mode = "n", keys = "<leader>f", desc = "Pick" },
				{ mode = "n", keys = "<leader>g", desc = "Git" },
				{ mode = "n", keys = "<leader>n", desc = "Note" },
				{ mode = "n", keys = "<leader>o", desc = "Obsidian" },
				{ mode = "n", keys = "<leader>s", desc = "Search/Jump" },
				{ mode = "n", keys = "<leader>w", desc = "Window" },
				{ mode = "n", keys = "<leader>x", desc = "Trouble" },
				{ mode = "v", keys = "<leader>c", desc = "Code" },
				{ mode = "v", keys = "<leader>n", desc = "Note" },

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

		require("mini.visits").setup()

		local map_vis = function(keys, call, desc)
			local rhs = "<Cmd>lua MiniVisits." .. call .. "<CR>"
			vim.keymap.set("n", "<Leader>" .. keys, rhs, { desc = desc })
		end

		map_vis("a", 'add_label("pin")', "Pin file")
		map_vis("A", 'remove_label("pin")', "Unpin file")

		vim.keymap.set("n", "<Leader><Space>", function()
			MiniExtra.pickers.visit_paths({
				filter = "pin",
				cwd = vim.fn.getcwd(),
			}, {
				mappings = {
					unpin = {
						char = "<C-d>",
						func = function()
							local picker = MiniPick.get_picker_matches()
							local current = picker and picker.current
							if current then
								MiniVisits.remove_label("pin", current, vim.fn.getcwd())
								-- Refresh picker
								local items = MiniVisits.list_paths(vim.fn.getcwd(), { filter = "pin" })
								MiniPick.set_picker_items(items)
							end
						end,
					},
					clear = {
						char = "<C-x>",
						func = function()
							MiniVisits.remove_label("pin", "", vim.fn.getcwd())

							local items = MiniVisits.list_paths(vim.fn.getcwd(), { filter = "pin" })
							MiniPick.set_picker_items(items)
						end,
					},
				},
			})
		end, { desc = "Pick pinned" })

		local sort_latest = MiniVisits.gen_sort.default({ recency_weight = 1 })
		local iterate_pin = function(direction)
			return function()
				MiniVisits.iterate_paths(direction, vim.fn.getcwd(), {
					filter = "pin",
					sort = sort_latest,
					wrap = true,
				})
			end
		end

		vim.keymap.set("n", "[p", iterate_pin("forward"), { desc = "Prev pinned" })
		vim.keymap.set("n", "]p", iterate_pin("backward"), { desc = "Next pinned" })

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
