local gitsigns = require("gitsigns")
local utils = require("core.utils")

gitsigns.setup({
	current_line_blame = true,
})

utils.nmap_leader("ghr", gitsigns.reset_hunk, "Git hunk reset")
utils.nmap_leader("ghs", gitsigns.stage_hunk, "Git hunk stage")

utils.nmap_leader("gg", function()
	Snacks.lazygit()
end, "Git Lazygit")

utils.nmap_leader("gd", gitsigns.diffthis, "Git diff (buffer)")
utils.nmap_leader("gD", function()
	gitsigns.diffthis("~")
end, "Git diff (~)")
