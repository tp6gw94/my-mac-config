local palette = {
    base00 = "#F8F8F8", 
    base01 = "#EFEFEF", 
    base02 = "#D8D8D8", 
    base03 = "#A0A0A0", 
    base04 = "#444444",
    base05 = "#000000",
    base06 = "#181818",
    base07 = "#282828",

    base08 = "#CC0000", 
    base09 = "#B58900", 
    base0A = "#C0A300", 
    base0B = "#008800", 
    base0C = "#009999", 
    base0D = "#0066CC",
    base0E = "#9933CC",
    base0F = "#888800",
}

require("mini.base16").setup({
	palette = palette,
	use_cterm = true,
	plugins = { default = true },
})

vim.g.colors_name = "base16"

vim.cmd([[highlight Visual guibg=#92c3f7 guifg=#000000]])

vim.api.nvim_set_hl(0, "CursorLine", {
	bg = "#d6d6d6",
	fg = "NONE",

	ctermbg = "darkgrey",
	ctermfg = "NONE",
})

vim.api.nvim_set_hl(0, "Cursor", {
	bg = "#92c3f7",
	fg = "#000000",
})
