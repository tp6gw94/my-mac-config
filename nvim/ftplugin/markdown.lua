vim.opt.wrap = true
if require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
	local function map(...)
		vim.api.nvim_buf_set_keymap(0, ...)
	end
	local opts = { noremap = true, silent = false }

	map("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
	map("n", "<leader>nl", "<Cmd>ZkLinks<CR>", opts)
end

