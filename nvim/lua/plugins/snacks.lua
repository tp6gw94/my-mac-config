local utils = require("core.utils")
local nmap_leader = utils.nmap_leader

require("snacks").setup({
	bigfile = { enabled = true },
	bufdelete = { enabled = true },
	debug = { enabled = true },
	gitbrowse = { enabled = true },
	input = { enabled = true },
	lazygit = { enabled = true },
	notifier = { enabled = true },
	quickfile = { enabled = true },
	rename = { enabled = true },
	scope = { enabled = true },
	statuscolumn = { enabled = true, folds = { open = true } },
	words = { enabled = true },
	image = { enabled = true },
	indent = { enabled = true },
	picker = {
		ui_select = true,
		formatters = {
			file = {
				truncate = "left",
			},
		},
		layout = {
			preset = "vertical",
		},
	},
	--
	gh = { enabled = false },
	dashboard = { enabled = false },
	explorer = { enabled = false },
	scroll = { enabled = false },
})

local lsp_layout = {
	preset = "vertical",
	layout = {
		width = 0.8,
		min_width = 100,
		height = 0.85,
		min_height = 25,
	},
}

Snacks.indent.enable()

-- File & Grep
nmap_leader("ff", function()
	Snacks.picker.files()
end, "Find Files")
nmap_leader("fg", function()
	Snacks.picker.grep()
end, "Find Grep")
nmap_leader("fl", function()
	Snacks.picker.lines()
end, "Find Lines")
nmap_leader("f'", function()
	Snacks.picker.resume()
end, "Find Resume")
nmap_leader("fh", function()
	Snacks.picker.help()
end, "Find Help")
nmap_leader("<space>", function()
	Snacks.picker.recent({
		filter = { cwd = true },
	})
end, "Recent")
vim.keymap.set({ "n", "v" }, "<leader>fw", function()
	Snacks.picker.grep_word()
end, { desc = "Find Word" })

-- LSP picker
vim.keymap.set("n", "gd", function()
	Snacks.picker.lsp_definitions({ layout = lsp_layout })
end, { desc = "Goto Definitions" })
vim.keymap.set("n", "gr", function()
	Snacks.picker.lsp_references({ layout = lsp_layout })
end, { desc = "Goto References", nowait = true })
vim.keymap.set("n", "gt", function()
	Snacks.picker.lsp_type_definitions({ layout = lsp_layout })
end, { desc = "Goto Type Definition" })
vim.keymap.set("n", "gD", function()
	Snacks.picker.lsp_declarations({ layout = lsp_layout })
end, { desc = "Goto Declarations" })
nmap_leader("cs", function()
	Snacks.picker.lsp_symbols()
end, "Lsp Symbols")

-- Window
nmap_leader("wz", function()
	Snacks.zen.zoom()
end, "Zoom")

-- Buffer
nmap_leader("ba", function()
	Snacks.bufdelete.all()
end, "Delete(all)")
nmap_leader("bo", function()
	Snacks.bufdelete.other()
end, "Delete(other)")
nmap_leader("bd", function()
	Snacks.bufdelete()
end, "Delete(other)")

-- Rename
nmap_leader("cR", function()
	Snacks.rename.rename_file()
end, "Rename File")

-- Word jump
vim.keymap.set("n", "[w", function()
	Snacks.words.jump(-vim.v.count1)
end, { desc = "Prev Word" })
vim.keymap.set("n", "]w", function()
	Snacks.words.jump(vim.v.count1)
end, { desc = "Next Word" })
