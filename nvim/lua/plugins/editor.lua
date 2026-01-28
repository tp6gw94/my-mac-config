local utils = require("core.utils")
local nmap_leader = utils.nmap_leader

require("mini.icons").setup()
require("mini.pairs").setup()
require("mini.cursorword").setup()
require("mini.statusline").setup()
require("img-clip").setup()
require("render-markdown").setup()
require("flash").setup()

require("mini.surround").setup({
	mappings = {
		add = "ms",
		delete = "md",
		find_left = "",
		highlight = "",
		replace = "mr",
	},
})

local hipatterns = require("mini.hipatterns")
hipatterns.setup({
	highlighters = {
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		warning = { pattern = "%f[%w]()WARNING()%f[%W]", group = "MiniHipatternsWarning" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		hex_color = hipatterns.gen_highlighter.hex_color(),
	},
})

local spec_treesitter = require("mini.ai").gen_spec.treesitter
require("mini.ai").setup({
	custom_textobjects = {
		F = spec_treesitter({
			a = "@function.outer", -- Around: selects the whole function
			i = "@function.inner", -- Inside: selects the function body
		}),
		P = spec_treesitter({
			a = "@parameter.outer", -- Around: argument plus surrounding space/separator
			i = "@parameter.inner", -- Inside: just the argument content
		}),
		C = spec_treesitter({
			a = { "@conditional.outer", "@loop.outer" },
			i = { "@conditional.inner", "@loop.inner" },
		}),
	},
})

require("ts_context_commentstring").setup({
	enable_autocmd = false,
})
require("mini.comment").setup({
	options = {
		custom_commentstring = function()
			return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
		end,
	},
})

require("mini.bracketed").setup({
	file = { suffix = "" },
	window = { suffix = "" },
	oldfile = { suffix = "" },
	quickfix = { suffix = "" },
	undo = { suffix = "" },
	yank = { suffix = "" },
	treesitter = { suffix = "" },
})

local miniclue = require("mini.clue")
miniclue.setup({
	triggers = {
		{ mode = "n", keys = "<leader>" },
		-- { mode = "i", keys = "<C-x>" },
		{ mode = "v", keys = "<leader>" },
		{ mode = "n", keys = "[" },
		{ mode = "n", keys = "]" },
	},
	clues = {
		{ mode = "n", keys = "<leader>b", desc = "Buffer" },
		{ mode = "n", keys = "<leader>c", desc = "Code" },
		{ mode = "n", keys = "<leader>f", desc = "Pick" },
		{ mode = "n", keys = "<leader>g", desc = "Git" },
		{ mode = "n", keys = "<leader>n", desc = "Note" },
		{ mode = "n", keys = "<leader>w", desc = "Window" },
		{ mode = "n", keys = "<leader>x", desc = "Trouble" },
		{ mode = "v", keys = "<leader>c", desc = "Code" },
		{ mode = "v", keys = "<leader>n", desc = "Note" },

		miniclue.gen_clues.builtin_completion(),
		miniclue.gen_clues.g(),
		miniclue.gen_clues.marks(),
		miniclue.gen_clues.registers(),
		miniclue.gen_clues.windows(),
		miniclue.gen_clues.z(),
	},
	window = {
		delay = 0,
		config = {
			width = "auto",
			border = "double",
		},
	},
})

require("kulala").setup({
	global_keymaps = true,
	global_keymaps_prefix = "<leader>R",
	kulala_keymaps_prefix = "",
})

require("yazi").setup({
	keymaps = {
		open_file_in_horizontal_split = "<C-s>",
		grep_in_directory = false,
	},
})

require("no-neck-pain").setup()

nmap_leader("wn", "<cmd>NoNeckPain<cr>", "NoNeckPain")

nmap_leader("e", "<CMD>Yazi<CR>", "Explore(current)")
nmap_leader("E", "<CMD>Yazi cwd<CR>", "Explore(root)")

nmap_leader("u", "<cmd>UndotreeToggle<cr>", "Undotree")

vim.keymap.set("n", "<C-p>", "<cmd>PasteImage<cr>", { desc = "Paste image from system clipboard" })
nmap_leader("p", "<cmd>PasteImage<cr>", "Paste Image")

vim.keymap.set({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", function()
	require("flash").jump({
		search = { mode = "search", max_length = 0 },
		label = { after = { 0, 0 } },
		pattern = "^",
	})
end, { desc = "Flash Line" })
vim.keymap.set({ "n", "x", "o" }, "<c-space>", function()
	require("flash").treesitter({
		labels = "",

		label = { before = false, after = false },
		actions = {
			["<c-space>"] = "next",
			["<BS>"] = "prev",
		},
	})
end, { desc = "Treesitter incremental selection" })
