-- LSP configuration
return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				{ path = "snacks.nvim", words = { "Snacks" } },
			},
		},
	},
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
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

			vim.lsp.enable({
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
			})
		end,
	},
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,
		opts = {
			preset = "simple",
			options = {
				show_source = {
					enabled = true,
					if_many = true,
				},
				multilines = true,
			},
		},
		config = function(_, opts)
			require("tiny-inline-diagnostic").setup(opts)
			vim.diagnostic.config({ virtual_text = false }) -- Disable default virtual text

			vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualTextError", { fg = "#8c2d26", italic = true })
			vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualTextWarn", { fg = "#ffbb00", italic = true })
			vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualTextInfo", { fg = "#1d1899", italic = true })
			vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualTextHint", { fg = "#048a66", italic = true })
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{
		"fladson/vim-kitty",
		ft = "kitty",
	},
}
