-- Keymap configuration

-- Set leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- General mappings
vim.keymap.set("n", "<Esc>", "<cmd>nohl<cr>")
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("n", "U", "<C-r>", { noremap = true })

-- Better navigation for wrapped lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Buffer navigation
vim.keymap.set("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

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
vim.keymap.set("n", "<C-s>", "<C-W>s", { desc = "Split Window Below", remap = true })
vim.keymap.set("n", "<C-v>", "<C-W>v", { desc = "Split Window Right", remap = true })
vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- LSP mappings
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
vim.keymap.set("n", "<leader>cA", function()
	vim.lsp.buf.code_action({ context = { only = { "source" } } })
end, { desc = "Code Action(source)" })
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diangostics" })
vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Reanem" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, { desc = "Signature Help" })

-- Snacks mappings
local utils = require("config.utils")
utils.nmap_leader("gg", function()
	Snacks.lazygit()
end, "Lazygit")
utils.nmap_leader("gv", function()
	Snacks.gitbrowse()
end, "Gitbrowse")
utils.nmap_leader("gb", function()
	Snacks.git.blame_line()
end, "Blame")
utils.nmap_leader("bd", function()
	Snacks.bufdelete()
end, "Delete")
utils.nmap_leader("ba", function()
	Snacks.bufdelete.all()
end, "Delete(all)")
utils.nmap_leader("bo", function()
	Snacks.bufdelete.other()
end, "Delete(other)")
