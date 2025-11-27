return {
	{
		"mbbill/undotree",
		cmd = { "UndotreeToggle" },
		keys = {
			{ "<leader>u", "<CMD>UndotreeToggle<CR>", desc = "Undotree" },
		},
	},
	{
		"esmuellert/vscode-diff.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
	},
}
