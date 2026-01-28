vim.opt.wrap = true
if require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
	local function map(...)
		vim.api.nvim_buf_set_keymap(0, ...)
	end
	local opts = { noremap = true, silent = false }

	map("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
	map("n", "<leader>nl", "<Cmd>ZkLinks<CR>", opts)
end

local lang_aliases = {
	ts = "typescript",
	js = "javascript",
	tsx = "typescriptreact",
	jsx = "javascriptreact",
	py = "python",
	sh = "bash",
}

local function create_codeblock_popup(lang, initial_lines, start_row, end_row)
	lang = lang_aliases[lang] or lang or "text"

	local original_buf = vim.api.nvim_get_current_buf()
	local original_win = vim.api.nvim_get_current_win()
	local cursor_pos = vim.api.nvim_win_get_cursor(original_win)

	local is_edit_mode = initial_lines ~= nil
	local edit_start_row = start_row
	local edit_end_row = end_row

	local popup_buf = vim.api.nvim_create_buf(true, false)
	vim.bo[popup_buf].bufhidden = "hide"
	vim.bo[popup_buf].swapfile = false

	local extension_map = {
		typescript = "ts",
		javascript = "js",
		typescriptreact = "tsx",
		javascriptreact = "jsx",
		python = "py",
		bash = "sh",
	}
	local ext = extension_map[lang] or lang
	local temp_name = string.format("codeblock_%s.%s", os.time(), ext)
	vim.api.nvim_buf_set_name(popup_buf, temp_name)

	vim.bo[popup_buf].filetype = lang

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = string.format(" Code Block (%s) ", lang),
		title_pos = "center",
	}

	local popup_win = vim.api.nvim_open_win(popup_buf, true, opts)
	vim.wo[popup_win].winblend = 0
	vim.wo[popup_win].cursorline = true

	if initial_lines then
		vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, initial_lines)
	end

	vim.schedule(function()
		vim.api.nvim_exec_autocmds("FileType", {
			buffer = popup_buf,
		})
		vim.api.nvim_exec_autocmds("BufReadPost", {
			buffer = popup_buf,
		})
		vim.api.nvim_exec_autocmds("BufWinEnter", {
			buffer = popup_buf,
		})
	end)

	local function save_and_close()
		local lines = vim.api.nvim_buf_get_lines(popup_buf, 0, -1, false)

		while #lines > 0 and lines[#lines]:match("^%s*$") do
			table.remove(lines)
		end

		if is_edit_mode then
			local codeblock = {}
			for _, line in ipairs(lines) do
				table.insert(codeblock, line)
			end
			vim.api.nvim_buf_set_lines(original_buf, edit_start_row, edit_end_row, false, codeblock)
		else
			local codeblock = { "```" .. lang }
			for _, line in ipairs(lines) do
				table.insert(codeblock, line)
			end
			table.insert(codeblock, "```")
			table.insert(codeblock, "")

			vim.api.nvim_buf_set_lines(original_buf, cursor_pos[1], cursor_pos[1], false, codeblock)
		end

		vim.api.nvim_buf_delete(popup_buf, { force = true })
	end

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = popup_buf,
		callback = function()
			save_and_close()
		end,
	})

	vim.keymap.set("n", "<leader>w", function()
		save_and_close()
	end, { buffer = popup_buf, noremap = true, desc = "Save and close" })

	vim.keymap.set("n", "<leader>q", function()
		vim.api.nvim_buf_delete(popup_buf, { force = true })
	end, { buffer = popup_buf, noremap = true, desc = "Cancel without inserting" })
end

local function find_codeblock_at_cursor()
	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local start_row, end_row, lang

	for i = cursor_row, 1, -1 do
		local line = lines[i]
		if line:match("^```") then
			start_row = i
			lang = line:match("^```(%S+)")
			break
		end
	end

	if not start_row then
		return nil
	end

	for i = cursor_row, #lines do
		local line = lines[i]
		if i > start_row and line:match("^```%s*$") then
			end_row = i
			break
		end
	end

	if not end_row then
		return nil
	end

	local content = {}
	for i = start_row + 1, end_row - 1 do
		table.insert(content, lines[i])
	end

	return {
		lang = lang or "text",
		content = content,
		start_row = start_row,
		end_row = end_row - 1,
	}
end

vim.api.nvim_buf_create_user_command(0, "CodeBlock", function(opts)
	local codeblock = find_codeblock_at_cursor()

	if codeblock then
		create_codeblock_popup(codeblock.lang, codeblock.content, codeblock.start_row, codeblock.end_row)
	else
		local lang = opts.args ~= "" and opts.args or nil
		if not lang then
			vim.ui.input({ prompt = "Language: ", default = "ts" }, function(input)
				if input then
					create_codeblock_popup(input)
				end
			end)
		else
			create_codeblock_popup(lang)
		end
	end
end, {
	nargs = "?",
	desc = "Create or edit code block with LSP support",
})

vim.keymap.set("n", "<leader>mc", "<cmd>CodeBlock<cr>", { buffer = 0, desc = "Markdown: Create/Edit code block" })
