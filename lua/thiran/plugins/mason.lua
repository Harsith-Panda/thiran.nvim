return {
	{
		"mason-org/mason.nvim",
		config = function()
			require("mason").setup({
				-- Silences unnecessary logs across user environments
				log_level = vim.log.levels.ERROR,

				ui = {
					-- Ensures the window uses universal border boundaries for styling
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
}
