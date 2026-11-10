return {
	-- 1. Gitsigns: Gutter indicators, inline diff previews, and hunk staging
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "┃" },
				change = { text = "┃" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			signcolumn = true, -- Toggle showing the gutter column
			numhl = false, -- Toggle line number highlighting
			linehl = false, -- Toggle full line highlighting
			word_diff = false, -- Toggle inline word diffs

			on_attach = function(bufnr)
				-- jupytext shows a .ipynb buffer as Python. The file on disk is
				-- still JSON, so the gutter diff would be noise.
				if require("thiran.config.notebooks").enabled then
					local name = vim.api.nvim_buf_get_name(bufnr)
					if name:match("%.ipynb$") then
						return false
					end
				end

				local gitsigns = require("gitsigns")

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation between changes (Hunks)
				map("n", "]c", function()
					if vim.wo.diff then
						vim.cmd.feedkeys("]c", "n")
					else
						gitsigns.nav_hunk("next")
					end
				end, { desc = "Git: Next Hunk" })

				map("n", "[c", function()
					if vim.wo.diff then
						vim.cmd.feedkeys("[c", "n")
					else
						gitsigns.nav_hunk("prev")
					end
				end, { desc = "Git: Prev Hunk" })

				-- Practical Actions
				map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Git: Preview Hunk Inline" })
				map("n", "<leader>hb", function()
					gitsigns.blame_line({ full = true })
				end, { desc = "Git: Blame Line" })
				map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Git: Stage Hunk" })
				map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Git: Reset Hunk" })
				map("v", "<leader>hs", function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Git: Stage Selected Hunk" })
				map("v", "<leader>hr", function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Git: Reset Selected Hunk" })
			end,
		},
	},

	-- 2. Vim-Fugitive: The ultimate Git tool for staging, committing, and pushing
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "G" },
		keys = {
			{ "<leader>gs", "<cmd>Git<cr>", desc = "Git: Status Control Center" },
			{ "<leader>gc", "<cmd>Git commit<cr>", desc = "Git: Commit" },
			{ "<leader>gp", "<cmd>Git push<cr>", desc = "Git: Push" },
		},
	},

	-- 3. Diffview: Toggles a clean, visual side-by-side project diff view
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git: Open Full Visual Diff" },
			{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Git: Close Visual Diff" },
		},
		opts = {},
	},
}
