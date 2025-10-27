return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-mini/mini.icons" },
	opts = {
    lsp = {
      code_actions = {
        previewer = false
      }
    },
		keymap = {
			fzf = {
				["ctrl-q"] = "select-all+accept",
				["ctrl-f"] = "half-page-down",
				["ctrl-b"] = "half-page-up",
			},
		},
		fzf_colors = {
			true,
			["fg+"] = { "fg", "Normal", "underline" },
			["bg+"] = { "bg", { "CursorLine", "Normal" } },
			["hl+"] = { "fg", "Statement" },
		},
		winopts = {
			preview = {
				wrap = true,
				layout = "vertical",
			},
		},
	},
	config = function(_, opts)
		require("fzf-lua").setup(opts)

		require("fzf-lua").register_ui_select()
	end,
	keys = {
		{
			"<leader>f",
			"<CMD>FzfLua global<CR>",
			silent = true,
		},
		{
			"<leader>F",
			"<CMD>FzfLua files no_ignore=true<CR>",
			silent = true,
		},
		{
			"<leader>ca",
			"<CMD>FzfLua lsp_code_actions<CR>",
			silent = true,
		},
		{
			"gr",
			"<CMD>FzfLua lsp_references<CR>",
			silent = true,
		},
		{
			"gf",
			"<CMD>FzfLua lsp_finder<CR>",
			silent = true,
		},
		{
			"gd",
			"<CMD>FzfLua lsp_definitions<CR>",
			silent = true,
		},
		{
			"gD",
			"<CMD>FzfLua lsp_declarations<CR>",
			silent = true,
		},
		{
			"gi",
			"<CMD>FzfLua lsp_implementations<CR>",
			silent = true,
		},
		{
			"<leader>bs",
			"<CMD>FzfLua blines<CR>",
			silent = true,
		},
		{
			"<leader>bS",
			"<CMD>FzfLua lines<CR>",
			silent = true,
		},
		{
			"<leader>/",
			"<CMD>FzfLua live_grep<CR>",
			silent = true,
		},
		{
			"<leader>'",
			"<CMD>FzfLua resume<CR>",
			silent = true,
		},
		{
			"<leader>h",
			"<CMD>FzfLua helptags<CR>",
			silent = true,
			desc = "Help",
		},
		{
			"<leader>gl",
			"<CMD>FzfLua git_bcommits<CR>",
			silent = true,
		},
		{
			"<leader>gL",
			"<CMD>FzfLua git_commits<CR>",
			silent = true,
		},
		{
			"<leader>gh",
			"<CMD>FzfLua git_hunks<CR>",
			silent = true,
		},
		{
			"<leader>s",
			"<CMD>FzfLua grep_cword<CR>",
			silent = true,
		},
		{
			"<leader>S",
			"<CMD>FzfLua grep_cWORD<CR>",
			silent = true,
		},
		{
			"<C-x><C-f>",
			"<CMD>FzfLua complete_path<CR>",
			mode = { "n", "v", "i" },
			silent = true,
		},
	},
}
