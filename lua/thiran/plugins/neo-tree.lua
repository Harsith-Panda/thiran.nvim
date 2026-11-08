-- .git is the repository database. Show it, and refuse edits that would change it.
local function git_store(path)
	if type(path) ~= "string" or path == "" then
		return false
	end
	path = vim.fs.normalize(path)
	return path:find("/%.git$") ~= nil or path:find("/%.git/") ~= nil
end

local function protected(state, selected_nodes)
	local nodes = selected_nodes
	if not nodes then
		local node = state.tree and state.tree:get_node()
		nodes = node and { node } or {}
	end
	for _, node in pairs(nodes) do
		if git_store(node.path) then
			vim.notify(".git is visible, but protected", vim.log.levels.WARN)
			return true
		end
	end
	return false
end

local function guard(name)
	return function(state, selected_nodes)
		if protected(state, selected_nodes) then
			return
		end
		return require("neo-tree.sources.filesystem.commands")[name](state, selected_nodes)
	end
end

return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		-- Neo-tree loads its UI on demand. Loading the plugin at startup lets it
		-- replace netrw when Neovim is opened on a directory.
		lazy = false,
		keys = {
			{ "<leader>e", "<cmd>Neotree toggle reveal<cr>", desc = "Toggle explorer" },
		},
		opts = {
			close_if_last_window = true,
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,
			window = {
				position = "left",
				width = 34,
				mappings = {
					-- Space is the leader. Leave it free so <leader>e still toggles from inside the tree.
					["<space>"] = "none",
					["h"] = "close_node",
					["l"] = "open",
				},
			},
			filesystem = {
				follow_current_file = {
					enabled = true,
				},
				use_libuv_file_watcher = true,
				hijack_netrw_behavior = "open_default",
				filtered_items = {
					hide_dotfiles = false,
					hide_gitignored = true,
				},
				commands = {
					add = guard("add"),
					add_directory = guard("add_directory"),
					delete = guard("delete"),
					delete_visual = guard("delete_visual"),
					trash = guard("trash"),
					trash_visual = guard("trash_visual"),
					rename = guard("rename"),
					rename_basename = guard("rename_basename"),
					move = guard("move"),
					cut_to_clipboard = guard("cut_to_clipboard"),
					cut_to_clipboard_visual = guard("cut_to_clipboard_visual"),
					copy_to_clipboard = guard("copy_to_clipboard"),
					copy_to_clipboard_visual = guard("copy_to_clipboard_visual"),
					paste_from_clipboard = function(state)
						local node = state.tree and state.tree:get_node()
						local dest = node and node.path
						if node and node.type ~= "directory" and node.get_parent_id then
							dest = node:get_parent_id()
						end
						if git_store(dest) then
							vim.notify(".git is visible, but protected", vim.log.levels.WARN)
							return
						end
						for _, item in pairs(state.clipboard or {}) do
							if git_store(item.node and item.node.path) then
								vim.notify(".git is visible, but protected", vim.log.levels.WARN)
								return
							end
						end
						require("neo-tree.sources.filesystem.commands").paste_from_clipboard(state)
					end,
				},
			},
		},
	},
}
