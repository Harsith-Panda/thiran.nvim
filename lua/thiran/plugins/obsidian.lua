-- Turn this plugin off in lua/thiran/config/markdown.lua.
-- Set your vault path in lua/thiran/config/vault.lua (see vault.example.lua).
local markdown = require("thiran.config.markdown")

local function vault_workspaces()
	local ok, vault = pcall(require, "thiran.config.vault")
	if not ok or type(vault) ~= "table" or type(vault.workspaces) ~= "table" then
		return {}
	end
	return vault.workspaces
end

local workspaces = vim.list_extend({}, vault_workspaces())
table.insert(workspaces, {
	-- Markdown files outside a configured vault still get the note commands.
	name = "markdown",
	path = function()
		return assert(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
	end,
	overrides = {
		notes_subdir = vim.NIL,
		new_notes_location = "current_dir",
		templates = {
			folder = vim.NIL,
		},
		disable_frontmatter = true,
	},
})

---@type LazySpec
return {
	"epwalsh/obsidian.nvim",
	enabled = markdown.enabled,
	version = "*",
	ft = "markdown",
	cmd = {
		"ObsidianNew",
		"ObsidianQuickSwitch",
		"ObsidianSearch",
		"ObsidianToday",
		"ObsidianBacklinks",
		"ObsidianRename",
		"ObsidianFollowLink",
		"ObsidianToggleCheckbox",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	keys = {
		{ "<leader>nn", "<cmd>ObsidianNew<cr>", desc = "New note" },
		{ "<leader>nf", "<cmd>ObsidianQuickSwitch<cr>", desc = "Find note" },
		{ "<leader>ns", "<cmd>ObsidianSearch<cr>", desc = "Search notes" },
		{ "<leader>nt", "<cmd>ObsidianToday<cr>", desc = "Today's note" },
		{ "<leader>nb", "<cmd>ObsidianBacklinks<cr>", desc = "Note backlinks" },
		{ "<leader>nr", "<cmd>ObsidianRename<cr>", desc = "Rename note" },
	},
	opts = {
		workspaces = workspaces,
		-- New notes land next to the file you have open, named from the title.
		new_notes_location = "current_dir",
		note_id_func = function(title)
			if title ~= nil and title ~= "" then
				local slug = title:gsub("%s+", "-"):gsub("[^%w%-]", ""):lower()
				if slug ~= "" then
					return slug
				end
			end
			return tostring(os.time())
		end,
		preferred_link_style = "wiki",
		-- Leave existing YAML alone. A notes folder used by another tool should stay as written.
		disable_frontmatter = true,
		daily_notes = {
			folder = "daily",
			date_format = "%Y-%m-%d",
		},
		templates = {
			folder = "templates",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
		},
		-- Link completion needs nvim-cmp, which Thiran does not ship.
		completion = {
			nvim_cmp = false,
		},
		picker = {
			name = "telescope.nvim",
		},
		sort_by = "modified",
		sort_reversed = true,
		follow_url_func = function(url)
			vim.ui.open(url)
		end,
		attachments = {
			img_folder = "assets",
		},
		mappings = {
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			["<leader>nc"] = {
				action = function()
					return require("obsidian").util.toggle_checkbox()
				end,
				opts = { buffer = true },
			},
		},
		-- render-markdown draws checkboxes, lists, links, and callouts.
		-- Leaving this on draws them a second time.
		ui = {
			enable = false,
		},
	},
}
