local harpoon = require("harpoon")
-- stylua: ignore start
vim.keymap.set("n", "1", function() harpoon:list():select(1) end)
vim.keymap.set("n", "2", function() harpoon:list():select(2) end)
vim.keymap.set("n", "3", function() harpoon:list():select(3) end)
vim.keymap.set("n", "4", function() harpoon:list():select(4) end)
vim.keymap.set("n", "5", function() harpoon:list():select(5) end)
vim.keymap.set("n", "6", function() harpoon:list():select(6) end)
-- stylua: ignore end
