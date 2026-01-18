local utils = require("core.utils")
local nmap_leader = utils.nmap_leader

local prettier = { "prettierd", "prettier", stop_after_first = true }
require("conform").setup({
	formatters = {
		biome = {
			require_cwd = true,
		},
	},
	formatters_by_ft = {
		lua = { "stylua" },
		markdown = prettier,
		javascript = { "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", stop_after_first = true },
		typescript = { "biome", "prettierd", "prettier", stop_after_first = true, lsp_format = "fallback" },
		typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
		vue = prettier,
		json = { "biome", "prettierd", "prettier", stop_after_first = true },
		jsonc = { "biome", "prettierd", "prettier", stop_after_first = true },
		python = { "black", "isort" },
		go = { "goimports", "gofumpt" },
	},
})

require("lint").linters_by_ft = {
	go = { "golangcilint" },
}

nmap_leader("cf", function()
	require("conform").format()
end, "Format")

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	callback = function()
		require("lint").try_lint()
		require("lint").try_lint("codespell")
	end,
})
