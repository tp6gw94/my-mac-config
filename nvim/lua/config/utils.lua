-- Utility functions for Neovim configuration
local M = {}

-- Helper function to create normal mode leader keymaps
M.nmap_leader = function(suffix, rhs, desc)
	vim.keymap.set("n", "<Leader>" .. suffix, rhs, { desc = desc })
end

return M
