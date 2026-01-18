local utils = require("core.utils")
local nmap_leader = utils.nmap_leader

require("zk").setup({
	-- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
	-- or select" (`vim.ui.select`).
	picker = "snacks_picker",

	lsp = {
		-- `config` is passed to `vim.lsp.start(config)`
		config = {
			name = "zk",
			cmd = { "zk", "lsp" },
			filetypes = { "markdown" },
			-- on_attach = ...
			-- etc, see `:h vim.lsp.start()`
		},

		-- automatically attach buffers in a zk notebook that match the given filetypes
		auto_attach = {
			enabled = true,
		},
	},
})

nmap_leader("nnd", "<cmd>ZkNew {dir = 'daily'}<cr>", "New Daily Note")
nmap_leader("nnn", "<cmd>ZkNew {dir = 'notes', title = vim.fn.input('Title: ')}<cr>", "New Note")
nmap_leader("nnp", "<cmd>ZkNew {dir = 'private', title = vim.fn.input('Title: ')}<cr>", "New Private Note")
nmap_leader("nnw", "<cmd>ZkNew {dir = 'work', title = vim.fn.input('Title: ')}<cr>", "New Work Note")
nmap_leader("no", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", "Open Note")
nmap_leader("nt", "<Cmd>ZkTags<CR>", "Open Note Tags")
