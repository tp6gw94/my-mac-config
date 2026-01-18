-- Close quickfix and help with 'q'
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "qf", "help" },
	callback = function()
		vim.keymap.set("n", "q", "<CMD>bd<CR>", { silent = true, buffer = true })
	end,
})

if vim.g.pack_debug then
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
end
