local utils = require("core.utils")
local nmap_leader = utils.nmap_leader

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


-- Trouble
nmap_leader("xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Diagnostics Buffer (Trouble)")
nmap_leader("xX", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics (Trouble)")
nmap_leader("xl", "<cmd>Trouble lsp<cr>", "Trouble Lsp")
vim.keymap.set("n", "[t", function()
	require("trouble").prev()
end, { desc = "Trouble Prev" })
vim.keymap.set("n", "]t", function()
	require("trouble").next()
end, { desc = "Trouble Next" })

-- Ufo
vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })

vim.api.nvim_create_autocmd("BufRead", {
	callback = function(ev)
		if vim.bo[ev.buf].buftype == "quickfix" then
			vim.schedule(function()
				vim.cmd([[cclose]])
				vim.cmd([[Trouble qflist open]])
			end)
		end
	end,
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
	callback = function()
		vim.cmd([[Trouble qflist open]])
	end,
})
