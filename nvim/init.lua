require("configs/autocmds")
require("configs/options")

vim.pack.add({
	"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },

	"https://github.com/nvim-mini/mini.pairs",
	"https://github.com/nvim-mini/mini.surround",
	"https://github.com/nvim-mini/mini.files",
	"https://github.com/nvim-mini/mini.icons",
	"https://github.com/nvim-mini/mini.ai",
	"https://github.com/nvim-mini/mini.hipatterns",
	"https://github.com/nvim-mini/mini.comment",
	"https://github.com/nvim-mini/mini.cursorword",
	"https://github.com/nvim-mini/mini.statusline",
	"https://github.com/nvim-mini/mini.clue",
	"https://github.com/nvim-mini/mini.bracketed",

	"https://github.com/rafamadriz/friendly-snippets",
	{ src = "https://github.com/saghen/blink.cmp", name = "blink", version = vim.version.range("*") },

	"https://github.com/stevearc/conform.nvim",
	"https://github.com/mfussenegger/nvim-lint",

	"https://github.com/folke/flash.nvim",
	"https://github.com/folke/snacks.nvim",
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/folke/trouble.nvim",

	"https://github.com/rebelot/kanagawa.nvim",

	"https://github.com/kevinhwang91/promise-async",
	"https://github.com/kevinhwang91/nvim-ufo",

	"https://github.com/mason-org/mason.nvim",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/windwp/nvim-ts-autotag",
	"https://github.com/dmmulroy/ts-error-translator.nvim",
	"https://github.com/fladson/vim-kitty",

	"https://github.com/mbbill/undotree",

	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
	"https://github.com/HakonHarnes/img-clip.nvim",

	"https://github.com/shortcuts/no-neck-pain.nvim",

	"https://github.com/JoosepAlviste/nvim-ts-context-commentstring", -- for better comment experience like react, vue
	"https://github.com/zk-org/zk-nvim",

	"https://github.com/nvim-lua/plenary.nvim",
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
}, { confirm = false })

require("plugins/treesitter")
require("plugins/lsp")
require("plugins/cmp")
require("plugins/formatting")
require("plugins/theme")
require("plugins/editor")
require("plugins/snacks")
require("plugins/ui")
require("plugins/notes")

require("configs/commands")
require("configs/keymaps")
