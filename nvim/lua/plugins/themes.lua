return {
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		config = function()
			require("kanagawa").setup({
				theme = "lotus",
				transparent = false,
				overrides = function(colors)
					local palette = colors.palette

					return {
						LineNr = {
							bg = palette.lotusWhite3,
						},
						DiagnosticSignError = { bg = palette.lotusWhite3 },
						DiagnosticSignWarn = { bg = palette.lotusWhite3 },
						DiagnosticSignInfo = { bg = palette.lotusWhite3 },
						DiagnosticSignHint = { bg = palette.lotusWhite3 },
						-- popup menu
						Pmenu = {
							bg = "NONE",
						},
						PmenuSel = {
							fg = palette.fujiWhite,
							bg = palette.waveBlue1,
						},
						BlinkCmpMenuBorder = {
							bg = "NONE",
						},
						-- Hipattern
						MiniHipatternsFixme = {
							bg = palette.peachRed,
							bold = true,
						},
						MiniHipatternsHack = {
							bg = palette.surimiOrange,
							bold = true,
						},
						MiniHipatternsTodo = {
							bg = palette.crystalBlue,
							bold = true,
						},
						MiniHipatternsWarning = {
							bg = palette.waveRed,
              fg = palette.lotusWhite3,
							bold = true,
						},
						MiniHipatternsNote = {
							bg = palette.waveAqua2,
							bold = false,
							italic = true,
						},
					}
				end,
			})
			vim.cmd("colorscheme kanagawa")
		end,
	},
}
