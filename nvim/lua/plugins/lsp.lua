require("lazydev").setup({
	library = {
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		{ path = "snacks.nvim", words = { "Snacks" } },
	},
})

require("mason").setup()

local tsserver_filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }
local vue_language_server_path = vim.fn.stdpath("data")
	.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
local vue_plugin = {
	name = "@vue/typescript-plugin",
	location = vue_language_server_path,
	languages = { "vue" },
	configNamespace = "typescript",
}
local vtsls_config = {
	settings = {
		vtsls = {
			tsserver = {
				globalPlugins = {
					vue_plugin,
				},
			},
		},
	},
	filetypes = tsserver_filetypes,
}
local vue_ls_config = {}
vim.lsp.config("vtsls", vtsls_config)
vim.lsp.config("vue_ls", vue_ls_config)

local cucumber_ls_config = {
	settings = {
		cucumber = {
			featurePath = { "features", "src/e2e/**/*.feature" },
			gluePath = { "src/e2e/**/*.step.ts" },
		},
	},
}
vim.lsp.config("cucumber_language_server", cucumber_ls_config)

vim.lsp.enable({
	"bashls",
	"lua_ls",
	"pyright",
	"vtsls",
	"vue_ls",
	"eslint",
	"tailwindcss",
	"cssls",
	"biome",
	"jsonls",
	"harper_ls",
	"cucumber_language_server",
	"markdown_oxide",
	"cspell_ls",
	"gopls",
	"cssmodules_ls",
})

require("nvim-ts-autotag").setup()
require("ts-error-translator").setup()

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local buffer = ev.buf

		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action", buffer = buffer })
		vim.keymap.set("n", "<leader>cA", function()
			vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
		end, { desc = "Code Action(source)", buffer = buffer })
		vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics", buffer = buffer })
		vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename", buffer = buffer })
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover", buffer = buffer })
		vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, { desc = "Signature Help", buffer = buffer })
		vim.keymap.set("n", "<leader>br", vim.lsp.buf.references, { desc = "Buffer reference", buffer = buffer })
	end,
})
