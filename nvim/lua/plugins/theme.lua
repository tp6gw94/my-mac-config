require("kanagawa").setup({
	theme = "lotus",
	transparent = false,
	colors = {
		palette = {
			fujiWhite = "#faf5d7",
		},
	},
	overrides = function(colors)
		local palette = colors.palette

		return {
			Normal = {
				bg = palette.fujiWhite,
			},
			LineNr = {
				bg = palette.fujiWhite,
			},
			NormalFloat = {
				bg = palette.fujiWhite,
			},
			FloatBorder = {
				bg = "NONE",
			},
			SmartPickPathMatch = { fg = palette.waveRed, bold = true },
			SmartPickBuffer = { fg = palette.waveRed, italic = true },
			DiagnosticSignError = { bg = palette.fujiWhite },
			DiagnosticSignWarn = { bg = palette.fujiWhite },
			DiagnosticSignInfo = { bg = palette.fujiWhite },
			DiagnosticSignHint = { bg = palette.fujiWhite },
			-- popup menu
			Pmenu = {
				bg = "NONE",
			},
			PmenuSel = {
				-- fg = palette.fujiWhite,
				bg = palette.lotusWhite3,
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

			FlashLabel = {
				fg = palette.surimiOrange,
        bold = true
			},
		}
	end,
})

vim.cmd("colorscheme kanagawa")
