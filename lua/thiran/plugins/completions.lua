return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate", -- Automatically updates parsers when the plugin updates
		event = { "BufReadPost", "BufNewFile" }, -- Lazy load when opening a file
		config = function()
			local configs = require("nvim-treesitter.configs")

			configs.setup({
				-- 1. Automate your language parser installations
				ensure_installed = {
					"lua",
					"vim",
					"vimdoc",
					"query",
					"markdown",
					"markdown_inline",
					-- Add languages you code in here:
					"python",
					"javascript",
					"typescript",
					"c",
				},

				-- Install parsers synchronously (only applied to `ensure_installed`)
				sync_install = false,

				-- Automatically install missing parsers when you open a new filetype
				auto_install = true,

				-- 2. Enable the advanced syntax highlighting engine
				highlight = {
					enable = true,
					-- Setting this to true will run standard Neovim syntax highlighting
					-- alongside Treesitter. Can be useful for languages like Ruby.
					additional_vim_regex_highlighting = false,
				},

				-- 3. Enable smart indentation based on Treesitter trees
				indent = { enable = true },
			})
		end,
	},
}
