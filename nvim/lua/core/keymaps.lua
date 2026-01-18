local utils = require("core.utils")
local nmap_leader = utils.nmap_leader
local vmap_leader = utils.vmap_leader

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

-- Window
nmap_leader("wd", "<C-W>c", "Delete Window")

-- Paths
nmap_leader("cp", "<cmd>CopyRelPath<cr>", "Copy relative path")
vmap_leader("cp", ":'<,'>CopyRelPath<cr>", "Copy relative path")
nmap_leader("cP", "<cmd>CopyAbsPath<cr>", "Copy absolute path")
vmap_leader("cP", ":'<,'>CopyAbsPath<cr>", "Copy absolute path")
