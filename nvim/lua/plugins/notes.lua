return {
	{
		"zk-org/zk-nvim",
		config = function()
			local zk = require("zk")
			local zk_api = require("zk.api")
			local utils = require("config.utils")
			local MiniPick = require("mini.pick")

			zk.setup({
				picker = "minipick",
			})

			local notebook_path = vim.env.ZK_NOTEBOOK_DIR
			local expanded_path = vim.fn.expand(notebook_path)
			local groups = {
				{ text = "📝 notes", value = "notes" },
				{ text = "🔧 tools", value = "tools" },
				{ text = "📅 daily", value = "daily" },
				{ text = "🔒 private", value = "private" },
				{ text = "💼 work", value = "work" },
			}

			local create_note = function(default_title, default_content)
				MiniPick.start({
					source = {
						items = groups,
						name = "Select Group",

						choose = function(item)
							local title = ""
							if item.value ~= "daily" then
								title = vim.fn.input("Title: ", default_title)
							end

							zk.new({
								-- 控制字符 (ASCII 0-31), < > : " / \ | ? *
								title = title:gsub('[<>:"/\\|?*]', "-"):gsub("[%c]", ""),
								group = item.value,
								dir = item.value,
								content = default_content,
							})
						end,
					},
				})
			end

			utils.vmap_leader("nnt", function()
				local start_pos = vim.fn.getpos("v")
				local end_pos = vim.fn.getpos(".")

				local lines = vim.fn.getregion(start_pos, end_pos)
				local text = table.concat(lines, " "):gsub("^%s+", ""):gsub("%s+$", "")
				create_note(text)
			end, "Create note selection as note title")
			utils.vmap_leader("nnc", function()
				local start_pos = vim.fn.getpos("v")
				local end_pos = vim.fn.getpos(".")

				local lines = vim.fn.getregion(start_pos, end_pos)
				local text = table.concat(lines, "\n")
				create_note("", text)
			end, "Create note selection as note content")
			utils.vmap_leader("nm", ":'<,'>ZkMatch<CR>", "Note Match")

			utils.nmap_leader("nn", function()
				create_note("")
			end, "New Note")
			utils.nmap_leader("nt", "<CMD>ZkTags<CR>", "Pick tag")
			utils.nmap_leader("ns", function()
				-- Track the current querytick for this picker instance
				local current_querytick = MiniPick.get_querytick()
				local current_query = ""

				-- Custom match function for live search
				local match_zk_live = function(stritems, inds, query)
					local pattern = table.concat(query, "")
					local querytick = MiniPick.get_querytick()
					current_query = pattern

					if querytick ~= current_querytick then
						current_querytick = querytick
					end

					local search_opts = {
						select = { "title", "path", "tags" },
						sort = { "modified" },
					}

					if pattern ~= "" then
						search_opts.match = { pattern }
					end

					-- Set items options with do_match = false to avoid re-triggering match
					local set_items_opts = { do_match = false, querytick = querytick }

					zk_api.list(notebook_path, search_opts, function(err, res)
						-- Check if picker is still active and query hasn't changed
						if not MiniPick.is_picker_active() then
							return
						end

						if MiniPick.get_querytick() ~= querytick then
							return
						end

						if err then
							Snacks.debug(err)
							MiniPick.set_picker_items({}, set_items_opts)
							return
						end

						local items = {}

						if res and #res > 0 then
							items = vim.tbl_map(function(note)
								return {
									path = note.path,
									tags = note.tags or {},
									text = note.title or vim.fn.fnamemodify(note.path, ":t:r"),
								}
							end, res)
						else
							items = {
								{
									text = "✨ Create Note: " .. (pattern ~= "" and pattern or "new note"),
									is_create_action = true,
									create_title = pattern,
								},
							}
						end

						MiniPick.set_picker_items(items, set_items_opts)
					end)
				end

				MiniPick.start({
					source = {
						-- Start with empty items to trigger match function
						items = {},
						name = "ZK Notes Search",
						cwd = expanded_path,

						match = match_zk_live,

						show = function(buf_id, items_to_show, query)
							local lines = vim.tbl_map(function(item)
								if item.is_create_action then
									return item.text
								end

								local tags_str = ""
								if item.tags and #item.tags > 0 then
									tags_str = " [" .. table.concat(item.tags, ", ") .. "]"
								end
								return item.text .. tags_str
							end, items_to_show)

							vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
						end,

						preview = function(buf_id, item)
							if item.is_create_action then
								local help_text = {
									"",
									"  Create a new note",
									"",
									"  Press <CR> to select a group for this note",
									"",
									"  Available groups:",
									"    • notes   - General notes",
									"    • tools   - Tool/software notes",
									"    • daily   - Daily journal entries",
									"    • private - Private notes",
									"    • work    - Work-related notes",
									"",
								}
								vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, help_text)
								vim.bo[buf_id].filetype = "markdown"
								return
							end

							local note_path = vim.fs.joinpath(expanded_path, item.path)

							if vim.fn.filereadable(note_path) == 1 then
								local lines = vim.fn.readfile(note_path)
								vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
								vim.bo[buf_id].filetype = "markdown"
							else
								Snacks.debug("File not readable: " .. note_path)
							end
						end,

						choose = function(item)
							if item.is_create_action then
								create_note(item.create_title)
								return true -- Continue picker to show the group picker
							end

							local note_path = vim.fs.joinpath(expanded_path, item.path)
							vim.schedule(function()
								vim.cmd("edit " .. vim.fn.fnameescape(note_path))
							end)
						end,
					},
				})
			end, "ZK Search Notes")
		end,
	},
}
