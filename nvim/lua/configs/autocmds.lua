vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesActionRename",
	callback = function(event)
		Snacks.rename.on_rename_file(event.data.from, event.data.to)
	end,
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
		vim.keymap.set("n", "H", "<Left>", { buffer = buf_id })
		vim.keymap.set("n", "L", "<Right>", { buffer = buf_id })
	end,
})

-- auto delete buffer when delete file from mini.file
vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesActionDelete",
	callback = function(event)
		local file_path = event.data.from
		local bufnr = vim.fn.bufnr(file_path)
		if bufnr ~= -1 and vim.fn.buflisted(bufnr) == 1 then
      Snacks.bufdelete.delete({buf = bufnr})
		end
	end,
})

-- Close quickfix and help with 'q'
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "qf", "help" },
	callback = function()
		vim.keymap.set("n", "q", "<CMD>bd<CR>", { silent = true, buffer = true })
	end,
})

-- Replace quickfix with Trouble
vim.api.nvim_create_autocmd("BufRead", {
	callback = function(ev)
		if vim.bo[ev.buf].buftype == "quickfix" then
			vim.schedule(function()
				vim.cmd([[cclose]])
				vim.cmd([[Trouble qflist open]])
			end)
		end
	end,
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
	callback = function()
		vim.cmd([[Trouble qflist open]])
	end,
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	callback = function()
		require("lint").try_lint()
		require("lint").try_lint("codespell")
	end,
})

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		vim.notify("PackChanged " .. name .. " " .. kind)
	end,
})

vim.api.nvim_create_autocmd("PackChangedPre", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		vim.notify("PackChangedPre " .. name .. " " .. kind)
	end,
})
