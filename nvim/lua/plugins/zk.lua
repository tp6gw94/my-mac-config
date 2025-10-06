-- Zk note-taking plugin
return {
	"zk-org/zk-nvim",
	config = function()
		require("zk").setup({
			picker = "minipick",

			lsp = {
				config = {
					name = "zk",
					cmd = { "zk", "lsp" },
					filetypes = { "markdown" },
				},
				auto_attach = {
					enabled = true,
				},
			},
		})

		-- Parse advanced search patterns
		local function parse_search_query(query)
			local pattern = {
				query = "",
				tags = {},
				excluded_tags = {},
				path = nil,
				is_regex = false,
			}

			-- Extract special patterns
			local remaining_words = {}
			for word in query:gmatch("%S+") do
				if word:match("^#") then
					-- Positive tag: #work
					table.insert(pattern.tags, word:sub(2))
				elseif word:match("^%-#") then
					-- Negative tag: -#personal
					table.insert(pattern.excluded_tags, word:sub(3))
				elseif word:match("^@") then
					-- Path restriction: @work/daily
					pattern.path = word:sub(2)
				elseif word:match("^re:") then
					-- Regex mode: re:pattern
					pattern.is_regex = true
					-- Extract everything after "re:"
					pattern.query = query:sub(query:find("re:") + 3)
					break -- Regex consumes rest of query
				else
					-- Regular search text
					table.insert(remaining_words, word)
				end
			end

			if not pattern.is_regex then
				pattern.query = table.concat(remaining_words, " ")
			end

			-- Trim whitespace
			pattern.query = pattern.query:match("^%s*(.-)%s*$") or ""
			return pattern
		end

		-- Custom commands
		local commands = require("zk.commands")

		-- ZkMenu - custom menu for creating notes
		commands.add("ZkMenu", function(opts)
			require("mini.pick").start({
				source = {
					items = { "Index", "Note", "Work Note", "Daily Work Note", "Meeting" },
					name = "ZkMenu",
					choose = function(choice)
						if not choice then
							return
						end

						if choice == "Index" then
							-- Edit index.md directly
							local index_path = vim.fn.expand("$ZK_NOTEBOOK_DIR/index.md")
							if vim.fn.filereadable(index_path) == 0 then
								index_path = vim.fn.getcwd() .. "/index.md"
							end
							vim.cmd("edit " .. index_path)
						elseif choice == "Daily Work Note" then
							-- Check if today's daily note exists
							local today = os.date("%Y-%m-%d")
							local daily_path = "work/daily/" .. today .. ".md"
							local full_path = vim.fn.getcwd() .. "/" .. daily_path

							if vim.fn.filereadable(full_path) == 1 then
								-- File exists, open it
								vim.cmd("edit " .. vim.fn.fnameescape(full_path))
							else
								-- File doesn't exist, create it
								require("zk").new({
									dir = "work/daily",
									edit = true,
								})
							end
						elseif choice == "Note" or choice == "Work Note" or choice == "Meeting" then
							local dir_map = {
								["Note"] = "notes",
								["Work Note"] = "work/notes",
								["Meeting"] = "work/meeting",
							}
							local target_dir = dir_map[choice]

							-- Create new note in specific directory
							vim.ui.input({ prompt = "Note title: " }, function(title)
								if title and title ~= "" then
									require("zk").new({
										title = title,
										dir = target_dir,
										edit = true,
									})
								else
									vim.notify("Title is required for " .. choice)
								end
							end)
						end
					end,
				},
			})
		end)

		-- ZkNewMeeting - quick command for creating meeting notes
		commands.add("ZkNewMeeting", function(opts)
			opts = vim.tbl_extend("force", { dir = "work/meeting" }, opts or {})
			require("zk").new(opts)
		end)

		-- Create note from search
		local function create_note_from_search(query)
			-- Parse query to get default title
			local parsed = parse_search_query(query)
			local default_title = parsed.query

			-- Show creation menu
			require("mini.pick").start({
				source = {
					items = { "Note", "Work Note", "Meeting", "Daily Work Note" },
					name = "Create Note Type",
					choose = function(choice)
						if not choice then return end

						if choice == "Daily Work Note" then
							-- Check if exists, open or create
							local today = os.date("%Y-%m-%d")
							local daily_path = "work/daily/" .. today .. ".md"
							local full_path = vim.fn.getcwd() .. "/" .. daily_path

							if vim.fn.filereadable(full_path) == 1 then
								vim.cmd("edit " .. vim.fn.fnameescape(full_path))
							else
								require("zk").new({ dir = "work/daily", edit = true })
							end
						else
							-- Prompt for title with search query as default
							vim.ui.input(
								{
									prompt = choice .. " title: ",
									default = default_title ~= "" and default_title or nil
								},
								function(title)
									if title and title ~= "" then
										local dir_map = {
											["Note"] = "notes",
											["Work Note"] = "work/notes",
											["Meeting"] = "work/meeting",
										}
										require("zk").new({
											title = title,
											dir = dir_map[choice],
											edit = true,
										})
									else
										vim.notify("Note creation cancelled")
									end
								end
							)
						end
					end,
				},
				window = {
					config = {
						width = 40,
					},
				},
			})
		end

		-- ZkUnified - unified search with creation option
		commands.add("ZkUnified", function(opts)
			vim.ui.input({ prompt = "Search notes (or press Enter for all): " }, function(query)
				if query == nil then return end  -- User cancelled

				local parsed = parse_search_query(query)

				-- Build search options
				local search_opts = {
					sort = { "modified" },
					select = { "title", "absPath", "path" },
				}

				-- Add filters based on parsed pattern
				if parsed.query ~= "" then
					if parsed.is_regex then
						search_opts.match = { parsed.query }
						search_opts.matchStrategy = "re"
					else
						search_opts.match = { parsed.query }
					end
				end

				if #parsed.tags > 0 then
					search_opts.tags = parsed.tags
				end

				if parsed.path then
					search_opts.hrefs = { parsed.path }
				end

				-- Perform search
				require("zk.api").list(nil, search_opts, function(err, notes)
					if err then
						vim.notify("Search error: " .. (err.message or "Unknown error"))
						return
					end

					notes = notes or {}
					local items = {}
					local items_data = {}  -- Store the actual data separately

					-- Add found notes
					for _, note in ipairs(notes) do
						local display_text = note.title or note.path
						table.insert(items, display_text)
						items_data[display_text] = {
							absPath = note.absPath,
							path = note.path,
							is_note = true,
						}
					end

					-- Always add create option at the end
					local create_title = parsed.query ~= "" and parsed.query or "New Note"
					local create_text = "📝 Create Note: " .. create_title
					table.insert(items, create_text)
					items_data[create_text] = {
						is_create_option = true,
						search_query = query,
					}

					-- Show picker with results + create option
					require("mini.pick").start({
						source = {
							items = items,
							name = "Zk Notes",
							choose = function(selected_item)
								if not selected_item then return end

								local data = items_data[selected_item]
								if data.is_create_option then
									create_note_from_search(data.search_query)
								else
									vim.cmd("edit " .. vim.fn.fnameescape(data.absPath))
								end
							end,
						},
					})
				end)
			end)
		end)
	end,
	keys = {
		{
			"<leader>zm",
			"<Cmd>ZkMenu<CR>",
			desc = "Zk Menu (Index/Notes/Work/Meeting)",
		},
		{
			"<leader>zo",
			"<Cmd>ZkUnified<CR>",
			desc = "Zk unified search",
		},
		{
			"<leader>zf",
			":'<,'>ZkMatch<CR>",
			mode = "v",
			desc = "Search notes matching selection",
		},
		{
			"<leader>zi",
			"<Cmd>ZkIndex<CR>",
			desc = "Index zk notebook",
		},
	},
}
