local utils = require("core.utils")
local nmap_leader = utils.nmap_leader

nmap_leader("fr", function()
	require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
end, "Find and Replace (Current)")

nmap_leader("fR", function()
	require("grug-far").open()
end, "Find and Replace (All)")
