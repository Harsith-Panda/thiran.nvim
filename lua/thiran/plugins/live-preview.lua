---@type LazySpec
return {
	"brianhuster/live-preview.nvim",
	version = "*",
	cmd = "LivePreview",
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
	keys = {
		{
			"<leader>p",
			function()
				local preview = require("livepreview")
				if preview.is_running() then
					preview.close()
				else
					vim.cmd("LivePreview start")
				end
			end,
			desc = "Live preview",
		},
		{ "<leader>P", "<cmd>LivePreview pick<cr>", desc = "Pick a file to preview" },
		{
			"<leader>q",
			function()
				require("livepreview").close()
			end,
			desc = "Quit live preview",
		},
	},
	opts = {
		-- Telescope lists Markdown, HTML, AsciiDoc, and SVG in the working directory.
		picker = "telescope",
		-- The browser follows the cursor while editing Markdown.
		sync_scroll = true,
		-- Serve the working directory, so links between notes and their images resolve.
		dynamic_root = false,
		address = "127.0.0.1",
	},
	config = function(_, opts)
		require("livepreview.config").set(opts)
	end,
}
