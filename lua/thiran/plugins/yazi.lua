---@type LazySpec
return {
	"mikavilpas/yazi.nvim",
	version = "*",
	event = "VeryLazy",
	dependencies = {
		{ "nvim-lua/plenary.nvim", lazy = true },
	},
	keys = {
		{
			"<leader>yy",
			"<cmd>Yazi<cr>",
			mode = { "n", "v" },
			desc = "Yazi at file",
		},
		{
			"<leader>yw",
			"<cmd>Yazi cwd<cr>",
			desc = "Yazi in working directory",
		},
		{
			"<leader>yr",
			"<cmd>Yazi toggle<cr>",
			desc = "Yazi resume",
		},
	},
	---@type YaziConfig | {}
	opts = {
		-- Neo-tree opens directories. Yazi stays a floating file manager.
		open_for_directories = false,
		open_multiple_tabs = true,
		yazi_floating_window_border = "rounded",
		keymaps = {
			show_help = "<f1>",
			open_file_in_vertical_split = "<c-v>",
			open_file_in_horizontal_split = "<c-x>",
			open_file_in_tab = "<c-t>",
			grep_in_directory = "<c-s>",
			send_to_quickfix_list = "<c-q>",
			-- Needs GNU realpath (`grealpath` on macOS). Off until that exists.
			copy_relative_path_to_selected_files = false,
			cycle_open_buffers = "<tab>",
			change_working_directory = "<c-\\>",
			-- These need plugins Thiran does not ship.
			replace_in_directory = false,
			open_and_pick_window = false,
		},
	},
}
