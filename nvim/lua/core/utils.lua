-- Utility functions for Neovim configuration
local M = {}

-- Helper function to create normal mode leader keymaps
M.nmap_leader = function(suffix, rhs, desc)
	vim.keymap.set("n", "<Leader>" .. suffix, rhs, { desc = desc })
end

M.vmap_leader = function(suffix, rhs, desc)
	vim.keymap.set("v", "<Leader>" .. suffix, rhs, { desc = desc })
end

M.get_visual_selection_lines = function()
	vim.cmd('noau normal! "vy')
	local text = vim.fn.getreg("v")
	vim.fn.setreg("v", {})
	return vim.split(text, "\n", { trimempty = true })
end

return M
