-- User commands configuration

-- Copy relative path
vim.api.nvim_create_user_command("CopyRelPath", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify("Copied: " .. path)
end, {})

-- Copy absolute path
vim.api.nvim_create_user_command("CopyAbsPath", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify("Copied: " .. path)
end, {})