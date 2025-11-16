vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldmethod = "expr"
vim.o.wrap = true

if require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
	local function map(mod, keymap, action, desc)
		local opts = { noremap = true, silent = false, buffer = 0, desc = desc }

		vim.keymap.set(mod, keymap, action, opts)
	end

	map("n", "<CR>", vim.lsp.buf.definition)
	map("n", "<leader>nb", vim.lsp.buf.references, "Note references")
	map("n", "<leader>nl", "<CMD>ZkLinks<CR>", "Note links")
	map("v", "<leader>ni", "<CMD>'<,'>ZkInsertLinkAtSelection<CR>", "Insert note link")
end
