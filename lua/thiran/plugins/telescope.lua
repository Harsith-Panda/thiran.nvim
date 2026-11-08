return {
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		keys = {
			{ "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
			{ "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Find text" },
			{
				"<leader>fw",
				function() require("telescope.builtin").grep_string() end,
				mode = { "n", "v" },
				desc = "Find word",
			},
			{ "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Find buffers" },
			{ "<leader>fr", function() require("telescope.builtin").oldfiles() end, desc = "Find recent files" },
			{ "<leader>fp", function() require("telescope.builtin").resume() end, desc = "Find previous search" },
			{ "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Find help" },
			{ "<leader>fd", function() require("telescope.builtin").diagnostics() end, desc = "Find diagnostics" },
			{
				"<leader>/",
				function() require("telescope.builtin").current_buffer_fuzzy_find() end,
				desc = "Find in buffer",
			},
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					prompt_prefix = "❯ ",
					selection_caret = "❯ ",
					path_display = { "smart" },
					sorting_strategy = "ascending",
					layout_strategy = "flex",
					layout_config = {
						prompt_position = "top",
						horizontal = { preview_width = 0.55 },
						vertical = { mirror = true, preview_height = 0.45 },
						flex = { flip_columns = 140 },
					},
					borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
						},
						n = {
							["q"] = actions.close,
						},
					},
				},
				pickers = {
					find_files = {
						hidden = true,
					},
					buffers = {
						sort_mru = true,
						ignore_current_buffer = true,
					},
					live_grep = {
						additional_args = function()
							return { "--hidden" }
						end,
					},
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
				},
			})

			pcall(telescope.load_extension, "fzf")
		end,
	},
}
