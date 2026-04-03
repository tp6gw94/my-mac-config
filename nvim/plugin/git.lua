local gitsigns = require("gitsigns")
local utils = require("core.utils")

gitsigns.setup({
	current_line_blame = true,
})

utils.nmap_leader("ghr", gitsigns.reset_hunk, "Git hunk reset")
utils.nmap_leader("ghs", gitsigns.stage_hunk, "Git hunk stage")

require('codediff').setup({
  diff = {
    compute_moves = false
  },
  explorer = {
    view_mode = "tree",
    flatten_dirs = true,
  }
})
utils.nmap_leader("gd", "<cmd>CodeDiff<cr>", "Git diff")
