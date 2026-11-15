-- The name of the block, shown at its closing line in the comment color.
-- Only the line under the cursor, and only when the block is tall enough
-- to be worth the hint. Space b b hides or shows them.
return {
	{
		"code-biscuits/nvim-biscuits",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		keys = {
			{
				"<leader>bb",
				function()
					require("nvim-biscuits").toggle_biscuits()
				end,
				desc = "Toggle context hints",
			},
		},
		opts = {
			show_on_start = true,
			cursor_line_only = true,
			min_distance = 8,
			max_length = 36,
			prefix_string = " · ",
			max_file_size = "100kb",
		},
	},
}
