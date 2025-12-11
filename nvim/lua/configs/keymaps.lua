local nmap_leader = function(suffix, rhs, desc)
	vim.keymap.set("n", "<Leader>" .. suffix, rhs, { desc = desc })
end
-- General mappings
vim.keymap.set("n", "<Esc>", "<cmd>nohl<cr>")
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("n", "U", "<C-r>", { noremap = true })

-- Better navigation for wrapped lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Keeping the cursor centered.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll downwards" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll upwards" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next result" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous result" })

-- Indent while remaining in visual mode.
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Command line navigation
vim.keymap.set("c", "<C-h>", "<Left>", { noremap = true })
vim.keymap.set("c", "<C-j>", "<Down>", { noremap = true })
vim.keymap.set("c", "<C-k>", "<Up>", { noremap = true })
vim.keymap.set("c", "<C-l>", "<Right>", { noremap = true })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Window resizing
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Window splitting
vim.keymap.set("n", "<C-s>", "<C-W>s", { desc = "Split Window Below", noremap = true })
vim.keymap.set("n", "<C-v>", "<C-W>v", { desc = "Split Window Right", noremap = true })

-- Trouble
nmap_leader("xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Diagnostics Buffer (Trouble)")
nmap_leader("xX", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics (Trouble)")
nmap_leader("xl", "<cmd>Trouble lsp<cr>", "Trouble Lsp")
-- stylua: ignore
vim.keymap.set("n", "[t", function () require('trouble').prev() end, { desc = "Trouble Prev" })
-- stylua: ignore
vim.keymap.set("n", "]t", function () require('trouble').next() end, { desc = "Trouble Next" })

-- Window
nmap_leader("wn", "<cmd>NoNeckPain<cr>", "NoNeckPain")
-- stylua: ignore
nmap_leader("wz", function () Snacks.zen.zoom() end, "Zoom")
nmap_leader("wd", "<C-W>c", "Delete Window")

-- Explore
nmap_leader("e", "<CMD>lua MiniFiles.open(vim.api.nvim_buf_get_name(0), false)<CR>", "Explore(current)")
nmap_leader("E", "<CMD>lua MiniFiles.open(nil, false)<CR>", "Explore(root)")


-- Bookmark
-- stylua: ignore
vim.keymap.set("n", "<C-s>", function() require("arrow.persist").toggle() end)


-- Git
-- stylua: ignore start
nmap_leader("gg", function() Snacks.lazygit() end, "Git Lazygit")
nmap_leader("gb", function() Snacks.git.blame_line() end, "Git Blame")
nmap_leader("gd", function() Snacks.picker.git_diff() end, "Git Diff")
nmap_leader("gf", function() Snacks.picker.git_files() end, "Git Files")
-- stylua: ignore end


-- File & Grep
-- stylua: ignore start
nmap_leader("ff", function() Snacks.picker.files() end, "Find Files")
nmap_leader("fg", function() Snacks.picker.grep() end, "Find Grep")
nmap_leader("fl", function() Snacks.picker.lines() end, "Find Lines")
nmap_leader("f'", function() Snacks.picker.resume() end, "Find Resume")
nmap_leader("fh", function() Snacks.picker.help() end, "Find Help")
nmap_leader("`", function () Snacks.picker.recent() end, "Recent")
vim.keymap.set({"n", "v"}, "<leader>fw", function () Snacks.picker.grep_word() end, { desc = "Find Word" })
-- stylua: ignore end


-- LSP
-- stylua: ignore start
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
vim.keymap.set("n", "<leader>cA", function()
	vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
end, { desc = "Code Action(source)" })
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "<leader>cR", function () Snacks.rename.rename_file() end, { desc = "Rename File" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, { desc = "Signature Help" })
vim.keymap.set("n", "gd", function () Snacks.picker.lsp_definitions() end, { desc = "Goto Definitions" })
vim.keymap.set("n", "gr", function () Snacks.picker.lsp_references() end, { desc = "Goto References", nowait = true })
vim.keymap.set("n", "gt", function () Snacks.picker.lsp_type_definitions() end, { desc = "Goto Type Definition" })
vim.keymap.set("n", "gD", function () Snacks.picker.lsp_declarations() end, { desc = "Goto Declarations" })
vim.keymap.set("n", "<leader>cf", function() require("conform").format() end, { desc = "Format" })
nmap_leader("cs", function () Snacks.picker.lsp_symbols() end, "Lsp Symbols")
-- stylua: ignore end


-- Buffer
-- stylua: ignore start 
nmap_leader("ba", function() Snacks.bufdelete.all() end, "Delete(all)")
nmap_leader("bo", function() Snacks.bufdelete.other() end, "Delete(other)")
nmap_leader("bd", function() Snacks.bufdelete() end, "Delete(other)")
nmap_leader("br", vim.lsp.buf.references,  "Buffer reference")
-- stylua: ignore end

-- Helper
nmap_leader("u", "<cmd>UndotreeToggle<cr>", "Undotree")
vim.keymap.set("n", "<C-p>", "<cmd>PasteImage<cr>", { desc = "Paste image from system clipboard" })
vim.keymap.set("n", "zR", require("ufo").openAllFolds)
vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
-- stylua: ignore
vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump({ search = { forward = true, wrap = false, multi_window = false } }) end, { desc = "Flash Forward" })
-- stylua: ignore
vim.keymap.set({ "n", "x", "o" }, "S", function() require("flash").jump({ search = { forward = false, wrap = false, multi_window = false } }) end, { desc = "Flash Backward" })
vim.keymap.set({ "n", "x", "o" }, "<c-space>", function()
	require("flash").treesitter({
		actions = {
			["<c-space>"] = "next",
			["<BS>"] = "prev",
		},
	})
end, { desc = "Treesitter incremental selection" })
-- stylua: ignore
vim.keymap.set("n", "[w", function () Snacks.words.jump(-vim.v.count1) end, { desc = "Prev Word" })
-- stylua: ignore
vim.keymap.set("n", "]w", function () Snacks.words.jump(vim.v.count1) end, { desc = "Next Word" })

