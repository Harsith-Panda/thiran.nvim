-- .git is the repository database. Show it, and refuse edits that would change it.
local function git_store(path)
	if type(path) ~= "string" or path == "" then
		return false
	end
	path = vim.fs.normalize((path:gsub("^%w+://", "")))
	return path:find("/%.git$") ~= nil or path:find("/%.git/") ~= nil
end

return {
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
			{
				"<leader>o",
				function()
					require("oil").toggle_float()
				end,
				desc = "Oil float",
			},
		},
		---@module "oil"
		---@type oil.SetupOpts
		opts = {
			-- Neo-tree opens directories. Oil is for editing a directory like a buffer.
			default_file_explorer = false,
			columns = { "icon", "size" },
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
			constrain_cursor = "name",
			watch_for_changes = true,
			view_options = {
				show_hidden = true,
				highlight_filename = function(entry, _, _, _, bufnr)
					local parent = vim.api.nvim_buf_get_name(bufnr)
					if entry.name == ".git" or git_store(parent) then
						return "DiagnosticWarn"
					end
				end,
			},
			float = {
				border = "rounded",
				max_width = 0.8,
				max_height = 0.8,
			},
			confirmation = {
				border = "rounded",
			},
			keymaps_help = {
				border = "rounded",
			},
		},
		config = function(_, opts)
			local oil = require("oil")
			oil.setup(opts)

			local confirmation = require("oil.mutator.confirmation")
			if confirmation._thiran_git_protected then
				return
			end
			local show = confirmation.show
			confirmation.show = function(actions, should_confirm, cb)
				for _, action in ipairs(actions) do
					if git_store(action.url) or git_store(action.src_url) or git_store(action.dest_url) then
						vim.notify(".git is visible, but protected", vim.log.levels.WARN)
						cb(false)
						oil.discard_all_changes()
						return
					end
				end
				show(actions, should_confirm, cb)
			end
			confirmation._thiran_git_protected = true
		end,
	},
}
