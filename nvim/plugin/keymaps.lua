local utils = require("core.utils")
local nmap_leader = utils.nmap_leader
local vmap_leader = utils.vmap_leader

-- General mappings
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

-- Window splitting
vim.keymap.set("n", "<C-s>", "<C-W>s", { desc = "Split Window Below", noremap = true })
vim.keymap.set("n", "<C-v>", "<C-W>v", { desc = "Split Window Right", noremap = true })

-- Window
nmap_leader("wd", "<C-W>c", "Delete Window")
nmap_leader("wp", function()
	local wn = vim.fn.input("Enter win number: ")
	if wn:match("%d") then
		vim.cmd(wn .. "wincmd w")
	end
end, "Window Pick")

-- Tab
nmap_leader("td", "<cmd>tabclose<cr>", "Tab Close")
nmap_leader("tn", "<cmd>tabnext<cr>", "Tab Next")
nmap_leader("tp", "<cmd>tabprevious<cr>", "Tab Previous")

-- resizing splits
vim.keymap.set("n", "<C-left>", "<cmd>resize -2<cr>")
vim.keymap.set("n", "<C-down>", "<cmd>resize +2<cr>")
vim.keymap.set("n", "<C-up>", "<cmd>vertical resize -2<cr>")
vim.keymap.set("n", "<C-right>", "<cmd>vertical resize +2<cr>")
-- moving between splits
local rex_directions = {
	h = "left",
	j = "down",
	k = "up",
	l = "right",
}

local focus_pending = false

local function request_focus(session_id, source_block_id, direction)
	if focus_pending then
		return
	end
	focus_pending = true
	local ok, err = pcall(vim.system, {
		"rex",
		"--autostart=false",
		"do",
		"-s",
		session_id,
		"-b",
		source_block_id,
		"focus_from_source",
		"direction=" .. direction,
	}, { text = true }, function(result)
		vim.schedule(function()
			focus_pending = false
			if result.code ~= 0 or result.signal ~= 0 then
				vim.notify(
					("Rex focus failed (exit %d, signal %d): %s"):format(
						result.code,
						result.signal,
						vim.trim(result.stderr)
					),
					vim.log.levels.ERROR
				)
			end
		end)
	end)
	if not ok then
		focus_pending = false
		vim.notify("Rex focus failed: " .. err, vim.log.levels.ERROR)
	end
end

local function move_window(key)
	local window = vim.fn.win_getid()
	vim.cmd("wincmd " .. vim.v.count1 .. key)
	if vim.fn.win_getid() ~= window or not vim.env.REX_SESSION then
		return
	end
	if not vim.env.REX_BLOCK or vim.env.REX_BLOCK == "" then
		vim.notify("Rex focus failed: REX_BLOCK is not set", vim.log.levels.ERROR)
		return
	end
	request_focus(vim.env.REX_SESSION, vim.env.REX_BLOCK, rex_directions[key])
end

local function report_neighbors()
	local keys = "hjkl"
	if vim.api.nvim_get_mode().mode == "n" then
		keys = ""
		for key in pairs(rex_directions) do
			if vim.fn.winnr(key) ~= vim.fn.winnr() then
				keys = keys .. key
			end
		end
	end
	vim.api.nvim_ui_send("\27]7501;id=nvim-nav:state=idle:msg=" .. vim.base64.encode(keys) .. "\27\\")
end

if vim.env.REX_SESSION then
	local group = vim.api.nvim_create_augroup("rex_nav", {})
	vim.api.nvim_create_autocmd(
		{ "VimEnter", "WinEnter", "WinNew", "WinClosed", "WinResized", "VimResized", "TabEnter", "ModeChanged", "FocusGained" },
		{ group = group, callback = vim.schedule_wrap(report_neighbors) }
	)
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			vim.api.nvim_ui_send("\27]7501;id=nvim-nav:state=clear\27\\")
		end,
	})
end

for key in pairs(rex_directions) do
	vim.keymap.set("n", "<C-" .. key .. ">", function()
		move_window(key)
	end)
	vim.keymap.set("n", "<C-w>" .. key, function()
		move_window(key)
	end)
end

-- Paths
nmap_leader("cp", "<cmd>CopyRelPath<cr>", "Copy relative path")
vmap_leader("cp", ":'<,'>CopyRelPath<cr>", "Copy relative path")
nmap_leader("cP", "<cmd>CopyAbsPath<cr>", "Copy absolute path")
vmap_leader("cP", ":'<,'>CopyAbsPath<cr>", "Copy absolute path")
