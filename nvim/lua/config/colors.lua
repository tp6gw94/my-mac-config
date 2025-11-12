-- Centralized color configuration
local M = {}

-- Theme base colors
M.theme = {
	background = "#F5F0E8",
	foreground = "#884499",
}

-- Semantic colors derived from theme
M.colors = {
	-- Status colors
	add = "#2d8c26",      -- Green for additions
	change = "#ffbb00",   -- Yellow for changes
	delete = "#8c2d26",   -- Red for deletions
	info = "#1d1899",     -- Blue for information

	-- Light backgrounds for overlays
	add_bg = "#d4f0d4",
	change_bg = "#fff5cc",
	change_buf_bg = "#ffe8b3",
	delete_bg = "#f0d4d4",
	context_bg = "#f5ebe8",
	context_buf_bg = "#f9f5ed",

	-- Text colors
	white = "#ffffff",
	gray = "#666666",
}

-- Apply all highlight groups
function M.setup()
	-- MiniHipatterns highlights
	vim.api.nvim_set_hl(0, "MiniHipatternsTodo", {
		bg = M.colors.change,
		fg = M.colors.white,
	})
	vim.api.nvim_set_hl(0, "MiniHipatternsNote", {
		bg = M.colors.info,
		fg = M.colors.white,
	})
	vim.api.nvim_set_hl(0, "MiniHipatternsFixme", {
		bg = M.colors.delete,
		fg = M.colors.white,
	})

	-- MiniDiff sign highlights
	vim.api.nvim_set_hl(0, "MiniDiffSignAdd", {
		fg = M.colors.add,
		bold = true,
	})
	vim.api.nvim_set_hl(0, "MiniDiffSignChange", {
		fg = M.colors.change,
		bold = true,
	})
	vim.api.nvim_set_hl(0, "MiniDiffSignDelete", {
		fg = M.colors.delete,
		bold = true,
	})

	-- MiniDiff overlay highlights
	vim.api.nvim_set_hl(0, "MiniDiffOverAdd", {
		bg = M.colors.add_bg,
    bold = true
	})
	vim.api.nvim_set_hl(0, "MiniDiffOverChange", {
		bg = M.colors.change_bg,
    bold = true
	})
	vim.api.nvim_set_hl(0, "MiniDiffOverChangeBuf", {
		bg = M.colors.change_buf_bg,
    bold = true
	})
	vim.api.nvim_set_hl(0, "MiniDiffOverContext", {
		bg = M.colors.context_bg,
		fg = M.colors.gray,
	})
	vim.api.nvim_set_hl(0, "MiniDiffOverContextBuf", {
		bg = M.colors.context_buf_bg,
		fg = M.colors.gray,
	})
	vim.api.nvim_set_hl(0, "MiniDiffOverDelete", {
		bg = M.colors.delete_bg,
    bold = true
	})

	-- SmartPick highlights
	vim.api.nvim_set_hl(0, "SmartPickPathMatch", {
		fg = M.colors.delete,
		bold = true,
	})
	vim.api.nvim_set_hl(0, "SmartPickBuffer", {
		fg = M.colors.info,
		italic = true,
	})
end

return M
