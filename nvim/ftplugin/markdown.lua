vim.opt.wrap = true

local lang_aliases = {
	ts = "typescript",
	js = "javascript",
	tsx = "typescriptreact",
	jsx = "javascriptreact",
	py = "python",
	sh = "bash",
}

local extension_map = {}
for k, v in pairs(lang_aliases) do
	extension_map[v] = k
end

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

-- Returns nil for unsupported modes (blockwise, non-visual).
-- range = { srow, scol, erow, ecol, lines } -- 0-indexed, ecol exclusive (nvim_buf_set_text convention)
local function md_get_selection()
	local mode = vim.fn.mode()
	if mode ~= "v" and mode ~= "V" then
		return nil
	end

	local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
	local sp, ep = a, b
	if a[2] > b[2] or (a[2] == b[2] and a[3] > b[3]) then
		sp, ep = b, a
	end

	local lines = vim.fn.getregion(a, b, { type = mode })
	local srow = sp[2] - 1
	local erow = ep[2] - 1
	local scol = (mode == "V") and 0 or (sp[3] - 1)
	local ecol = (#lines == 1) and (scol + #lines[1]) or #lines[#lines]

	return { srow = srow, scol = scol, erow = erow, ecol = ecol, lines = lines }
end

local function md_replace_range(range, lines)
	vim.api.nvim_buf_set_text(0, range.srow, range.scol, range.erow, range.ecol, lines)
end

-- Leaves Visual mode immediately (flushes typeahead) so later code runs in Normal mode.
local function md_exit_visual()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
end

-- "  foo  " -> "  ", "foo", "  "
local function md_trim(text)
	return text:match("^(%s*)(.-)(%s*)$")
end

-- Pure string op. Returns new_text, did_unwrap. Returns nil when there is nothing to wrap.
local function md_toggle_marker(text, marker, alts)
	local lead, core, trail = md_trim(text)
	if core == "" then
		return nil
	end

	local candidates = { marker }
	for _, m in ipairs(alts or {}) do
		table.insert(candidates, m)
	end

	-- Italic guard: `<leader>mi` on `**bold**` must wrap to `_**bold**_`, not degrade it to `*bold*`.
	local doubled = false
	if #marker == 1 and (marker == "_" or marker == "*") then
		for _, d in ipairs({ "**", "__" }) do
			if core:sub(1, 2) == d and core:sub(-2) == d then
				doubled = true
			end
		end
	end

	if not doubled then
		for _, m in ipairs(candidates) do
			if #core > 2 * #m and core:sub(1, #m) == m and core:sub(-#m) == m then
				return lead .. core:sub(#m + 1, -#m - 1) .. trail, true
			end
		end
	end

	return lead .. marker .. core .. marker .. trail, false
end

-- Visual-mode entry point for every emphasis command.
local function md_format_visual(marker, alts)
	local range = md_get_selection()
	if not range then
		vim.notify("Markdown: only charwise and linewise selections are supported", vim.log.levels.WARN)
		md_exit_visual()
		return
	end

	md_exit_visual()

	local lines = range.lines
	if #lines == 1 then
		local new = md_toggle_marker(lines[1], marker, alts)
		if new == nil then
			vim.notify("Markdown: selection is empty", vim.log.levels.WARN)
			return
		end
		md_replace_range(range, { new })
	else
		local first_lead, first_core = lines[1]:match("^(%s*)(.-)$")
		local last_core, last_trail = lines[#lines]:match("^(.-)(%s*)$")

		local wrapped = #first_core >= #marker
			and first_core:sub(1, #marker) == marker
			and #last_core >= #marker
			and last_core:sub(-#marker) == marker

		if wrapped then
			lines[1] = first_lead .. first_core:sub(#marker + 1)
			lines[#lines] = last_core:sub(1, -#marker - 1) .. last_trail
		else
			lines[1] = first_lead .. marker .. first_core
			lines[#lines] = last_core .. marker .. last_trail
		end
		md_replace_range(range, lines)
	end

	local line = vim.api.nvim_buf_get_lines(0, range.srow, range.srow + 1, false)[1] or ""
	vim.api.nvim_win_set_cursor(0, { range.srow + 1, math.min(range.scol, #line) })
end

-- Byte range of the keyword run under the cursor, or nil.
-- Returns row (0-indexed), scol, ecol (0-indexed bytes, ecol exclusive).
local function md_cword_range()
	local pos = vim.api.nvim_win_get_cursor(0) -- { 1-indexed row, 0-indexed BYTE col }
	local row, cur = pos[1] - 1, pos[2]
	local line = vim.api.nvim_get_current_line()
	local init = 0
	while init <= #line do
		local m = vim.fn.matchstrpos(line, "\\k\\+", init)
		local scol, ecol = m[2], m[3]
		if scol < 0 then
			return nil
		end
		if cur < ecol then
			if cur >= scol then
				return row, scol, ecol
			end
			return nil -- cursor sits on whitespace/punctuation before the next run
		end
		init = ecol
	end
	return nil
end

-- Normal-mode entry point for every emphasis command.
local function md_format_normal(marker, alts)
	local row, scol, ecol = md_cword_range()
	if row then
		local word = vim.api.nvim_buf_get_text(0, row, scol, row, ecol, {})[1]
		local new = md_toggle_marker(word, marker, alts)
		if new == nil then
			return
		end
		vim.api.nvim_buf_set_text(0, row, scol, row, ecol, { new })
		vim.api.nvim_win_set_cursor(0, { row + 1, scol })
		return
	end

	-- Byte offset the pair will be inserted at: just past the character under the
	-- cursor (nvim_put with after = true), or 0 on an empty line.
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local at = #line
	if line ~= "" then
		local next_char = vim.fn.byteidx(line, vim.fn.charidx(line, col) + 1)
		at = (next_char < 0) and #line or next_char
	end

	vim.api.nvim_put({ marker .. marker }, "c", true, true)
	vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], at + #marker })
	vim.cmd("startinsert")
end

-- true if s should be treated as a URL/link target rather than display text.
local function md_looks_like_url(s)
	s = vim.trim(s or "")
	if s == "" or s:find("%s") then
		return false
	end
	if s:match("^%a[%w+.%-]*://") then
		return true
	end
	if s:match("^mailto:") then
		return true
	end
	if s:match("^www%.[%w%-]+%.%a") then
		return true
	end
	if s:match("^%.?%.?/") then
		return true
	end
	if s:match("^[%w%-%.]+%.%a%a+$") then
		return true
	end
	return false
end

-- Returns clipboard contents if md_looks_like_url() says it is a URL, else "".
local function md_clipboard_url()
	local clip = vim.trim(vim.fn.getreg("+") or "")
	if md_looks_like_url(clip) then
		return clip
	end
	return ""
end

local function md_link_normal()
	vim.ui.input({ prompt = "Link text: " }, function(text)
		if text == nil then
			return
		end
		vim.ui.input({ prompt = "URL: ", default = md_clipboard_url() }, function(url)
			if url == nil then
				return
			end
			if text == "" and url == "" then
				return
			end
			if text == "" then
				text = url
			end
			vim.api.nvim_put({ ("[%s](%s)"):format(text, url) }, "c", true, true)
			if url == "" then
				vim.cmd("startinsert")
			end
		end)
	end)
end

local function md_link_visual()
	local range = md_get_selection()
	if not range then
		vim.notify("Markdown: only charwise and linewise selections are supported", vim.log.levels.WARN)
		md_exit_visual()
		return
	end

	md_exit_visual()

	if #range.lines > 1 then
		vim.notify("Markdown: link needs a single-line selection", vim.log.levels.WARN)
		return
	end

	local lead, core, trail = md_trim(range.lines[1])
	if core == "" then
		vim.notify("Markdown: selection is empty", vim.log.levels.WARN)
		return
	end

	local function insert_link(text, url)
		md_replace_range(range, { lead .. ("[%s](%s)"):format(text, url) .. trail })
		if url == "" then
			vim.api.nvim_win_set_cursor(0, { range.srow + 1, range.scol + #lead + 1 + #text + 2 })
			vim.cmd("startinsert")
		else
			vim.api.nvim_win_set_cursor(0, { range.srow + 1, range.scol + #lead })
		end
	end

	if md_looks_like_url(core) then
		vim.ui.input({ prompt = "Link text: " }, function(text)
			if text == nil then
				return
			end
			if text == "" then
				text = core
			end
			insert_link(text, core)
		end)
	else
		vim.ui.input({ prompt = "URL: ", default = md_clipboard_url() }, function(url)
			if url == nil then
				return
			end
			insert_link(core, url)
		end)
	end
end

vim.keymap.set("n", "<leader>mb", function()
	md_format_normal("**", { "__" })
end, { buffer = 0, desc = "Markdown: Toggle bold" })
vim.keymap.set("x", "<leader>mb", function()
	md_format_visual("**", { "__" })
end, { buffer = 0, desc = "Markdown: Toggle bold" })

vim.keymap.set("n", "<leader>mi", function()
	md_format_normal("_", { "*" })
end, { buffer = 0, desc = "Markdown: Toggle italic" })
vim.keymap.set("x", "<leader>mi", function()
	md_format_visual("_", { "*" })
end, { buffer = 0, desc = "Markdown: Toggle italic" })

vim.keymap.set("n", "<leader>ms", function()
	md_format_normal("~~")
end, { buffer = 0, desc = "Markdown: Toggle strikethrough" })
vim.keymap.set("x", "<leader>ms", function()
	md_format_visual("~~")
end, { buffer = 0, desc = "Markdown: Toggle strikethrough" })

vim.keymap.set("n", "<leader>m`", function()
	md_format_normal("`")
end, { buffer = 0, desc = "Markdown: Toggle inline code" })
vim.keymap.set("x", "<leader>m`", function()
	md_format_visual("`")
end, { buffer = 0, desc = "Markdown: Toggle inline code" })

vim.keymap.set("n", "<leader>ml", md_link_normal, { buffer = 0, desc = "Markdown: Insert link" })
vim.keymap.set("x", "<leader>ml", md_link_visual, { buffer = 0, desc = "Markdown: Insert link" })

vim.keymap.set("i", "<C-k>", function()
	local ok, result = pcall(vim.fn.systemlist, { "presenterm", "--list-comment-commands" })
	if not ok then
		return
	end

	vim.ui.select(result, {}, function(choice)
		if choice then
			vim.api.nvim_put({ choice }, "c", false, true)
		end
	end)
end, { desc = "presenterm comment" })
