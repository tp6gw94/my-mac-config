require("ufo").setup({
	provider_selector = function(bufnr, filetype, buftype)
		return { "treesitter", "indent" }
	end,
})

require("trouble").setup({
	focus = true,
	auto_preview = true,
	win = {
		size = 16,
	},
	keys = {
		["<Tab>"] = "toggle_preview",
		["}"] = { action = "next", skip_groups = true, desc = "Next item (skip groups)" },
		["{"] = { action = "prev", skip_groups = true, desc = "Prev item (skip groups)" },
	},
	modes = {
		diagnostics = {
			preview = {
				type = "split",
				relative = "win",
				position = "right",
				size = 0.4,
			},
		},
		lsp_base = {
			follow = false,
		},
		lsp = {
			focus = true,
			follow = false,
			preview = {
				type = "split",
				relative = "win",
				position = "right",
				size = 0.5,
			},
		},
	},
})

require("no-neck-pain").setup()
