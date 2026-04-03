require("core.autocmds")
require("core.options")
require("core.filetype")
require("core.commands")
require("core.keymaps")

local gh = function(repo)
	return "https://github.com/" .. repo
end

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name = ev.data.spec.name
		local kind = ev.data.kind

		local install_or_update = kind == "install" or kind == "update"

		if name == "blink.cmp" and install_or_update then
			vim.notify("Building blink.cmp..." .. ev.data.spec.dir, vim.log.levels.INFO)
			local obj = vim.system({ "cargo", "build", "--release" }, { cwd = ev.data.spec.dir }):wait()
			if obj.code == 0 then
				vim.notify("Building blink.cmp done", vim.log.levels.INFO)
			else
				vim.notify("Building blink.cmp failed", vim.log.levels.ERROR)
			end
		end
	end,
})

vim.pack.add({
	gh("projekt0n/github-nvim-theme"),
	gh("scottmckendry/cyberdream.nvim"),
	gh("mistweaverco/kulala.nvim"),

	gh("esmuellert/codediff.nvim"),

	gh("nvim-treesitter/nvim-treesitter-textobjects"),
	{ src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },

	gh("nvim-mini/mini.pairs"),
	gh("nvim-mini/mini.surround"),
	gh("nvim-mini/mini.icons"),
	gh("nvim-mini/mini.ai"),
	gh("nvim-mini/mini.hipatterns"),
	gh("nvim-mini/mini.comment"),
	gh("nvim-mini/mini.cursorword"),
	gh("nvim-mini/mini.statusline"),
	gh("nvim-mini/mini.clue"),
	gh("nvim-mini/mini.bracketed"),

	gh("rafamadriz/friendly-snippets"),
	{ src = gh("saghen/blink.cmp"), name = "blink.cmp", version = vim.version.range("^1") },

	gh("stevearc/conform.nvim"),
	gh("mfussenegger/nvim-lint"),

	gh("folke/flash.nvim"),
	gh("folke/snacks.nvim"),
	gh("folke/lazydev.nvim"),
	gh("folke/trouble.nvim"),

	gh("nanozuki/tabby.nvim"),

	gh("rebelot/kanagawa.nvim"),

	gh("kevinhwang91/promise-async"),
	gh("kevinhwang91/nvim-ufo"),

	gh("mason-org/mason.nvim"),
	gh("neovim/nvim-lspconfig"),
	gh("windwp/nvim-ts-autotag"),

	gh("mbbill/undotree"),

	gh("MeanderingProgrammer/render-markdown.nvim"),
	gh("HakonHarnes/img-clip.nvim"),

	gh("JoosepAlviste/nvim-ts-context-commentstring"), -- for better comment experience like react, vue

	{ src = gh("nvim-lua/plenary.nvim"), name = "plenary.nvim" },
	gh("MagicDuck/grug-far.nvim"),
	gh("lewis6991/gitsigns.nvim"),

  gh("mikavilpas/yazi.nvim")
}, { confirm = false })

-- dev use
vim.cmd.packadd("usememos.nvim")
require("usememos").setup({
	endpoint = "http://localhost:5230",
	token = "memos_pat_aAeOkOvYVBnR5bffd5PysQRkwKdvP4e6",
})
