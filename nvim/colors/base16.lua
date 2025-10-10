local palette = {
	base00 = "#F5F0E8",
	base01 = "#E8DFD0",
	base02 = "#D4C4B0",
	base03 = "#8B7A68",
	base04 = "#5C4F42",
	base05 = "#2B2520",
	base06 = "#3D3328",
	base07 = "#1A1612",
	base08 = "#B5432E",
	base09 = "#C76030",
	base0A = "#A67C52",
	base0B = "#5C7A3A",
	base0C = "#3A6B60",
	base0D = "#4A6A7A",
	base0E = "#9A4A5F",
	base0F = "#8B6442",
}

require("mini.base16").setup({
	palette = palette,
	use_cterm = true,
	plugins = { default = true },
})

vim.g.colors_name = "base16"

vim.cmd([[highlight Visual guibg=#A67C52 guifg=#F5F0E8]])

vim.api.nvim_set_hl(0, "CursorLine", {
	bg = "#E8DFD0",
	fg = "NONE",

	ctermbg = "darkgrey",
	ctermfg = "NONE",
})

vim.api.nvim_set_hl(0, "Cursor", {
	bg = "#6B4423",
	fg = "#F5F0E8",
})
