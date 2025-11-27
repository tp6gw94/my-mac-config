-- UI plugins
return {
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}
			local language_servers = vim.lsp.get_clients()
			for _, ls in ipairs(language_servers) do
				require("lspconfig")[ls].setup({
					capabilities = capabilities,
				})
			end
			require("ufo").setup()
		end,
		cond = function()
			return vim.bo.filetype ~= "markdown"
		end,
	},
	{
		"folke/trouble.nvim",
		opts = {
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
		},
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{ "gl", "<cmd>Trouble lsp<cr>", desc = "Lsp (Trouble)" },
			{
				"<M-]>",
				function()
					require("trouble").next({ skip_groups = true })
				end,
				desc = "Next Trouble Item",
			},
			{
				"<M-[>",
				function()
					require("trouble").prev({ skip_groups = true })
				end,
				desc = "Previous Trouble Item",
			},
		},
	},
	{
		"shortcuts/no-neck-pain.nvim",
		version = "*",
		config = function()
			require("no-neck-pain").setup()
			local utils = require("config.utils")
			utils.nmap_leader("wn", "<CMD>NoNeckPain<CR>", "NoNeckPain")
		end,
	},
}
