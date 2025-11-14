-- Centralized color configuration
local M = {}

M.theme = {
	background = "#F5F0E8",
	foreground = "#000000",
}

-- Semantic colors derived from theme
M.colors = {
	-- Status colors
	add = "#228B22",
	change = "#DAA520",
	delete = "#DC143C",
	info = "#4169E1",

	-- Light backgrounds for overlays
	add_bg = "#90EE90",
	change_bg = "#FF8C00",
	change_buf_bg = "#87CEEB",
	delete_bg = "#CD5C5C",
	context_bg = "#F5F0E8",
	context_buf_bg = "#F5F0E8",

	-- Text colors
	white = "#ffffff",
	gray = "#727272",
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
	})
	vim.api.nvim_set_hl(0, "MiniDiffOverChange", {
		bg = M.colors.change_bg,
	})
	vim.api.nvim_set_hl(0, "MiniDiffOverChangeBuf", {
		bg = M.colors.change_buf_bg,
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
		bold = true,
	})

	-- SmartPick highlights
	vim.api.nvim_set_hl(0, "SmartPickPathMatch", {
		fg = M.colors.add,
		bold = true,
	})
	vim.api.nvim_set_hl(0, "SmartPickBuffer", {
    fg = M.colors.info,
		italic = true,
	})
end

-- TinyInlineDiagnostic
vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualTextError", { bg = M.colors.delete, italic = true })
vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualTextWarn", { bg = M.colors.change, italic = true })
vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualTextInfo", { bg = M.colors.info, italic = true })
vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualTextHint", { bg = M.colors.add_bg, italic = true })

return M