-- Notes
nmap_leader("nnd", "<cmd>ZkNew {dir = 'daily'}<cr>", "New Daily Note")
nmap_leader("nnn", "<cmd>ZkNew {dir = 'notes', title = vim.fn.input('Title: ')}<cr>", "New Note")
nmap_leader("nnp", "<cmd>ZkNew {dir = 'private', title = vim.fn.input('Title: ')}<cr>", "New Private Note")
nmap_leader("nnw", "<cmd>ZkNew {dir = 'work', title = vim.fn.input('Title: ')}<cr>", "New Work Note")
nmap_leader("no", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", "Open Note")
nmap_leader("nt", "<Cmd>ZkTags<CR>", "Open Note Tags")

-- Harpoon
local harpoon = require("harpoon")
-- stylua: ignore start
nmap_leader("a", function() harpoon:list():add() end, "Add Harpoon")
nmap_leader("<space>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, "Harpoon Menu")
nmap_leader("1", function() harpoon:list():select(1) end, harpoon:list():get(1).value)
nmap_leader("2", function() harpoon:list():select(2) end, harpoon:list():get(2).value)
nmap_leader("3", function() harpoon:list():select(3) end, harpoon:list():get(3).value)
nmap_leader("4", function() harpoon:list():select(4) end, harpoon:list():get(4).value)
-- stylua: ignore end
harpoon:extend({
  UI_CREATE = function(cx)
    vim.keymap.set("n", "<C-v>", function()
      harpoon.ui:select_menu_item({ vsplit = true })
    end, { buffer = cx.bufnr })

    vim.keymap.set("n", "<C-s>", function()
      harpoon.ui:select_menu_item({ split = true })
    end, { buffer = cx.bufnr })
  end,
})
nmap_leader("ht", function ()
  Snacks.debug(harpoon:list():display())
end)
