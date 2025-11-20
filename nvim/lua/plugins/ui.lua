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
			keys = {
				["<Tab>"] = "toggle_preview",
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
