require("github-theme").setup({
	groups = {
		all = {
			Cursor = { bg = "#FE7430" },
		},
	},
	options = {
		dim_inactive = true,
	},
})
vim.cmd("colorscheme github_light_colorblind")

require("rose-pine").setup()
-- vim.cmd("colorscheme rose-pine-dawn")

-- vim.g.gruvbox_material_background = 'hard'
-- vim.g.gruvbox_material_enable_italic = true
-- vim.cmd.colorscheme("gruvbox-material")

-- vim.cmd("colorscheme dayfox")

require("kanagawa").setup({
	theme = "lotus",
	transparent = false,
	colors = {
		palette = {
			fujiWhite = "#FFFBEB",
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
				bold = true,
			},
			RenderMarkdownCode = { bg = "#F2E9DE" },
			RenderMarkdownCodeBorder = { bg = "#F2E9DE" },
		}
	end,
})
-- vim.cmd("colorscheme kanagawa")
