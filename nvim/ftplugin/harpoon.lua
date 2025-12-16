local harpoon = require("harpoon")
-- stylua: ignore start
vim.keymap.set("n", "1", function() harpoon:list():select(1) end, { buffer = 0 })
vim.keymap.set("n", "2", function() harpoon:list():select(2) end, { buffer = 0 })
vim.keymap.set("n", "3", function() harpoon:list():select(3) end,{ buffer = 0 })
vim.keymap.set("n", "4", function() harpoon:list():select(4) end,{ buffer = 0 })
vim.keymap.set("n", "5", function() harpoon:list():select(5) end,{ buffer = 0 })
vim.keymap.set("n", "6", function() harpoon:list():select(6) end,{ buffer = 0 })
vim.keymap.set("n", "7", function() harpoon:list():select(7) end,{ buffer = 0 })
vim.keymap.set("n", "8", function() harpoon:list():select(8) end,{ buffer = 0 })
vim.keymap.set("n", "9", function() harpoon:list():select(9) end,{ buffer = 0 })
-- stylua: ignore end
