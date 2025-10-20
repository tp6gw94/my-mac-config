-- Formatting and linting
return {
	{
		"stevearc/conform.nvim",
		opts = {},
		config = function()
			local prettier = { "prettierd", "prettier", sto_after_first = true }
			local conform = require("conform")
			conform.setup({
				formatters = {
					biome = {
						require_cwd = true,
					},
				},
				formatters_by_ft = {
					lua = { "stylua" },
					markdown = prettier,
					javascript = { "prettierd", "prettier", sto_after_first = true },
					javascriptreact = { "prettierd", "prettier", sto_after_first = true },
					typescript = { "biome", "prettierd", "prettier", sto_after_first = true, lsp_format = "fallback" },
					typescriptreact = { "biome", "prettierd", "prettier", sto_after_first = true },
					vue = prettier,
					json = { "biome", "prettierd", "prettier", sto_after_first = true },
					jsonc = { "biome", "prettierd", "prettier", sto_after_first = true },
					python = { "black", "isort" },
				},
			})
			vim.keymap.set("n", "<leader>cf", function(args)
				conform.format()
			end)
		end,
	},
	{
		"mfussenegger/nvim-lint",
		config = function()
			require("lint").linters_by_ft = {}

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
					require("lint").try_lint("codespell")
				end,
			})
		end,
	},
}
